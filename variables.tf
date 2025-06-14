variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"  # Change this to your preferred region
}

variable "availability_zones" {
  description = "List of AZs to use for the deployment (must be in the same region)"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]  # Update these to match your selected region
}

# VPC CIDRs
variable "security_vpc_cidr" {
  description = "CIDR block for Security VPC"
  type        = string
  default     = "10.11.0.0/16"
}

variable "spoke_a_vpc_cidr" {
  description = "CIDR block for Spoke VPC A"
  type        = string
  default     = "10.12.0.0/16"
}

variable "spoke_b_vpc_cidr" {
  description = "CIDR block for Spoke VPC B"
  type        = string
  default     = "10.13.0.0/16"
}

variable "spoke_vpc_cidrs" {
  description = "List of CIDR blocks for Spoke VPCs"
  type        = list(string)
  default     = ["10.12.0.0/16", "10.13.0.0/16", "10.14.0.0/16"]
}

# Subnet CIDRs for Security VPC
variable "security_vpc_mgmt_subnet_cidrs" {
  description = "CIDR blocks for management subnets in Security VPC"
  type        = list(string)
  default     = ["10.11.0.0/24", "10.11.1.0/24"]
}

variable "security_vpc_gwlb_subnet_cidrs" {
  description = "CIDR blocks for private dataplane subnets in Security VPC (used for firewall private ENIs)"
  type        = list(string)
  default     = ["10.11.2.0/24", "10.11.3.0/24"]
}

variable "security_vpc_public_dataplane_subnet_cidrs" {
  description = "CIDR blocks for public dataplane subnets in Security VPC"
  type        = list(string)
  default     = ["10.11.4.0/24", "10.11.5.0/24"]
}

variable "security_vpc_tgw_attachment_subnet_cidrs" {
  description = "CIDR blocks for TGW attachment subnets in Security VPC"
  type        = list(string)
  default     = ["10.11.6.0/24", "10.11.7.0/24"]
}

variable "security_vpc_gwlb_dedicated_subnet_cidrs" {
  description = "CIDR blocks for dedicated GWLB subnets in Security VPC"
  type        = list(string)
  default     = ["10.11.8.0/24", "10.11.9.0/24"]
}

variable "security_vpc_gwlbe_dedicated_subnet_cidrs" {
  description = "CIDR blocks for dedicated GWLB endpoint subnets in Security VPC"
  type        = list(string)
  default     = ["10.11.10.0/24", "10.11.11.0/24"]
}

# Subnet CIDRs for Spoke VPCs
variable "spoke_a_app_subnet_cidrs" {
  description = "CIDR blocks for app subnets in Spoke VPC A"
  type        = list(string)
  default     = ["10.12.0.0/24", "10.12.1.0/24"]
}

variable "spoke_b_app_subnet_cidrs" {
  description = "CIDR blocks for app subnets in Spoke VPC B"
  type        = list(string)
  default     = ["10.13.0.0/24", "10.13.1.0/24"]
}

# Web VPC variables
variable "web_vpc_cidr" {
  description = "CIDR block for Web VPC"
  type        = string
  default     = "10.14.0.0/16"
}

variable "web_vpc_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets in Web VPC"
  type        = list(string)
  default     = ["10.14.1.0/24", "10.14.2.0/24"]
}

# Firewall variables
variable "palo_ami_id" {
  description = "AMI ID for Palo Alto VM-Series firewall - find the correct AMI ID for your region at https://docs.paloaltonetworks.com/vm-series/10-2/vm-series-deployment/set-up-the-vm-series-firewall-on-aws/deploy-the-vm-series-firewall-on-aws/obtain-the-ami"
  type        = string
  default     = "ami-08c466959792f4c4b" # Replace with the correct AMI ID for your region and license type
}

variable "palo_instance_type" {
  description = "Instance type for Palo Alto VM-Series firewall"
  type        = string
  default     = "m5.large"
}

variable "key_name" {
  description = "EC2 Key pair name for VM-Series instances - must already exist in your AWS account"
  type        = string
  default     = "your-key-pair-name" # Replace with your EC2 key pair name
}

variable "bootstrap_bucket" {
  description = "S3 bucket for Palo Alto bootstrap configuration - will be created if it doesn't exist"
  type        = string
  default     = "palo-bootstrap-UNIQUE-NAME" # Replace with a globally unique bucket name
}

variable "bootstrap_path" {
  description = "Path in S3 bucket for bootstrap configuration"
  type        = string
  default     = "/"
}

# Routing control variables
variable "route_web_vpc_through_tgw" {
  description = "If true, route Web VPC traffic through Transit Gateway for inspection. If false, use Internet Gateway for direct internet access."
  type        = bool
  default     = false  # Start with IGW for initial setup
}
