# Network Load Balancer ARN - can be used for further resource associations
output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.inbound_nlb.arn
}

# Network Load Balancer DNS name - use this to access the NLB via DNS
# Example: public-inbound-nlb-12345678.us-west-2.elb.amazonaws.com
output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.inbound_nlb.dns_name
}

# Network Load Balancer Zone ID - required for Route 53 alias records
output "nlb_zone_id" {
  description = "Zone ID of the Network Load Balancer (used for Route 53 alias records)"
  value       = aws_lb.inbound_nlb.zone_id
}

# HTTPS Target Group ARN - can be used for further resource associations
output "https_target_group_arn" {
  description = "ARN of the HTTPS target group"
  value       = aws_lb_target_group.https_tg.arn
}

# SSH Target Group ARN - can be used for further resource associations
output "ssh_target_group_arn" {
  description = "ARN of the SSH target group"
  value       = aws_lb_target_group.ssh_tg.arn
}

# Network Load Balancer Elastic IP - the static public IP address for the NLB
# This is the IP address that external clients will connect to
output "nlb_elastic_ip" {
  description = "Elastic IP address associated with the NLB"
  value       = aws_eip.nlb_eip.public_ip
}
