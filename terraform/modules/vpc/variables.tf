variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "main"
}

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
  default     = 3
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "AZ count must be between 2 and 3."
  }
}

variable "subnet_newbits" {
  description = "Number of additional bits to extend the subnet CIDR"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets (cost savings)"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets (set to false to disable NAT gateways completely)"
  type        = bool
  default     = true
}

variable "create_subnet_types" {
  description = "List of subnet types to create (valid values: public, private)"
  type        = list(string)
  default     = ["public", "private"]
  validation {
    condition     = length([for type in var.create_subnet_types : type if contains(["public", "private"], type)]) == length(var.create_subnet_types)
    error_message = "Valid values for create_subnet_types are 'public' and 'private'."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
