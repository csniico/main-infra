# EBS Volume
resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  size              = var.size
  type              = var.type

  # IOPS - only set for supported volume types
  iops = local.use_iops ? (var.iops != null ? var.iops : local.default_iops[var.type]) : null

  # Throughput - only set for gp3 volumes
  throughput = local.use_throughput ? (var.throughput != null ? var.throughput : local.default_throughput[var.type]) : null

  # Multi-attach - only supported for io1 and io2 volumes
  multi_attach_enabled = var.multi_attach_enabled && contains(["io1", "io2"], var.type) ? true : false

  # Encryption
  encrypted  = var.encrypted
  kms_key_id = var.encrypted ? var.kms_key_id : null

  # Snapshot
  snapshot_id = var.snapshot_id

  # Final snapshot
  final_snapshot = var.final_snapshot

  tags = merge(
    var.tags,
    {
      Name = local.volume_name
    }
  )
}

# Volume Attachment (optional)
resource "aws_volume_attachment" "this" {
  count = var.attach_volume && var.instance_id != null ? 1 : 0

  device_name                    = var.device_name
  volume_id                      = aws_ebs_volume.this.id
  instance_id                    = var.instance_id
  skip_destroy                   = var.skip_destroy
  stop_instance_before_detaching = var.stop_instance_before_detaching
}
