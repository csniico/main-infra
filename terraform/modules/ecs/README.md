# AWS ECS Terraform Module

This module provisions an AWS Elastic Container Service (ECS) cluster with support for both Fargate and EC2 launch types, task definitions, and services. It follows the principle of separation of concerns by accepting external resources like IAM roles, security groups, and load balancer configurations as inputs.

## Features

- Creates a complete ECS cluster with configurable settings
- Supports both Fargate and EC2 launch types
- Configures capacity providers (Fargate, Fargate Spot, and EC2)
- Creates task definitions with customizable container definitions
- Sets up ECS services with configurable deployment settings
- Integrates with existing VPC and subnets
- Accepts security groups from a dedicated security group module
- Supports load balancer integration with target groups from ALB module
- Uses external IAM roles
- Configures auto scaling for ECS services

## Usage

### Basic Usage with Fargate

```terraform
# Create IAM roles using the IAM module
module "ecs_iam" {
  source = "./terraform/modules/iam"

  # IAM roles configuration...
}

# Create security groups using the security-group module
module "ecs_sg" {
  source = "./terraform/modules/security-group"

  # Security group configuration...
}

# Create ECS resources
module "ecs" {
  source = "./terraform/modules/ecs"

  name       = "web-app"
  subnet_ids = module.vpc.private_subnet_ids

  # Use IAM roles from IAM module
  task_execution_role_arn = module.ecs_iam.role_arn
  task_role_arn           = module.ecs_iam.role_arn

  # Use security groups from security-group module
  security_group_ids = [module.ecs_sg.security_group_id]

  # Task definition settings
  task_cpu             = 256
  task_memory          = 512
  container_definitions = [
    {
      name      = "web"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/web-app"
          "awslogs-region"        = "us-west-1"
          "awslogs-stream-prefix" = "web"
        }
      }
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "web-app"
  }
}
```

### Advanced Usage with Custom Container Definition and Load Balancer

```terraform
# Create IAM roles, security groups, and other resources using dedicated modules...

# Create load balancer using the ALB module
module "alb" {
  source = "./terraform/modules/alb"

  # Load balancer configuration...
}

# Create ECS resources
module "ecs" {
  source = "./terraform/modules/ecs"

  name         = "api-service"
  cluster_name = "production-cluster"
  subnet_ids   = module.vpc.private_subnet_ids

  # Use IAM roles from IAM module
  task_execution_role_arn = module.ecs_iam.role_arn
  task_role_arn           = module.ecs_iam.role_arn

  # Use security groups from security-group module
  security_group_ids = [module.ecs_sg.security_group_id]

  # Task definition settings
  task_cpu             = 1024
  task_memory          = 2048
  container_definitions = [
    {
      name      = "api"
      image     = "123456789012.dkr.ecr.us-west-1.amazonaws.com/api:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "production"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/api-service"
          "awslogs-region"        = "us-west-1"
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  ]

  # Service settings
  desired_count                      = 3
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = 60

  # Load balancer integration using ALB module outputs
  load_balancer_config = [
    {
      target_group_arn = module.alb.target_group_arns[0]
      container_name   = "api"
      container_port   = 8080
    }
  ]

  # Auto scaling
  enable_autoscaling       = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 10
  autoscaling_policies = {
    cpu = {
      policy_type            = "TargetTrackingScaling"
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 70
    }
    memory = {
      policy_type            = "TargetTrackingScaling"
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
      target_value           = 80
    }
  }

  tags = {
    Environment = "production"
    Project     = "api"
  }
}
```

### Using EC2 Launch Type

