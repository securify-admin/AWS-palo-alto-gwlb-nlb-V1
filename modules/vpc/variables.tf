variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  type        = list(string)
}

variable "subnet_names" {
  description = "List of subnet names corresponding to subnet_cidrs"
  type        = list(string)
}

variable "public_subnet_indices" {
  description = "Indices of public subnets in the subnet_cidrs list"
  type        = list(number)
  default     = []
}

variable "private_subnet_indices" {
  description = "Indices of private subnets in the subnet_cidrs list"
  type        = list(number)
  default     = []
}

variable "create_private_rt" {
  description = "Whether to create a common private route table"
  type        = bool
  default     = true
}

variable "custom_route_tables" {
  description = "Map of custom route tables to create"
  type        = map(string)
  default     = {}
}

variable "custom_route_table_associations" {
  description = "Map of subnet to custom route table associations"
  type = map(object({
    subnet_index    = number
    route_table_key = string
  }))
  default = {}
}

variable "create_s3_endpoint" {
  description = "Whether to create an S3 VPC endpoint"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for the S3 endpoint service name"
  type        = string
  default     = "us-west-2"
}
