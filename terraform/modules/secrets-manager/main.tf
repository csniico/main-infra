# AWS Secrets Manager
resource "aws_secretsmanager_secret" "this" {
  count = var.create_secret ? 1 : 0

  name                    = var.name
  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days
  force_overwrite_replica_secret = var.force_overwrite_replica_secret

  # Replica configuration
  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region     = replica.value.region
      kms_key_id = lookup(replica.value, "kms_key_id", null)
    }
  }

  tags = var.tags
}

# AWS Secrets Manager Secret Version (if secret value is provided)
resource "aws_secretsmanager_secret_version" "this" {
  count = var.create_secret && var.secret_string != null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this[0].id
  secret_string = var.secret_string
  
  # Only create new version if secret value has changed
  version_stages = ["AWSCURRENT"]
}

# AWS Secrets Manager Secret Version with JSON (if secret map is provided)
resource "aws_secretsmanager_secret_version" "json" {
  count = var.create_secret && var.secret_string == null && var.secret_key_value != null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this[0].id
  secret_string = jsonencode(var.secret_key_value)
  
  # Only create new version if secret value has changed
  version_stages = ["AWSCURRENT"]
}

# Multiple AWS Secrets Manager Secrets
resource "aws_secretsmanager_secret" "multiple" {
  for_each = var.create_secret ? {} : var.secrets

  name                    = each.key
  description             = lookup(each.value, "description", null)
  kms_key_id              = lookup(each.value, "kms_key_id", null)
  recovery_window_in_days = lookup(each.value, "recovery_window_in_days", var.recovery_window_in_days)
  force_overwrite_replica_secret = lookup(each.value, "force_overwrite_replica_secret", var.force_overwrite_replica_secret)

  # Replica configuration
  dynamic "replica" {
    for_each = lookup(each.value, "replica_regions", [])
    content {
      region     = replica.value.region
      kms_key_id = lookup(replica.value, "kms_key_id", null)
    }
  }

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {})
  )
}

# AWS Secrets Manager Secret Versions for multiple secrets
resource "aws_secretsmanager_secret_version" "multiple" {
  for_each = { 
    for k, v in var.secrets : k => v 
    if !var.create_secret && lookup(v, "secret_string", null) != null 
  }

  secret_id     = aws_secretsmanager_secret.multiple[each.key].id
  secret_string = each.value.secret_string
  
  # Only create new version if secret value has changed
  version_stages = ["AWSCURRENT"]
}

# AWS Secrets Manager Secret Versions with JSON for multiple secrets
resource "aws_secretsmanager_secret_version" "multiple_json" {
  for_each = { 
    for k, v in var.secrets : k => v 
    if !var.create_secret && lookup(v, "secret_string", null) == null && lookup(v, "secret_key_value", null) != null 
  }

  secret_id     = aws_secretsmanager_secret.multiple[each.key].id
  secret_string = jsonencode(each.value.secret_key_value)
  
  # Only create new version if secret value has changed
  version_stages = ["AWSCURRENT"]
}
