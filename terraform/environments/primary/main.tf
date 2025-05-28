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

  # Allow traffic for microservices
  ingress_with_cidr_blocks = {
    task_api = {
      from_port   = var.port["task_api"]
      to_port     = var.port["task_api"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    user_service = {
      from_port   = var.port["user_service"]
      to_port     = var.port["user_service"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    notification_service = {
      from_port   = var.port["notification_service"]
      to_port     = var.port["notification_service"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    frontend = {
      from_port   = var.port["frontend"]
      to_port     = var.port["frontend"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    jenkins = {
      from_port   = var.port["jenkins"]
      to_port     = var.port["jenkins"]
      protocol    = "tcp"
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

# Auto Scaling Groups
module "jenkins_asg" {
  source = "../../modules/asg"

  name = "${local.name}-jenkins"

  # Launch template configuration
  image_id      = "ami-03d8b47244d950bbb" # Amazon Linux 2023 AMI
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

  # Auto scaling group configuration
  min_size         = var.asg_min_sizes["jenkins"]
  max_size         = var.asg_max_sizes["jenkins"]
  desired_capacity = var.asg_desired_capacities["jenkins"]

  # Networking from VPC module
  vpc_zone_identifier = module.vpc.public_subnet_ids

  tags = var.tags
}

module "monitoring_asg" {
  source = "../../modules/asg"

  name = "${local.name}-monitoring"

  # Launch template configuration
  image_id      = "ami-03d8b47244d950bbb" # Amazon Linux 2023 AMI
  instance_type = var.instance_types["monitoring"]
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

  # Auto scaling group configuration
  min_size         = var.asg_min_sizes["monitoring"]
  max_size         = var.asg_max_sizes["monitoring"]
  desired_capacity = var.asg_desired_capacities["monitoring"]

  # Networking from VPC module
  vpc_zone_identifier = module.vpc.public_subnet_ids

  tags = var.tags
}

# EFS
module "efs" {
  source = "../../modules/efs"

  name       = "${local.name}-efs"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Use security groups from security-group module
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

  tags = var.tags
}

# Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  name = "${local.name}-web"

  # Load balancer configuration
  load_balancer_type = "application"
  internal           = false

  # Network configuration
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  # Target group configuration and listener
  create_listener = true
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"

  # Target groups
  target_groups = {
    web = {
      name_prefix      = "web-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-399"
      }
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

# ECS Service with ALB
module "ecs_service_web" {
  source = "../../modules/ecs"

  name = "${local.name}-web"

  # Use existing cluster
  create_cluster = false
  cluster_name   = module.ecs_cluster.cluster_name

  # Task definition
  create_task_definition = true
  container_definitions  = local.container_definitions["web"]

  # Service configuration
  create_service = true
  service_name   = "web"

  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.ecs_frontend_sg.security_group_id]

  # Load balancer integration
  load_balancer_config = [
    {
      target_group_arn = module.alb.target_group_arns[0]
      container_name   = "web"
      container_port   = 80
    }
  ]

  # IAM roles
  task_execution_role_arn = module.ecs_task_execution_role.role_arn
  task_role_arn           = module.ecs_task_role.role_arn

  # Auto scaling
  enable_autoscaling       = true
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3
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

  tags = var.tags
}

# Internal ECS Service
module "ecs_service_internal" {
  source = "../../modules/ecs"

  name = "${local.name}-internal"

  # Use existing cluster
  create_cluster = false
  cluster_name   = module.ecs_cluster.cluster_name

  # Task definition
  create_task_definition = true
  container_definitions  = local.container_definitions["web"]

  # Service configuration
  create_service = true
  service_name   = "internal"

  # Network configuration
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.ecs_backend_sg.security_group_id]

  # IAM roles
  task_execution_role_arn = module.ecs_task_execution_role.role_arn
  task_role_arn           = module.ecs_task_role.role_arn

  # Auto scaling
  enable_autoscaling       = true
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3
  autoscaling_policies = {
    cpu = {
      policy_type            = "TargetTrackingScaling"
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
      target_value           = 70
    }
  }

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
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true

  # Network
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]
  publicly_accessible    = false

  # Backup
  backup_retention_period = 7

  # Maintenance
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Parameter group
  create_db_parameter_group = true
  parameters = [
    {
      name  = "character_set_server"
      value = "utf8"
    },
    {
      name  = "character_set_client"
      value = "utf8"
    }
  ]

  tags = var.tags
}
