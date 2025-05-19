data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition

  # Use provided name or generate one
  repository_name = var.name_prefix != null ? "${var.name_prefix}-${var.name}" : var.name

  # Default lifecycle policy if none provided
  default_lifecycle_policy = var.lifecycle_policy == null && var.create_lifecycle_policy ? jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_count_limit} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_count_limit
        }
        action = {
          type = "expire"
        }
      }
    ]
  }) : var.lifecycle_policy

  # Default repository policy if none provided
  default_repository_policy = var.repository_policy == null && var.create_repository_policy ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPull"
        Effect    = "Allow"
        Principal = var.repository_policy_principals
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  }) : var.repository_policy
}
