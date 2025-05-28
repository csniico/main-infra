# IAM Role for DR Failover Lambda
module "dr_failover_lambda_role" {
  source = "../../modules/iam"

  name = "${local.name}-dr-failover-lambda"

  # Role configuration
  trusted_role_services = ["lambda.amazonaws.com"]

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  # Custom policy for RDS, ASG, ECS, and ELB operations
  policies = {
    dr_failover = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "rds:DescribeDBInstances",
            "rds:PromoteReadReplica",
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:UpdateAutoScalingGroup",
            "ecs:DescribeServices",
            "ecs:UpdateService",
            "ecs:ListTasks",
            "ecs:DescribeTasks",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:RegisterTargets",
            "ec2:DescribeInstances"
          ],
          Resource = "*"
        }
      ]
    })
  }

  tags = var.tags
}

# Lambda Function for DR Failover
module "dr_failover_lambda" {
  source = "../../modules/lambda"

  name        = "${local.name}-dr-failover"
  description = "Lambda function to handle DR failover operations"
  role_arn    = module.dr_failover_lambda_role.role_arn
  runtime     = "python3.9"
  handler     = "dr_failover.handler"
  timeout     = 300  # 5 minutes
  memory_size = 256

  # Deployment package
  deployment_package_type = "local_file"
  local_filename          = "${path.module}/../../../scripts/lambda/dr_failover.zip"

  # Environment variables
  environment_variables = {
    DB_INSTANCE_IDENTIFIER = module.rds.db_instance_id
    JENKINS_ASG_NAME      = module.jenkins_asg.autoscaling_group_name
    MONITORING_ASG_NAME   = module.monitoring_asg.autoscaling_group_name
    ECS_CLUSTER_NAME      = module.ecs_cluster.cluster_name
    ECS_SERVICES          = join(",", [
      var.service_names["frontend"],
      var.service_names["notification_service"],
      var.service_names["user_service"],
      var.service_names["task_api"],
      var.service_names["ckafka"]
    ])
    TARGET_GROUPS = jsonencode({
      # Jenkins target group
      (module.alb.target_group_arns_map["jenkins"]) = {
        type       = "instance",
        source_asg = module.jenkins_asg.autoscaling_group_name
      },
      # Prometheus target group
      (module.alb.target_group_arns_map["prometheus"]) = {
        type       = "instance",
        source_asg = module.monitoring_asg.autoscaling_group_name
      },
      # Grafana target group
      (module.alb.target_group_arns_map["grafana"]) = {
        type       = "instance",
        source_asg = module.monitoring_asg.autoscaling_group_name
      },
      # Jaeger target group
      (module.alb.target_group_arns_map["jaeger"]) = {
        type       = "instance",
        source_asg = module.monitoring_asg.autoscaling_group_name
      }
      # Uncomment and add ECS service target groups when they're enabled
      # (module.alb.target_group_arns_map["frontend"]) = {
      #   type       = "ip",
      #   source_ecs = "${module.ecs_cluster.cluster_name}/${var.service_names["frontend"]}"
      # }
    })
  }

  # CloudWatch Event Rule to trigger Lambda (disabled by default)
  permissions = {
    cloudwatch_events = {
      action    = "lambda:InvokeFunction",
      principal = "events.amazonaws.com"
    }
  }

  tags = var.tags
}

# CloudWatch Event Rule for manual DR failover testing
resource "aws_cloudwatch_event_rule" "dr_failover_test" {
  name        = "${local.name}-dr-failover-test"
  description = "Rule to manually test DR failover process"
  
  # This schedule expression is disabled (never runs automatically)
  schedule_expression = "rate(999 days)"
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "dr_failover_lambda" {
  rule      = aws_cloudwatch_event_rule.dr_failover_test.name
  target_id = "${local.name}-dr-failover-lambda"
  arn       = module.dr_failover_lambda.function_arn
}
