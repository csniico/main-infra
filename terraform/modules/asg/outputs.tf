# Auto Scaling Group Outputs
output "autoscaling_group_id" {
  description = "The ID of the Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.this[0].id : null
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.this[0].name : null
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.this[0].arn : null
}

output "autoscaling_group_min_size" {
  description = "The minimum size of the Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.this[0].min_size : null
}

output "autoscaling_group_max_size" {
  description = "The maximum size of the Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.this[0].max_size : null
}

output "autoscaling_group_desired_capacity" {
  description = "The desired capacity of the Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.this[0].desired_capacity : null
}

output "autoscaling_group_health_check_type" {
  description = "The health check type of the Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.this[0].health_check_type : null
}

output "autoscaling_group_vpc_zone_identifier" {
  description = "The VPC zone identifier of the Auto Scaling Group"
  value       = var.create_asg ? aws_autoscaling_group.this[0].vpc_zone_identifier : null
}

# Launch Template Outputs
output "launch_template_id" {
  description = "The ID of the Launch Template"
  value       = var.create_launch_template ? aws_launch_template.this[0].id : null
}

output "launch_template_arn" {
  description = "The ARN of the Launch Template"
  value       = var.create_launch_template ? aws_launch_template.this[0].arn : null
}

output "launch_template_name" {
  description = "The name of the Launch Template"
  value       = var.create_launch_template ? aws_launch_template.this[0].name : null
}

output "launch_template_latest_version" {
  description = "The latest version of the Launch Template"
  value       = var.create_launch_template ? aws_launch_template.this[0].latest_version : null
}

output "launch_template_default_version" {
  description = "The default version of the Launch Template"
  value       = var.create_launch_template ? aws_launch_template.this[0].default_version : null
}
