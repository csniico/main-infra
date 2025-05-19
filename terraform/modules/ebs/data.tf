data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Use provided name or generate one
  volume_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}" : var.name

  # Default IOPS based on volume type
  default_iops = {
    "gp3"      = 3000
    "io1"      = 100 * var.size
    "io2"      = 100 * var.size
    "gp2"      = 0
    "sc1"      = 0
    "st1"      = 0
    "standard" = 0
  }

  # Default throughput based on volume type
  default_throughput = {
    "gp3"      = 125
    "io1"      = null
    "io2"      = null
    "gp2"      = null
    "sc1"      = null
    "st1"      = null
    "standard" = null
  }

  # Determine if IOPS should be set based on volume type
  iops_supported_types = ["io1", "io2", "gp3"]
  use_iops             = contains(local.iops_supported_types, var.type)

  # Determine if throughput should be set based on volume type
  throughput_supported_types = ["gp3"]
  use_throughput             = contains(local.throughput_supported_types, var.type)
}
