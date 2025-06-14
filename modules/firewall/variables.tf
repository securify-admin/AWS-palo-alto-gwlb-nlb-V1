variable "vpc_id" {
  description = "ID of the Security VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to deploy firewalls in"
  type        = number
  default     = 2
}

variable "mgmt_subnet_ids" {
  description = "List of subnet IDs for firewall management interfaces"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of subnet IDs for firewall private dataplane interfaces"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of subnet IDs for firewall public dataplane interfaces"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for VM-Series firewall"
  type        = string
}

variable "instance_type" {
  description = "Instance type for VM-Series firewall"
  type        = string
  default     = "c5.2xlarge"
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "bootstrap_bucket" {
  description = "S3 bucket name for firewall bootstrap configuration"
  type        = string
}

variable "bootstrap_path" {
  description = "Path in S3 bucket for bootstrap configuration"
  type        = string
  default     = "/"
}
