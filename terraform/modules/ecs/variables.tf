variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "main"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

# Cluster Configuration
variable "create_cluster" {
  description = "Controls if ECS cluster should be created"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = null
}

variable "cluster_settings" {
  description = "List of cluster settings to add to the cluster"
  type        = list(map(string))
  default = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]
}

# Capacity Providers
variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy to use for the cluster"
  type        = list(map(string))
  default     = []
}

variable "fargate_capacity_providers" {
  description = "Map of Fargate capacity providers to add to the cluster"
  type        = map(any)
  default = {
    FARGATE = {
      default_strategy = {
        base   = 0
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_strategy = {
        base   = 0
        weight = 50
      }
    }
  }
}

variable "create_ec2_capacity_provider" {
  description = "Controls if EC2 capacity provider should be created"
  type        = bool
  default     = false
}

variable "autoscaling_group_arn" {
  description = "ARN of the ASG to use for the EC2 capacity provider"
  type        = string
  default     = ""
}

# Task Definition
variable "create_task_definition" {
  description = "Controls if task definition should be created"
  type        = bool
  default     = false
}

variable "task_definition_family" {
  description = "Family name of the task definition"
  type        = string
  default     = null
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MiB"
  type        = number
  default     = 512
}

variable "network_mode" {
  description = "Network mode for the task definition"
  type        = string
  default     = "awsvpc"
}

variable "requires_compatibilities" {
  description = "Set of launch types required by the task"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "container_definitions" {
  description = "List of container definitions in JSON format or as a list of maps"
  type        = any
  default     = []
}

# Service Configuration
variable "create_service" {
  description = "Controls if ECS service should be created"
  type        = bool
  default     = false
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = null
}

variable "deployment_maximum_percent" {
  description = "Maximum percentage of tasks that can be running during a deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum percentage of tasks that must remain healthy during a deployment"
  type        = number
  default     = 100
}

variable "desired_count" {
  description = "Number of instances of the task to place and keep running"
  type        = number
  default     = 1
}

variable "force_new_deployment" {
  description = "Enable to force a new task deployment of the service"
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks"
  type        = number
  default     = 0
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI"
  type        = bool
  default     = false
}

# External Resources - Security Groups
variable "security_group_ids" {
  description = "List of security group IDs to associate with the task or service"
  type        = list(string)
  default     = []
}

# External Resources - Networking
variable "subnet_ids" {
  description = "List of subnet IDs for the ECS tasks/service"
  type        = list(string)
  default     = []
}

# External Resources - Load Balancer
variable "target_group_arns" {
  description = "List of target group ARNs to associate with the service"
  type        = list(string)
  default     = []
}

variable "load_balancer_config" {
  description = "List of load balancer configurations to associate with the service"
  type        = list(map(string))
  default     = []
}

# External Resources - IAM Roles
variable "task_execution_role_arn" {
  description = "ARN of the task execution IAM role"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN of the task IAM role"
  type        = string
  default     = null
}

# CloudWatch Log Group
variable "create_cloudwatch_log_group" {
  description = "Controls if CloudWatch log group should be created"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 30
}

# Auto Scaling
variable "enable_autoscaling" {
  description = "Controls if service auto scaling should be enabled"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks to run in the service"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks to run in the service"
  type        = number
  default     = 10
}

variable "autoscaling_policies" {
  description = "Map of autoscaling policies to create"
  type        = any
  default     = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
