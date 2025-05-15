# Volume Outputs
output "volume_id" {
  description = "The ID of the EBS volume"
  value       = aws_ebs_volume.this.id
}

output "volume_arn" {
  description = "The ARN of the EBS volume"
  value       = aws_ebs_volume.this.arn
}

output "volume_size" {
  description = "The size of the EBS volume in gigabytes"
  value       = aws_ebs_volume.this.size
}

output "volume_type" {
  description = "The type of the EBS volume"
  value       = aws_ebs_volume.this.type
}

output "volume_iops" {
  description = "The provisioned IOPS of the EBS volume"
  value       = aws_ebs_volume.this.iops
}

output "volume_throughput" {
  description = "The throughput of the EBS volume in MiB/s"
  value       = aws_ebs_volume.this.throughput
}

output "volume_encrypted" {
  description = "Whether the EBS volume is encrypted"
  value       = aws_ebs_volume.this.encrypted
}

output "volume_kms_key_id" {
  description = "The ARN of the KMS Key used to encrypt the EBS volume"
  value       = aws_ebs_volume.this.kms_key_id
}

output "volume_snapshot_id" {
  description = "The snapshot ID the EBS volume was created from"
  value       = aws_ebs_volume.this.snapshot_id
}

output "volume_availability_zone" {
  description = "The availability zone of the EBS volume"
  value       = aws_ebs_volume.this.availability_zone
}

output "volume_tags" {
  description = "The tags of the EBS volume"
  value       = aws_ebs_volume.this.tags
}

# Attachment Outputs
output "attachment_id" {
  description = "The ID of the volume attachment"
  value       = var.attach_volume && var.instance_id != null ? aws_volume_attachment.this[0].id : null
}

output "attachment_instance_id" {
  description = "The ID of the instance the volume is attached to"
  value       = var.attach_volume && var.instance_id != null ? aws_volume_attachment.this[0].instance_id : null
}

output "attachment_device_name" {
  description = "The device name the volume is attached as"
  value       = var.attach_volume && var.instance_id != null ? aws_volume_attachment.this[0].device_name : null
}
