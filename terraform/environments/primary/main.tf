# VPC
module "vpc" {
  source = "../../modules/vpc"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  az_count             = var.az_count
  single_nat_gateway   = true
  create_subnet_types  = ["public", "private"]

  tags = var.tags
}

# Security Groups
module "alb_sg" {
  source = "../../modules/security-group"

  name   = "${local.name}-alb"
  vpc_id = module.vpc.vpc_id

  # Allow traffic for all services from ALB
  ingress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.tags
}

module "jenkins_sg" {
  source = "../../modules/security-group"

  name   = "${local.name}-jenkins"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = {
    # Allow SSH from everywhere
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow traffic from ALB
  ingress_with_source_security_group_id = {
    alb = {
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.alb_sg.security_group_id
    }
  }

  # Allow all outbound traffic
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.tags
}

module "monitoring_sg" {
  source = "../../modules/security-group"

  name   = "${local.name}-monitoring"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = {
    # Allow SSH from everywhere
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }


  # Allow traffic from microservices
  ingress_with_source_security_group_id = {
    microservices = {
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.microservices_sg.security_group_id
    }
    # Allow traffic from ALB
    alb = {
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.alb_sg.security_group_id
    }
  }

  # Allow all outbound traffic
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.tags
}

module "db_sg" {
  source = "../../modules/security-group"

  name   = "${local.name}-db"
  vpc_id = module.vpc.vpc_id

  # Allow PostgreSQL from microservices
  ingress_with_source_security_group_id = {
    postgres = {
      from_port                = var.port["postgres"]
      to_port                  = var.port["postgres"]
      protocol                 = "tcp"
      source_security_group_id = module.microservices_sg.security_group_id
    }
  }

  # Allow all outbound traffic
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.tags
}

module "microservices_sg" {
  source = "../../modules/security-group"

  name   = "${local.name}-microservices"
  vpc_id = module.vpc.vpc_id

  # Allow traffic between microservices
  ingress_with_self = {
    self = {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      self      = true
    }
  }

  # Allow traffic from ALB
  ingress_with_source_security_group_id = {
    alb = {
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.alb_sg.security_group_id
    }
    # Allow monitoring from monitoring security group
    monitoring = {
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = module.monitoring_sg.security_group_id
    }
  }

  # Allow all outbound traffic
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.tags
}

module "efs_sg" {
  source = "../../modules/security-group"

  name   = "${local.name}-efs"
  vpc_id = module.vpc.vpc_id

  # Allow NFS from jenkins and monitoring security group
  ingress_with_source_security_group_id = {
    nfs_jenkins = {
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      source_security_group_id = module.jenkins_sg.security_group_id
    }
    nfs_monitoring = {
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      source_security_group_id = module.monitoring_sg.security_group_id
    }
  }

  # Allow all outbound traffic
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = var.tags
}

# IAM Roles
module "ec2_monitoring_iam" {
  source = "../../modules/iam"

  name = "${local.name}-ec2-monitoring"

  # Role configuration
  trusted_role_services = ["ec2.amazonaws.com"]

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  # Create instance profile
  create_instance_profile = true

  tags = var.tags
}

module "ec2_jenkins_iam" {
  source = "../../modules/iam"

  name = "${local.name}-ec2-jenkins"

  # Role configuration
  trusted_role_services = ["ec2.amazonaws.com"]

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]

  # Create instance profile
  create_instance_profile = true

  tags = var.tags
}

module "ecs_task_execution_role" {
  source = "../../modules/iam"

  name = "${local.name}-ecs-execution"

  # Role configuration
  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

  tags = var.tags
}

module "ecs_task_role" {
  source = "../../modules/iam"

  name = "${local.name}-ecs-task"

  # Role configuration
  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]

  tags = var.tags
}


module "ecs_notif_task_role" {
  source = "../../modules/iam"

  name = "${local.name}-ecs-notif-task"

