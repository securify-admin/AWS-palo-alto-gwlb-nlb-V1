# Main Terraform configuration file for the Palo Alto VM-Series centralized inspection architecture

# Get current AWS region
data "aws_region" "current" {}

locals {
  # Web VPC Configuration
  web_vpc_cidr = "10.14.0.0/16"
  web_vpc_private_subnet_cidrs = ["10.14.1.0/24", "10.14.2.0/24"]
}

# Security VPC
module "security_vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.security_vpc_cidr
  vpc_name           = "security-vpc"
  availability_zones = var.availability_zones

  subnet_cidrs = concat(
    var.security_vpc_mgmt_subnet_cidrs,
    var.security_vpc_gwlb_subnet_cidrs,
    var.security_vpc_public_dataplane_subnet_cidrs,
    var.security_vpc_tgw_attachment_subnet_cidrs,
    var.security_vpc_gwlb_dedicated_subnet_cidrs,
    var.security_vpc_gwlbe_dedicated_subnet_cidrs
  )

  subnet_names = [
    "mgmt-subnet-a", "mgmt-subnet-b",
    "private-dataplane-subnet-a", "private-dataplane-subnet-b",
    "public-dataplane-subnet-a", "public-dataplane-subnet-b",
    "tgw-attachment-subnet-a", "tgw-attachment-subnet-b",
    "gwlb-dedicated-subnet-a", "gwlb-dedicated-subnet-b",
    "gwlbe-dedicated-subnet-a", "gwlbe-dedicated-subnet-b"
  ]

  # Management subnets (0, 1) and public dataplane subnets (4, 5) are public
  public_subnet_indices = [0, 1, 4, 5]

  # Private subnets include GWLB, TGW attachment, and dedicated GWLB/GWLBE subnets
  private_subnet_indices = [2, 3, 6, 7, 8, 9, 10, 11]

  # Don't create the private route table since all private subnets use custom route tables
  create_private_rt = false

  # Create per-AZ custom route tables for specific traffic flows
  custom_route_tables = {
    "private-dataplane-a" = "Private dataplane subnet route table for AZ-a",
    "private-dataplane-b" = "Private dataplane subnet route table for AZ-b",
    "tgw-a"               = "TGW attachment subnet route table for AZ-a",
    "tgw-b"               = "TGW attachment subnet route table for AZ-b",
    "gwlb-dedicated-a"    = "Dedicated GWLB subnet route table for AZ-a",
    "gwlb-dedicated-b"    = "Dedicated GWLB subnet route table for AZ-b",
    "gwlbe-dedicated-a"   = "Dedicated GWLBE subnet route table for AZ-a",
    "gwlbe-dedicated-b"   = "Dedicated GWLBE subnet route table for AZ-b"
  }

  # Associate each subnet with its AZ-specific route table
  custom_route_table_associations = {
    "private-dataplane-a" = { subnet_index = 2, route_table_key = "private-dataplane-a" },
    "private-dataplane-b" = { subnet_index = 3, route_table_key = "private-dataplane-b" },
    "tgw-a"               = { subnet_index = 6, route_table_key = "tgw-a" },
    "tgw-b"               = { subnet_index = 7, route_table_key = "tgw-b" },
    "gwlb-dedicated-a"    = { subnet_index = 8, route_table_key = "gwlb-dedicated-a" },
    "gwlb-dedicated-b"    = { subnet_index = 9, route_table_key = "gwlb-dedicated-b" },
    "gwlbe-dedicated-a"   = { subnet_index = 10, route_table_key = "gwlbe-dedicated-a" },
    "gwlbe-dedicated-b"   = { subnet_index = 11, route_table_key = "gwlbe-dedicated-b" }
  }

  # Create an S3 VPC endpoint for bootstrap access
  create_s3_endpoint = true
}

# Spoke VPC A
module "spoke_vpc_a" {
  source             = "./modules/vpc"
  vpc_cidr           = var.spoke_a_vpc_cidr
  vpc_name           = "spoke-vpc-a"
  availability_zones = var.availability_zones

  subnet_cidrs = var.spoke_a_app_subnet_cidrs
  subnet_names = ["app-subnet-a", "app-subnet-b"]

  # Make app subnets public for test Windows instances
  public_subnet_indices  = [0, 1]
  private_subnet_indices = []
  create_private_rt      = false

