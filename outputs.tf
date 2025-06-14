output "security_vpc_id" {
  description = "ID of the Security VPC"
  value       = module.security_vpc.vpc_id
}

output "spoke_vpc_a_id" {
  description = "ID of the Spoke VPC A"
  value       = module.spoke_vpc_a.vpc_id
}

output "spoke_vpc_b_id" {
  description = "ID of the Spoke VPC B"
  value       = module.spoke_vpc_b.vpc_id
}

output "security_vpc_subnet_ids" {
  description = "IDs of subnets in the Security VPC"
  value = {
    mgmt_subnet_a             = module.security_vpc.subnet_ids[0]
    mgmt_subnet_b             = module.security_vpc.subnet_ids[1]
    gwlb_subnet_a             = module.security_vpc.subnet_ids[2]
    gwlb_subnet_b             = module.security_vpc.subnet_ids[3]
    public_dataplane_subnet_a = module.security_vpc.subnet_ids[4]
    public_dataplane_subnet_b = module.security_vpc.subnet_ids[5]
    tgw_attachment_subnet_a   = module.security_vpc.subnet_ids[6]
    tgw_attachment_subnet_b   = module.security_vpc.subnet_ids[7]
  }
}

output "spoke_a_subnet_ids" {
  description = "IDs of subnets in Spoke VPC A"
  value = {
    app_subnet_a = module.spoke_vpc_a.subnet_ids[0]
    app_subnet_b = module.spoke_vpc_a.subnet_ids[1]
  }
}

output "spoke_b_subnet_ids" {
  description = "IDs of subnets in Spoke VPC B"
  value = {
    app_subnet_a = module.spoke_vpc_b.subnet_ids[0]
    app_subnet_b = module.spoke_vpc_b.subnet_ids[1]
  }
}

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = module.tgw.tgw_id
}

output "gwlb_endpoint_service_name" {
  description = "Service name of the GWLB endpoint service"
  value       = module.gwlb.gwlb_endpoint_service_name
}

output "palo_alto_firewall_management_ips" {
  description = "Public IPs of the Palo Alto VM-Series management interfaces"
  value       = module.firewall.firewall_mgmt_public_ips
}

output "palo_alto_firewall_public_ips" {
  description = "Public IPs of the Palo Alto VM-Series public dataplane interfaces"
  value       = module.firewall.firewall_public_ips
}

output "windows_server_private_ips" {
  description = "Private IPs of the Windows test servers in Spoke VPCs"
  value       = module.test_instances.windows_server_private_ips
}

output "windows_server_public_ips" {
  description = "Public IPs of the Windows test servers (if applicable)"
  value       = module.test_instances.windows_server_public_ips
}

# Network Load Balancer outputs
output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer for inbound traffic"
  value       = module.nlb.nlb_dns_name
}

output "nlb_zone_id" {
  description = "Route 53 zone ID of the Network Load Balancer"
  value       = module.nlb.nlb_zone_id
}

# Public NLB Outputs
output "public_nlb_dns_name" {
  description = "The DNS name of the public Network Load Balancer"
  value       = module.nlb.nlb_dns_name
}

output "public_nlb_zone_id" {
  description = "The Zone ID of the public Network Load Balancer"
  value       = module.nlb.nlb_zone_id
}

output "public_nlb_elastic_ip" {
  description = "The Elastic IP associated with the public Network Load Balancer"
  value       = module.nlb.nlb_elastic_ip
}

# Web VPC Outputs
output "web_vpc_id" {
  description = "The ID of the Web VPC"
  value       = module.web_vpc.vpc_id
}

output "web_vpc_subnet_ids" {
  description = "The IDs of the Web VPC subnets"
  value       = module.web_vpc.subnet_ids
}

# Web Server Outputs
output "web_server_private_ips" {
  description = "The private IPs of the web servers in Web VPC"
  value       = module.web_instances.web_server_private_ips
}

# Internal ALB Outputs
output "internal_alb_dns_name" {
  description = "The DNS name of the internal Application Load Balancer in Web VPC"
  value       = module.app_lb.alb_dns_name
}
