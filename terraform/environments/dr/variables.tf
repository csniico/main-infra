# General
variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "dr"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dr"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "eu-west-1"
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnets_cidr" {
  description = "CIDR block for public subnets"
  type        = string
  default     = "10.1.0.0/20"
}

variable "private_subnets_cidr" {
  description = "CIDR block for private subnets"
  type        = string
  default     = "10.1.16.0/20"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

# EC2 and Auto Scaling
variable "instance_types" {
  description = "EC2 instance types for ASGs"
  type        = map(string)
  default = {
    "jenkins"    = "t3.small"
    "monitoring" = "t3.small"
  }
}

variable "asg_min_sizes" {
  description = "Minimum sizes for ASGs"
  type        = map(number)
  default = {
    "jenkins"    = 1
    "monitoring" = 1
  }
}

variable "asg_max_sizes" {
  description = "Maximum sizes for ASGs"
  type        = map(number)
  default = {
    "jenkins"    = 3
    "monitoring" = 3
  }
}

variable "asg_desired_capacities" {
  description = "Desired capacities for ASGs"
  type        = map(number)
  default = {
    "jenkins"    = 0
    "monitoring" = 0
  }
}

variable "key_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
  default     = "capstone-2-dr"
}

variable "amzn_2023_ami" {
  description = "Amazon Linux 2023 AMI ID"
  type        = string
  default     = "ami-0953476d60561c955"
  
}

# EFS
variable "jenkins_id" {
  description = "UID and GID for Jenkins user and group"
  type        = number
  default     = 900
}

variable "efs_jenkins_dir" {
  description = "Directory for Jenkins on EFS"
  type        = string
  default     = "/mnt/jenkins"
}

variable "monitoring_id" {
  description = "UID and GID for monitoring user and group"
  type        = number
  default     = 901
}

variable "efs_monitoring_dir" {
  description = "Directory for monitoring on EFS"
  type        = string
  default     = "/mnt/monitoring"
}

# RDS
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "17.2"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the database (GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Ports
variable "port" {
  description = "Port for services"
  type        = map(number)
  default = {
    "jenkins"    = 8080
    "prometheus" = 7000
    "grafana"    = 7001
    "jaeger"     = 7002
    "postgres"   = 5432
    # microservices
    "frontend"             = 3000
    "notification_service" = 9292
    "user_service"         = 9193
    "task_api"             = 9191
    "ckafka"               = 9092
  }
}

# ECS
variable "service_names" {
  description = "Names for ECS services"
  type        = map(string)
  default = {
    "frontend"             = "frontend"
    "notification_service" = "notification-service"
    "user_service"         = "user-service"
    "task_api"             = "task-api"
    "ckafka"               = "ckafka"
  }
}

variable "service_min_sizes" {
  description = "Minimum sizes for ECS services"
  type        = number
  default     = 1
}

variable "service_max_sizes" {
  description = "Maximum sizes for ECS services"
  type        = number
  default     = 3
}

variable "discovery_namespace" {
  description = "Service discovery namespace"
  type        = map(any)
  default = {
    "name"        = "dr-services-namespace"
    "description" = "Services discovery namespace"
    "type"        = "DNS_PRIVATE"
    "dns_ttl"    = 60
    "dns_type"    = "A"
  }
}

# Tags
variable "primary_tags" {
  description = "Tags applied to all primary resources"
  type        = map(string)
  default = {
    Environment = "primary"
    Project     = "capstone"
    Terraform   = "true"
  }
}

variable "tags" {
  description = "Tags to apply to all DR resources"
  type        = map(string)
  default = {
    Environment = "dr"
    Project     = "capstone"
    Terraform   = "true"
  }
}
