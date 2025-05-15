# Repository Outputs
output "repository_id" {
  description = "The ID of the ECR repository"
  value       = var.create_repository ? aws_ecr_repository.this[0].id : null
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = var.create_repository ? aws_ecr_repository.this[0].arn : null
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = var.create_repository ? aws_ecr_repository.this[0].name : null
}

output "repository_url" {
  description = "The URL of the ECR repository"
  value       = var.create_repository ? aws_ecr_repository.this[0].repository_url : null
}

output "repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = var.create_repository ? aws_ecr_repository.this[0].registry_id : null
}

# Policy Outputs
output "repository_policy_id" {
  description = "The ID of the ECR repository policy"
  value       = var.create_repository && var.create_repository_policy ? aws_ecr_repository_policy.this[0].id : null
}

output "lifecycle_policy_id" {
  description = "The ID of the ECR lifecycle policy"
  value       = var.create_repository && var.create_lifecycle_policy ? aws_ecr_lifecycle_policy.this[0].id : null
}

# Replication Configuration Output
output "replication_configuration_id" {
  description = "The ID of the ECR replication configuration"
  value       = var.create_repository && var.enable_replication && length(var.replication_destinations) > 0 ? aws_ecr_replication_configuration.this[0].id : null
}