  # Role configuration
  trusted_role_services = ["ecs-tasks.amazonaws.com"]

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  ]

  tags = var.tags
}

# Auto Scaling Groups
module "jenkins_asg" {
  source = "../../modules/asg"

  name = "${local.name}-jenkins"

  # Launch template configuration
  image_id      = var.amzn_2023_ami
  instance_type = var.instance_types["jenkins"]
  user_data = templatefile("${path.module}/../../../scripts/user-data/jenkins.sh", {
    efs_id      = module.efs.file_system_id
    ap_id       = module.efs.access_point_ids["jenkins"]
    jenkins_uid = var.jenkins_id
    jenkins_gid = var.jenkins_id
    mount_dir   = var.efs_jenkins_dir
  })

  # Use IAM instance profile from IAM module
  iam_instance_profile_name = module.ec2_jenkins_iam.instance_profile_name

  # Use security groups from security-group module
  security_group_ids = [module.jenkins_sg.security_group_id]

  # Block device mappings
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 30
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    }
  ]

  # Auto scaling group configuration
  min_size         = var.asg_min_sizes["jenkins"]
  max_size         = var.asg_max_sizes["jenkins"]
  desired_capacity = var.asg_desired_capacities["jenkins"]

  # Networking
  vpc_zone_identifier = module.vpc.public_subnet_ids
  target_group_arns   = [module.alb.target_group_arns_map["jenkins"]]

  tags = var.tags
}

module "monitoring_asg" {
  source = "../../modules/asg"

  name = "${local.name}-monitoring"

  # Launch template configuration
  image_id      =  var.amzn_2023_ami
  instance_type = var.instance_types["monitoring"]
  key_name      = var.key_name
  user_data = templatefile("${path.module}/../../../scripts/user-data/monitoring.sh", {
    efs_id     = module.efs.file_system_id
    ap_id      = module.efs.access_point_ids["monitoring"]
    docker_uid = var.monitoring_id
    docker_gid = var.monitoring_id
    mount_dir  = var.efs_monitoring_dir
  })

  # Use IAM instance profile from IAM module
  iam_instance_profile_name = module.ec2_monitoring_iam.instance_profile_name

  # Use security groups from security-group module
  security_group_ids = [module.monitoring_sg.security_group_id]

  # Block device mappings
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = 12
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    }
  ]

  # Auto scaling group configuration
  min_size         = var.asg_min_sizes["monitoring"]
  max_size         = var.asg_max_sizes["monitoring"]
  desired_capacity = var.asg_desired_capacities["monitoring"]

  # Networking
  vpc_zone_identifier = module.vpc.public_subnet_ids
  target_group_arns   = [module.alb.target_group_arns_map["prometheus"], module.alb.target_group_arns_map["grafana"], module.alb.target_group_arns_map["jaeger"]]

  tags = var.tags
}

# EFS
module "efs" {
  source = "../../modules/efs"

  name               = "${local.name}-efs"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.efs_sg.security_group_id]

  # Access points
  access_points = [
    {
      name                = "jenkins"
      root_directory_path = var.efs_jenkins_dir
      owner_uid           = var.jenkins_id
      owner_gid           = var.jenkins_id
      permissions         = "0755"
      posix_user_uid      = var.jenkins_id
      posix_user_gid      = var.jenkins_id
    },
    {
      name                = "monitoring"
      root_directory_path = var.efs_monitoring_dir
      owner_uid           = var.monitoring_id
      owner_gid           = var.monitoring_id
      permissions         = "0755"
      posix_user_uid      = var.monitoring_id
      posix_user_gid      = var.monitoring_id
    }
  ]

  # Enable replication
  enable_replication             = true
  replication_destination_region = var.dr_region
  destination_system_id = local.dr_efs_file_system.id != null ? local.dr_efs_file_system.id : null

  tags = var.tags
}

# Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  name = "${local.name}-alb"

  # Load balancer configuration
  load_balancer_type = "application"
  internal           = false

  # Network configuration
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  # Target groups
  target_groups = {
    notification_service = {
      name        = "notification-service"
      protocol    = "HTTP"
      port        = var.port["notification_service"]
      target_type = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/api/v1/"
        port                = var.port["notification_service"]
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
    user_service = {
      name        = "user-service"
      protocol    = "HTTP"
      port        = var.port["user_service"]
      target_type = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/api/v1/"
        port                = var.port["user_service"]
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
    task_api = {
      name        = "task-api"
      protocol    = "HTTP"
      port        = var.port["task_api"]
      target_type = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/api/v1/tasks"
        port                = var.port["task_api"]
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
    frontend = {
      name        = "frontend"
      protocol    = "HTTP"
      port        = var.port["frontend"]
      target_type = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = var.port["frontend"]
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
    jenkins = {
      name        = "jenkins"
      protocol    = "HTTP"
      port        = var.port["jenkins"]
      target_type = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/login"
        port                = var.port["jenkins"]
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
    prometheus = {
      name        = "prometheus"
      protocol    = "HTTP"
      port        = var.port["prometheus"]
      target_type = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = var.port["prometheus"]
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
    grafana = {
      name        = "grafana"
      protocol    = "HTTP"
      port        = var.port["grafana"]
      target_type = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = var.port["grafana"]
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
    jaeger = {
      name        = "jaeger"
      protocol    = "HTTP"
      port        = var.port["jaeger"]
      target_type = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = var.port["jaeger"]
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
      }
    }
  }

  # Listeners
  listeners = {
    notification_service = {
      port             = var.port["notification_service"]
      protocol         = "HTTP"
      target_group_key = "notification_service"
    }
    user_service = {
      port             = var.port["user_service"]
      protocol         = "HTTP"
      target_group_key = "user_service"
    }
    task_api = {
      port             = var.port["task_api"]
      protocol         = "HTTP"
      target_group_key = "task_api"
    }
    frontend = {
      port             = 80
      protocol         = "HTTP"
      target_group_key = "frontend"
    }
    jenkins = {
      port             = var.port["jenkins"]
      protocol         = "HTTP"
      target_group_key = "jenkins"
    }
    prometheus = {
      port             = var.port["prometheus"]
      protocol         = "HTTP"
      target_group_key = "prometheus"
    }
    grafana = {
      port             = var.port["grafana"]
      protocol         = "HTTP"
      target_group_key = "grafana"
    }
    jaeger = {
      port             = var.port["jaeger"]
      protocol         = "HTTP"
      target_group_key = "jaeger"
    }
  }

  tags = var.tags
}

# ECS Cluster
module "ecs_cluster" {
  source = "../../modules/ecs"

  name = local.name

  # Cluster configuration
  create_cluster = true

  # Fargate capacity providers
  fargate_capacity_providers = {
    FARGATE = {
      default_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_strategy = {
        weight = 50
      }
    }
  }

  tags = var.tags
}

# Frontend Service with ALB
module "ecs_service_frontend" {
  source = "../../modules/ecs"

  name = "${local.name}-${var.service_names["frontend"]}"

  # Use existing cluster
  create_cluster = false
  cluster_name   = module.ecs_cluster.cluster_name

  # Task definition
  create_task_definition = true
  container_definitions  = local.container_definitions["frontend"]

  # Service configuration
  create_service = true
  service_name   = var.service_names["frontend"]

  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.microservices_sg.security_group_id]

  # Load balancer integration
  load_balancer_config = [
    {
      target_group_arn = module.alb.target_group_arns_map["frontend"]
      container_name   = var.service_names["frontend"]
      container_port   = var.port["frontend"]
    }
  ]

  # IAM roles
  task_execution_role_arn = module.ecs_task_execution_role.role_arn
  task_role_arn           = module.ecs_task_role.role_arn

  # Auto scaling
  enable_autoscaling       = true
  autoscaling_min_capacity = var.service_min_sizes
  autoscaling_max_capacity = var.service_max_sizes
  autoscaling_policies = {
    cpu = {
      policy_type            = "TargetTrackingScaling"
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 70
    }
    memory = {
      policy_type            = "TargetTrackingScaling"
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
      target_value           = 80
    }
  }

  # Service discovery namespace
  create_service_discovery_namespace      = true
  vpc_id                                  = module.vpc.vpc_id
  service_discovery_namespace_name        = var.discovery_namespace["name"]
  service_discovery_namespace_description = var.discovery_namespace["description"]
  service_discovery_namespace_type        = var.discovery_namespace["type"]

  # Service discovery service
  enable_service_discovery       = true
  service_discovery_service_name = var.service_names["frontend"]
  service_discovery_dns_ttl      = var.discovery_namespace["dns_ttl"]
  service_discovery_dns_type     = var.discovery_namespace["dns_type"]

  tags = var.tags
}

# Notification Service
module "ecs_service_notification" {
  source = "../../modules/ecs"

  name = "${local.name}-${var.service_names["notification_service"]}"

  # Use existing cluster
  create_cluster = false
  cluster_name   = module.ecs_cluster.cluster_name

  # Task definition
  create_task_definition = true
  container_definitions  = local.container_definitions["notification_service"]
  task_cpu               = 512
  task_memory            = 1024

  # Service configuration
  create_service = true
  service_name   = var.service_names["notification_service"]

  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.microservices_sg.security_group_id]

  # IAM roles
  task_execution_role_arn = module.ecs_task_execution_role.role_arn
  task_role_arn           = module.ecs_notif_task_role.role_arn

  # Load balancer integration
  load_balancer_config = [
    {
      target_group_arn = module.alb.target_group_arns_map["notification-service"]
      container_name   = var.service_names["notification_service"]
      container_port   = var.port["notification_service"]
    }
  ]

  # Auto scaling
  enable_autoscaling       = true
  autoscaling_min_capacity = var.service_min_sizes
  autoscaling_max_capacity = var.service_max_sizes
  autoscaling_policies = {
    cpu = {
      policy_type            = "TargetTrackingScaling"
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 70
    }
  }

  # Service discovery service
  enable_service_discovery       = true
  service_discovery_namespace_id = module.ecs_service_frontend.service_discovery_namespace_id
  service_discovery_service_name = var.service_names["notification_service"]
  service_discovery_dns_ttl      = var.discovery_namespace["dns_ttl"]
  service_discovery_dns_type     = var.discovery_namespace["dns_type"]

  tags = var.tags
}

# User Service
module "ecs_service_user" {
  source = "../../modules/ecs"

  name = "${local.name}-${var.service_names["user_service"]}"

  # Use existing cluster
  create_cluster = false
  cluster_name   = module.ecs_cluster.cluster_name

  # Task definition
  create_task_definition = true
  container_definitions  = local.container_definitions["user_service"]
  task_cpu               = 512
  task_memory            = 1024

  # Service configuration
  create_service = true
  service_name   = var.service_names["user_service"]

  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.microservices_sg.security_group_id]

  # IAM roles
  task_execution_role_arn = module.ecs_task_execution_role.role_arn
  task_role_arn           = module.ecs_task_role.role_arn

  # Load balancer integration
  load_balancer_config = [
    {
      target_group_arn = module.alb.target_group_arns_map["user-service"]
      container_name   = var.service_names["user_service"]
      container_port   = var.port["user_service"]
    }
  ]

  # Auto scaling
  enable_autoscaling             = true
  service_discovery_namespace_id = module.ecs_service_frontend.service_discovery_namespace_id
  autoscaling_min_capacity       = var.service_min_sizes
  autoscaling_max_capacity       = var.service_max_sizes
  autoscaling_policies = {
    cpu = {
      policy_type            = "TargetTrackingScaling"
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 70
    }
  }

  # Service discovery service
  enable_service_discovery       = true
  service_discovery_service_name = var.service_names["user_service"]
  service_discovery_dns_ttl      = var.discovery_namespace["dns_ttl"]
  service_discovery_dns_type     = var.discovery_namespace["dns_type"]

  tags = var.tags
}

# Task API
module "ecs_service_task_api" {
  source = "../../modules/ecs"

  name = "${local.name}-${var.service_names["task_api"]}"

  # Use existing cluster
  create_cluster = false
  cluster_name   = module.ecs_cluster.cluster_name

  # Task definition
  create_task_definition = true
  container_definitions  = local.container_definitions["task_api"]
  task_cpu               = 512
  task_memory            = 1024

  # Service configuration
  create_service = true
  service_name   = var.service_names["task_api"]

  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.microservices_sg.security_group_id]

  # IAM roles
  task_execution_role_arn = module.ecs_task_execution_role.role_arn
  task_role_arn           = module.ecs_task_role.role_arn

  # Load balancer integration
  load_balancer_config = [
    {
      target_group_arn = module.alb.target_group_arns_map["task-api"]
      container_name   = var.service_names["task_api"]
      container_port   = var.port["task_api"]
    }
  ]

  # Auto scaling
  enable_autoscaling       = true
  autoscaling_min_capacity = var.service_min_sizes
  autoscaling_max_capacity = var.service_max_sizes
  autoscaling_policies = {
    cpu = {
      policy_type            = "TargetTrackingScaling"
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 70
    }
  }

  # Service discovery service
  enable_service_discovery       = true
  service_discovery_namespace_id = module.ecs_service_frontend.service_discovery_namespace_id
  service_discovery_service_name = var.service_names["task_api"]
  service_discovery_dns_ttl      = var.discovery_namespace["dns_ttl"]
  service_discovery_dns_type     = var.discovery_namespace["dns_type"]

  tags = var.tags
}

# Kafka
module "ecs_service_kafka" {
  source = "../../modules/ecs"

  name = "${local.name}-${var.service_names["ckafka"]}"

  # Use existing cluster
  create_cluster = false
  cluster_name   = module.ecs_cluster.cluster_name

  # Task definition
  create_task_definition = true
  container_definitions  = local.container_definitions["ckafka"]
  task_cpu               = 1024
  task_memory            = 2048

  # Service configuration
  create_service = true
  service_name   = var.service_names["ckafka"]

  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.microservices_sg.security_group_id]

  # IAM roles
  task_execution_role_arn = module.ecs_task_execution_role.role_arn
  task_role_arn           = module.ecs_task_role.role_arn

  # Auto scaling
  enable_autoscaling = false

  # Volume configuration for Kafka data
  # volumes = [
  #   {
  #     name = "kafka_data"
  #     efs_volume_configuration = {
  #       file_system_id     = module.efs.file_system_id
  #       transit_encryption = "ENABLED"
  #       authorization_config = {
  #         access_point_id = module.efs.access_point_ids["kafka"]
  #       }
  #     }
  #   }
  # ]

  # Service discovery service
  enable_service_discovery       = true
  service_discovery_namespace_id = module.ecs_service_frontend.service_discovery_namespace_id
  service_discovery_service_name = var.service_names["ckafka"]
  service_discovery_dns_ttl      = var.discovery_namespace["dns_ttl"]
  service_discovery_dns_type     = var.discovery_namespace["dns_type"]

  tags = var.tags
}

# RDS Database
module "rds" {
  source = "../../modules/rds"

  name        = local.name
  environment = var.environment

  # Engine options
  engine         = var.db_engine
  engine_version = var.db_engine_version

  # Instance configuration
  instance_class = var.db_instance_class
  multi_az       = true

  # Storage
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  # Authentication
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  port                   = var.port["postgres"]
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]
  publicly_accessible    = false

  # Backup
  backup_retention_period = 7

  # Maintenance
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  tags = var.tags
}
