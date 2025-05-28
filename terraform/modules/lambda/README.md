# AWS Lambda Terraform Module

This module provisions AWS Lambda functions with comprehensive configuration options, following AWS best practices and the principle of separation of concerns by accepting external dependencies as input variables.

## Features

- Creates Lambda functions with configurable runtime and deployment options
- Supports multiple deployment package types (S3, local files, container images)
- Configurable VPC integration using external VPC and security group resources
- CloudWatch log group management with customizable retention
- Lambda permissions for various trigger sources
- Dead letter queue configuration
- X-Ray tracing support
- Ephemeral storage configuration
- Environment variables and layers support
- Comprehensive validation for all input parameters

## Usage

### Basic Lambda Function with S3 Deployment Package

```terraform
# Create IAM role using the IAM module
module "lambda_iam" {
  source = "./terraform/modules/iam"

  name = "my-lambda-role"

  # Role configuration
  trusted_role_services = ["lambda.amazonaws.com"]

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = {
    Environment = "dev"
    Project     = "my-app"
  }
}

# Create Lambda function
module "lambda" {
  source = "./terraform/modules/lambda"

  name        = "my-function"
  description = "My Lambda function"
  runtime     = "python3.11"
  handler     = "lambda_function.lambda_handler"

  # Use IAM role from IAM module
  role_arn = module.lambda_iam.role_arn

  # S3 deployment package
  deployment_package_type = "s3"
  s3_bucket              = "my-deployment-bucket"
  s3_key                 = "lambda-functions/my-function.zip"

  # Function configuration
  memory_size = 256
  timeout     = 30

  environment_variables = {
    ENVIRONMENT = "dev"
    LOG_LEVEL   = "INFO"
  }

  tags = {
    Environment = "dev"
    Project     = "my-app"
  }
}
```

### Lambda Function with VPC Configuration

```terraform
# Create VPC using the VPC module
module "vpc" {
  source = "./terraform/modules/vpc"

  name     = "lambda-vpc"
  vpc_cidr = "10.0.0.0/16"

  tags = {
    Environment = "production"
  }
}

# Create security group using the security-group module
module "lambda_sg" {
  source = "./terraform/modules/security-group"

  name   = "lambda-sg"
  vpc_id = module.vpc.vpc_id

  # Allow outbound HTTPS traffic
  egress_with_cidr_blocks = {
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Environment = "production"
  }
}

# Create IAM role with VPC permissions
module "lambda_iam" {
  source = "./terraform/modules/iam"

  name = "lambda-vpc-role"

  trusted_role_services = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  tags = {
    Environment = "production"
  }
}

# Create Lambda function with VPC configuration
module "lambda" {
  source = "./terraform/modules/lambda"

  name        = "vpc-lambda"
  description = "Lambda function with VPC access"
  runtime     = "python3.11"
  handler     = "app.handler"

  # Use IAM role from IAM module
  role_arn = module.lambda_iam.role_arn

  # S3 deployment package
  deployment_package_type = "s3"
  s3_bucket              = "my-deployment-bucket"
  s3_key                 = "lambda-functions/vpc-lambda.zip"

  # VPC configuration using external resources
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.lambda_sg.security_group_id]

  # Function configuration
  memory_size = 512
  timeout     = 60

  # Dead letter queue
  dead_letter_target_arn = "arn:aws:sqs:us-east-1:123456789012:lambda-dlq"

  # X-Ray tracing
  tracing_mode = "Active"

  tags = {
    Environment = "production"
    Project     = "vpc-app"
  }
}
```

### Lambda Function with API Gateway Integration

