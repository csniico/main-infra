# General
variable "name" {
  description = "Name of the EBS volume"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to add to the EBS volume name"
  type        = string
  default     = null
}

# Volume Configuration
variable "size" {
  description = "Size of the EBS volume in gigabytes"
  type        = number
  default     = 20
}

variable "type" {
  description = "Type of EBS volume. Can be 'standard', 'gp2', 'gp3', 'io1', 'io2', 'sc1', or 'st1'"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"], var.type)
    error_message = "Valid values for type are (standard, gp2, gp3, io1, io2, sc1, st1)."
  }
}

variable "iops" {
  description = "Amount of IOPS to provision for the disk. Only valid for 'io1', 'io2', and 'gp3' types"
  type        = number
  default     = null
}

variable "throughput" {
  description = "Throughput to provision for a volume in MiB/s. Only valid for 'gp3' type"
  type        = number
  default     = null
}

variable "multi_attach_enabled" {
  description = "Specifies whether to enable Amazon EBS Multi-Attach. Multi-Attach is supported on io1 and io2 volumes"
  type        = bool
  default     = false
}

# Encryption
variable "encrypted" {
  description = "If true, the disk will be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting the volume"
  type        = string
  default     = null
}

# Snapshot
variable "snapshot_id" {
  description = "The Snapshot ID to create the volume from"
  type        = string
  default     = null
}

# Availability Zone
variable "availability_zone" {
  description = "The AZ where the EBS volume will exist"
  type        = string
}

# Attachment
variable "attach_volume" {
  description = "Whether to attach the volume to an EC2 instance"
  type        = bool
  default     = false
}

variable "instance_id" {
  description = "ID of the Instance to attach to"
  type        = string
  default     = null
}

variable "device_name" {
  description = "The device name to expose to the instance (e.g., /dev/sdh or xvdh)"
  type        = string
  default     = "/dev/sdb"
}

variable "skip_destroy" {
  description = "Set this to true if you want to keep the volume when destroying the instance"
  type        = bool
  default     = false
}

variable "stop_instance_before_detaching" {
  description = "Whether the instance should be stopped before detaching the volume"
  type        = bool
  default     = false
}

# Final Snapshot
variable "final_snapshot" {
  description = "Whether to create a final snapshot before the volume is deleted"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
