variable "name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to add to the Auto Scaling Group name"
  type        = string
  default     = null
}

# Launch Template Configuration
variable "create_launch_template" {
  description = "Controls if the Launch Template should be created"
  type        = bool
  default     = true
}

variable "launch_template_name" {
  description = "Name of the Launch Template"
  type        = string
  default     = null
}

variable "launch_template_description" {
  description = "Description of the Launch Template"
  type        = string
  default     = null
}

variable "update_default_version" {
  description = "Whether to update Default Version each update"
  type        = bool
  default     = true
}

variable "image_id" {
  description = "The AMI ID to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "The key name to use for the instance"
  type        = string
  default     = null
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  type        = string
  default     = null
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring"
  type        = bool
  default     = true
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type        = map(string)
  default     = {}
}

variable "block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type        = list(any)
  default     = []
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile to associate with launched instances"
  type        = string
  default     = null
}

variable "tag_specifications" {
  description = "The tags to apply to the resources during launch"
  type        = list(any)
  default     = []
}

# Auto Scaling Group Configuration
variable "create_asg" {
  description = "Controls if the Auto Scaling Group should be created"
  type        = bool
  default     = true
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "capacity_rebalance" {
  description = "Indicates whether capacity rebalance is enabled"
  type        = bool
  default     = false
}

variable "default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start"
  type        = number
  default     = 300
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "Controls how health checking is done. Valid values are EC2 or ELB"
  type        = string
  default     = "EC2"
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Valid values for health_check_type are (EC2, ELB)."
  }
}

variable "force_delete" {
  description = "Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate"
  type        = bool
  default     = false
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the Auto Scaling Group should be terminated"
  type        = list(string)
  default     = ["Default"]
}

# Networking
variable "vpc_zone_identifier" {
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
}

# Load Balancer Integration
variable "target_group_arns" {
  description = "A list of aws_alb_target_group ARNs, for use with Application Load Balancing"
  type        = list(string)
  default     = []
}

# Security Groups
variable "security_group_ids" {
  description = "A list of security group IDs to associate with the instances"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