```terraform
# Create IAM role for Lambda
module "api_lambda_iam" {
  source = "./terraform/modules/iam"

  name = "api-lambda-role"

  trusted_role_services = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  # Custom policy for DynamoDB access
  policies = {
    dynamodb_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
            "dynamodb:Query",
            "dynamodb:Scan"
          ]
          Resource = [
            "arn:aws:dynamodb:*:*:table/my-table",
            "arn:aws:dynamodb:*:*:table/my-table/index/*"
          ]
        }
      ]
    })
  }

  tags = {
    Environment = "production"
  }
}

# Create Lambda function
module "api_lambda" {
  source = "./terraform/modules/lambda"

  name        = "api-handler"
  description = "API Gateway Lambda handler"
  runtime     = "nodejs20.x"
  handler     = "index.handler"

  # Use IAM role from IAM module
  role_arn = module.api_lambda_iam.role_arn

  # Local deployment package
  deployment_package_type = "local_file"
  local_filename         = "api-handler.zip"

  # Function configuration
  memory_size = 1024
  timeout     = 30

  environment_variables = {
    TABLE_NAME = "my-table"
    REGION     = "us-east-1"
  }

  # API Gateway permission
  permissions = {
    api_gateway = {
      action    = "lambda:InvokeFunction"
      principal = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:us-east-1:123456789012:api-id/*/*"
    }
  }

  tags = {
    Environment = "production"
    Project     = "api"
  }
}
```

### Container Image Lambda Function

