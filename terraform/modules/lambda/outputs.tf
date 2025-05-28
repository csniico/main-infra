# Lambda Function Outputs
output "function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_qualified_arn" {
  description = "The qualified ARN of the Lambda function"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "function_last_modified" {
  description = "The date the Lambda function was last modified"
  value       = aws_lambda_function.this.last_modified
}

output "function_kms_key_arn" {
  description = "The ARN of the KMS key used to encrypt the Lambda function's environment variables"
  value       = aws_lambda_function.this.kms_key_arn
}

output "function_source_code_hash" {
  description = "Base64-encoded representation of raw SHA-256 sum of the zip file"
  value       = aws_lambda_function.this.source_code_hash
}

output "function_source_code_size" {
  description = "The size in bytes of the function .zip file"
  value       = aws_lambda_function.this.source_code_size
}

output "function_invoke_arn" {
  description = "The ARN to be used for invoking Lambda function from API Gateway"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_signing_job_arn" {
  description = "ARN of the signing job"
  value       = aws_lambda_function.this.signing_job_arn
}

output "function_signing_profile_version_arn" {
  description = "ARN of the signing profile version"
  value       = aws_lambda_function.this.signing_profile_version_arn
}

# CloudWatch Log Group Outputs
output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : null
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].arn : null
}

# Lambda Permission Outputs
output "permission_statement_ids" {
  description = "List of statement IDs of the Lambda permissions"
  value       = [for permission in aws_lambda_permission.this : permission.statement_id]
}
