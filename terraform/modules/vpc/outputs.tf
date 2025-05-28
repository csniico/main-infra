output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = contains(var.create_subnet_types, "public") ? aws_subnet.public[*].id : []
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = contains(var.create_subnet_types, "private") ? aws_subnet.private[*].id : []
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = contains(var.create_subnet_types, "public") ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = contains(var.create_subnet_types, "private") ? aws_route_table.private[*].id : []
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = var.enable_nat_gateway && contains(var.create_subnet_types, "private") && contains(var.create_subnet_types, "public") ? aws_nat_gateway.this[*].id : []
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}