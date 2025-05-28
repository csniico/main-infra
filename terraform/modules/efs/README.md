# AWS EFS (Elastic File System) Terraform Module

This module provisions AWS Elastic File System (EFS) resources with mount targets, access points, and security groups, following AWS best practices and the principle of separation of concerns. The module provides flexible configuration options for creating new EFS file systems or extending existing ones with additional mount targets and access points.

## Features

- Creates EFS file systems with configurable settings
- Supports all performance modes (generalPurpose, maxIO)
- Supports all throughput modes (bursting, provisioned, elastic)
- Enables encryption with AWS managed or customer managed KMS keys
- Creates mount targets in specified subnets across multiple AZs
- Creates access points with custom POSIX user/group settings
- Supports security group attachment for network access control
- Supports replication to another AWS region for disaster recovery
- Supports lifecycle policies for infrequent access (IA) storage class transitions
- Supports automatic backups with configurable policies
- Flexible creation flags to create only required resources
- Highly customizable through variables with sensible defaults
- Generation of unique creation tokens to avoid conflicts

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

### Using Existing File System (Mount Targets and Access Points Only)

```terraform
module "efs_additional_access" {
  source = "./terraform/modules/efs"

  # Don't create a new file system, use existing one
  create_file_system    = false
  source_file_system_id = "fs-0123456789abcdef0"
  
  # Create mount targets in different subnets
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.additional_subnet_ids
  
  # Create additional access points
  access_points = [
    {
      name                = "logs"
      root_directory_path = "/logs"
      owner_uid           = 1002
      owner_gid           = 1002
      permissions         = "0755"
      posix_user_uid      = 1002
      posix_user_gid      = 1002
    }
  ]
  
  tags = {
    Environment = "production"
    Project     = "additional-access"
  }
}
```

### Minimal Configuration

```terraform
module "efs_minimal" {
  source = "./terraform/modules/efs"

  name       = "simple-storage"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  tags = {
    Environment = "dev"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the EFS file system | `string` | `null` | no |
| name_prefix | Prefix to add to the EFS file system name | `string` | `null` | no |
| create_file_system | Whether to create an EFS file system | `bool` | `true` | no |
| create_mount_targets | Whether to create mount targets for the EFS file system | `bool` | `true` | no |
| create_access_points | Whether to create access points for the EFS file system | `bool` | `true` | no |
| vpc_id | ID of the VPC where the EFS file system will be created | `string` | `null` | no |
| subnet_ids | List of subnet IDs where mount targets will be created | `list(string)` | `null` | no |
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
| source_file_system_id | The ID of the source file system to replicate. If not provided, the source file system will be the one created by this module | `string` | `null` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

### Access Points Object Structure

The `access_points` variable accepts a list of objects with the following structure:

```hcl
access_points = [
  {
    name                      = string                 # Required: Name of the access point
    root_directory_path       = optional(string, "/") # Optional: Root directory path (default: "/")
    owner_uid                 = optional(number)      # Optional: Owner user ID
    owner_gid                 = optional(number)      # Optional: Owner group ID
    permissions               = optional(string, "0755") # Optional: Directory permissions (default: "0755")
    posix_user_uid            = optional(number)      # Optional: POSIX user ID
    posix_user_gid            = optional(number)      # Optional: POSIX group ID
    posix_user_secondary_gids = optional(list(number)) # Optional: Secondary group IDs
  }
]
```

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
| access_point_ids | IDs of the access points |
| access_point_arns | ARNs of the access points |
| access_points | Map of access points created and their attributes |
| replication_configuration_destination_file_system_id | The file system ID of the replica |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later
- Random provider 3.5.1 or later
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

## Security Considerations

- Security groups must allow NFS traffic (port 2049) from EC2 instances
- Use VPC endpoint for EFS if instances are in private subnets without internet access
- Enable encryption for sensitive data
- Consider using IAM policies for access control in addition to POSIX permissions
- Access points provide an additional layer of access control

## Best Practices

- Use multiple availability zones for high availability
- Enable automatic backups for data protection
- Use appropriate performance mode based on your use case:
  - `generalPurpose`: Lower latency per operation, up to 7,000 file operations per second
  - `maxIO`: Higher levels of aggregate throughput and operations per second (over 7,000)
- Choose throughput mode based on requirements:
  - `bursting`: Throughput scales with file system size
  - `provisioned`: Specify throughput independent of storage size
  - `elastic`: Automatically scales throughput up or down based on workload
- Use lifecycle policies to automatically move files to Infrequent Access storage class
- Monitor file system performance using CloudWatch metrics

## Common Issues and Troubleshooting

- **Mount timeouts**: Check security group rules and NFS port 2049 accessibility
- **Permission denied**: Verify POSIX user/group settings in access points
- **Performance issues**: Consider switching from `generalPurpose` to `maxIO` performance mode
- **High costs**: Implement lifecycle policies to move infrequently accessed files to IA storage class
