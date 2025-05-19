# EFS File System
resource "aws_efs_file_system" "this" {
  creation_token = local.creation_token

  # Performance settings
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  # Encryption settings
  encrypted  = var.encrypted
  kms_key_id = var.encrypted && var.kms_key_id != null ? var.kms_key_id : null

  # Lifecycle policy
  dynamic "lifecycle_policy" {
    for_each = var.transition_to_ia != null ? [1] : []
    content {
      transition_to_ia = var.transition_to_ia
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.transition_to_primary_storage_class != null ? [1] : []
    content {
      transition_to_primary_storage_class = var.transition_to_primary_storage_class
    }
  }

  # File system protection
  dynamic "lifecycle_policy" {
    for_each = var.enable_protection ? [1] : []
    content {
      transition_to_primary_storage_class = "AFTER_1_DAY"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = local.file_system_name
    }
  )
}

# EFS Backup Policy
resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids
}

# EFS Access Points (optional)
resource "aws_efs_access_point" "this" {
  for_each = { for ap in var.access_points : ap.name => ap }

  file_system_id = aws_efs_file_system.this.id

  # Root directory
  root_directory {
    path = lookup(each.value, "root_directory_path", "/")

    dynamic "creation_info" {
      for_each = lookup(each.value, "owner_uid", null) != null && lookup(each.value, "owner_gid", null) != null ? [1] : []
      content {
        owner_uid   = lookup(each.value, "owner_uid", 0)
        owner_gid   = lookup(each.value, "owner_gid", 0)
        permissions = lookup(each.value, "permissions", "0755")
      }
    }
  }

  # POSIX user
  dynamic "posix_user" {
    for_each = lookup(each.value, "posix_user_uid", null) != null && lookup(each.value, "posix_user_gid", null) != null ? [1] : []
    content {
      uid            = lookup(each.value, "posix_user_uid", 0)
      gid            = lookup(each.value, "posix_user_gid", 0)
      secondary_gids = lookup(each.value, "posix_user_secondary_gids", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.file_system_name}-ap-${each.value.name}",
      AccessPoint = each.value.name
    }
  )
}

# EFS Replication Configuration (optional)
resource "aws_efs_replication_configuration" "this" {
  count = var.enable_replication && var.replication_destination_region != null ? 1 : 0

  source_file_system_id = aws_efs_file_system.this.id

  destination {
    region     = var.replication_destination_region
    kms_key_id = var.replication_destination_kms_key_id
  }
}
