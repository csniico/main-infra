data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Use provided name or generate one
  function_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}" : var.name

  # CloudWatch log group name
  log_group_name = "/aws/lambda/${local.function_name}"

  # Dead letter queue configuration
  dead_letter_config = var.dead_letter_target_arn != null ? {
    target_arn = var.dead_letter_target_arn
  } : null

  # VPC configuration
  vpc_config = var.subnet_ids != null && length(var.subnet_ids) > 0 ? {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  } : null

  # Environment variables
  environment_variables = length(var.environment_variables) > 0 ? {
    variables = var.environment_variables
  } : null
}