  # No custom route tables needed since app subnets are public and use public route table
  custom_route_tables = {}

  # No custom route table associations needed
  custom_route_table_associations = {}
}

# Spoke VPC B
module "spoke_vpc_b" {
  source             = "./modules/vpc"
  vpc_cidr           = var.spoke_b_vpc_cidr
  vpc_name           = "spoke-vpc-b"
  availability_zones = var.availability_zones

  subnet_cidrs = var.spoke_b_app_subnet_cidrs
  subnet_names = ["app-subnet-a", "app-subnet-b"]

  # Make app subnets private (no IGW access)
  public_subnet_indices  = []
  private_subnet_indices = [0, 1]
  create_private_rt      = true

  # No custom route tables needed
  custom_route_tables = {}

  # No custom route table associations needed
  custom_route_table_associations = {}
}

# Web VPC - Private subnets only
module "web_vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = local.web_vpc_cidr
  vpc_name           = "web-vpc"
  availability_zones = var.availability_zones

  subnet_cidrs = local.web_vpc_private_subnet_cidrs
  subnet_names = ["private-subnet-a", "private-subnet-b"]

  # All subnets are private
  public_subnet_indices  = []
  private_subnet_indices = [0, 1]
  
  # Create per-AZ custom route tables for routing through TGW
  custom_route_tables = {
    "private-a" = "Private subnet route table for AZ-a",
    "private-b" = "Private subnet route table for AZ-b"
  }
  
  # Associate each subnet with its AZ-specific route table
  custom_route_table_associations = {
    "private-a" = { subnet_index = 0, route_table_key = "private-a" },
    "private-b" = { subnet_index = 1, route_table_key = "private-b" }
  }
}

# Transit Gateway and attachments
module "tgw" {
  source   = "./modules/tgw"
  tgw_name = "centralized-inspection-tgw"

  security_vpc_id = module.security_vpc.vpc_id
  security_vpc_attachment_subnet_ids = [
    module.security_vpc.subnet_ids[6], # tgw-attachment-subnet-a
    module.security_vpc.subnet_ids[7]  # tgw-attachment-subnet-b
  ]

  spoke_vpc_ids = [
    module.spoke_vpc_a.vpc_id,
    module.spoke_vpc_b.vpc_id,
    module.web_vpc.vpc_id   # Add Web VPC to TGW attachments
  ]

  spoke_vpc_cidrs = [
    var.spoke_a_vpc_cidr,
    var.spoke_b_vpc_cidr,
    local.web_vpc_cidr    # Add Web VPC CIDR
  ]

  spoke_vpc_attachment_subnet_ids = [
    [module.spoke_vpc_a.subnet_ids[0], module.spoke_vpc_a.subnet_ids[1]], # app-subnet-a, app-subnet-b in Spoke VPC A
    [module.spoke_vpc_b.subnet_ids[0], module.spoke_vpc_b.subnet_ids[1]], # app-subnet-a, app-subnet-b in Spoke VPC B
    [module.web_vpc.subnet_ids[0], module.web_vpc.subnet_ids[1]]          # private-subnet-a, private-subnet-b in Web VPC
  ]
}

# Bootstrap S3 bucket and configuration
module "bootstrap" {
  source      = "./modules/bootstrap"
  bucket_name = var.bootstrap_bucket
}

# Palo Alto VM-Series Firewalls
module "firewall" {
  source = "./modules/firewall"

  vpc_id   = module.security_vpc.vpc_id
  az_count = length(var.availability_zones)

  mgmt_subnet_ids = [
    module.security_vpc.subnet_ids[0], # mgmt-subnet-a
    module.security_vpc.subnet_ids[1]  # mgmt-subnet-b
  ]

  private_subnet_ids = [
    module.security_vpc.subnet_ids[2], # gwlb-subnet-a
    module.security_vpc.subnet_ids[3]  # gwlb-subnet-b
  ]

  public_subnet_ids = [
    module.security_vpc.subnet_ids[4], # public-dataplane-subnet-a
    module.security_vpc.subnet_ids[5]  # public-dataplane-subnet-b
  ]

  ami_id           = var.palo_ami_id
  instance_type    = var.palo_instance_type
  key_name         = var.key_name
  bootstrap_bucket = module.bootstrap.bootstrap_bucket_name
  bootstrap_path   = var.bootstrap_path
}

