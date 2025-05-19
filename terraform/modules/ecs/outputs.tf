# Cluster Outputs
output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.this[0].id : null
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.this[0].arn : null
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = var.create_cluster ? aws_ecs_cluster.this[0].name : null
}

# Task Definition Outputs
output "task_definition_arn" {
  description = "The ARN of the Task Definition"
  value       = var.create_task_definition ? aws_ecs_task_definition.this[0].arn : null
}

output "task_definition_family" {
  description = "The family of the Task Definition"
  value       = var.create_task_definition ? aws_ecs_task_definition.this[0].family : null
}

output "task_definition_revision" {
  description = "The revision of the Task Definition"
  value       = var.create_task_definition ? aws_ecs_task_definition.this[0].revision : null
}

# Service Outputs
output "service_id" {
  description = "The ID of the ECS service"
  value       = var.create_service && var.create_task_definition ? aws_ecs_service.this[0].arn : null
}

output "service_name" {
  description = "The name of the ECS service"
  value       = var.create_service && var.create_task_definition ? aws_ecs_service.this[0].name : null
}

output "service_arn" {
  description = "The ARN of the ECS service"
  value       = var.create_service && var.create_task_definition ? aws_ecs_service.this[0].id : null
}

# CloudWatch Log Group Outputs
output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.this[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.this[0].name : null
}

# Auto Scaling Outputs
output "autoscaling_target_id" {
  description = "The ID of the Application Auto Scaling Target"
  value       = var.create_service && var.enable_autoscaling ? aws_appautoscaling_target.this[0].id : null
}

output "autoscaling_policies" {
  description = "Map of Auto Scaling Policies and their ARNs"
  value       = var.create_service && var.enable_autoscaling ? { for k, v in aws_appautoscaling_policy.this : k => v.arn } : null
}
