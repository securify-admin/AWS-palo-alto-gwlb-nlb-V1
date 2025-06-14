output "gwlb_id" {
  description = "ID of the Gateway Load Balancer"
  value       = aws_lb.gwlb.id
}

output "gwlb_arn" {
  description = "ARN of the Gateway Load Balancer"
  value       = aws_lb.gwlb.arn
}

output "target_group_arn" {
  description = "ARN of the GWLB target group"
  value       = aws_lb_target_group.firewall_tg.arn
}

output "gwlb_endpoint_service_id" {
  description = "ID of the GWLB endpoint service"
  value       = aws_vpc_endpoint_service.gwlb_endpoint_service.id
}

output "gwlb_endpoint_service_name" {
  description = "Service name of the GWLB endpoint service"
  value       = aws_vpc_endpoint_service.gwlb_endpoint_service.service_name
}

output "security_vpc_endpoint_ids" {
  description = "IDs of the GWLB endpoints in the Security VPC"
  value       = aws_vpc_endpoint.security_vpc_gwlb_endpoints[*].id
}

output "spoke_vpc_endpoint_ids" {
  description = "IDs of the GWLB endpoints in the Spoke VPCs (empty in centralized model)"
  value       = []
}