# Gateway Load Balancer - in centralized model, GWLB and endpoints are only in Security VPC
module "gwlb" {
  source = "./modules/gwlb"

  gwlb_name = "palo-alto-gwlb"
  vpc_id    = module.security_vpc.vpc_id

  gwlb_subnet_ids = [
    module.security_vpc.subnet_ids[8], # gwlb-dedicated-subnet-a
    module.security_vpc.subnet_ids[9]  # gwlb-dedicated-subnet-b
  ]

  # We're using IP-based target registration for better health checks and traffic flow
  firewall_instance_ids = [] # Empty list since we're using IP-based targets
  firewall_target_ips   = module.firewall.firewall_private_eni_ips

  security_vpc_endpoint_subnet_ids = [
    module.security_vpc.subnet_ids[10], # gwlbe-dedicated-subnet-a
    module.security_vpc.subnet_ids[11]  # gwlbe-dedicated-subnet-b
  ]

  # In centralized model, these aren't used for GWLB endpoints
  spoke_vpc_ids = [
    module.spoke_vpc_a.vpc_id,
    module.spoke_vpc_b.vpc_id
  ]

  # Not used in centralized model but kept for interface compatibility
  spoke_vpc_endpoint_subnet_ids = []
}

# Add specific routes for east-west traffic to go through the Transit Gateway
# These routes send traffic to the Transit Gateway, which will route it to the Security VPC
# for inspection by the Palo Alto firewalls before reaching the destination VPC

# Route from Spoke A to all 10.0.0.0/8 (covers all VPCs)
resource "aws_route" "spoke_a_all_vpc_route" {
  route_table_id         = module.spoke_vpc_a.public_route_table_id
  destination_cidr_block = "10.0.0.0/8" # Covers all VPCs in 10.x.x.x range
  transit_gateway_id     = module.tgw.tgw_id
}

# Route from Spoke B to Spoke A
resource "aws_route" "spoke_b_to_spoke_a_route" {
  route_table_id         = module.spoke_vpc_b.private_route_table_id
  destination_cidr_block = "10.12.0.0/16" # Spoke A's CIDR
  transit_gateway_id     = module.tgw.tgw_id
  
  depends_on = [module.tgw]
}

# Route for Security VPC traffic from Spoke B
resource "aws_route" "spoke_b_to_security_vpc_route" {
  route_table_id         = module.spoke_vpc_b.private_route_table_id
  destination_cidr_block = "10.48.76.0/24" # Security VPC's CIDR
  transit_gateway_id     = module.tgw.tgw_id
  
  depends_on = [module.tgw]
}

# Default route from Spoke B to Transit Gateway for all traffic
resource "aws_route" "spoke_b_default_route" {
  route_table_id         = module.spoke_vpc_b.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.tgw.tgw_id
  
  depends_on = [module.tgw]
}



# Windows test servers in each Spoke VPC for testing outbound and east-west traffic
module "test_instances" {
  source = "./modules/test_instances"

  vpc_ids = [
    module.spoke_vpc_a.vpc_id,
    module.spoke_vpc_b.vpc_id
  ]

  subnet_ids = [
    module.spoke_vpc_a.subnet_ids[0], # app-subnet-a in Spoke VPC A
    module.spoke_vpc_b.subnet_ids[0]  # app-subnet-a in Spoke VPC B
  ]

  instance_type = "t3.micro"
  key_name      = var.key_name
}

# Routes for east-west traffic through GWLB endpoints in TGW attachment subnets - AZ A
resource "aws_route" "security_tgw_a_to_spoke_routes" {
  count                  = length(var.spoke_vpc_cidrs)
  route_table_id         = module.security_vpc.custom_route_table_ids["tgw-a"]
  destination_cidr_block = var.spoke_vpc_cidrs[count.index]
  vpc_endpoint_id        = module.gwlb.security_vpc_endpoint_ids[0] # AZ-A GWLB endpoint
}

# Routes for east-west traffic through GWLB endpoints in TGW attachment subnets - AZ B
resource "aws_route" "security_tgw_b_to_spoke_routes" {
  count                  = length(var.spoke_vpc_cidrs)
  route_table_id         = module.security_vpc.custom_route_table_ids["tgw-b"]
  destination_cidr_block = var.spoke_vpc_cidrs[count.index]
  vpc_endpoint_id        = module.gwlb.security_vpc_endpoint_ids[1] # AZ-B GWLB endpoint
}

