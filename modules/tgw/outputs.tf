output "tgw_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.tgw.id
}

output "security_vpc_attachment_id" {
  description = "ID of the Security VPC attachment to the Transit Gateway"
  value       = aws_ec2_transit_gateway_vpc_attachment.security_vpc_attachment.id
}

output "spoke_vpc_attachment_ids" {
  description = "IDs of the Spoke VPC attachments to the Transit Gateway"
  value       = aws_ec2_transit_gateway_vpc_attachment.spoke_vpc_attachments[*].id
}

output "spokes_route_table_id" {
  description = "ID of the Spokes route table in the Transit Gateway"
  value       = aws_ec2_transit_gateway_route_table.spokes_rt.id
}

output "security_route_table_id" {
  description = "ID of the Security route table in the Transit Gateway"
  value       = aws_ec2_transit_gateway_route_table.security_rt.id
}
