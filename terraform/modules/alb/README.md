# AWS Application Load Balancer (ALB) Terraform Module

This module provisions an AWS Application Load Balancer with target groups and listeners, following AWS best practices and the principle of separation of concerns.

## Features

- Creates an Application Load Balancer with configurable settings
- Supports multiple target groups for different services
- Configures HTTP and HTTPS listeners with SSL certificates
- Accepts external security groups from a dedicated security group module
- Highly customizable through variables

## Usage

### Basic Usage

```terraform
# Create security groups using the security-group module
module "alb_sg" {
  source = "./terraform/modules/security-group"

  name   = "web-alb"
  vpc_id = module.vpc.vpc_id
  
  # Security group rules
  ingress_with_cidr_blocks = {
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  }
  
  egress_with_cidr_blocks = {
    all = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  }
}

# Create ALB
module "alb" {
  source = "./terraform/modules/alb"

  name               = "web-app"
  
  # Networking
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  
  # Use security groups from security-group module
  security_group_ids = [module.alb_sg.security_group_id]
  
  # Target group configuration
  target_type        = "instance"
  port               = 80
  protocol           = "HTTP"
  
  # Health check configuration
  health_check = {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  tags = {
    Environment = "dev"
    Project     = "web-app"
  }
}
```

### HTTPS Load Balancer with Multiple Target Groups

```terraform
# Create security groups using the security-group module
module "alb_sg" {
  source = "./terraform/modules/security-group"

  # Security group configuration...
}

# Create ALB
module "alb" {
  source = "./terraform/modules/alb"

  name               = "api-service"
  
  # Networking
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]
  
  # HTTPS configuration
  port                    = 443
  protocol                = "HTTPS"
  listener_certificate_arn = "arn:aws:acm:us-west-1:123456789012:certificate/abcdef-1234-5678-9012-abcdefghijkl"
  
  # Default target group
  target_type        = "ip"
  
  # Additional target groups
  target_groups = {
    api = {
      name        = "api"
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
      health_check = {
        path     = "/api/health"
        port     = "traffic-port"
        protocol = "HTTP"
      }
    }
    admin = {
      name        = "admin"
      port        = 8081
      protocol    = "HTTP"
      target_type = "ip"
      health_check = {
        path     = "/admin/health"
        port     = "traffic-port"
        protocol = "HTTP"
      }
    }
  }
  
  # Additional listeners
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
    api = {
      port            = 8080
      protocol        = "HTTP"
      target_group_key = "api"
    }
    admin = {
      port            = 8081
      protocol        = "HTTP"
      target_group_key = "admin"
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "api"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the load balancer | string | n/a | yes |
| name_prefix | Prefix to add to the load balancer name | string | null | no |
| load_balancer_type | Type of load balancer to create (application, network, or gateway) | string | "application" | no |
| internal | Whether the load balancer is internal | bool | false | no |
| enable_deletion_protection | If true, deletion of the load balancer will be disabled via the AWS API | bool | false | no |
| enable_cross_zone_load_balancing | If true, cross-zone load balancing of the load balancer will be enabled | bool | true | no |
| enable_http2 | Indicates whether HTTP/2 is enabled in application load balancers | bool | true | no |
| ip_address_type | The type of IP addresses used by the subnets for your load balancer (ipv4 or dualstack) | string | "ipv4" | no |
| drop_invalid_header_fields | Indicates whether invalid header fields are dropped in application load balancers | bool | false | no |
| idle_timeout | The time in seconds that the connection is allowed to be idle | number | 60 | no |
| vpc_id | ID of the VPC where to create the load balancer | string | n/a | yes |
| subnet_ids | List of subnet IDs for the load balancer | list(string) | n/a | yes |
| security_group_ids | List of security group IDs for the load balancer | list(string) | [] | no |
| create_target_group | Controls if target group should be created | bool | true | no |
| target_group_name | Name of the target group | string | null | no |
| target_groups | Map of target group configurations to create | any | {} | no |
| target_type | Type of target that you must specify when registering targets with this target group | string | "instance" | no |
| port | Port on which targets receive traffic | number | 80 | no |
| protocol | Protocol to use for routing traffic to the targets | string | "HTTP" | no |
| protocol_version | Protocol version. Only applicable when protocol is HTTP or HTTPS | string | "HTTP1" | no |
| deregistration_delay | Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused | number | 300 | no |
| slow_start | Amount time for targets to warm up before the load balancer sends them a full share of requests | number | 0 | no |
| stickiness | Target group sticky configuration | map(string) | {} | no |
| health_check | Health check configuration for the target group | map(string) | {} | no |
| create_listener | Controls if listener should be created | bool | true | no |
| listeners | Map of listener configurations to create | any | {} | no |
| listener_ssl_policy | Name of the SSL Policy for the listener | string | "ELBSecurityPolicy-2016-08" | no |
| listener_certificate_arn | ARN of the default SSL server certificate | string | null | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| lb_id | The ID of the load balancer |
| lb_arn | The ARN of the load balancer |
| lb_name | The name of the load balancer |
| lb_dns_name | The DNS name of the load balancer |
| lb_zone_id | The canonical hosted zone ID of the load balancer |
| lb_arn_suffix | The ARN suffix for use with CloudWatch Metrics |
| lb_security_group_ids | The security group IDs attached to the load balancer |
| lb_subnet_ids | The subnet IDs attached to the load balancer |
| target_group_arn | The ARN of the default target group |
| target_group_id | The ID of the default target group |
| target_group_name | The name of the default target group |
| target_group_arn_suffix | The ARN suffix for use with CloudWatch Metrics for the default target group |
| target_group_arns | ARNs of all target groups |
| target_group_names | Names of all target groups |
| http_listener_arn | The ARN of the HTTP listener |
| https_listener_arn | The ARN of the HTTPS listener |
| listener_arns | ARNs of all listeners |

## Prerequisites

- AWS account and credentials configured
- Terraform 0.13 or later
- AWS provider 3.0 or later
- VPC with subnets (from a VPC module)
- Security groups (from a security-group module)
- SSL certificate in AWS Certificate Manager (for HTTPS)

## Notes

- This module follows the principle of separation of concerns by accepting external resources as inputs
- For production workloads, it's recommended to use HTTPS with a valid SSL certificate
- When using multiple target groups, make sure to configure the listeners correctly
- The module creates default health checks if none are provided
- Security groups should be created using a dedicated security-group module
