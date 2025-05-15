# AWS ECR Terraform Module

This module provisions AWS Elastic Container Registry (ECR) repositories with support for lifecycle policies, repository policies, image scanning, encryption, and cross-region replication, following AWS best practices and the principle of separation of concerns.

## Features

- Creates ECR repositories with configurable settings
- Supports image tag mutability settings (MUTABLE or IMMUTABLE)
- Configures image scanning on push
- Enables encryption with AWS managed keys or customer managed KMS keys
- Creates lifecycle policies for automated image cleanup
- Sets up repository policies for access control
- Supports cross-region replication
- Highly customizable through variables

## Usage

### Basic Repository

```terraform
module "ecr" {
  source = "./terraform/modules/ecr"

  name = "app"
  
  # Use default settings (mutable tags, scan on push, AES256 encryption)
  
  tags = {
    Environment = "dev"
    Project     = "app"
  }
}
```

### Repository with Immutable Tags and Lifecycle Policy

```terraform
module "ecr" {
  source = "./terraform/modules/ecr"

  name                 = "api-service"
  
  # Repository configuration
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  
  # Lifecycle policy
  create_lifecycle_policy = true
  image_count_limit       = 50  # Keep only the last 50 images
  
  tags = {
    Environment = "production"
    Project     = "api"
  }
}
```

### Repository with Custom Lifecycle Policy

```terraform
module "ecr" {
  source = "./terraform/modules/ecr"

  name = "web-app"
  
  # Repository configuration
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  
  # Custom lifecycle policy
  create_lifecycle_policy = true
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 30 staging images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["staging"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Expire untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### Repository with KMS Encryption and Repository Policy

```terraform
# Create KMS key using the KMS module
module "kms" {
  source = "./terraform/modules/kms"

  # KMS key configuration...
}

module "ecr" {
  source = "./terraform/modules/ecr"

  name = "secure-app"
  
  # Repository configuration
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  
  # Encryption configuration
  encryption_type = "KMS"
  kms_key         = module.kms.key_arn
  
  # Repository policy
  create_repository_policy = true
  repository_policy_principals = {
    AWS = [
      "arn:aws:iam::${local.account_id}:role/developer",
      "arn:aws:iam::${local.account_id}:role/ci-cd"
    ]
  }
  
  tags = {
    Environment = "production"
    Project     = "secure-app"
    Security    = "high"
  }
}
```

### Repository with Cross-Region Replication

```terraform
module "ecr" {
  source = "./terraform/modules/ecr"

  name = "global-app"
  
  # Repository configuration
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  
  # Replication configuration
  enable_replication = true
  replication_destinations = [
    {
      region      = "us-west-2"
      account_id  = "123456789012"
      registry_id = "123456789012"
    },
    {
      region      = "eu-west-1"
      account_id  = "123456789012"
      registry_id = "123456789012"
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "global-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the ECR repository | string | n/a | yes |
| name_prefix | Prefix to add to the repository name | string | null | no |
| create_repository | Controls if the ECR repository should be created | bool | true | no |
| image_tag_mutability | The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE | string | "MUTABLE" | no |
| scan_on_push | Indicates whether images are scanned after being pushed to the repository | bool | true | no |
| encryption_type | The encryption type to use for the repository. Valid values are AES256 or KMS | string | "AES256" | no |
| kms_key | The ARN of the KMS key to use when encryption_type is KMS | string | null | no |
| create_lifecycle_policy | Controls if a lifecycle policy should be created | bool | false | no |
| lifecycle_policy | JSON formatted lifecycle policy text to apply to the repository | string | null | no |
| image_count_limit | The maximum number of images to keep in the repository (used in default lifecycle policy) | number | 100 | no |
| create_repository_policy | Controls if a repository policy should be created | bool | false | no |
| repository_policy | JSON formatted repository policy text to apply to the repository | string | null | no |
| repository_policy_principals | Map of principal objects for repository policy (used in default repository policy) | any | { AWS = "*" } | no |
| enable_replication | Controls if cross-region replication should be enabled | bool | false | no |
| replication_destinations | List of AWS account IDs and regions to replicate the repository to | list(object) | [] | no |
| tags | A mapping of tags to assign to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_id | The ID of the ECR repository |
| repository_arn | The ARN of the ECR repository |
| repository_name | The name of the ECR repository |
| repository_url | The URL of the ECR repository |
| repository_registry_id | The registry ID where the repository was created |
| repository_policy_id | The ID of the ECR repository policy |
| lifecycle_policy_id | The ID of the ECR lifecycle policy |
| replication_configuration_id | The ID of the ECR replication configuration |

## Prerequisites

- AWS account and credentials configured
- Terraform 0.13 or later
- AWS provider 3.0 or later
- KMS key (optional, for KMS encryption)

## Best Practices

- **Image Tag Immutability**: For production repositories, consider using IMMUTABLE tag settings to prevent tags from being overwritten, which improves security and traceability.
- **Image Scanning**: Always enable scan_on_push for security vulnerability detection.
- **Lifecycle Policies**: Implement lifecycle policies to automatically clean up unused images and reduce storage costs.
- **Repository Policies**: Use repository policies to control access to your repositories, following the principle of least privilege.
- **Encryption**: For sensitive container images, use KMS encryption with customer managed keys.
- **Cross-Region Replication**: For critical applications, enable cross-region replication for disaster recovery.
- **Tagging**: Apply consistent tags to repositories for better resource organization and cost allocation.
- **CI/CD Integration**: Use the repository URL output in your CI/CD pipelines for automated image pushing.

## Notes

- This module follows the principle of separation of concerns by focusing only on ECR resources
- For KMS encryption, you can use a dedicated KMS module to create and manage the keys
- Repository policies should be carefully crafted to avoid unintended access
- Cross-region replication requires appropriate IAM permissions across accounts
- Consider the cost implications of storing large numbers of container images
