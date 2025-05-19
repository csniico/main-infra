# AWS EBS (Elastic Block Storage) Terraform Module

This module provisions AWS Elastic Block Storage (EBS) volumes with optional attachment to EC2 instances, following AWS best practices and the principle of separation of concerns.

## Features

- Creates EBS volumes with configurable settings
- Supports all EBS volume types (gp2, gp3, io1, io2, sc1, st1, standard)
- Configures IOPS and throughput for supported volume types
- Enables encryption with AWS managed or customer managed KMS keys
- Supports creating volumes from snapshots
- Provides optional volume attachment to EC2 instances
- Highly customizable through variables

## Usage

### Basic Usage

```terraform
module "ebs" {
  source = "./terraform/modules/ebs"

  name              = "app-data"
  availability_zone = "us-west-2a"
  
  # Volume configuration
  size              = 50
  type              = "gp3"
  
  # Use default encryption settings
  encrypted         = true
  
  tags = {
    Environment = "dev"
    Project     = "app"
  }
}
```

### Advanced Usage with Custom Configuration

```terraform
module "ebs" {
  source = "./terraform/modules/ebs"

  name              = "db-data"
  availability_zone = "us-west-2a"
  
  # Volume configuration
  size              = 100
  type              = "io1"
  iops              = 3000
  
  # Encryption with custom KMS key
  encrypted         = true
  kms_key_id        = module.kms.key_arn
  
  tags = {
    Environment = "production"
    Project     = "database"
  }
}
```

### Creating Volume from Snapshot

```terraform
module "ebs" {
  source = "./terraform/modules/ebs"

  name              = "restored-volume"
  availability_zone = "us-west-2a"
  
  # Create from snapshot
  snapshot_id       = "snap-0abc123def456789"
  
  # Volume configuration
  type              = "gp3"
  
  tags = {
    Environment = "staging"
    Project     = "restore-test"
  }
}
```

### Attaching Volume to EC2 Instance

```terraform
# Create EC2 instance using the EC2 module
module "ec2" {
  source = "./terraform/modules/ec2"

  # EC2 instance configuration...
}

# Create and attach EBS volume
module "ebs" {
  source = "./terraform/modules/ebs"

  name              = "app-data"
  availability_zone = module.ec2.instance_az
  
  # Volume configuration
  size              = 50
  type              = "gp3"
  
  # Attachment configuration
  attach_volume     = true
  instance_id       = module.ec2.instance_id
  device_name       = "/dev/sdh"
  
  tags = {
    Environment = "dev"
    Project     = "app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the EBS volume | `string` | n/a | yes |
| name_prefix | Prefix to add to the EBS volume name | `string` | `null` | no |
| size | Size of the EBS volume in gigabytes | `number` | `20` | no |
| type | Type of EBS volume. Can be 'standard', 'gp2', 'gp3', 'io1', 'io2', 'sc1', or 'st1' | `string` | `"gp3"` | no |
| iops | Amount of IOPS to provision for the disk. Only valid for 'io1', 'io2', and 'gp3' types | `number` | `null` | no |
| throughput | Throughput to provision for a volume in MiB/s. Only valid for 'gp3' type | `number` | `null` | no |
| multi_attach_enabled | Specifies whether to enable Amazon EBS Multi-Attach. Multi-Attach is supported on io1 and io2 volumes | `bool` | `false` | no |
| encrypted | If true, the disk will be encrypted | `bool` | `true` | no |
| kms_key_id | The ARN of the KMS Key to use when encrypting the volume | `string` | `null` | no |
| snapshot_id | The Snapshot ID to create the volume from | `string` | `null` | no |
| availability_zone | The AZ where the EBS volume will exist | `string` | n/a | yes |
| attach_volume | Whether to attach the volume to an EC2 instance | `bool` | `false` | no |
| instance_id | ID of the Instance to attach to | `string` | `null` | no |
| device_name | The device name to expose to the instance (e.g., /dev/sdh or xvdh) | `string` | `"/dev/xvdf"` | no |
| skip_destroy | Set this to true if you want to keep the volume when destroying the instance | `bool` | `false` | no |
| stop_instance_before_detaching | Whether the instance should be stopped before detaching the volume | `bool` | `false` | no |
| final_snapshot | Whether to create a final snapshot before the volume is deleted | `bool` | `false` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| volume_id | The ID of the EBS volume |
| volume_arn | The ARN of the EBS volume |
| volume_size | The size of the EBS volume in gigabytes |
| volume_type | The type of the EBS volume |
| volume_iops | The provisioned IOPS of the EBS volume |
| volume_throughput | The throughput of the EBS volume in MiB/s |
| volume_encrypted | Whether the EBS volume is encrypted |
| volume_kms_key_id | The ARN of the KMS Key used to encrypt the EBS volume |
| volume_snapshot_id | The snapshot ID the EBS volume was created from |
| volume_availability_zone | The availability zone of the EBS volume |
| volume_tags | The tags of the EBS volume |
| attachment_id | The ID of the volume attachment |
| attachment_instance_id | The ID of the instance the volume is attached to |
| attachment_device_name | The device name the volume is attached as |

## Prerequisites

- AWS account and credentials configured
- Terraform 0.13 or later
- AWS provider 3.0 or later
- EC2 instance (if attaching the volume)
- KMS key (if using custom encryption)

## Notes

- EBS volumes are AZ-specific resources and cannot be attached to instances in different AZs
- For io1, io2, and gp3 volumes, you can specify IOPS
- For gp3 volumes, you can specify throughput
- Multi-attach is only supported for io1 and io2 volumes
- When creating a volume from a snapshot, the size must be equal to or greater than the snapshot size
- When attaching a volume, the EC2 instance must be in the same AZ as the volume
