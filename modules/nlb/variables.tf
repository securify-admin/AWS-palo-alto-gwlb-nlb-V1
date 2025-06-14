# Network Load Balancer name
variable "nlb_name" {
  description = "Name for the Network Load Balancer"
  type        = string
  default     = "palo-inbound-nlb"
}

# VPC where the NLB will be deployed
variable "vpc_id" {
  description = "VPC ID where the NLB will be deployed (typically the Security VPC)"
  type        = string
}

# Public subnets for the NLB
# Must provide at least two subnet IDs in different Availability Zones for high availability
variable "public_subnet_ids" {
  description = "List of public subnet IDs where the NLB will be deployed (should be in the public dataplane subnets)"
  type        = list(string)
}

# Firewall IPs to register as targets
# These are the private IPs of the public interfaces of the Palo Alto firewalls
variable "firewall_public_ips" {
  description = "List of Palo Alto firewall public interface private IPs to register as targets"
  type        = list(string)
}
