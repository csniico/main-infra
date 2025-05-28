# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    var.tags,
    {
      Name = local.log_group_name
    }
  )
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name = local.function_name
  description   = var.description
  role          = var.role_arn
  handler       = var.package_type == "Zip" ? var.handler : null
  runtime       = var.package_type == "Zip" ? var.runtime : null
  package_type  = var.package_type

  # Deployment package configuration
  s3_bucket         = var.deployment_package_type == "s3" ? var.s3_bucket : null
  s3_key            = var.deployment_package_type == "s3" ? var.s3_key : null
  s3_object_version = var.deployment_package_type == "s3" ? var.s3_object_version : null
  filename          = var.deployment_package_type == "local_file" ? var.local_filename : null
  image_uri         = var.deployment_package_type == "image" ? var.image_uri : null

  # Function configuration
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  layers                         = var.layers
  architectures                  = var.architectures

  # Environment variables
  dynamic "environment" {
    for_each = local.environment_variables != null ? [local.environment_variables] : []
    content {
      variables = environment.value.variables
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = local.vpc_config != null ? [local.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead letter queue configuration
  dynamic "dead_letter_config" {
    for_each = local.dead_letter_config != null ? [local.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  # Tracing configuration
  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [var.tracing_mode] : []
    content {
      mode = tracing_config.value
    }
  }

  # Ephemeral storage
  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  # Ensure log group is created before the function
  depends_on = [aws_cloudwatch_log_group.this]

  tags = merge(
    var.tags,
    {
      Name = local.function_name
    }
  )
}

# Lambda Permissions
resource "aws_lambda_permission" "this" {
  for_each = var.permissions

  statement_id   = each.value.statement_id != null ? each.value.statement_id : each.key
  action         = each.value.action
  function_name  = aws_lambda_function.this.function_name
  principal      = each.value.principal
  source_arn     = each.value.source_arn
  source_account = each.value.source_account
  qualifier      = each.value.qualifier
}
