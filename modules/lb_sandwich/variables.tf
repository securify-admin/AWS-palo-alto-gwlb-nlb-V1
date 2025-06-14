variable "security_vpc_id" {
  description = "ID of the Security VPC"
  type        = string
}

variable "spoke_vpc_ids" {
  description = "List of Spoke VPC IDs"
  type        = list(string)
}

variable "security_vpc_public_subnet_ids" {
  description = "List of public subnet IDs in the Security VPC for ALB"
  type        = list(string)
}

variable "spoke_vpc_subnet_ids" {
  description = "List of lists of subnet IDs in the Spoke VPCs for NLB"
  type        = list(list(string))
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener"
  type        = string
  default     = null
}
