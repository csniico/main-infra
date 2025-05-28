# General
variable "name" {
  description = "Name of the EFS file system"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefix to add to the EFS file system name"
  type        = string
  default     = null
}

variable "create_file_system" {
  description = "Whether to create an EFS file system"
  type        = bool
  default     = true
}

variable "create_mount_targets" {
  description = "Whether to create mount targets for the EFS file system"
  type        = bool
  default     = true
}

variable "create_access_points" {
  description = "Whether to create access points for the EFS file system"
  type        = bool
  default     = true
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC where the EFS file system will be created"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs where mount targets will be created"
  type        = list(string)
  default     = null
}

# Security Group
variable "security_group_ids" {
  description = "List of security group IDs to attach to the mount targets"
  type        = list(string)
  default     = []
}

# Performance Settings
variable "performance_mode" {
  description = "The file system performance mode. Can be 'generalPurpose' or 'maxIO'"
  type        = string
  default     = "generalPurpose"
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Valid values for performance_mode are (generalPurpose, maxIO)."
  }
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Can be 'bursting', 'provisioned', or 'elastic'"
  type        = string
  default     = "bursting"
  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Valid values for throughput_mode are (bursting, provisioned, elastic)."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to 'provisioned'"
  type        = number
  default     = null
}

# Encryption
variable "encrypted" {
  description = "If true, the file system will be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting the file system"
  type        = string
  default     = null
}

# Lifecycle Policies
variable "transition_to_ia" {
  description = "Describes the period of time that a file is not accessed, after which it transitions to IA storage. Can be AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS"
  type        = string
  default     = null
  validation {
    condition     = var.transition_to_ia == null ? true : contains(["AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"], var.transition_to_ia)
    error_message = "Valid values for transition_to_ia are (AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS)."
  }
}

variable "transition_to_primary_storage_class" {
  description = "Describes the period of time that a file is not accessed, after which it transitions back to primary storage. Can be AFTER_1_ACCESS"
  type        = string
  default     = null
  validation {
    condition     = var.transition_to_primary_storage_class == null ? true : contains(["AFTER_1_ACCESS"], var.transition_to_primary_storage_class)
    error_message = "Valid value for transition_to_primary_storage_class is AFTER_1_ACCESS."
  }
}

variable "enable_protection" {
  description = "Whether to enable protection for the file system"
  type        = bool
  default     = false
}

# Backup
variable "enable_backup" {
  description = "Whether to enable automatic backups"
  type        = bool
  default     = true
}

# Access Points
variable "access_points" {
  description = "List of access points to create"
  type        = list(object({
    name                  = string
    root_directory_path   = optional(string, "/")
    owner_uid             = optional(number)
    owner_gid             = optional(number)
    permissions           = optional(string, "0755")
    posix_user_uid        = optional(number)
    posix_user_gid        = optional(number)
    posix_user_secondary_gids = optional(list(number))
  }))
  default     = []
}

# Replication
variable "enable_replication" {
  description = "Whether to enable replication for the file system"
  type        = bool
  default     = false
}

variable "replication_destination_region" {
  description = "The AWS Region to replicate the file system to"
  type        = string
  default     = null
}

variable "replication_destination_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting the replicated file system"
  type        = string
  default     = null
}

variable "source_file_system_id" {
  description = "The ID of the source file system to replicate. If not provided, the source file system will be the one created by this module"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
