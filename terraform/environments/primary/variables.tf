# General
variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "primary"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "primary"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "CIDR block for public subnets"
  type        = string
  default     = "10.0.0.0/20"
}

variable "private_subnets_cidr" {
  description = "CIDR block for private subnets"
  type        = string
  default     = "10.0.16.0/20"
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
    "jenkins"  = "t3.small"
    "monitoring"  = "t3.small"
  }
}

variable "asg_min_sizes" {
  description = "Minimum sizes for ASGs"
  type        = map(number)
  default = {
    "jenkins"  = 1
    "monitoring"  = 1
  }
}

variable "asg_max_sizes" {
  description = "Maximum sizes for ASGs"
  type        = map(number)
  default = {
    "jenkins"  = 3
    "monitoring"  = 3
  }
}

variable "asg_desired_capacities" {
  description = "Desired capacities for ASGs"
  type        = map(number)
  default = {
    "jenkins"  = 1
    "monitoring"  = 1
  }
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
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
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
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = null
  sensitive   = true
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "primary"
    Project     = "capstone"
    Terraform   = "true"
  }
}