# Add static routes in the TGW spoke route table to ensure traffic between spoke VPCs
# is routed through the Security VPC for inspection
resource "aws_ec2_transit_gateway_route" "spoke_to_security_vpc_route" {
  count                          = length(var.spoke_vpc_cidrs)
  destination_cidr_block         = var.spoke_vpc_cidrs[count.index]
  transit_gateway_attachment_id  = module.tgw.security_vpc_attachment_id
  transit_gateway_route_table_id = module.tgw.spokes_route_table_id
  blackhole                      = false
}

# Routes for forwarding spoke VPC traffic to TGW in the private dataplane subnets - AZ A
resource "aws_route" "security_private_dataplane_a_to_tgw_route" {
  count                  = length(var.spoke_vpc_cidrs)
  route_table_id         = module.security_vpc.custom_route_table_ids["private-dataplane-a"]
  destination_cidr_block = var.spoke_vpc_cidrs[count.index]
  transit_gateway_id     = module.tgw.tgw_id
  
  depends_on = [module.tgw]
}

# Routes for forwarding spoke VPC traffic to TGW in the private dataplane subnets - AZ B
resource "aws_route" "security_private_dataplane_b_to_tgw_route" {
  count                  = length(var.spoke_vpc_cidrs)
  route_table_id         = module.security_vpc.custom_route_table_ids["private-dataplane-b"]
  destination_cidr_block = var.spoke_vpc_cidrs[count.index]
  transit_gateway_id     = module.tgw.tgw_id

  depends_on = [module.security_vpc, module.tgw]
}

# Default route to IGW for public dataplane subnet A (where firewall external interfaces are)
resource "aws_route" "security_public_dataplane_a_internet_route" {
  route_table_id         = module.security_vpc.public_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.security_vpc.internet_gateway_id
}

# Default route to IGW for public dataplane subnet B (where firewall external interfaces are)
resource "aws_route" "security_public_dataplane_b_internet_route" {
  route_table_id         = module.security_vpc.public_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.security_vpc.internet_gateway_id
}

# Routes for GWLBE subnets to send return traffic back to spoke VPCs via Transit Gateway
resource "aws_route" "gwlbe_a_to_tgw_route" {
  route_table_id         = module.security_vpc.custom_route_table_ids["gwlbe-dedicated-a"]
  destination_cidr_block = "10.0.0.0/8" # Covers all VPCs in 10.x.x.x range
  transit_gateway_id     = module.tgw.tgw_id
  
  depends_on = [module.tgw]
}

resource "aws_route" "gwlbe_b_to_tgw_route" {
  route_table_id         = module.security_vpc.custom_route_table_ids["gwlbe-dedicated-b"]
  destination_cidr_block = "10.0.0.0/8" # Covers all VPCs in 10.x.x.x range
  transit_gateway_id     = module.tgw.tgw_id
  
  depends_on = [module.tgw]
}

# Note: The routes in the TGW attachment subnet route table are now properly managed by the
# security_tgw_to_spoke_routes resource above, which points to the GWLB endpoint for inspection

# Inbound Traffic Architecture Components
# Security group for the public ALB
resource "aws_security_group" "public_alb_sg" {
  name        = "public-alb-sg"
  description = "Security group for public inbound traffic ALB"
  vpc_id      = module.security_vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "public-alb-sg"
  }
}

# 1. Public Application Load Balancer (ALB) as front-end for inbound traffic
module "public_alb" {
  source = "./modules/alb"
  name = "inbound-traffic-alb"
  internal = false
  vpc_id = module.security_vpc.vpc_id
  subnets = [
    module.security_vpc.subnet_ids[4], # public-dataplane-subnet-a
    module.security_vpc.subnet_ids[5]  # public-dataplane-subnet-b
  ]
  security_groups = [aws_security_group.public_alb_sg.id]
  http_listener_enabled = true
  target_groups = {
    web = {
      name = "web-servers"
      backend_protocol = "HTTP"
      backend_port = 80
      target_type = "ip"
      health_check = {
        enabled = true
        path = "/"
        port = 80
        protocol = "HTTP"
        interval = 30
        timeout = 5
        healthy_threshold = 3
        unhealthy_threshold = 3
        matcher = "200"
      }
    }
  }
  http_listeners = {
    web = {
      port = 80
      protocol = "HTTP"
      target_group = "web"
      action_type = "forward"
    }
  }
}

