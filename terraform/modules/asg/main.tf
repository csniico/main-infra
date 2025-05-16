# Launch Template
resource "aws_launch_template" "this" {
  count = var.create_launch_template ? 1 : 0

  name        = local.launch_template_name
  description = var.launch_template_description != null ? var.launch_template_description : "Launch template for ${local.asg_name}"

  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data != null ? base64encode(var.user_data) : null
  ebs_optimized = var.ebs_optimized

  monitoring {
    enabled = var.enable_monitoring
  }

  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", null)
      http_tokens                 = lookup(metadata_options.value, "http_tokens", null)
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", null)
      instance_metadata_tags      = lookup(metadata_options.value, "instance_metadata_tags", null)
    }
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != null ? [1] : []
    content {
      name = var.iam_instance_profile_name
    }
  }

  dynamic "network_interfaces" {
    for_each = length(var.security_group_ids) > 0 ? [1] : []
    content {
      security_groups = var.security_group_ids
    }
  }

  dynamic "tag_specifications" {
    for_each = local.default_tag_specifications
    content {
      resource_type = tag_specifications.value.resource_type
      tags          = tag_specifications.value.tags
    }
  }

  update_default_version = var.update_default_version

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = local.launch_template_name
    }
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  count = var.create_asg ? 1 : 0

  name                      = local.asg_name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  capacity_rebalance        = var.capacity_rebalance
  default_cooldown          = var.default_cooldown
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  force_delete              = var.force_delete
  termination_policies      = var.termination_policies

  vpc_zone_identifier = var.vpc_zone_identifier
  target_group_arns   = var.target_group_arns

  # Launch Template
  dynamic "launch_template" {
    for_each = var.create_launch_template ? [1] : []
    content {
      id      = aws_launch_template.this[0].id
      version = aws_launch_template.this[0].latest_version
    }
  }

  # Tags
  dynamic "tag" {
    for_each = merge(
      {
        Name = local.asg_name
      },
      var.tags
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
