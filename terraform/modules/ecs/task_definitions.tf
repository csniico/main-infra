# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  count = var.create_task_definition ? 1 : 0

  family                   = local.task_definition_family
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  execution_role_arn = var.task_execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode(local.default_container_definitions)

  tags = merge(
    var.tags,
    {
      Name = local.task_definition_family
    }
  )
}
