# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = module.alb_sg.security_group_id
}

output "jenkins_security_group_id" {
  description = "The ID of the Jenkins security group"
  value       = module.jenkins_sg.security_group_id
}

output "monitoring_security_group_id" {
  description = "The ID of the monitoring security group"
  value       = module.monitoring_sg.security_group_id
}

output "db_security_group_id" {
  description = "The ID of the database security group"
  value       = module.db_sg.security_group_id
}

# ALB Outputs
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.alb.lb_dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the ALB"
  value       = module.alb.lb_zone_id
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

# RDS Outputs
output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.rds.db_instance_address
}

# ASG Outputs
output "jenkins_asg_id" {
  description = "The ID of the Jenkins Auto Scaling Group"
  value       = module.jenkins_asg.autoscaling_group_id
}

output "monitoring_asg_id" {
  description = "The ID of the monitoring Auto Scaling Group"
  value       = module.monitoring_asg.autoscaling_group_id
}
