data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Use provided name or generate one
  alarm_name_prefix = var.name_prefix != null ? "${var.name_prefix}-" : ""
  
  # Default dashboard name if none provided
  dashboard_name = var.dashboard_name != null ? var.dashboard_name : "${local.alarm_name_prefix}${var.name}-dashboard"
  
  # Default log group name if none provided
  log_group_name = var.log_group_name != null ? var.log_group_name : "${local.alarm_name_prefix}${var.name}-logs"
}
