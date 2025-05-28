# DR Failover Lambda Function

## Overview

The DR Failover Lambda function automates the disaster recovery process by promoting the DR environment from a standby state to a fully operational production environment. This document explains how the Lambda function works and how to trigger it during a disaster recovery scenario or test.

## How It Works

The Lambda function performs four key operations in sequence:

1. **RDS Promotion**: Promotes the RDS read replica to a standalone primary instance
2. **ASG Scaling**: Increases capacity for Jenkins and monitoring Auto Scaling Groups
3. **ECS Scaling**: Scales up ECS services to handle production traffic
4. **Target Registration**: Registers instances and containers with load balancer target groups

### Detailed Process Flow

#### 1. RDS Promotion

- Verifies if the DB instance is a read replica
- Calls the `promote_read_replica` API
- Waits for the promotion to complete
- The database becomes a standalone instance that can accept write operations

#### 2. ASG Scaling

- Updates Jenkins ASG to min=1, max=3, desired=1
- Updates Monitoring ASG to min=1, max=3, desired=1
- This ensures critical infrastructure services are running

#### 3. ECS Scaling

- Scales up all microservices in the ECS cluster
- Sets desired count to at least 1 for each service
- Services include: frontend, notification service, user service, task API, and Kafka

#### 4. Target Registration

- Registers Jenkins instances with the Jenkins target group
- Registers monitoring instances with Prometheus, Grafana, and Jaeger target groups
- When enabled, registers ECS tasks with their respective target groups

## How to Trigger the Lambda Function

### Manual Invocation (AWS Console)

1. Log in to the AWS Management Console
2. Navigate to the Lambda service
3. Find the function named `dr-dr-failover`
4. Click the "Test" button
5. Use an empty JSON object `{}` as the test event
6. Click "Invoke"

### Using AWS CLI

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

### Using CloudWatch Events Rule

A CloudWatch Events Rule named `dr-dr-failover-test` is configured but disabled by default (999-day schedule). To use this rule:

1. Log in to the AWS Management Console
2. Navigate to CloudWatch service
3. Go to Events → Rules
4. Find the rule named `dr-dr-failover-test`
5. Select the rule and click "Actions" → "Enable"

## Monitoring the Failover Process

### CloudWatch Logs

The Lambda function logs all operations to CloudWatch Logs. To view the logs:

1. Navigate to CloudWatch → Log Groups
2. Find the log group named `/aws/lambda/dr-dr-failover`
3. Click on the latest log stream to view the execution logs

### Expected Log Patterns

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

## Troubleshooting

### Common Issues

1. **Lambda Timeout**: If the function times out (default timeout is 5 minutes), you may need to increase the timeout value in the Lambda configuration.

2. **Permission Errors**: If you see permission-related errors, verify that the Lambda execution role has all necessary permissions.

3. **Resource Not Found**: If resources like ASGs or ECS services are not found, verify that the environment variables are correctly set.

### Rollback Process

There is no automated rollback process. If you need to revert to the primary region:

1. Scale down resources in the DR region
2. Ensure the primary region is operational
3. Update DNS or Route 53 records to point back to the primary region

## Testing Recommendations

- Conduct regular DR tests (quarterly recommended)
- Test during maintenance windows to minimize impact
- Document test results and any issues encountered
- Update the DR process based on test findings
