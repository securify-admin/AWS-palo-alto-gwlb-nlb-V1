output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = aws_subnet.subnets[*].id
}

output "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  value       = aws_subnet.subnets[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table, if created"
  value       = var.create_private_rt ? aws_route_table.private_rt[0].id : null
}

output "custom_route_table_ids" {
  description = "Map of custom route table IDs"
  value       = { for k, v in aws_route_table.custom_rt : k => v.id }
}
