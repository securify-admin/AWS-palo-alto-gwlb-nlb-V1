variable "vpc_ids" {
  description = "List of VPC IDs for the test instances"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs for the test instances (one per VPC)"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for the Windows test servers"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name for accessing the instances"
  type        = string
}
