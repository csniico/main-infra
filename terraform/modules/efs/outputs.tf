# File System Outputs
output "file_system_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "The ARN of the EFS file system"
  value       = aws_efs_file_system.this.arn
}

output "file_system_dns_name" {
  description = "The DNS name of the EFS file system"
  value       = "${aws_efs_file_system.this.id}.efs.${local.region}.amazonaws.com"
}

output "file_system_size_in_bytes" {
  description = "The latest known metered size (in bytes) of data stored in the file system"
  value       = aws_efs_file_system.this.size_in_bytes
}

output "file_system_performance_mode" {
  description = "The performance mode of the EFS file system"
  value       = aws_efs_file_system.this.performance_mode
}

output "file_system_throughput_mode" {
  description = "The throughput mode of the EFS file system"
  value       = aws_efs_file_system.this.throughput_mode
}

output "file_system_provisioned_throughput_in_mibps" {
  description = "The provisioned throughput of the EFS file system in MiB/s"
  value       = aws_efs_file_system.this.provisioned_throughput_in_mibps
}

output "file_system_encrypted" {
  description = "Whether the EFS file system is encrypted"
  value       = aws_efs_file_system.this.encrypted
}

output "file_system_kms_key_id" {
  description = "The ARN of the KMS Key used to encrypt the EFS file system"
  value       = aws_efs_file_system.this.kms_key_id
}

output "file_system_tags" {
  description = "The tags of the EFS file system"
  value       = aws_efs_file_system.this.tags
}

# Mount Target Outputs
output "mount_target_ids" {
  description = "The IDs of the mount targets"
  value       = aws_efs_mount_target.this[*].id
}

output "mount_target_dns_names" {
  description = "The DNS names of the mount targets"
  value       = [for mt in aws_efs_mount_target.this : "${aws_efs_file_system.this.id}.efs.${local.region}.amazonaws.com:${mt.subnet_id}"]
}

output "mount_target_network_interface_ids" {
  description = "The IDs of the network interfaces created for the mount targets"
  value       = aws_efs_mount_target.this[*].network_interface_id
}

# Access Point Outputs
output "access_point_ids" {
  description = "The IDs of the access points"
  value       = [for ap in aws_efs_access_point.this : ap.id]
}

output "access_point_arns" {
  description = "The ARNs of the access points"
  value       = [for ap in aws_efs_access_point.this : ap.arn]
}

output "access_points" {
  description = "Map of access points created and their attributes"
  value       = { for k, v in aws_efs_access_point.this : k => {
    id              = v.id
    arn             = v.arn
    file_system_id  = v.file_system_id
    posix_user      = v.posix_user
    root_directory  = v.root_directory
  }}
}

# Replication Outputs
output "replication_configuration_destination_file_system_id" {
  description = "The file system ID of the replica"
  value       = var.enable_replication && var.replication_destination_region != null ? try(aws_efs_replication_configuration.this[0].destination[0].file_system_id, null) : null
}
