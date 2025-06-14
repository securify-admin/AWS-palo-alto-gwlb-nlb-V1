variable "nlb_name" {
  description = "Name for the internal Network Load Balancer"
  type        = string
  default     = "web-internal-nlb"
}

variable "vpc_id" {
  description = "VPC ID where the internal NLB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the internal NLB will be deployed"
  type        = list(string)
}

variable "target_instance_ids" {
  description = "List of EC2 instance IDs to register as targets"
  type        = list(string)
}
