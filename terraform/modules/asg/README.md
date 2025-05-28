# AWS Auto Scaling Group (ASG) Terraform Module

This module provisions an AWS Auto Scaling Group with Launch Template, following AWS best practices and the principle of separation of concerns. It supports custom tag specifications for both ASG and launched instances.

## Features

- Creates an Auto Scaling Group with configurable settings and tag specifications
- Supports Launch Templates with detailed instance configurations
- Integrates with load balancers for target group registration
- Accepts external security groups and IAM instance profiles
- Configurable health checks, termination policies, and cooldown periods
- Supports capacity rebalancing for Spot Instances
- Customizable metadata options for IMDSv2 compliance
- Flexible tagging for both ASG and launched instances
- Support for custom EBS volumes with encryption
- Conditional resource creation for flexible deployments
- Integration with multiple availability zones for high availability

## Usage

### Basic Usage

```terraform
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

  # Instance metadata options for IMDSv2
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  # Auto scaling group configuration
  min_size                  = 2
  max_size                  = 10
  desired_capacity          = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300
  capacity_rebalance        = true

  # Networking
  vpc_zone_identifier = module.vpc.private_subnet_ids

  # Load balancer integration
  target_group_arns = [module.alb.target_group_arns[0]]

  # Custom tag specifications
  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        Name = "api-service-instance"
        Role = "api"
      }
    },
    {
      resource_type = "volume"
      tags = {
        Name = "api-service-volume"
      }
    }
  ]

  tags = {
    Environment = "production"
    Project     = "api"
  }
}
```

### Usage with Custom EBS Volumes

```terraform
module "asg" {
  source = "./terraform/modules/asg"

  name               = "storage-app"
  image_id           = "ami-0123456789abcdef0"
  instance_type      = "t3.large"
  
  # Custom EBS volumes
  block_device_mappings = [
    {
      device_name = "/dev/sda1"
      ebs = {
        volume_size           = 50
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = true
      }
    },
    {
      device_name = "/dev/sdf"
      ebs = {
        volume_size           = 100
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = false
        iops                  = 3000
        throughput            = 125
      }
    }
  ]

  # Auto scaling group configuration
  min_size         = 1
  max_size         = 5
  desired_capacity = 2

  # Networking
  vpc_zone_identifier = module.vpc.private_subnet_ids
  security_group_ids  = [module.asg_sg.security_group_id]

  tags = {
    Environment = "production"
    Project     = "storage-app"
  }
}
```

### Minimal Configuration

```terraform
module "asg_minimal" {
  source = "./terraform/modules/asg"

  name    = "simple-app"
  image_id = "ami-0123456789abcdef0"
  
  vpc_zone_identifier = module.vpc.private_subnet_ids

  tags = {
    Environment = "dev"
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

### Metadata Options Structure

The `metadata_options` variable accepts a map with the following supported keys:

```hcl
metadata_options = {
  http_endpoint               = "enabled"     # "enabled" or "disabled"
  http_tokens                 = "required"    # "optional" or "required" (IMDSv2)
  http_put_response_hop_limit = 2             # Number between 1 and 64
  instance_metadata_tags      = "enabled"     # "enabled" or "disabled"
}
```

### Tag Specifications Structure

The `tag_specifications` variable accepts a list of objects for tagging resources during launch:

```hcl
tag_specifications = [
  {
    resource_type = "instance"    # "instance", "volume", "network-interface", "spot-instances-request"
    tags = {
      Name = "my-instance"
      Role = "web-server"
    }
  },
  {
    resource_type = "volume"
    tags = {
      Name = "my-volume"
    }
  }
]
```

### Block Device Mappings Structure

The `block_device_mappings` variable accepts a list of objects for custom EBS volumes:

```hcl
block_device_mappings = [
  {
    device_name  = "/dev/sda1"
    ebs = {
      volume_size           = 20                # Size in GB
      volume_type           = "gp3"             # gp2, gp3, io1, io2, st1, sc1
      encrypted             = true              # Boolean
      delete_on_termination = true              # Boolean
      iops                  = 3000              # For gp3, io1, io2
      throughput            = 125               # For gp3 only (125-1000)
      kms_key_id            = "arn:aws:kms:..." # KMS key ARN
    }
  }
]
```

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
- Terraform 1.3.2 or later
- AWS provider 5.83 or later
- VPC with subnets (from a VPC module)
- Security groups (from a security-group module)
- IAM instance profile (from an IAM module)
- Load balancer and target groups (from an ALB module) if needed

## Notes

- This module follows the principle of separation of concerns by accepting external resources as inputs rather than creating them internally
- For production workloads, it's recommended to use the ELB health check type (`health_check_type = "ELB"`)
- When using target groups, make sure to set the `health_check_grace_period` to allow instances time to bootstrap
- The module creates default tag specifications if none are provided
- Security groups, IAM roles, and load balancers should be created using their respective dedicated modules
- Use `capacity_rebalance = true` when working with Spot Instances to enable automatic rebalancing
- For enhanced security, configure `metadata_options` to enforce IMDSv2 by setting `http_tokens = "required"`
- The module supports custom tag specifications for different resource types (instances, volumes, etc.)

## Best Practices

### Security

- Always use IMDSv2 by setting `metadata_options.http_tokens = "required"`
- Enable EBS encryption for all volumes by setting `encrypted = true` in block device mappings
- Use dedicated security groups with minimal required permissions
- Avoid placing instances in public subnets unless absolutely necessary

### Performance and Reliability

- Use ELB health checks for better application-aware health monitoring
- Set appropriate `health_check_grace_period` to allow application startup time
- Use multiple availability zones in `vpc_zone_identifier` for high availability
- Consider using `capacity_rebalance = true` for Spot Instances
- Choose appropriate instance types based on workload requirements

### Cost Optimization

- Use appropriate EBS volume types (gp3 is often more cost-effective than gp2)
- Set `delete_on_termination = true` for temporary volumes
- Consider using Spot Instances for fault-tolerant workloads
- Right-size instances based on actual usage patterns

### Monitoring and Maintenance

- Enable detailed monitoring with `enable_monitoring = true` for better observability
- Use appropriate termination policies based on your application architecture
- Tag resources consistently for better cost allocation and management
- Monitor Auto Scaling metrics and adjust min/max/desired capacity as needed

## Common Issues and Troubleshooting

- **Instance Launch Failures**: Check AMI availability in the target region, verify IAM permissions, and ensure subnets have available IP addresses
- **Health Check Failures**: Increase `health_check_grace_period`, verify application startup time, check security group rules for health check ports
- **Scaling Issues**: Review CloudWatch alarms, check service quotas, verify scaling policies and cooldown periods
- **EBS Volume Issues**: Verify device names, check volume types and sizes, ensure encryption settings are correct
- **Networking Problems**: Verify security group rules, check route tables, ensure NAT Gateway or Internet Gateway configuration
- **Permission Errors**: Verify IAM instance profile has required permissions, check policy attachments, review CloudTrail logs for specific permission errors
