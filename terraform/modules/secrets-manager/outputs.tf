# Single Secret Outputs
output "secret_id" {
  description = "The ID of the secret"
  value       = var.create_secret ? try(aws_secretsmanager_secret.this[0].id, null) : null
}

output "secret_arn" {
  description = "The ARN of the secret"
  value       = var.create_secret ? try(aws_secretsmanager_secret.this[0].arn, null) : null
}

output "secret_name" {
  description = "The name of the secret"
  value       = var.create_secret ? try(aws_secretsmanager_secret.this[0].name, null) : null
}

output "secret_version_id" {
  description = "The unique identifier of the version of the secret"
  value       = var.create_secret && (var.secret_string != null || var.secret_key_value != null) ? (
    var.secret_string != null ? 
    try(aws_secretsmanager_secret_version.this[0].version_id, null) : 
    try(aws_secretsmanager_secret_version.json[0].version_id, null)
  ) : null
}

output "secret_policy_id" {
  description = "The ID of the secret policy"
  value       = var.create_secret && var.secret_policy != null ? try(aws_secretsmanager_secret_policy.this[0].id, null) : null
}

output "access_policy_id" {
  description = "The ID of the IAM policy for accessing the secret"
  value       = var.create_secret && var.create_access_policy ? try(aws_iam_policy.secret_access_policy[0].id, null) : null
}

output "access_policy_arn" {
  description = "The ARN of the IAM policy for accessing the secret"
  value       = var.create_secret && var.create_access_policy ? try(aws_iam_policy.secret_access_policy[0].arn, null) : null
}

output "access_policy_name" {
  description = "The name of the IAM policy for accessing the secret"
  value       = var.create_secret && var.create_access_policy ? try(aws_iam_policy.secret_access_policy[0].name, null) : null
}

# Multiple Secrets Outputs
output "secrets" {
  description = "Map of secrets created and their attributes"
  value       = !var.create_secret ? {
    for k, v in aws_secretsmanager_secret.multiple : k => {
      id         = v.id
      arn        = v.arn
      name       = v.name
      tags       = v.tags
      version_id = try(
        aws_secretsmanager_secret_version.multiple[k].version_id,
        try(aws_secretsmanager_secret_version.multiple_json[k].version_id, null)
      )
      policy_id  = try(aws_secretsmanager_secret_policy.multiple[k].id, null)
    }
  } : {}
  sensitive = true
}

output "secret_arns" {
  description = "Map of secret names to ARNs"
  value       = !var.create_secret ? {
    for k, v in aws_secretsmanager_secret.multiple : k => v.arn
  } : {}
}

output "secret_ids" {
  description = "Map of secret names to IDs"
  value       = !var.create_secret ? {
    for k, v in aws_secretsmanager_secret.multiple : k => v.id
  } : {}
}

output "access_policy_arns" {
  description = "Map of secret names to access policy ARNs"
  value       = !var.create_secret ? {
    for k, v in aws_iam_policy.multiple_secret_access_policy : k => v.arn
  } : {}
}
