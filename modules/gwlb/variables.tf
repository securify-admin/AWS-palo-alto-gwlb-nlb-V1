variable "gwlb_name" {
  description = "Name of the Gateway Load Balancer"
  type        = string
  default     = "palo-alto-gwlb"
}

variable "vpc_id" {
  description = "ID of the Security VPC where GWLB is deployed"
  type        = string
}

variable "gwlb_subnet_ids" {
  description = "List of subnet IDs for the GWLB"
  type        = list(string)
}

variable "firewall_instance_ids" {
  description = "List of firewall instance IDs (kept for backward compatibility)"
  type        = list(string)
  default     = []
}

variable "firewall_target_ips" {
  description = "List of firewall private ENI IP addresses to attach to the GWLB target group"
  type        = list(string)
  default     = []
}

variable "security_vpc_endpoint_subnet_ids" {
  description = "List of subnet IDs in the Security VPC for GWLB endpoints"
  type        = list(string)
}

variable "spoke_vpc_ids" {
  description = "List of Spoke VPC IDs"
  type        = list(string)
}

variable "spoke_vpc_endpoint_subnet_ids" {
  description = "List of lists of subnet IDs in Spoke VPCs for GWLB endpoints (not used in centralized model)"
  type        = list(list(string))
  default     = []
}
