resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "subnets" {
  count             = length(var.subnet_cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  
  # If subnet type is public, enable auto-assign public IP
  map_public_ip_on_launch = contains(var.public_subnet_indices, count.index) ? true : false

  tags = {
    Name = "${var.vpc_name}-${var.subnet_names[count.index]}"
    Type = contains(var.public_subnet_indices, count.index) ? "public" : "private"
  }
}

# Route tables for public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# Default route to IGW for public route table
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Route tables for private subnets
resource "aws_route_table" "private_rt" {
  count  = var.create_private_rt ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

# Associate route tables with public subnets
resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(var.public_subnet_indices)
  subnet_id      = aws_subnet.subnets[var.public_subnet_indices[count.index]].id
  route_table_id = aws_route_table.public_rt.id
}

# Associate route tables with private subnets if private route table is created and not in custom associations
resource "aws_route_table_association" "private_rt_assoc" {
  count = var.create_private_rt ? length([for idx in var.private_subnet_indices : idx if !contains(
    [for assoc in values(var.custom_route_table_associations) : assoc.subnet_index], idx
  )]) : 0
  
  # Get private subnet indices that are not in custom associations
  subnet_id      = aws_subnet.subnets[var.private_subnet_indices[index([for idx in var.private_subnet_indices : idx if !contains(
    [for assoc in values(var.custom_route_table_associations) : assoc.subnet_index], idx
  )], var.private_subnet_indices[count.index])]].id
  route_table_id = aws_route_table.private_rt[0].id
}

# Create custom route tables for specific subnets if needed
resource "aws_route_table" "custom_rt" {
  for_each = var.custom_route_tables
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-${each.key}-rt"
  }
}

# Associate custom route tables with specific subnets
resource "aws_route_table_association" "custom_rt_assoc" {
  for_each       = var.custom_route_table_associations
  subnet_id      = aws_subnet.subnets[each.value.subnet_index].id
  route_table_id = aws_route_table.custom_rt[each.value.route_table_key].id
}