# 2. Public-facing NLB targeting the firewall public ENIs (for non-HTTP traffic)
module "nlb" {
  source = "./modules/nlb"
  nlb_name = "public-inbound-nlb"
  vpc_id  = module.security_vpc.vpc_id
  public_subnet_ids = [
    module.security_vpc.subnet_ids[4], # public-dataplane-subnet-a
    module.security_vpc.subnet_ids[5]  # public-dataplane-subnet-b
  ]
  firewall_public_ips = module.firewall.fw_public_eni_private_ips
}

# Security group for the internal ALB
resource "aws_security_group" "internal_alb_sg" {
  name        = "internal-alb-sg"
  description = "Security group for internal application load balancer"
  vpc_id      = module.web_vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.web_vpc.vpc_cidr]
    description = "Allow HTTP from web VPC"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.web_vpc.vpc_cidr]
    description = "Allow HTTPS from web VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "internal-alb-sg"
  }
}

# 3. Internal Application Load Balancer for distribution to web servers
module "app_lb" {
  source = "./modules/alb"
  name = "app-lb-internal"
  internal = true
  vpc_id = module.web_vpc.vpc_id
  subnets = [
    module.web_vpc.subnet_ids[0], # private-a
    module.web_vpc.subnet_ids[1]  # private-b
  ]
  security_groups = [aws_security_group.internal_alb_sg.id]
  http_listener_enabled = true
  target_groups = {
    web = {
      name = "web-servers-internal"
      backend_protocol = "HTTP"
      backend_port = 80
      target_type = "instance"
      targets = [
        for id in module.web_instances.web_server_ids : {
          id = id
          port = 80
        }
      ]
      health_check = {
        enabled = true
        path = "/health"
        port = 80
        protocol = "HTTP"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 3
        matcher = "200-399"
      }
    }
  }
  http_listeners = {
    web = {
      port = 80
      protocol = "HTTP"
      target_group = "web"
      action_type = "forward"
    }
  }
}

# Web server instances in Web VPC
module "web_instances" {
  source = "./modules/web_instances"
  vpc_id = module.web_vpc.vpc_id
  subnet_ids = [
    module.web_vpc.subnet_ids[0], # private-subnet-a
    module.web_vpc.subnet_ids[1]  # private-subnet-b
  ]
  availability_zones = var.availability_zones
  key_name = var.key_name
}

# Internal NLB removed - using only the internal ALB for web server load balancing

# Routes for Web VPC private subnets - controlled by var.route_web_vpc_through_tgw
# When var.route_web_vpc_through_tgw = false: Route directly to Internet Gateway for package installation
# When var.route_web_vpc_through_tgw = true: Route through Transit Gateway for inspection

# Internet Gateway routes - created when route_web_vpc_through_tgw = false
resource "aws_route" "web_vpc_private_a_internet_route" {
  count                  = var.route_web_vpc_through_tgw ? 0 : 1
  route_table_id         = module.web_vpc.custom_route_table_ids["private-a"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.web_vpc.internet_gateway_id
}

resource "aws_route" "web_vpc_private_b_internet_route" {
  count                  = var.route_web_vpc_through_tgw ? 0 : 1
  route_table_id         = module.web_vpc.custom_route_table_ids["private-b"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.web_vpc.internet_gateway_id
}

# Transit Gateway routes - created when route_web_vpc_through_tgw = true
resource "aws_route" "web_vpc_private_a_tgw_route" {
  count                  = var.route_web_vpc_through_tgw ? 1 : 0
  route_table_id         = module.web_vpc.custom_route_table_ids["private-a"]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.tgw.tgw_id
  
  depends_on = [module.tgw]
}

resource "aws_route" "web_vpc_private_b_tgw_route" {
  count                  = var.route_web_vpc_through_tgw ? 1 : 0
  route_table_id         = module.web_vpc.custom_route_table_ids["private-b"]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.tgw.tgw_id
  
  depends_on = [module.tgw]
}
