data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Use provided name or generate one
  cluster_name = var.cluster_name != null ? var.cluster_name : "${var.name}-cluster"

  # Use provided name or generate one
  task_definition_family = var.task_definition_family != null ? var.task_definition_family : "${var.name}-task"

  # Use provided name or generate one
  service_name = var.service_name != null ? var.service_name : "${var.name}-service"

  # Use provided name or generate one
  cloudwatch_log_group_name = var.cloudwatch_log_group_name != null ? var.cloudwatch_log_group_name : "/ecs/${var.name}"

  # Service Discovery
  service_discovery_namespace_name = var.service_discovery_namespace_name != null ? var.service_discovery_namespace_name : "${var.name}.local"
  service_discovery_service_name   = var.service_discovery_service_name != null ? var.service_discovery_service_name : var.name

  # Determine which namespace to use
  service_discovery_namespace_id = var.create_service_discovery_namespace ? (
    var.service_discovery_namespace_type == "DNS_PRIVATE" ?
    aws_service_discovery_private_dns_namespace.this[0].id :
    aws_service_discovery_public_dns_namespace.this[0].id
  ) : var.service_discovery_namespace_id
}
