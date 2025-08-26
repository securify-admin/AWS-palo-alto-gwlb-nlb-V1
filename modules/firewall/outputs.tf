output "firewall_instance_ids" {
  description = "IDs of the Palo Alto VM-Series firewall instances"
  value       = aws_instance.palo_fw[*].id
}

output "firewall_mgmt_public_ips" {
  description = "Public IPs of the firewall management interfaces - dynamically assigned"
  value       = aws_instance.palo_fw[*].public_ip
}

output "firewall_public_ips" {
  description = "Public IPs of the firewall public dataplane interfaces"
  value       = aws_eip.fw_public_eip[*].public_ip
}

output "firewall_private_eni_ids" {
  description = "IDs of the firewall private dataplane ENIs"
  value       = aws_network_interface.fw_private_eni[*].id
}

output "firewall_private_eni_ips" {
  description = "Private IPs of the firewall private dataplane interfaces"
  value       = [for eni in aws_network_interface.fw_private_eni : eni.private_ip]
}

output "fw_public_eni_private_ips" {
  description = "Private IPs of the firewall public dataplane interfaces (for NLB targets)"
  value       = [for eni in aws_network_interface.fw_public_eni : eni.private_ip]
}
