# ECS Cluster
resource "aws_ecs_cluster" "this" {
  count = var.create_cluster ? 1 : 0

  name = local.cluster_name

  dynamic "setting" {
    for_each = var.cluster_settings
    content {
      name  = setting.value.name
      value = setting.value.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = local.cluster_name
    }
  )
}

# Fargate Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "this" {
  count = var.create_cluster ? 1 : 0

  cluster_name = aws_ecs_cluster.this[0].name

  capacity_providers = concat(
    [for k, v in var.fargate_capacity_providers : k],
    var.create_ec2_capacity_provider && var.autoscaling_group_arn != "" ? ["ec2_capacity_provider"] : []
  )

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = lookup(default_capacity_provider_strategy.value, "weight", null)
      base              = lookup(default_capacity_provider_strategy.value, "base", null)
    }
  }

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy == [] ? var.fargate_capacity_providers : {}
    iterator = strategy

    content {
      capacity_provider = strategy.key
      weight            = lookup(strategy.value.default_strategy, "weight", null)
      base              = lookup(strategy.value.default_strategy, "base", null)
    }
  }
}

# EC2 Capacity Provider (if enabled)
resource "aws_ecs_capacity_provider" "ec2" {
  count = var.create_cluster && var.create_ec2_capacity_provider && var.autoscaling_group_arn != "" ? 1 : 0

  name = "ec2_capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = var.autoscaling_group_arn

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "ec2_capacity_provider"
    }
  )
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_cloudwatch_log_group ? 1 : 0

  name              = local.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_group_retention_in_days

  tags = merge(
    var.tags,
    {
      Name = local.cloudwatch_log_group_name
    }
  )
}
