# Load Balancer Outputs
output "lb_id" {
  description = "The ID of the load balancer"
  value       = aws_lb.this.id
}

output "lb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "lb_name" {
  description = "The name of the load balancer"
  value       = aws_lb.this.name
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.this.zone_id
}

output "lb_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.this.arn_suffix
}

output "lb_security_group_ids" {
  description = "The security group IDs attached to the load balancer"
  value       = var.security_group_ids
}

output "lb_subnet_ids" {
  description = "The subnet IDs attached to the load balancer"
  value       = var.subnet_ids
}

# Target Group Outputs
output "target_group_arn" {
  description = "The ARN of the default target group"
  value       = var.create_target_group ? aws_lb_target_group.this[0].arn : null
}

output "target_group_id" {
  description = "The ID of the default target group"
  value       = var.create_target_group ? aws_lb_target_group.this[0].id : null
}

output "target_group_name" {
  description = "The name of the default target group"
  value       = var.create_target_group ? aws_lb_target_group.this[0].name : null
}

output "target_group_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics for the default target group"
  value       = var.create_target_group ? aws_lb_target_group.this[0].arn_suffix : null
}

output "target_group_arns" {
  description = "ARNs of all target groups"
  value       = concat(
    var.create_target_group ? [aws_lb_target_group.this[0].arn] : [],
    [for tg in aws_lb_target_group.additional : tg.arn]
  )
}

output "target_group_names" {
  description = "Names of all target groups"
  value       = concat(
    var.create_target_group ? [aws_lb_target_group.this[0].name] : [],
    [for tg in aws_lb_target_group.additional : tg.name]
  )
}

# Listener Outputs
output "http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = var.create_listener && var.protocol == "HTTP" ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  value       = var.create_listener && var.protocol == "HTTPS" && var.listener_certificate_arn != null ? aws_lb_listener.https[0].arn : null
}

output "listener_arns" {
  description = "ARNs of all listeners"
  value       = concat(
    var.create_listener && var.protocol == "HTTP" ? [aws_lb_listener.http[0].arn] : [],
    var.create_listener && var.protocol == "HTTPS" && var.listener_certificate_arn != null ? [aws_lb_listener.https[0].arn] : [],
    [for listener in aws_lb_listener.additional : listener.arn]
  )
}
