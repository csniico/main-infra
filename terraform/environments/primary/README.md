# AWS Infrastructure - Primary Environment

This directory contains Terraform configurations for deploying a secure, highly available, and cost-effective AWS infrastructure in a single region. The infrastructure follows AWS best practices and implements a robust architecture for hosting containerized applications.

## Architecture Overview

The infrastructure consists of the following components:

### Core Network Infrastructure

- VPC with 2 public and 2 private subnets across different availability zones
- Internet Gateway for public internet access
- NAT Gateways in each AZ for private subnet internet access
- Route tables for traffic management

### Compute Resources

- 2 Auto Scaling Groups (ASGs) for different application tiers:
  - App tier ASG for web-facing applications
  - API tier ASG for internal services
- Each EC2 instance has an attached EBS volume for persistent storage
- Scaling policies based on CPU/memory usage

### Container Services

- ECS cluster with Fargate and Fargate Spot capacity providers
- 5 distinct ECS services:
  - 1 web-facing service connected to an Application Load Balancer
  - 4 internal services for backend processing

### Database

- RDS MySQL instance in private subnets
- Multi-AZ deployment for high availability
- Automated backups and maintenance windows
- Custom parameter group for performance optimization

### Security Components

- Security groups with least privilege access
- IAM roles with specific permissions for each service
- Encryption for data at rest and in transit
- Private subnets for sensitive resources

## Deployment Instructions

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform 1.3.2 or later
- AWS provider 5.83 or later

### Deployment Steps

1. Initialize Terraform:

```bash
terraform init
```

1. Review the execution plan:

```bash
terraform plan
```

1. Apply the configuration:

```bash
terraform apply
```

1. To destroy the infrastructure:

```bash
terraform destroy
```

## Infrastructure Components

### VPC and Networking

- VPC CIDR: 10.0.0.0/16
- Public Subnets: 10.0.0.0/20 (split across AZs)
- Private Subnets: 10.0.16.0/20 (split across AZs)
- NAT Gateways: One per AZ for high availability

### Security Groups

- ALB Security Group: Allows HTTP/HTTPS from internet
- App Security Group: Allows traffic from ALB only
- API Security Group: Allows traffic from App tier only
- Database Security Group: Allows MySQL traffic from App and API tiers only

### IAM Roles

- EC2 Instance Role: Permissions for SSM and CloudWatch
- ECS Task Execution Role: Permissions for pulling images and logging
- ECS Task Role: Permissions for application-specific AWS services

### Auto Scaling Groups

- App ASG: t3.small instances with 20GB EBS volumes
- API ASG: t3.small instances with 20GB EBS volumes
- Scaling based on CPU utilization

### Load Balancer

- Application Load Balancer in public subnets
- HTTP listener on port 80
- Health checks for target services

### ECS Services

- Web Service: Connected to ALB, scales between 2-6 tasks
- Internal Services: Not exposed to internet, scale between 1-3 tasks
- All services use Fargate for serverless container management

### RDS Database

- MySQL 8.0 on db.t3.small instance
- Multi-AZ deployment for high availability
- 20GB storage with auto-scaling up to 40GB
- 7-day backup retention period

## Customization

The infrastructure can be customized by modifying the variables in `variables.tf`. Key variables include:

- `vpc_cidr`: CIDR block for the VPC
- `az_count`: Number of availability zones to use
- `instance_types`: EC2 instance types for ASGs
- `db_instance_class`: RDS instance class
- `db_allocated_storage`: Allocated storage for RDS

## Monitoring and Logging

- CloudWatch Container Insights enabled for ECS cluster
- CloudWatch Logs for container logs
- Auto Scaling notifications for scaling events

## Security Considerations

- All data is encrypted at rest using AWS managed keys
- All traffic between services is encrypted in transit
- Security groups follow least privilege principle
- Sensitive resources are placed in private subnets
- IAM roles follow least privilege access

## Cost Optimization

- Fargate Spot used for non-critical workloads
- Auto Scaling to match capacity with demand
- t3 instance family for cost-effective compute
- gp3 EBS volumes for better performance/cost ratio

## Future Enhancements

- Implement AWS WAF for web application firewall protection
- Add CloudFront distribution for content delivery
- Implement cross-region disaster recovery
- Add AWS Secrets Manager for sensitive configuration
- Implement AWS Config and Security Hub for compliance monitoring
