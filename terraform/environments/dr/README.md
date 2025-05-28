# Disaster Recovery (DR) Environment

## Overview

This directory contains the Terraform configuration for the Disaster Recovery (DR) environment of the TaskMaster application. The DR environment is designed to take over operations in case the primary environment becomes unavailable due to a regional outage or other disaster scenarios.

## Architecture

The DR environment is deployed in the `us-east-1` region, while the primary environment is in `eu-west-1`. The DR environment maintains a reduced-capacity replica of the primary environment's infrastructure, which can be rapidly scaled up during a failover event.

### Key Components

- **VPC and Networking**: Identical network topology to the primary region
- **RDS Database**: Read replica of the primary database that can be promoted to primary
- **Auto Scaling Groups**: Jenkins and monitoring servers with initially minimal capacity
- **ECS Services**: Microservices with minimal or zero initial capacity
- **Load Balancers**: Application Load Balancer with target groups for services
- **Failover Automation**: Lambda function to orchestrate the DR failover process

## Failover Strategy

The DR environment implements a "pilot light" disaster recovery strategy, where:

1. Critical components (like the database) are replicated from primary to DR
2. Non-critical components are provisioned but kept at minimal or zero capacity
3. During failover, the Lambda function scales up resources to handle production traffic

## Directory Structure

- `main.tf`: Main infrastructure configuration
- `variables.tf`: Input variables for the DR environment
- `outputs.tf`: Output values from the DR environment
- `data.tf`: Data sources, including references to primary region resources
- `lambda.tf`: DR failover Lambda function configuration

## Usage

### Prerequisites

- AWS credentials with appropriate permissions
- Terraform v1.0.0 or newer
- Primary environment must be deployed first

### Deployment

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### Testing DR Readiness

Regular testing of the DR environment is crucial to ensure it can take over when needed. See the `lambda-README.md` file for details on how to trigger a DR failover test.

## Monitoring and Maintenance

- The DR environment should be regularly tested to ensure it can be activated when needed
- Any changes to the primary environment should be reflected in the DR environment
- Database replication lag should be monitored to ensure minimal data loss during failover

## Cost Optimization

The DR environment is designed to minimize costs during normal operation by:

- Using minimal capacity for compute resources
- Leveraging AWS's pay-as-you-go pricing model
- Sharing some resources with the primary environment where possible

## Security Considerations

- The DR environment has the same security controls as the primary environment
- IAM roles and security groups are configured with least privilege principles
- All sensitive data is encrypted at rest and in transit
