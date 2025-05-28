# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "random_id" "cluster_id" {
  byte_length = 24
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  name       = "${var.name}-${var.environment}"
  azs        = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Container definitions for ECS services
  container_definitions = {
    # Frontend Service
    frontend = jsonencode([
      {
        name      = var.service_names["frontend"]
        image     = "124355645722.dkr.ecr.eu-west-1.amazonaws.com/frontend-service:latest"
        essential = true
        portMappings = [
          {
            containerPort = var.port["frontend"]
            hostPort      = var.port["frontend"]
            protocol      = "tcp"
          }
        ]
        environment = [
          {
            name  = "NODE_ENV"
            value = "production"
          },
          {
            name  = "AUTH_API_URL"
            value = "http://localhost:${var.port["user_service"]}"
          },
          {
            name  = "TASK_API_URL"
            value = "http://localhost:${var.port["task_api"]}"
          }
        ]
      }
    ]),

    # Notification Service
    notification_service = jsonencode([
      {
        name      = var.service_names["notification_service"]
        image     = "124355645722.dkr.ecr.eu-west-1.amazonaws.com/notification-service:latest"
        essential = true
        portMappings = [
          {
            containerPort = var.port["notification_service"]
            hostPort      = var.port["notification_service"]
            protocol      = "tcp"
          }
        ]
        environment = [
          {
            name  = "SNS_TOPIC_ARN"
            value = "arn:aws:sns:eu-west-1:124355645722:primaryApplication"
          },
          {
            name  = "AWS_REGION"
            value = "eu-west-1"
          },
          {
            name  = "SPRING_KAFKA_BOOTSTRAP_SERVERS"
            value = "${var.service_names["ckafka"]}:${var.port["ckafka"]}"
          },
          {
            name  = "SERVER_PORT"
            value = "${tostring(var.port["notification_service"])}"
          },
          {
            name  = "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"
            value = "${module.alb.lb_dns_name}:${var.port["jaeger"]}/v1/traces"
          },
          {
            name  = "OTEL_SERVICE_NAME"
            value = "${var.service_names["notification_service"]}"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${local.name}-notification-service"
            "awslogs-region"        = local.region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }
    ]),

    # User Service
    user_service = jsonencode([
      {
        name      = var.service_names["user_service"]
        image     = "124355645722.dkr.ecr.eu-west-1.amazonaws.com/user-service:latest"
        essential = true
        portMappings = [
          {
            containerPort = var.port["user_service"]
            hostPort      = var.port["user_service"]
            protocol      = "tcp"
          }
        ]
        environment = [
          {
            name  = "SPRING_DATASOURCE_HOST_URL"
            value = "${module.rds.db_instance_endpoint}/${var.db_name}"
          },
          {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "${var.db_username}"
          },
          {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = "${var.db_password}"
          },
          {
            name  = "SPRING_KAFKA_BOOTSTRAP_SERVERS"
            value = "${var.service_names["ckafka"]}:${var.port["ckafka"]}"
          },
          {
            name  = "SERVER_PORT"
            value = "${tostring(var.port["user_service"])}"
          },
          {
            name  = "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"
            value = "${module.alb.lb_dns_name}:${var.port["jaeger"]}/v1/traces"
          },
          {
            name  = "OTEL_SERVICE_NAME"
            value = "${var.service_names["user_service"]}"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${local.name}-user-service"
            "awslogs-region"        = local.region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }
    ]),

    # Task API
    task_api = jsonencode([
      {
        name      = var.service_names["task_api"]
        image     = "124355645722.dkr.ecr.eu-west-1.amazonaws.com/task-service:latest"
        essential = true
        portMappings = [
          {
            containerPort = var.port["task_api"]
            hostPort      = var.port["task_api"]
            protocol      = "tcp"
          }
        ]
        environment = [
          {
            name  = "SPRING_DATASOURCE_HOST_URL"
            value = "${module.rds.db_instance_endpoint}/${var.db_name}"
          },
          {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "${var.db_username}"
          },
          {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = "${var.db_password}"
          },
          {
            name  = "SERVER_PORT"
            value = "${tostring(var.port["task_api"])}"
          },
          {
            name  = "SPRING_KAFKA_BOOTSTRAP_SERVERS"
            value = "${var.service_names["ckafka"]}:${var.port["ckafka"]}"
          },
          {
            name  = "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"
            value = "${module.alb.lb_dns_name}:${var.port["jaeger"]}/v1/traces"
          },
          {
            name  = "OTEL_SERVICE_NAME"
            value = "${var.service_names["task_api"]}"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${local.name}-task-api"
            "awslogs-region"        = local.region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }
    ]),

    # Kafka
    ckafka = jsonencode([
      {
        name      = var.service_names["ckafka"]
        image     = "124355645722.dkr.ecr.eu-west-1.amazonaws.com/kafka-service:latest"
        essential = true
        portMappings = [
          {
            containerPort = var.port["ckafka"]
            hostPort      = var.port["ckafka"]
            protocol      = "tcp"
          },
          {
            containerPort = var.port["ckafka"] + 1
            hostPort      = var.port["ckafka"] + 1
            protocol      = "tcp"
          }
        ]
        environment = [
          {
            name  = "KAFKA_KRAFT_MODE"
            value = "true"
          },
          {
            name  = "KAFKA_NODE_ID"
            value = "1"
          },
          {
            name  = "KAFKA_PROCESS_ROLES"
            value = "broker,controller"
          },
          {
            name  = "KAFKA_CONTROLLER_QUORUM_VOTERS"
            value = "1@localhost:${var.port["ckafka"] + 1}"
          },
          {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://0.0.0.0:${var.port["ckafka"]},CONTROLLER://0.0.0.0:${var.port["ckafka"] + 1}"
          },
          {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://localhost:${var.port["ckafka"]}"
          },
          {
            name  = "KAFKA_CONTROLLER_LISTENER_NAMES"
            value = "CONTROLLER"
          },
          {
            name  = "KAFKA_INTER_BROKER_LISTENER_NAME"
            value = "PLAINTEXT"
          },
          {
            name  = "KAFKA_AUTO_CREATE_TOPICS_ENABLE"
            value = "true"
          },
          {
            name  = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = "1"
          },
          {
            name  = "KAFKA_LOG_RETENTION_HOURS"
            value = "168"
          },
          {
            name  = "KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS"
            value = "0"
          },
          {
            name  = "KAFKA_LOG_DIRS"
            value = "/var/lib/kafka/data"
          },
          {
            name  = "CLUSTER_ID"
            value = "${random_id.cluster_id.hex}"
          }
        ]
        # mountPoints = [
        #   {
        #     sourceVolume  = "kafka_data"
        #     containerPath = "/var/lib/kafka/data"
        #     readOnly      = false
        #   }
        # ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${local.name}-ckafka"
            "awslogs-region"        = local.region
            "awslogs-stream-prefix" = "ecs"
          }
        }
      }
    ])
  }
}