```terraform
# Create IAM roles, security groups, and other resources using dedicated modules...

# Create Auto Scaling Group using the ASG module
module "ecs_asg" {
  source = "./terraform/modules/asg"

  # ASG configuration...
}

# Create ECS resources
module "ecs" {
  source = "./terraform/modules/ecs"

  name       = "batch-processor"
  subnet_ids = module.vpc.private_subnet_ids

  # Use IAM roles from IAM module
  task_execution_role_arn = module.ecs_iam.role_arn
  task_role_arn           = module.ecs_iam.role_arn

  # Use security groups from security-group module
  security_group_ids = [module.ecs_sg.security_group_id]

  # EC2 capacity provider
  create_ec2_capacity_provider = true
  autoscaling_group_arn        = module.ecs_asg.autoscaling_group_arn

  # Use EC2 launch type
  default_capacity_provider_strategy = [
    {
      capacity_provider = "ec2_capacity_provider"
      weight            = 100
      base              = 1
    }
  ]

  # Task definition for EC2
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"

  # Rest of the configuration...
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name prefix for all resources | string | "main" | no |
| region | AWS region to deploy resources | string | "eu-west-1" | no |
| create_cluster | Controls if ECS cluster should be created | bool | true | no |
| cluster_name | Name of the ECS cluster | string | null | no |
| cluster_settings | List of cluster settings to add to the cluster | list(map(string)) | [{name = "containerInsights", value = "enabled"}] | no |
| default_capacity_provider_strategy | Default capacity provider strategy to use for the cluster | list(map(string)) | [] | no |
| fargate_capacity_providers | Map of Fargate capacity providers to add to the cluster | map(any) | {FARGATE = {...}, FARGATE_SPOT = {...}} | no |
| create_ec2_capacity_provider | Controls if EC2 capacity provider should be created | bool | false | no |
| autoscaling_group_arn | ARN of the ASG to use for the EC2 capacity provider | string | "" | no |
| create_task_definition | Controls if task definition should be created | bool | true | no |
| task_definition_family | Family name of the task definition | string | null | no |
| task_cpu | CPU units for the task | number | 256 | no |
| task_memory | Memory for the task in MiB | number | 512 | no |
| network_mode | Network mode for the task definition | string | "awsvpc" | no |
| requires_compatibilities | Set of launch types required by the task | list(string) | ["FARGATE"] | no |
| container_definitions | List of container definitions in JSON format or as a list of maps | any | [] | no |
| create_service | Controls if ECS service should be created | bool | true | no |
| service_name | Name of the ECS service | string | null | no |
| deployment_maximum_percent | Maximum percentage of tasks that can be running during a deployment | number | 200 | no |
| deployment_minimum_healthy_percent | Minimum percentage of tasks that must remain healthy during a deployment | number | 100 | no |
| desired_count | Number of instances of the task to place and keep running | number | 1 | no |
| force_new_deployment | Enable to force a new task deployment of the service | bool | false | no |
| health_check_grace_period_seconds | Seconds to ignore failing load balancer health checks on newly instantiated tasks | number | 0 | no |
| assign_public_ip | Assign a public IP address to the ENI | bool | false | no |
| security_group_ids | List of security group IDs to associate with the task or service | list(string) | [] | no |
| subnet_ids | List of subnet IDs for the ECS tasks/service | list(string) | [] | no |
| target_group_arns | List of target group ARNs to associate with the service | list(string) | [] | no |
| load_balancer_config | List of load balancer configurations to associate with the service | list(map(string)) | [] | no |
| task_execution_role_arn | ARN of the task execution IAM role | string | null | no |
| task_role_arn | ARN of the task IAM role | string | null | no |
| create_cloudwatch_log_group | Controls if CloudWatch log group should be created | bool | true | no |
| cloudwatch_log_group_name | Name of the CloudWatch log group | string | null | no |
| cloudwatch_log_group_retention_in_days | Number of days to retain log events | number | 30 | no |
| enable_autoscaling | Controls if service auto scaling should be enabled | bool | false | no |
| autoscaling_min_capacity | Minimum number of tasks to run in the service | number | 1 | no |
| autoscaling_max_capacity | Maximum number of tasks to run in the service | number | 10 | no |
| autoscaling_policies | Map of autoscaling policies to create | any | {} | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the ECS cluster |
| cluster_arn | The ARN of the ECS cluster |
| cluster_name | The name of the ECS cluster |
| task_definition_arn | The ARN of the Task Definition |
| task_definition_family | The family of the Task Definition |
| task_definition_revision | The revision of the Task Definition |
| service_id | The ID of the ECS service |
| service_name | The name of the ECS service |
| service_arn | The ARN of the ECS service |
| cloudwatch_log_group_arn | The ARN of the CloudWatch log group |
| cloudwatch_log_group_name | The name of the CloudWatch log group |
| autoscaling_target_id | The ID of the Application Auto Scaling Target |
| autoscaling_policies | Map of Auto Scaling Policies and their ARNs |

## Prerequisites

- AWS account and credentials configured
- Terraform 0.13 or later
- AWS provider 3.0 or later
- VPC with subnets (from a VPC module)
- Security groups (from a security-group module)
- IAM roles (from an IAM module)
- Load balancer and target groups (from an ALB module) if needed

## Notes

- This module follows the principle of separation of concerns by accepting external resources as inputs
- For production workloads, it's recommended to use private subnets for ECS tasks
- When using Fargate, the `awsvpc` network mode is required
- For EC2 launch type, you need to create an Auto Scaling Group using a dedicated ASG module
- The module creates a default container definition if none is provided
- Auto scaling is disabled by default but can be enabled with the `enable_autoscaling` variable
- IAM roles, security groups, and load balancers should be created using their respective dedicated modules
