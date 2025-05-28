# General
variable "name" {
  description = "Name of the secret"
  type        = string
  default     = "example-secret"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = "Managed by Terraform"
}

# Secret Configuration
variable "create_secret" {
  description = "Whether to create a single secret (true) or multiple secrets (false)"
  type        = bool
  default     = true
}

variable "secret_string" {
  description = "Specifies text data that you want to encrypt and store in this version of the secret"
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_key_value" {
  description = "Key-value map that will be converted to JSON and stored as secret"
  type        = map(string)
  default     = null
  sensitive   = true
}

variable "recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret"
  type        = number
  default     = 30
  validation {
    condition     = var.recovery_window_in_days >= 0 && var.recovery_window_in_days <= 30
    error_message = "Recovery window must be between 0 and 30 days."
  }
}

variable "kms_key_id" {
  description = "ARN or Id of the AWS KMS key to be used to encrypt the secret values"
  type        = string
  default     = null
}

variable "force_overwrite_replica_secret" {
  description = "Whether to overwrite a secret with the same name in the destination Region"
  type        = bool
  default     = false
}

# Replica Configuration
variable "replica_regions" {
  description = "List of regions to replicate the secret to"
  type        = list(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default     = []
}

# Multiple Secrets Configuration
variable "secrets" {
  description = "Map of secrets to create"
  type        = map(object({
    description                    = optional(string)
    kms_key_id                     = optional(string)
    secret_string                  = optional(string)
    secret_key_value               = optional(map(string))
    recovery_window_in_days        = optional(number)
    force_overwrite_replica_secret = optional(bool)
    replica_regions                = optional(list(object({
      region     = string
      kms_key_id = optional(string)
    })), [])
    create_access_policy           = optional(bool, false)
    policy_actions                 = optional(list(string))
    secret_policy                  = optional(string)
    tags                           = optional(map(string), {})
  }))
  default     = {}
  sensitive   = true
}

# IAM Policy Configuration
variable "create_access_policy" {
  description = "Whether to create an IAM policy for accessing the secret"
  type        = bool
  default     = false
}

variable "policy_actions" {
  description = "List of actions to allow in the IAM policy"
  type        = list(string)
  default     = [
    "secretsmanager:GetSecretValue",
    "secretsmanager:DescribeSecret"
  ]
}

# Resource Policy
variable "secret_policy" {
  description = "Valid JSON document representing a resource policy for the secret"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
