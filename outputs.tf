output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Sorted Availability Zones used by the module."
  value       = local.availability_zones
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs ordered by availability_zones."
  value       = [for az in local.availability_zones : aws_subnet.public[az].id]
}

output "public_subnet_ids_by_az" {
  description = "Public subnet IDs keyed by Availability Zone."
  value       = { for az in local.availability_zones : az => aws_subnet.public[az].id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs ordered by availability_zones."
  value       = [for az in local.availability_zones : aws_subnet.private[az].id]
}

output "private_subnet_ids_by_az" {
  description = "Private subnet IDs keyed by Availability Zone."
  value       = { for az in local.availability_zones : az => aws_subnet.private[az].id }
}

output "database_subnet_ids" {
  description = "Database subnet IDs ordered by availability_zones."
  value       = [for az in local.availability_zones : aws_subnet.database[az].id]
}

output "database_subnet_ids_by_az" {
  description = "Database subnet IDs keyed by Availability Zone."
  value       = { for az in local.availability_zones : az => aws_subnet.database[az].id }
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids_by_az" {
  description = "Private route table IDs keyed by Availability Zone."
  value       = { for az in local.availability_zones : az => aws_route_table.private[az].id }
}

output "database_route_table_ids_by_az" {
  description = "Database route table IDs keyed by Availability Zone."
  value       = { for az in local.availability_zones : az => aws_route_table.database[az].id }
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs ordered by Availability Zone. Empty when nat_gateway_mode is none."
  value       = [for az in sort(tolist(local.nat_gateway_azs)) : aws_nat_gateway.this[az].id]
}

output "nat_gateway_ids_by_az" {
  description = "NAT gateway IDs keyed by the Availability Zone hosting each gateway."
  value       = { for az in sort(tolist(local.nat_gateway_azs)) : az => aws_nat_gateway.this[az].id }
}

output "private_nat_gateway_ids_by_az" {
  description = "NAT gateway used by each private subnet AZ. Empty when nat_gateway_mode is none."
  value = {
    for private_az, nat_az in local.private_nat_gateway_az_by_az :
    private_az => aws_nat_gateway.this[nat_az].id
  }
}

output "nat_eip_public_ips" {
  description = "Public Elastic IP addresses used by the NAT gateways."
  value       = [for az in sort(tolist(local.nat_gateway_azs)) : aws_eip.nat[az].public_ip]
}

output "database_subnet_group_name" {
  description = "RDS DB subnet group name, or null when creation is disabled."
  value       = try(aws_db_subnet_group.this[0].name, null)
}

output "default_security_group_id" {
  description = "Managed default security group ID, or null when management is disabled."
  value       = try(aws_default_security_group.this[0].id, null)
}

output "flow_log_id" {
  description = "VPC Flow Log ID, or null when flow logs are disabled."
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_group_arn" {
  description = "CloudWatch VPC Flow Logs log group ARN, or null when flow logs are disabled."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}
