# AWS Auto Scaling Group (ASG) Terraform Module

This module provisions an AWS Auto Scaling Group with Launch Template, following AWS best practices and the principle of separation of concerns.

## Features

- Creates an Auto Scaling Group with configurable settings
- Supports Launch Templates with detailed instance configurations
- Integrates with load balancers for target group registration
- Accepts external security groups and IAM instance profiles
- Highly customizable through variables

## Usage

### Basic Usage

```terraform
# Create security groups using the security-group module
module "asg_sg" {
  source = "./terraform/modules/security-group"

  name   = "web-app-asg"
  vpc_id = module.vpc.vpc_id
  
  # Security group rules
  ingress_with_cidr_blocks = {
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "10.0.0.0/8"
    }
  }
}

# Create IAM instance profile using the IAM module
module "asg_iam" {
  source = "./terraform/modules/iam"

  name                    = "web-app-ec2"
  trusted_role_services   = ["ec2.amazonaws.com"]
  create_instance_profile = true
  
  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

# Create Auto Scaling Group
module "asg" {
  source = "./terraform/modules/asg"

  name               = "web-app"
  
  # Launch template configuration
  image_id           = "ami-0123456789abcdef0"
  instance_type      = "t3.micro"
  
  # Use IAM instance profile from IAM module
  iam_instance_profile_name = module.asg_iam.instance_profile_name
  
  # Use security groups from security-group module
  security_group_ids = [module.asg_sg.security_group_id]
  
  # Auto scaling group configuration
  min_size         = 1
  max_size         = 3
  desired_capacity = 2
  
  # Networking from VPC module
  vpc_zone_identifier = module.vpc.private_subnet_ids
  
  # Target groups from ALB module
  target_group_arns = [module.alb.target_group_arns[0]]
  
  tags = {
    Environment = "dev"
    Project     = "web-app"
  }
}
```

### Advanced Usage with Custom Configuration

```terraform
module "asg" {
  source = "./terraform/modules/asg"

  name                 = "api-service"
  
  # Launch template configuration
  image_id             = "ami-0123456789abcdef0"
  instance_type        = "t3.medium"
  key_name             = "my-key-pair"
  iam_instance_profile_name = module.asg_iam.instance_profile_name
  security_group_ids   = [module.asg_sg.security_group_id]
  
  # User data
  user_data            = <<-EOF
    #!/bin/bash
    echo "Hello, World!" > /var/www/html/index.html
    systemctl start httpd
  EOF
  
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
  min_size                  = 2
  max_size                  = 10
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  # Networking
  vpc_zone_identifier = module.vpc.private_subnet_ids
  
  # Load balancer integration
  target_group_arns = [module.alb.target_group_arns[0]]
  
  tags = {
    Environment = "production"
    Project     = "api"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the Auto Scaling Group | string | n/a | yes |
| name_prefix | Prefix to add to the Auto Scaling Group name | string | null | no |
| create_launch_template | Controls if the Launch Template should be created | bool | true | no |
| launch_template_name | Name of the Launch Template | string | null | no |
| launch_template_description | Description of the Launch Template | string | null | no |
| update_default_version | Whether to update Default Version each update | bool | true | no |
| image_id | The AMI ID to use for the instance | string | n/a | yes |
| instance_type | The type of instance to start | string | "t3.micro" | no |
| key_name | The key name to use for the instance | string | null | no |
| user_data | The user data to provide when launching the instance | string | null | no |
| ebs_optimized | If true, the launched EC2 instance will be EBS-optimized | bool | false | no |
| enable_monitoring | Enables/disables detailed monitoring | bool | true | no |
| metadata_options | Customize the metadata options for the instance | map(string) | {} | no |
| block_device_mappings | Specify volumes to attach to the instance besides the volumes specified by the AMI | list(any) | [] | no |
| iam_instance_profile_name | The name of the IAM instance profile to associate with launched instances | string | null | no |
| tag_specifications | The tags to apply to the resources during launch | list(any) | [] | no |
| create_asg | Controls if the Auto Scaling Group should be created | bool | true | no |
| min_size | Minimum size of the Auto Scaling Group | number | 1 | no |
| max_size | Maximum size of the Auto Scaling Group | number | 3 | no |
| desired_capacity | Desired capacity of the Auto Scaling Group | number | 1 | no |
| capacity_rebalance | Indicates whether capacity rebalance is enabled | bool | false | no |
| default_cooldown | The amount of time, in seconds, after a scaling activity completes before another scaling activity can start | number | 300 | no |
| health_check_grace_period | Time (in seconds) after instance comes into service before checking health | number | 300 | no |
| health_check_type | Controls how health checking is done. Valid values are EC2 or ELB | string | "EC2" | no |
| force_delete | Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate | bool | false | no |
| termination_policies | A list of policies to decide how the instances in the Auto Scaling Group should be terminated | list(string) | ["Default"] | no |
| vpc_zone_identifier | A list of subnet IDs to launch resources in | list(string) | n/a | yes |
| target_group_arns | A list of aws_alb_target_group ARNs, for use with Application Load Balancing | list(string) | [] | no |
| security_group_ids | A list of security group IDs to associate with the instances | list(string) | [] | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| autoscaling_group_id | The ID of the Auto Scaling Group |
| autoscaling_group_name | The name of the Auto Scaling Group |
| autoscaling_group_arn | The ARN of the Auto Scaling Group |
| autoscaling_group_min_size | The minimum size of the Auto Scaling Group |
| autoscaling_group_max_size | The maximum size of the Auto Scaling Group |
| autoscaling_group_desired_capacity | The desired capacity of the Auto Scaling Group |
| autoscaling_group_health_check_type | The health check type of the Auto Scaling Group |
| autoscaling_group_vpc_zone_identifier | The VPC zone identifier of the Auto Scaling Group |
| launch_template_id | The ID of the Launch Template |
| launch_template_arn | The ARN of the Launch Template |
| launch_template_name | The name of the Launch Template |
| launch_template_latest_version | The latest version of the Launch Template |
| launch_template_default_version | The default version of the Launch Template |

## Prerequisites

- AWS account and credentials configured
- Terraform 0.13 or later
- AWS provider 3.0 or later
- VPC with subnets (from a VPC module)
- Security groups (from a security-group module)
- IAM instance profile (from an IAM module)
- Load balancer and target groups (from an ALB module) if needed

## Notes

- This module follows the principle of separation of concerns by accepting external resources as inputs
- For production workloads, it's recommended to use the ELB health check type
- When using target groups, make sure to set the health_check_grace_period to allow instances time to bootstrap
- The module creates default block device mappings and metadata options if none are provided
- Security groups, IAM roles, and load balancers should be created using their respective dedicated modules
