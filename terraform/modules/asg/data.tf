data "aws_region" "current" {}

locals {
  region     = data.aws_region.current.name

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

  # Default tag specifications if none provided
  default_tag_specifications = var.tag_specifications == [] ? [
    {
      resource_type = "instance"
      tags          = merge(var.tags, { Name = "${local.asg_name}-instance" })
    }
  ] : var.tag_specifications
}
