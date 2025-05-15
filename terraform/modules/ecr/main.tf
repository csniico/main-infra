# ECR Repository
resource "aws_ecr_repository" "this" {
  count = var.create_repository ? 1 : 0
  
  name                 = local.repository_name
  image_tag_mutability = var.image_tag_mutability
  
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
  
  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key : null
  }
  
  tags = merge(
    var.tags,
    {
      Name = local.repository_name
    }
  )
}

# ECR Repository Policy
resource "aws_ecr_repository_policy" "this" {
  count = var.create_repository && var.create_repository_policy ? 1 : 0
  
  repository = aws_ecr_repository.this[0].name
  policy     = local.default_repository_policy
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "this" {
  count = var.create_repository && var.create_lifecycle_policy ? 1 : 0
  
  repository = aws_ecr_repository.this[0].name
  policy     = local.default_lifecycle_policy
}

# ECR Replication Configuration
resource "aws_ecr_replication_configuration" "this" {
  count = var.create_repository && var.enable_replication && length(var.replication_destinations) > 0 ? 1 : 0
  
  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = var.replication_destinations
        content {
          region      = destination.value.region
          registry_id = destination.value.registry_id
        }
      }
    }
  }
}
