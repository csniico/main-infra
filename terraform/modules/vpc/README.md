# AWS VPC Terraform Module

This module provisions an AWS VPC with public and private subnets across multiple availability zones, following AWS best practices.

## Features

- Creates a VPC with configurable CIDR block
- Provisions public and private subnets across multiple availability zones
- Sets up Internet Gateway for public subnets
- Configures NAT Gateways for private subnets (with option for single or multiple NAT Gateways)
- Creates appropriate route tables for both subnet types
- Highly customizable through variables

## Usage

### Basic Usage

```terraform
module "vpc" {
  source = "./terraform/modules/vpc"

  name     = "example"
  vpc_cidr = "10.0.0.0/16"
  region   = "eu-west-1"
  
  tags = {
    Environment = "dev"
    Project     = "example"
  }
}
```

### Advanced Usage

```terraform
module "vpc" {
  source = "./terraform/modules/vpc"

  name                 = "production"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = "10.0.0.0/20"
  private_subnets_cidr = "10.0.16.0/20"
  region               = "eu-west-1"
  az_count             = 3
  single_nat_gateway   = false  # Use one NAT Gateway per AZ for high availability
  subnet_newbits       = 2      # Divide each subnet CIDR into 4 (2^2) equal parts
  
  tags = {
    Environment = "production"
    Project     = "example"
    Terraform   = "true"
  }
}
```

### Cost-Saving Configuration

```terraform
module "vpc" {
  source = "./terraform/modules/vpc"

  name               = "staging"
  vpc_cidr           = "10.0.0.0/16"
  az_count           = 2
  single_nat_gateway = true  # Use a single NAT Gateway for cost savings
  
  tags = {
    Environment = "staging"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name prefix for all resources | string | "main" | no |
| region | AWS region to deploy resources | string | "eu-west-1" | no |
| vpc_cidr | CIDR block for the VPC | string | "10.0.0.0/16" | no |
| public_subnets_cidr | CIDR block for public subnets | string | "10.0.0.0/20" | no |
| private_subnets_cidr | CIDR block for private subnets | string | "10.0.16.0/20" | no |
| az_count | Number of availability zones to use (2-3) | number | 3 | no |
| subnet_newbits | Number of additional bits to extend the subnet CIDR | number | 2 | no |
| single_nat_gateway | Use a single NAT gateway for all private subnets | bool | false | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr | The CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| public_route_table_id | ID of the public route table |
| private_route_table_ids | List of private route table IDs |
| nat_gateway_ids | List of NAT Gateway IDs |
| internet_gateway_id | ID of the Internet Gateway |
| availability_zones | List of availability zones used |

## Prerequisites

- AWS account and credentials configured
- Terraform 0.13 or later
- AWS provider 3.0 or later

## Notes

- NAT Gateways are relatively expensive resources. Using `single_nat_gateway = true` can significantly reduce costs for non-production environments.
- The module automatically selects available availability zones in the specified region.