resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "Transit Gateway for centralized inspection architecture"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name = var.tgw_name
  }
}

# Create TGW route tables
resource "aws_ec2_transit_gateway_route_table" "spokes_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  
  tags = {
    Name = "${var.tgw_name}-spokes-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table" "security_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  
  tags = {
    Name = "${var.tgw_name}-security-rt"
  }
}

# Create TGW VPC attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "security_vpc_attachment" {
  subnet_ids                                      = var.security_vpc_attachment_subnet_ids
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = var.security_vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  appliance_mode_support                          = "enable" # Enable appliance mode for Security VPC

  tags = {
    Name = "${var.tgw_name}-security-vpc-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_vpc_attachments" {
  count                                           = length(var.spoke_vpc_ids)
  subnet_ids                                      = var.spoke_vpc_attachment_subnet_ids[count.index]
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = var.spoke_vpc_ids[count.index]
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  
  tags = {
    Name = "${var.tgw_name}-spoke-vpc-${count.index}-attachment"
  }
}

# Associate TGW route tables with VPC attachments
resource "aws_ec2_transit_gateway_route_table_association" "security_vpc_rt_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_vpc_rt_associations" {
  count                          = length(var.spoke_vpc_ids)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_vpc_attachments[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_rt.id
}

# Add routes to TGW route tables
resource "aws_ec2_transit_gateway_route" "spokes_default_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_rt.id
}

# Routes in the Security VPC TGW route table point to the appropriate spoke VPC attachments
# This allows return traffic to reach the correct spoke VPC after inspection
resource "aws_ec2_transit_gateway_route" "security_to_spoke_routes" {
  count                          = length(var.spoke_vpc_cidrs)
  destination_cidr_block         = var.spoke_vpc_cidrs[count.index]
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_vpc_attachments[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security_rt.id
}

# Propagate routes between TGW route tables
# For centralized inspection, we DON'T want the security VPC routes to propagate to spoke route table
# Instead, we'll use static routes to force traffic through the security VPC
# resource "aws_ec2_transit_gateway_route_table_propagation" "security_to_spokes" {
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security_vpc_attachment.id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spokes_rt.id
# }

# COMMENTED OUT: We DO NOT want spoke VPC routes to propagate to the security route table
# This was causing traffic to bypass the GWLB endpoints and firewalls
# Instead, traffic should flow into the Security VPC where our updated routes
# in the TGW attachment subnet route table will direct it to the GWLB endpoints for inspection
# resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_security" {
#   count                          = length(var.spoke_vpc_ids)
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_vpc_attachments[count.index].id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security_rt.id
# }