```terraform
# Create IAM role for container Lambda
module "container_lambda_iam" {
  source = "./terraform/modules/iam"

  name = "container-lambda-role"

  trusted_role_services = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = {
    Environment = "production"
  }
}

# Create Lambda function with container image
module "container_lambda" {
  source = "./terraform/modules/lambda"

  name        = "container-function"
  description = "Lambda function using container image"

  # Use IAM role from IAM module
  role_arn = module.container_lambda_iam.role_arn

  # Container image deployment
  deployment_package_type = "image"
  package_type           = "Image"
  image_uri              = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-lambda:latest"

  # Function configuration
  memory_size = 2048
  timeout     = 300

  # Use ARM64 architecture for cost optimization
  architectures = ["arm64"]

  # Increased ephemeral storage
  ephemeral_storage_size = 1024

  environment_variables = {
    ENVIRONMENT = "production"
    LOG_LEVEL   = "DEBUG"
  }

  tags = {
    Environment = "production"
    Project     = "container-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the Lambda function | string | n/a | yes |
| role_arn | ARN of the IAM role that Lambda assumes when it executes your function | string | n/a | yes |
| name_prefix | Prefix to add to Lambda function name | string | null | no |
| description | Description of the Lambda function | string | "Lambda function managed by Terraform" | no |
| runtime | Runtime for the Lambda function | string | "python3.11" | no |
| handler | Function entrypoint in your code | string | "index.handler" | no |
| deployment_package_type | Type of deployment package (s3, local_file, or image) | string | "s3" | no |
| s3_bucket | S3 bucket containing the deployment package | string | null | no |
| s3_key | S3 key of the deployment package | string | null | no |
| s3_object_version | S3 object version of the deployment package | string | null | no |
| local_filename | Path to the local deployment package file | string | null | no |
| image_uri | ECR image URI containing the function's deployment package | string | null | no |
| package_type | Lambda deployment package type | string | "Zip" | no |
| memory_size | Amount of memory in MB your Lambda function can use at runtime | number | 128 | no |
| timeout | Amount of time your Lambda function has to run in seconds | number | 3 | no |
| reserved_concurrent_executions | Amount of reserved concurrent executions for this lambda function | number | null | no |
| environment_variables | Map of environment variables for the Lambda function | map(string) | {} | no |
| layers | List of Lambda Layer Version ARNs to attach to your Lambda function | list(string) | [] | no |
| subnet_ids | List of subnet IDs associated with the Lambda function (for VPC configuration) | list(string) | null | no |
| security_group_ids | List of security group IDs associated with the Lambda function (for VPC configuration) | list(string) | null | no |
| dead_letter_target_arn | ARN of an SQS queue or SNS topic for dead letter queue | string | null | no |
| create_log_group | Whether to create CloudWatch log group for the Lambda function | bool | true | no |
| log_retention_in_days | Specifies the number of days you want to retain log events in the specified log group | number | 14 | no |
| log_kms_key_id | KMS key ID to use for encrypting CloudWatch logs | string | null | no |
| permissions | Map of permission configurations for the Lambda function | map(object) | {} | no |
| tracing_mode | Tracing mode for the Lambda function (Active or PassThrough) | string | null | no |
| architectures | Instruction set architecture for your Lambda function | list(string) | ["x86_64"] | no |
| ephemeral_storage_size | Amount of ephemeral storage (/tmp) in MB your Lambda function can use at runtime | number | 512 | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| function_arn | The ARN of the Lambda function |
| function_name | The name of the Lambda function |
| function_qualified_arn | The qualified ARN of the Lambda function |
| function_version | Latest published version of the Lambda function |
| function_last_modified | The date the Lambda function was last modified |
| function_kms_key_arn | The ARN of the KMS key used to encrypt the Lambda function's environment variables |
| function_source_code_hash | Base64-encoded representation of raw SHA-256 sum of the zip file |
| function_source_code_size | The size in bytes of the function .zip file |
| function_invoke_arn | The ARN to be used for invoking Lambda function from API Gateway |
| function_signing_job_arn | ARN of the signing job |
| function_signing_profile_version_arn | ARN of the signing profile version |
| log_group_name | The name of the CloudWatch log group |
| log_group_arn | The ARN of the CloudWatch log group |
| permission_statement_ids | List of statement IDs of the Lambda permissions |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later
- IAM role with appropriate Lambda execution permissions (created using the IAM module)
- S3 bucket for deployment packages (when using S3 deployment)
- VPC and security groups (when using VPC configuration, created using VPC and security-group modules)

## Dependencies

This module follows the separation of concerns principle and requires external resources:

### Required Dependencies

- **IAM Role**: Must be created using the dedicated IAM module and passed via `role_arn` variable
- **Deployment Package**: Must be available in S3, as a local file, or as a container image in ECR

### Optional Dependencies

- **VPC Resources**: When VPC configuration is needed, subnet IDs and security group IDs must be provided from VPC and security-group modules
- **Dead Letter Queue**: SQS queue or SNS topic ARN for error handling
- **KMS Key**: For encrypting CloudWatch logs and environment variables

## Notes

### Deployment Package Types

- **S3**: Recommended for production environments. Requires `s3_bucket` and `s3_key` variables
- **Local File**: Suitable for development and testing. Requires `local_filename` variable
- **Container Image**: For containerized Lambda functions. Requires `image_uri` variable and `package_type = "Image"`

### VPC Configuration

- When using VPC configuration, ensure the IAM role has `AWSLambdaVPCAccessExecutionRole` policy
- VPC-enabled Lambda functions may experience cold start delays
- Ensure NAT Gateway or VPC endpoints are configured for internet access from private subnets

### Performance Considerations

- Use ARM64 architecture (`architectures = ["arm64"]`) for better price-performance ratio
- Configure appropriate memory allocation as it affects CPU allocation
- Use provisioned concurrency for latency-sensitive applications
- Consider using Lambda layers for shared dependencies

### Security Best Practices

- Follow the principle of least privilege when creating IAM roles
- Use environment variables for configuration, not secrets
- Enable X-Ray tracing for observability (`tracing_mode = "Active"`)
- Configure dead letter queues for error handling
- Use VPC configuration when accessing private resources

### Cost Optimization

- Set appropriate timeout values to avoid unnecessary charges
- Use reserved concurrency to control costs and prevent runaway executions
- Consider using ARM64 architecture for cost savings
- Monitor and optimize memory allocation based on actual usage

## Integration Examples

This module is designed to work seamlessly with other infrastructure modules:

```terraform
# Complete serverless application setup
module "vpc" {
  source = "./terraform/modules/vpc"
  # VPC configuration...
}

module "lambda_iam" {
  source = "./terraform/modules/iam"
  # IAM configuration...
}

module "lambda_sg" {
  source = "./terraform/modules/security-group"
  vpc_id = module.vpc.vpc_id
  # Security group configuration...
}

module "lambda" {
  source = "./terraform/modules/lambda"

  # Use outputs from other modules
  role_arn           = module.lambda_iam.role_arn
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.lambda_sg.security_group_id]

  # Lambda configuration...
}
```

This approach ensures proper resource isolation, reusability, and maintainability across your infrastructure.
