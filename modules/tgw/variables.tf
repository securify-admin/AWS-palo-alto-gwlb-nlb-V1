variable "tgw_name" {
  description = "Name of the Transit Gateway"
  type        = string
  default     = "centralized-inspection-tgw"
}

variable "security_vpc_id" {
  description = "ID of the Security VPC"
  type        = string
}

variable "security_vpc_attachment_subnet_ids" {
  description = "List of subnet IDs in the Security VPC for TGW attachment"
  type        = list(string)
}

variable "spoke_vpc_ids" {
  description = "List of Spoke VPC IDs"
  type        = list(string)
}

variable "spoke_vpc_cidrs" {
  description = "List of Spoke VPC CIDR blocks"
  type        = list(string)
}

variable "spoke_vpc_attachment_subnet_ids" {
  description = "List of lists of subnet IDs in Spoke VPCs for TGW attachment"
  type        = list(list(string))
}
