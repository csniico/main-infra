# General
variable "name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to add to the repository name"
  type        = string
  default     = null
}

# Repository Configuration
variable "create_repository" {
  description = "Controls if the ECR repository should be created"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Valid values for image_tag_mutability are (MUTABLE, IMMUTABLE)."
  }
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository. Valid values are AES256 or KMS"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Valid values for encryption_type are (AES256, KMS)."
  }
}

variable "kms_key" {
  description = "The ARN of the KMS key to use when encryption_type is KMS. If not specified, uses the default AWS managed key"
  type        = string
  default     = null
}

# Lifecycle Policy
variable "create_lifecycle_policy" {
  description = "Controls if a lifecycle policy should be created"
  type        = bool
  default     = false
}

variable "lifecycle_policy" {
  description = "JSON formatted lifecycle policy text to apply to the repository. If not provided, a default policy will be used"
  type        = string
  default     = null
}

variable "image_count_limit" {
  description = "The maximum number of images to keep in the repository (used in default lifecycle policy)"
  type        = number
  default     = 100
}

# Repository Policy
variable "create_repository_policy" {
  description = "Controls if a repository policy should be created"
  type        = bool
  default     = false
}

variable "repository_policy" {
  description = "JSON formatted repository policy text to apply to the repository. If not provided, a default policy will be used"
  type        = string
  default     = null
}

variable "repository_policy_principals" {
  description = "Map of principal objects for repository policy (used in default repository policy)"
  type        = any
  default     = { AWS = "*" }
}

# Cross-Region Replication
variable "enable_replication" {
  description = "Controls if cross-region replication should be enabled"
  type        = bool
  default     = false
}

variable "replication_destinations" {
  description = "List of AWS account IDs and regions to replicate the repository to"
  type        = list(object({
    region      = string
    account_id  = string
    registry_id = string
  }))
  default     = []
}

# Tags
variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}
