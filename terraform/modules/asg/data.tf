data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition
  
  # Use provided name or generate one
  asg_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}" : var.name
  
  # Use provided name or generate one
  launch_template_name = var.launch_template_name != null ? var.launch_template_name : "${local.asg_name}-lt"
  
  # Default block device mappings if none provided
  default_block_device_mappings = var.block_device_mappings == [] ? [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 20
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    }
  ] : var.block_device_mappings
  
  # Default metadata options if none provided
  default_metadata_options = var.metadata_options == {} ? {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  } : var.metadata_options
  
  # Default tag specifications if none provided
  default_tag_specifications = var.tag_specifications == [] ? [
    {
      resource_type = "instance"
      tags          = merge(var.tags, { Name = "${local.asg_name}-instance" })
    },
    {
      resource_type = "volume"
      tags          = merge(var.tags, { Name = "${local.asg_name}-volume" })
    }
  ] : var.tag_specifications
}
