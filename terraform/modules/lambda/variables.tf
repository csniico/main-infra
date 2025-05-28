variable "name" {
  description = "Name of the Lambda function"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "Lambda function name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "name_prefix" {
  description = "Prefix to add to Lambda function name"
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Lambda function managed by Terraform"
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.11"

  validation {
    condition = contains([
      "nodejs18.x", "nodejs20.x",
      "python3.8", "python3.9", "python3.10", "python3.11", "python3.12",
      "java8", "java8.al2", "java11", "java17", "java21",
      "dotnet6", "dotnet8",
      "go1.x",
      "ruby3.2", "ruby3.3",
      "provided", "provided.al2", "provided.al2023"
    ], var.runtime)
    error_message = "Runtime must be a valid AWS Lambda runtime."
  }
}

variable "handler" {
  description = "Function entrypoint in your code"
  type        = string
  default     = "index.handler"
}

variable "role_arn" {
  description = "ARN of the IAM role that Lambda assumes when it executes your function"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+", var.role_arn))
    error_message = "Role ARN must be a valid IAM role ARN."
  }
}

# Deployment Package Configuration
variable "deployment_package_type" {
  description = "Type of deployment package (s3, local_file, or image)"
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "local_file", "image"], var.deployment_package_type)
    error_message = "Deployment package type must be 's3', 'local_file', or 'image'."
  }
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment package (required when deployment_package_type is 's3')"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment package (required when deployment_package_type is 's3')"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version of the deployment package"
  type        = string
  default     = null
}

variable "local_filename" {
  description = "Path to the local deployment package file (required when deployment_package_type is 'local_file')"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI containing the function's deployment package (required when deployment_package_type is 'image')"
  type        = string
  default     = null
}

variable "package_type" {
  description = "Lambda deployment package type"
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "Package type must be 'Zip' or 'Image'."
  }
}

# Function Configuration
variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use at runtime"
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 MB and 10,240 MB."
  }
}

variable "timeout" {
  description = "Amount of time your Lambda function has to run in seconds"
  type        = number
  default     = 3

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this lambda function"
  type        = number
  default     = null

  validation {
    condition     = var.reserved_concurrent_executions == null || var.reserved_concurrent_executions >= 0
    error_message = "Reserved concurrent executions must be a non-negative number."
  }
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs to attach to your Lambda function"
  type        = list(string)
  default     = []
}

# VPC Configuration
variable "subnet_ids" {
  description = "List of subnet IDs associated with the Lambda function (for VPC configuration)"
  type        = list(string)
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs associated with the Lambda function (for VPC configuration)"
  type        = list(string)
  default     = null
}

# Dead Letter Queue
variable "dead_letter_target_arn" {
  description = "ARN of an SQS queue or SNS topic for dead letter queue"
  type        = string
  default     = null
}

# CloudWatch Logs
variable "create_log_group" {
  description = "Whether to create CloudWatch log group for the Lambda function"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_in_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "log_kms_key_id" {
  description = "KMS key ID to use for encrypting CloudWatch logs"
  type        = string
  default     = null
}

# Permissions
variable "permissions" {
  description = "Map of permission configurations for the Lambda function"
  type = map(object({
    action         = string
    principal      = string
    source_arn     = optional(string)
    source_account = optional(string)
    statement_id   = optional(string)
    qualifier      = optional(string)
  }))
  default = {}
}

# Tracing
variable "tracing_mode" {
  description = "Tracing mode for the Lambda function (Active or PassThrough)"
  type        = string
  default     = null

  validation {
    condition     = var.tracing_mode == null || contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "Tracing mode must be 'Active' or 'PassThrough'."
  }
}

# Architecture
variable "architectures" {
  description = "Instruction set architecture for your Lambda function"
  type        = list(string)
  default     = ["x86_64"]

  validation {
    condition = alltrue([
      for arch in var.architectures : contains(["x86_64", "arm64"], arch)
    ])
    error_message = "Architectures must be 'x86_64' or 'arm64'."
  }
}

# Ephemeral Storage
variable "ephemeral_storage_size" {
  description = "Amount of ephemeral storage (/tmp) in MB your Lambda function can use at runtime"
  type        = number
  default     = 512

  validation {
    condition     = var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240
    error_message = "Ephemeral storage size must be between 512 MB and 10,240 MB."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
