output "nlb_arn" {
  description = "ARN of the internal Network Load Balancer"
  value       = aws_lb.internal_nlb.arn
}

output "nlb_dns_name" {
  description = "DNS name of the internal Network Load Balancer"
  value       = aws_lb.internal_nlb.dns_name
}

output "nlb_zone_id" {
  description = "Zone ID of the internal Network Load Balancer"
  value       = aws_lb.internal_nlb.zone_id
}

output "http_target_group_arn" {
  description = "ARN of the HTTP target group"
  value       = aws_lb_target_group.http_tg.arn
}

output "nlb_private_ips" {
  description = "Private IPs of the internal Network Load Balancer (one per subnet)"
  value       = aws_lb.internal_nlb.subnet_mapping[*].private_ipv4_address
}
