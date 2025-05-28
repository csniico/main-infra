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

# Service Discovery Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "this" {
  count = var.create_service_discovery_namespace && var.service_discovery_namespace_type == "DNS_PRIVATE" ? 1 : 0

  name        = local.service_discovery_namespace_name
  description = var.service_discovery_namespace_description
  vpc         = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = local.service_discovery_namespace_name
    }
  )
}

# Service Discovery Public DNS Namespace
resource "aws_service_discovery_public_dns_namespace" "this" {
  count = var.create_service_discovery_namespace && var.service_discovery_namespace_type == "DNS_PUBLIC" ? 1 : 0

  name        = local.service_discovery_namespace_name
  description = var.service_discovery_namespace_description

  tags = merge(
    var.tags,
    {
      Name = local.service_discovery_namespace_name
    }
  )
}

# Service Discovery Service
resource "aws_service_discovery_service" "this" {
  count = var.enable_service_discovery ? 1 : 0

  name         = local.service_discovery_service_name
  namespace_id = local.service_discovery_namespace_id

  dns_config {
    namespace_id = local.service_discovery_namespace_id

    dns_records {
      ttl  = var.service_discovery_dns_ttl
      type = var.service_discovery_dns_type
    }

    routing_policy = "MULTIVALUE"
  }

  dynamic "health_check_custom_config" {
    for_each = var.service_discovery_namespace_type == "DNS_PRIVATE" ? [1] : []
    content {
      failure_threshold = var.service_discovery_failure_threshold
    }
  }

  tags = merge(
    var.tags,
    {
      Name = local.service_discovery_service_name
    }
  )
}
