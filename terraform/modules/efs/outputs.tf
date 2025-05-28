# File System Outputs
output "file_system_id" {
  description = "The ID of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].id : null
}

output "file_system_arn" {
  description = "The ARN of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].arn : null
}

output "file_system_dns_name" {
  description = "The DNS name of the EFS file system"
  value       = var.create_file_system ? "${aws_efs_file_system.this[0].id}.efs.${local.region}.amazonaws.com" : null
}

output "file_system_size_in_bytes" {
  description = "The latest known metered size (in bytes) of data stored in the file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].size_in_bytes : null
}

output "file_system_performance_mode" {
  description = "The performance mode of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].performance_mode : null
}

output "file_system_throughput_mode" {
  description = "The throughput mode of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].throughput_mode : null
}

output "file_system_provisioned_throughput_in_mibps" {
  description = "The provisioned throughput of the EFS file system in MiB/s"
  value       = var.create_file_system ? aws_efs_file_system.this[0].provisioned_throughput_in_mibps : null
}

output "file_system_encrypted" {
  description = "Whether the EFS file system is encrypted"
  value       = var.create_file_system ? aws_efs_file_system.this[0].encrypted : null
}

output "file_system_kms_key_id" {
  description = "The ARN of the KMS Key used to encrypt the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].kms_key_id : null
}

output "file_system_tags" {
  description = "The tags of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].tags : null
}

# Mount Target Outputs
output "mount_target_ids" {
  description = "The IDs of the mount targets"
  value       = var.create_mount_targets ? aws_efs_mount_target.this[*].id : null
}

output "mount_target_dns_names" {
  description = "The DNS names of the mount targets"
  value = (var.create_mount_targets && var.create_file_system) ? [for mt in aws_efs_mount_target.this[*] : "${aws_efs_file_system.this[0].id}.efs.${local.region}.amazonaws.com:${mt.subnet_id}"] : null
}

output "mount_target_network_interface_ids" {
  description = "The IDs of the network interfaces created for the mount targets"
  value       = var.create_mount_targets ? aws_efs_mount_target.this[*].network_interface_id : null
}

# Access Point Outputs
output "access_point_ids" {
  description = "IDs of the access points"
  value       = var.create_access_points ? { for k, ap in aws_efs_access_point.this : k => ap.id } : null
}

output "access_point_arns" {
  description = "ARNs of the access points"
  value       = var.create_access_points ? { for k, ap in aws_efs_access_point.this : k => ap.arn } : null
}

output "access_points" {
  description = "Map of access points created and their attributes"
  value       = var.create_access_points ? { for k, ap in aws_efs_access_point.this : k => {
    id              = ap.id
    arn             = ap.arn
    file_system_id  = ap.file_system_id
    posix_user      = ap.posix_user
    root_directory  = ap.root_directory
  }} : null
}

# Replication Outputs
output "replication_configuration_destination_file_system_id" {
  description = "The file system ID of the replica"
  value       = var.enable_replication && var.replication_destination_region != null ? try(aws_efs_replication_configuration.this[0].destination[0].file_system_id, null) : null
}
