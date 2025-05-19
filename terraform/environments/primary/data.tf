# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  name       = "${var.name}-${var.environment}"
  azs        = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Default container definitions for ECS services
  container_definitions = {
    web = jsonencode([
      {
        name      = "web"
        image     = "nginx:latest"
        essential = true
        portMappings = [
          {
            containerPort = 80
            hostPort      = 80
            protocol      = "tcp"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${local.name}-web"
            "awslogs-region"        = local.region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }
    ])
  }
}
