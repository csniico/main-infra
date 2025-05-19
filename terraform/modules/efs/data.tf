data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Use provided name or generate one
  file_system_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}" : var.name
  
  # Creation token must be unique
  creation_token = "${local.file_system_name}-${random_string.suffix.result}"
}

# Generate a random suffix for the creation token
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
