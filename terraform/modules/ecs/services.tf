# ECS Service
resource "aws_ecs_service" "this" {
  count = var.create_service ? 1 : 0

  name                               = local.service_name
  cluster                            = var.create_cluster ? aws_ecs_cluster.this[0].id : var.cluster_name
  task_definition                    = var.create_task_definition ? aws_ecs_task_definition.this[0].arn : null
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  force_new_deployment               = var.force_new_deployment

  # Launch type or capacity provider strategy
  dynamic "capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = lookup(capacity_provider_strategy.value, "weight", null)
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  # Use launch type if no capacity provider strategy is defined
  launch_type = length(var.default_capacity_provider_strategy) == 0 ? "FARGATE" : null

  # Network configuration
  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? [1] : []
    content {
      subnets          = var.subnet_ids
      security_groups  = var.security_group_ids
      assign_public_ip = var.assign_public_ip
    }
  }

  # Target group attachments
  dynamic "load_balancer" {
    for_each = var.load_balancer_config
    content {
      target_group_arn = lookup(load_balancer.value, "target_group_arn", null)
      container_name   = lookup(load_balancer.value, "container_name", null)
      container_port   = lookup(load_balancer.value, "container_port", null)
    }
  }

  # Ignore changes to desired_count if autoscaling is enabled
  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }

  tags = merge(
    var.tags,
    {
      Name = local.service_name
    }
  )
}
