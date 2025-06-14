variable "vpc_id" {
  description = "VPC ID where web servers will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where web servers will be deployed"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones matching the subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key pair name for web server instances"
  type        = string
}
