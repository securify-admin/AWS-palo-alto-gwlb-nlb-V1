output "windows_server_ids" {
  description = "IDs of the Windows test servers"
  value       = aws_instance.windows_server[*].id
}

output "windows_server_private_ips" {
  description = "Private IPs of the Windows test servers"
  value       = aws_instance.windows_server[*].private_ip
}

output "windows_server_public_ips" {
  description = "Public IPs of the Windows test servers (if applicable)"
  value       = aws_instance.windows_server[*].public_ip
}
