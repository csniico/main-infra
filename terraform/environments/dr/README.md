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

## DR Failover Lambda Function

### How It Works

The DR Failover Lambda function automates the disaster recovery process by promoting the DR environment from a standby state to a fully operational production environment. The function performs four key operations in sequence:

1. **RDS Promotion**: Promotes the RDS read replica to a standalone primary instance
2. **ASG Scaling**: Increases capacity for Jenkins and monitoring Auto Scaling Groups
3. **ECS Scaling**: Scales up ECS services to handle production traffic
4. **Target Registration**: Registers instances and containers with load balancer target groups

#### Detailed Process Flow

**RDS Promotion**

- Verifies if the DB instance is a read replica
- Calls the `promote_read_replica` API
- Waits for the promotion to complete
- The database becomes a standalone instance that can accept write operations

**ASG Scaling**

- Updates Jenkins ASG to min=1, max=3, desired=1
- Updates Monitoring ASG to min=1, max=3, desired=1
- This ensures critical infrastructure services are running

**ECS Scaling**

- Scales up all microservices in the ECS cluster
- Sets desired count to at least 1 for each service
- Services include: frontend, notification service, user service, task API, and Kafka

**Target Registration**

- Registers Jenkins instances with the Jenkins target group
- Registers monitoring instances with Prometheus, Grafana, and Jaeger target groups
- When enabled, registers ECS tasks with their respective target groups

### How to Trigger DR Failover

#### Manual Invocation (AWS Console)

1. Log in to the AWS Management Console
2. Navigate to the Lambda service
3. Find the function named `dr-dr-failover`
4. Click the "Test" button
5. Use an empty JSON object `{}` as the test event
6. Click "Invoke"

#### Using AWS CLI

```bash
# Invoke the Lambda function
aws lambda invoke \
  --function-name dr-dr-failover \
  --region us-east-1 \
  --payload '{}' \
  response.json

# Check the response
cat response.json
```

#### Using CloudWatch Events Rule

A CloudWatch Events Rule named `dr-dr-failover-test` is configured but disabled by default (999-day schedule). To use this rule:

1. Log in to the AWS Management Console
2. Navigate to CloudWatch service
3. Go to Events → Rules
4. Find the rule named `dr-dr-failover-test`
5. Select the rule and click "Actions" → "Enable"

### Monitoring the Failover Process

#### CloudWatch Logs

The Lambda function logs all operations to CloudWatch Logs. To view the logs:

1. Navigate to CloudWatch → Log Groups
2. Find the log group named `/aws/lambda/dr-dr-failover`
3. Click on the latest log stream to view the execution logs

#### Expected Log Patterns

A successful failover will show logs similar to:

```
INFO: Promoting RDS read replica db-instance-name to standalone instance
INFO: Successfully initiated promotion of db-instance-name
INFO: Waiting for db-instance-name to complete promotion...
INFO: RDS instance db-instance-name successfully promoted to standalone instance
INFO: Scaling ASG dr-jenkins to min=1, max=3, desired=1
INFO: Successfully updated ASG dr-jenkins
INFO: Scaling ASG dr-monitoring to min=1, max=3, desired=1
INFO: Successfully updated ASG dr-monitoring
INFO: Scaling ECS service frontend in cluster dr
INFO: Successfully scaled ECS service frontend
...
INFO: Registering instances from ASG dr-jenkins with target group arn:aws:...
INFO: Successfully registered 1 instances with target group arn:aws:...
```

### Troubleshooting DR Failover

#### Common Issues

1. **Lambda Timeout**: If the function times out (default timeout is 5 minutes), you may need to increase the timeout value in the Lambda configuration.

2. **Permission Errors**: If you see permission-related errors, verify that the Lambda execution role has all necessary permissions.

3. **Resource Not Found**: If resources like ASGs or ECS services are not found, verify that the environment variables are correctly set.

#### Rollback Process

There is no automated rollback process. If you need to revert to the primary region:

1. Scale down resources in the DR region
2. Ensure the primary region is operational
3. Update DNS or Route 53 records to point back to the primary region

## Testing DR Readiness

Regular testing of the DR environment is crucial to ensure it can take over when needed. Testing recommendations:

- Conduct regular DR tests (quarterly recommended)
- Test during maintenance windows to minimize impact
- Document test results and any issues encountered
- Update the DR process based on test findings

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
