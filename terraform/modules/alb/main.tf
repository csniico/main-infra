# Load Balancer
resource "aws_lb" "this" {
  name               = local.load_balancer_name
  load_balancer_type = var.load_balancer_type
  internal           = var.internal

  security_groups = var.load_balancer_type == "application" ? var.security_group_ids : null
  subnets         = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  ip_address_type                  = var.ip_address_type
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  idle_timeout                     = var.idle_timeout

  tags = merge(
    var.tags,
    {
      Name = local.load_balancer_name
    }
  )
}

# Target Group
resource "aws_lb_target_group" "this" {
  count = var.create_target_group ? 1 : 0

  name        = local.target_group_name
  port        = var.port
  protocol    = var.protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  protocol_version     = var.protocol_version
  deregistration_delay = var.deregistration_delay
  slow_start           = var.slow_start

  dynamic "stickiness" {
    for_each = length(var.stickiness) > 0 ? [var.stickiness] : []
    content {
      type            = lookup(stickiness.value, "type", "lb_cookie")
      cookie_duration = lookup(stickiness.value, "cookie_duration", 86400)
      enabled         = lookup(stickiness.value, "enabled", true)
    }
  }

  dynamic "health_check" {
    for_each = length(var.health_check) > 0 ? [var.health_check] : []
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      interval            = lookup(health_check.value, "interval", 30)
      path                = lookup(health_check.value, "path", "/")
      port                = lookup(health_check.value, "port", "traffic-port")
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 3)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 3)
      timeout             = lookup(health_check.value, "timeout", 5)
      protocol            = lookup(health_check.value, "protocol", var.protocol)
      matcher             = lookup(health_check.value, "matcher", "200-299")
    }
  }

  tags = merge(
    var.tags,
    {
      Name = local.target_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Additional Target Groups
resource "aws_lb_target_group" "additional" {
  for_each = var.target_groups

  name        = lookup(each.value, "name", "${local.load_balancer_name}-${each.key}")
  port        = lookup(each.value, "port", var.port)
  protocol    = lookup(each.value, "protocol", var.protocol)
  vpc_id      = var.vpc_id
  target_type = lookup(each.value, "target_type", var.target_type)

  protocol_version     = lookup(each.value, "protocol_version", var.protocol_version)
  deregistration_delay = lookup(each.value, "deregistration_delay", var.deregistration_delay)
  slow_start           = lookup(each.value, "slow_start", var.slow_start)

  dynamic "stickiness" {
    for_each = lookup(each.value, "stickiness", null) != null ? [lookup(each.value, "stickiness", null)] : []
    content {
      type            = lookup(stickiness.value, "type", "lb_cookie")
      cookie_duration = lookup(stickiness.value, "cookie_duration", 86400)
      enabled         = lookup(stickiness.value, "enabled", true)
    }
  }

  dynamic "health_check" {
    for_each = lookup(each.value, "health_check", null) != null ? [lookup(each.value, "health_check", null)] : []
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      interval            = lookup(health_check.value, "interval", 30)
      path                = lookup(health_check.value, "path", "/")
      port                = lookup(health_check.value, "port", "traffic-port")
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 3)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 3)
      timeout             = lookup(health_check.value, "timeout", 5)
      protocol            = lookup(health_check.value, "protocol", lookup(each.value, "protocol", var.protocol))
      matcher             = lookup(health_check.value, "matcher", "200-299")
    }
  }

  tags = merge(
    var.tags,
    {
      Name = lookup(each.value, "name", "${local.load_balancer_name}-${each.key}")
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  count = var.create_listener && var.protocol == "HTTP" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.port
  protocol          = var.protocol

  default_action {
    type             = "forward"
    target_group_arn = var.create_target_group ? aws_lb_target_group.this[0].arn : null
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.load_balancer_name}-http-listener"
    }
  )
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count = var.create_listener && var.protocol == "HTTPS" && var.listener_certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.port
  protocol          = var.protocol
  ssl_policy        = var.listener_ssl_policy
  certificate_arn   = var.listener_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.create_target_group ? aws_lb_target_group.this[0].arn : null
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.load_balancer_name}-https-listener"
    }
  )
}

# Additional Listeners
resource "aws_lb_listener" "additional" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = lookup(each.value, "port", var.port)
  protocol          = lookup(each.value, "protocol", var.protocol)
  ssl_policy        = lookup(each.value, "protocol", "") == "HTTPS" ? lookup(each.value, "ssl_policy", var.listener_ssl_policy) : null
  certificate_arn   = lookup(each.value, "protocol", "") == "HTTPS" ? lookup(each.value, "certificate_arn", var.listener_certificate_arn) : null

  dynamic "default_action" {
    for_each = lookup(each.value, "target_group_key", "") != "" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.additional[lookup(each.value, "target_group_key", "")].arn
    }
  }

  dynamic "default_action" {
    for_each = lookup(each.value, "target_group_key", "") == "" && var.create_target_group ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[0].arn
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.load_balancer_name}-${each.key}-listener"
    }
  )
}
