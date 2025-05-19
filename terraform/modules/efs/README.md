# AWS EFS (Elastic File System) Terraform Module

This module provisions AWS Elastic File System (EFS) resources with mount targets, access points, and security groups, following AWS best practices and the principle of separation of concerns.

## Features

- Creates EFS file systems with configurable settings
- Supports all performance modes (generalPurpose, maxIO)
- Supports all throughput modes (bursting, provisioned, elastic)
- Enables encryption with AWS managed or customer managed KMS keys
- Creates mount targets in specified subnets
- Creates access points with custom settings
- Utilizes security groups for mount targets
- Supports replication to another region
- Supports lifecycle policies for infrequent access (IA) storage class
- Supports file system replication
- Supports automatic backups
- Highly customizable through variables

## Usage

### Basic Usage

```terraform
module "efs" {
  source = "./terraform/modules/efs"

  name       = "app-data"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Security groups for mount targets
  security_group_ids = [module.efs_sg.security_group_id]
  
  tags = {
    Environment = "dev"
    Project     = "app"
  }
}
```

### Advanced Usage with Custom Configuration

```terraform
module "efs" {
  source = "./terraform/modules/efs"

  name       = "db-data"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Performance settings
  performance_mode                = "maxIO"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 256
  
  # Encryption with custom KMS key
  encrypted  = true
  kms_key_id = module.kms.key_arn
  
  # Lifecycle policy
  transition_to_ia = "AFTER_30_DAYS"
  
  # Security groups for mount targets
  security_group_ids = [module.efs_sg.security_group_id]
  
  # Create access points
  access_points = [
    {
      name                = "app1"
      root_directory_path = "/app1"
      owner_uid           = 1000
      owner_gid           = 1000
      permissions         = "0755"
      posix_user_uid      = 1000
      posix_user_gid      = 1000
    },
    {
      name                = "app2"
      root_directory_path = "/app2"
      owner_uid           = 1001
      owner_gid           = 1001
      permissions         = "0755"
      posix_user_uid      = 1001
      posix_user_gid      = 1001
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "database"
  }
}
```

### With Replication to Another Region

```terraform
module "efs" {
  source = "./terraform/modules/efs"

  name       = "critical-data"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Enable replication
  enable_replication              = true
  replication_destination_region  = "us-west-2"
  
  tags = {
    Environment = "production"
    Project     = "critical"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the EFS file system | `string` | n/a | yes |
| name_prefix | Prefix to add to the EFS file system name | `string` | `null` | no |
| vpc_id | ID of the VPC where the EFS file system will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where mount targets will be created | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs to attach to the mount targets | `list(string)` | `[]` | no |
| performance_mode | The file system performance mode. Can be 'generalPurpose' or 'maxIO' | `string` | `"generalPurpose"` | no |
| throughput_mode | Throughput mode for the file system. Can be 'bursting', 'provisioned', or 'elastic' | `string` | `"bursting"` | no |
| provisioned_throughput_in_mibps | The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to 'provisioned' | `number` | `null` | no |
| encrypted | If true, the file system will be encrypted | `bool` | `true` | no |
| kms_key_id | The ARN of the KMS Key to use when encrypting the file system | `string` | `null` | no |
| transition_to_ia | Describes the period of time that a file is not accessed, after which it transitions to IA storage. Can be AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS | `string` | `null` | no |
| transition_to_primary_storage_class | Describes the period of time that a file is not accessed, after which it transitions back to primary storage. Can be AFTER_1_ACCESS | `string` | `null` | no |
| enable_protection | Whether to enable protection for the file system | `bool` | `false` | no |
| enable_backup | Whether to enable automatic backups | `bool` | `true` | no |
| access_points | List of access points to create | `list(object)` | `[]` | no |
| enable_replication | Whether to enable replication for the file system | `bool` | `false` | no |
| replication_destination_region | The AWS Region to replicate the file system to | `string` | `null` | no |
| replication_destination_kms_key_id | The ARN of the KMS Key to use when encrypting the replicated file system | `string` | `null` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| file_system_id | The ID of the EFS file system |
| file_system_arn | The ARN of the EFS file system |
| file_system_dns_name | The DNS name of the EFS file system |
| file_system_size_in_bytes | The latest known metered size (in bytes) of data stored in the file system |
| file_system_performance_mode | The performance mode of the EFS file system |
| file_system_throughput_mode | The throughput mode of the EFS file system |
| file_system_provisioned_throughput_in_mibps | The provisioned throughput of the EFS file system in MiB/s |
| file_system_encrypted | Whether the EFS file system is encrypted |
| file_system_kms_key_id | The ARN of the KMS Key used to encrypt the EFS file system |
| file_system_tags | The tags of the EFS file system |
| mount_target_ids | The IDs of the mount targets |
| mount_target_dns_names | The DNS names of the mount targets |
| mount_target_network_interface_ids | The IDs of the network interfaces created for the mount targets |
| access_point_ids | Map of access point IDs, keyed by tag AccessPoint |
| access_point_arns | Map of access point ARNs, keyed by tag AccessPoint |
| access_points | Map of access points created and their attributes, keyed by tag AccessPoint |
| replication_configuration_destination_file_system_id | The file system ID of the replica |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later
- VPC with subnets
- IAM permissions to create EFS resources

## Notes

- EFS mount targets are created in each specified subnet
- NFS port 2049 is used for EFS access
- EFS file systems can be mounted on Linux-based instances only
- For cross-AZ data transfer, standard AWS data transfer charges apply
- Provisioned throughput incurs additional costs
- Replication creates a new EFS file system in the destination region
- Access points provide application-specific entry points to the EFS file system
- Lifecycle policies can be used to transition files to infrequent access storage class to reduce costs
