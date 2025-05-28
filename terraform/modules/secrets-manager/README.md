# AWS Secrets Manager Terraform Module

This module provisions AWS Secrets Manager resources with support for creating single or multiple secrets, configuring access policies, and replication, following AWS best practices and the principle of separation of concerns.

## Features

- Creates AWS Secrets Manager secrets with configurable settings
- Supports both string and key-value pair secrets
- Enables encryption with AWS managed or customer managed KMS keys
- Configures recovery window for secret deletion
- Supports cross-region replication
- Creates IAM policies for accessing secrets
- Supports resource policies for fine-grained access control
- Highly customizable through variables
- Follows separation of concerns by focusing only on Secrets Manager resources

## Usage

### Basic Usage - Single Secret

```terraform
module "database_secret" {
  source = "./terraform/modules/secrets-manager"

  name        = "database-credentials"
  description = "Database credentials for the application"
  
  # Secret value as a string
  secret_string = jsonencode({
    username = "admin"
    password = "example-password"
    engine   = "mysql"
    host     = "db.example.com"
    port     = 3306
  })
  
  # Enable encryption with default AWS KMS key
  encrypted = true
  
  tags = {
    Environment = "dev"
    Project     = "example"
  }
}
```

### Using Key-Value Pairs

```terraform
module "api_secret" {
  source = "./terraform/modules/secrets-manager"

  name        = "api-credentials"
  description = "API credentials for external service"
  
  # Secret value as key-value pairs (will be converted to JSON)
  secret_key_value = {
    api_key    = "example-api-key"
    api_secret = "example-api-secret"
    endpoint   = "https://api.example.com"
  }
  
  # Create IAM policy for accessing the secret
  create_access_policy = true
  policy_actions       = [
    "secretsmanager:GetSecretValue",
    "secretsmanager:DescribeSecret"
  ]
  
  tags = {
    Environment = "production"
    Project     = "api-integration"
  }
}
```

### Multiple Secrets

```terraform
module "application_secrets" {
  source = "./terraform/modules/secrets-manager"

  # Set create_secret to false to use the secrets map
  create_secret = false
  
  # Define multiple secrets
  secrets = {
    "database-credentials" = {
      description = "Database credentials for the application"
      secret_key_value = {
        username = "admin"
        password = "example-password"
        engine   = "mysql"
        host     = "db.example.com"
        port     = 3306
      }
      create_access_policy = true
    },
    "api-credentials" = {
      description = "API credentials for external service"
      secret_key_value = {
        api_key    = "example-api-key"
        api_secret = "example-api-secret"
        endpoint   = "https://api.example.com"
      }
      create_access_policy = true
    },
    "jwt-secret" = {
      description = "JWT signing secret"
      secret_string = "example-jwt-secret"
      kms_key_id    = module.kms.key_arn
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "example"
  }
}
```

### With Cross-Region Replication

```terraform
module "critical_secret" {
  source = "./terraform/modules/secrets-manager"

  name        = "critical-credentials"
  description = "Critical credentials with cross-region replication"
  
  secret_string = jsonencode({
    username = "admin"
    password = "example-password"
  })
  
  # Enable replication to another region
  replica_regions = [
    {
      region = "us-west-2"
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "critical"
  }
}
```

### With Resource Policy

```terraform
module "shared_secret" {
  source = "./terraform/modules/secrets-manager"

  name        = "shared-credentials"
  description = "Credentials shared with another AWS account"
  
  secret_string = jsonencode({
    username = "shared-user"
    password = "example-password"
  })
  
  # Resource policy allowing access from another account
  secret_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Environment = "production"
    Project     = "cross-account"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the secret | string | null | no |
| name_prefix | Prefix to add to the secret name | string | null | no |
| use_name_prefix | Whether to use name_prefix or name | bool | false | no |
| environment | Environment name | string | "dev" | no |
| description | Description of the secret | string | "Managed by Terraform" | no |
| create_secret | Whether to create a single secret (true) or multiple secrets (false) | bool | true | no |
| secret_string | Specifies text data that you want to encrypt and store in this version of the secret | string | null | no |
| secret_key_value | Key-value map that will be converted to JSON and stored as secret | map(string) | null | no |
| recovery_window_in_days | Number of days that AWS Secrets Manager waits before it can delete the secret | number | 30 | no |
| kms_key_id | ARN or Id of the AWS KMS key to be used to encrypt the secret values | string | null | no |
| force_overwrite_replica_secret | Whether to overwrite a secret with the same name in the destination Region | bool | false | no |
| replica_regions | List of regions to replicate the secret to | list(object) | [] | no |
| secrets | Map of secrets to create | map(object) | {} | no |
| create_access_policy | Whether to create an IAM policy for accessing the secret | bool | false | no |
| policy_actions | List of actions to allow in the IAM policy | list(string) | ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"] | no |
| secret_policy | Valid JSON document representing a resource policy for the secret | string | null | no |
| tags | A map of tags to add to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_id | The ID of the secret |
| secret_arn | The ARN of the secret |
| secret_name | The name of the secret |
| secret_version_id | The unique identifier of the version of the secret |
| secret_policy_id | The ID of the secret policy |
| access_policy_id | The ID of the IAM policy for accessing the secret |
| access_policy_arn | The ARN of the IAM policy for accessing the secret |
| access_policy_name | The name of the IAM policy for accessing the secret |
| secrets | Map of secrets created and their attributes |
| secret_arns | Map of secret names to ARNs |
| secret_ids | Map of secret names to IDs |
| access_policy_arns | Map of secret names to access policy ARNs |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later
- IAM permissions to create Secrets Manager resources

## Notes

- Secrets are encrypted by default using the default AWS KMS key for Secrets Manager
- For cross-region replication, ensure that the IAM role has the necessary permissions
- When using KMS encryption, ensure that the IAM role has the necessary permissions to use the KMS key
- Resource policies can be used to share secrets across AWS accounts
- IAM policies created by this module can be attached to IAM roles or users to grant access to secrets
- Secrets Manager charges for each secret stored and for API calls
- Recovery window can be set to 0 to force immediate deletion (not recommended for production)
- For security best practices, rotate secrets regularly using AWS Secrets Manager rotation feature
