output "web_server_ids" {
  description = "IDs of the web server instances"
  value       = aws_instance.web_server[*].id
}

output "web_server_private_ips" {
  description = "Private IPs of the web server instances"
  value       = aws_instance.web_server[*].private_ip
}

output "web_security_group_id" {
  description = "ID of the web servers security group"
  value       = aws_security_group.web_sg.id
}
