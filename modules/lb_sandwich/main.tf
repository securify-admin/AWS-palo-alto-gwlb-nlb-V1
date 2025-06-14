# Security group for the public NLB
resource "aws_security_group" "nlb_sg" {
  name        = "public-nlb-sg"
  description = "Security group for public NLB"
  vpc_id      = var.security_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "public-nlb-sg"
  }
}

# Security group for NLB targets - for security best practices
# NLB itself doesn't have a security group, but we need this for targets
resource "aws_security_group" "nlb_target_sg" {
  name        = "nlb-target-sg"
  description = "Security group for NLB targets"
  vpc_id      = var.security_vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDP
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "nlb-target-security-group"
  }
}

# Public NLB in Security VPC - centralized load balancer supporting all protocols
resource "aws_lb" "public_nlb" {
  name               = "centralized-nlb"
  internal           = false
  load_balancer_type = "network"
  # NLBs don't have security groups directly attached
  subnets            = var.security_vpc_public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "centralized-nlb"
  }
}

# Target groups for NLB supporting multiple protocols
# HTTP Target Group
resource "aws_lb_target_group" "nlb_http_tg" {
  name     = "nlb-http-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.security_vpc_id
  target_type = "ip"

  # In a real deployment, these would be IP targets pointing to application IPs in spoke VPCs
  # or to GWLB endpoints in the security VPC
  health_check {
    protocol = "TCP"
    port     = 80
    interval = 30
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

# HTTPS Target Group
resource "aws_lb_target_group" "nlb_https_tg" {
  name     = "nlb-https-tg"
  port     = 443
  protocol = "TCP"
  vpc_id   = var.security_vpc_id
  target_type = "ip"

  health_check {
    protocol = "TCP"
    port     = 443
    interval = 30
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

# RDP Target Group
resource "aws_lb_target_group" "nlb_rdp_tg" {
  name     = "nlb-rdp-tg"
  port     = 3389
  protocol = "TCP"
  vpc_id   = var.security_vpc_id
  target_type = "ip"

  health_check {
    protocol = "TCP"
    port     = 3389
    interval = 30
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

# NLB listeners for multiple protocols
# HTTP Listener
resource "aws_lb_listener" "nlb_http_listener" {
  load_balancer_arn = aws_lb.public_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nlb_http_tg.arn
  }
}

# HTTPS Listener
resource "aws_lb_listener" "nlb_https_listener" {
  load_balancer_arn = aws_lb.public_nlb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nlb_https_tg.arn
  }
}

# RDP Listener
resource "aws_lb_listener" "nlb_rdp_listener" {
  load_balancer_arn = aws_lb.public_nlb.arn
  port              = 3389
  protocol          = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nlb_rdp_tg.arn
  }
}
