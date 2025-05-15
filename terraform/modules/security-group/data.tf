data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Use provided name or generate one
  security_group_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}" : var.name
}
