output "nlb_dns_name" {
  description = "DNS name of the centralized NLB"
  value       = aws_lb.public_nlb.dns_name
}

output "nlb_zone_id" {
  description = "Zone ID of the centralized NLB"
  value       = aws_lb.public_nlb.zone_id
}

output "nlb_arn" {
  description = "ARN of the centralized NLB"
  value       = aws_lb.public_nlb.arn
}
