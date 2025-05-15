# Application Auto Scaling for ECS Service
resource "aws_appautoscaling_target" "this" {
  count = var.create_service && var.enable_autoscaling ? 1 : 0
  
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.create_cluster ? aws_ecs_cluster.this[0].name : var.cluster_name}/${aws_ecs_service.this[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policies
resource "aws_appautoscaling_policy" "this" {
  for_each = var.create_service && var.enable_autoscaling ? var.autoscaling_policies : {}
  
  name               = each.key
  policy_type        = lookup(each.value, "policy_type", "TargetTrackingScaling")
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  
  dynamic "target_tracking_scaling_policy_configuration" {
    for_each = lookup(each.value, "policy_type", "TargetTrackingScaling") == "TargetTrackingScaling" ? [1] : []
    content {
      predefined_metric_specification {
        predefined_metric_type = lookup(each.value, "predefined_metric_type", "ECSServiceAverageCPUUtilization")
      }
      target_value       = lookup(each.value, "target_value", 70)
      scale_in_cooldown  = lookup(each.value, "scale_in_cooldown", 300)
      scale_out_cooldown = lookup(each.value, "scale_out_cooldown", 300)
    }
  }
  
  dynamic "step_scaling_policy_configuration" {
    for_each = lookup(each.value, "policy_type", "TargetTrackingScaling") == "StepScaling" ? [1] : []
    content {
      adjustment_type         = lookup(each.value, "adjustment_type", "ChangeInCapacity")
      cooldown                = lookup(each.value, "cooldown", 300)
      metric_aggregation_type = lookup(each.value, "metric_aggregation_type", "Average")
      
      dynamic "step_adjustment" {
        for_each = lookup(each.value, "step_adjustments", [])
        content {
          metric_interval_lower_bound = lookup(step_adjustment.value, "metric_interval_lower_bound", null)
          metric_interval_upper_bound = lookup(step_adjustment.value, "metric_interval_upper_bound", null)
          scaling_adjustment          = step_adjustment.value.scaling_adjustment
        }
      }
    }
  }
}
