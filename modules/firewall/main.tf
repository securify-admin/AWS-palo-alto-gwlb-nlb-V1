# Get current AWS region
data "aws_region" "current" {}

# Security group for the firewall management interface
resource "aws_security_group" "fw_mgmt_sg" {
  name        = "palo-mgmt-sg"
  description = "Allow SSH and HTTPS to firewall management interface"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access to management interface"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access to management interface"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "palo-mgmt-sg"
  }
}

# Security group for the dataplane interfaces
resource "aws_security_group" "fw_dataplane_sg" {
  name        = "palo-dataplane-sg"
  description = "Allow all traffic to/from dataplane interfaces"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "palo-dataplane-sg"
  }
}

# IAM role for the VM-Series firewall
resource "aws_iam_role" "fw_role" {
  name = "palo-alto-vm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "palo-alto-vm-role"
  }
}

# IAM policy for S3 bootstrap access
resource "aws_iam_policy" "fw_s3_policy" {
  name        = "palo-alto-s3-bootstrap-policy"
  description = "Policy for VM-Series to access bootstrap bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.bootstrap_bucket}",
          "arn:aws:s3:::${var.bootstrap_bucket}/*"
        ]
      }
    ]
  })
}

# IAM policy for AWS services access
resource "aws_iam_policy" "fw_aws_services_policy" {
  name        = "palo-alto-aws-services-policy"
  description = "Policy for VM-Series to access AWS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeTransitGatewayAttachments",
          "ec2:DescribeVpcs",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcEndpoints"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:LookupEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policies to the role
resource "aws_iam_role_policy_attachment" "fw_s3_policy_attachment" {
  role       = aws_iam_role.fw_role.name
  policy_arn = aws_iam_policy.fw_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "fw_aws_services_policy_attachment" {
  role       = aws_iam_role.fw_role.name
  policy_arn = aws_iam_policy.fw_aws_services_policy.arn
}

# Create an IAM instance profile
resource "aws_iam_instance_profile" "fw_instance_profile" {
  name = "palo-alto-vm-profile"
  role = aws_iam_role.fw_role.name
}

# Elastic IPs for management interface
resource "aws_eip" "fw_mgmt_eip" {
  count = var.az_count
  tags = {
    Name = "palo-fw-${count.index + 1}-mgmt-eip"
  }
}

# Elastic IPs for public dataplane interface
resource "aws_eip" "fw_public_eip" {
  count = var.az_count
  tags = {
    Name = "palo-fw-${count.index + 1}-public-eip"
  }
}

# Network interfaces for VM-Series firewalls
resource "aws_network_interface" "fw_mgmt_eni" {
  count             = var.az_count
  subnet_id         = var.mgmt_subnet_ids[count.index]
  security_groups   = [aws_security_group.fw_mgmt_sg.id]
  source_dest_check = true
  
  tags = {
    Name = "palo-fw-${count.index + 1}-mgmt-eni"
  }
}

resource "aws_network_interface" "fw_private_eni" {
  count             = var.az_count
  subnet_id         = var.private_subnet_ids[count.index]
  security_groups   = [aws_security_group.fw_dataplane_sg.id]
  source_dest_check = false
  
  tags = {
    Name = "palo-fw-${count.index + 1}-private-eni"
  }
}

resource "aws_network_interface" "fw_public_eni" {
  count             = var.az_count
  subnet_id         = var.public_subnet_ids[count.index]
  security_groups   = [aws_security_group.fw_dataplane_sg.id]
  source_dest_check = false
  
  tags = {
    Name = "palo-fw-${count.index + 1}-public-eni"
  }
}

# EIP association for management interface
resource "aws_eip_association" "fw_mgmt_eip_assoc" {
  count                = var.az_count
  network_interface_id = aws_network_interface.fw_mgmt_eni[count.index].id
  allocation_id        = aws_eip.fw_mgmt_eip[count.index].id
}

# EIP association for public dataplane interface
resource "aws_eip_association" "fw_public_eip_assoc" {
  count                = var.az_count
  network_interface_id = aws_network_interface.fw_public_eni[count.index].id
  allocation_id        = aws_eip.fw_public_eip[count.index].id
}

# VM-Series firewall instances
resource "aws_instance" "palo_fw" {
  count         = var.az_count
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile = aws_iam_instance_profile.fw_instance_profile.name
  user_data = <<EOF
vmseries-bootstrap-aws-s3bucket=${var.bootstrap_bucket}
vmseries-bootstrap-aws-s3prefix=${var.bootstrap_path}
vmseries-bootstrap-aws-s3region=${data.aws_region.current.name}
EOF

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.fw_private_eni[count.index].id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.fw_mgmt_eni[count.index].id
  }

  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.fw_public_eni[count.index].id
  }

  tags = {
    Name = "palo-fw-${count.index + 1}"
  }

  # Root device
  root_block_device {
    volume_type = "gp3"
    volume_size = 60
    encrypted   = true
  }
}
