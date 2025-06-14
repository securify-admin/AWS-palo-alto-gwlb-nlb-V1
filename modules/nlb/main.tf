# Single Elastic IP for the NLB
# This EIP will be assigned to the NLB in the first availability zone
resource "aws_eip" "nlb_eip" {
  vpc = true
  tags = {
    Name = "${var.nlb_name}-eip"
  }
}

# Network Load Balancer for inbound traffic to the firewalls
# This NLB is external-facing and distributes traffic to the firewall instances
resource "aws_lb" "inbound_nlb" {
  name               = var.nlb_name
  internal           = false
  load_balancer_type = "network"
  
  # Enable cross-zone load balancing for high availability
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  # Use a subnet mapping with the EIP assigned to the first AZ
  # This provides a static IP address for the NLB in the first AZ
  subnet_mapping {
    subnet_id     = var.public_subnet_ids[0]
    allocation_id = aws_eip.nlb_eip.id
  }
  
  # Add a second subnet mapping without an EIP for the second AZ
  # AWS will automatically assign a public IP to this subnet mapping
  subnet_mapping {
    subnet_id = var.public_subnet_ids[1]
  }

  tags = {
    Name = var.nlb_name
  }
}

# HTTPS Target Group - For secure web traffic (port 443)
# This target group will forward HTTPS traffic to the firewall instances
resource "aws_lb_target_group" "https_tg" {
  name        = "${var.nlb_name}-https-tg"
  port        = 443
  protocol    = "TCP"  # NLB uses TCP protocol
  vpc_id      = var.vpc_id
  target_type = "ip"  # Using IP addresses as targets rather than instance IDs

  # Health check configuration
  # The firewall must have a health check endpoint configured at /health
  health_check {
    enabled             = true
    protocol            = "HTTPS"
    port                = 443
    path                = "/health"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"  # Any HTTP status in this range is considered healthy
  }

  tags = {
    Name = "${var.nlb_name}-https-tg"
  }
}

# SSH Target Group - For SSH management access (port 22)
# This target group will forward SSH traffic to the firewall instances
resource "aws_lb_target_group" "ssh_tg" {
  name        = "${var.nlb_name}-ssh-tg"
  port        = 22
  protocol    = "TCP"  # NLB uses TCP protocol
  vpc_id      = var.vpc_id
  target_type = "ip"  # Using IP addresses as targets

  # TCP health check for SSH port
  # This performs a basic TCP connection test to verify the port is open
  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = 22
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.nlb_name}-ssh-tg"
  }
}

# RDP Target Group - For Windows Remote Desktop access (port 3389)
# This target group will forward RDP traffic to the firewall instances
resource "aws_lb_target_group" "rdp_tg" {
  name        = "${var.nlb_name}-rdp-tg"
  port        = 3389
  protocol    = "TCP"  # NLB uses TCP protocol
  vpc_id      = var.vpc_id
  target_type = "ip"  # Using IP addresses as targets

  # TCP health check for RDP port
  # This performs a basic TCP connection test to verify the port is open
  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = 3389
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.nlb_name}-rdp-tg"
  }
}

# HTTPS Listener - Listens on port 443 and forwards to the HTTPS target group
# This listener handles incoming HTTPS traffic from the internet
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.inbound_nlb.arn
  port              = 443
  protocol          = "TCP"  # NLB uses TCP protocol

  # Forward all traffic to the HTTPS target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https_tg.arn
  }
}

# SSH Listener - Listens on port 22 and forwards to the SSH target group
# This listener handles incoming SSH traffic for management access
resource "aws_lb_listener" "ssh_listener" {
  load_balancer_arn = aws_lb.inbound_nlb.arn
  port              = 22
  protocol          = "TCP"  # NLB uses TCP protocol

  # Forward all traffic to the SSH target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssh_tg.arn
  }
}

# RDP Listener - Listens on port 3389 and forwards to the RDP target group
# This listener handles incoming RDP traffic for Windows management access
resource "aws_lb_listener" "rdp_listener" {
  load_balancer_arn = aws_lb.inbound_nlb.arn
  port              = 3389
  protocol          = "TCP"  # NLB uses TCP protocol

  # Forward all traffic to the RDP target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rdp_tg.arn
  }
}

# HTTPS Target Group Attachments - Register firewall IPs as targets
# These attachments connect the firewall instances to the HTTPS target group
resource "aws_lb_target_group_attachment" "https_tg_attachment" {
  count            = length(var.firewall_public_ips)  # Create one attachment for each firewall
  target_group_arn = aws_lb_target_group.https_tg.arn
  target_id        = var.firewall_public_ips[count.index]  # Use the private IP of the firewall's public interface
  port             = 443  # Target port on the firewall
}

# SSH Target Group Attachments - Register firewall IPs as targets
# These attachments connect the firewall instances to the SSH target group
resource "aws_lb_target_group_attachment" "ssh_tg_attachment" {
  count            = length(var.firewall_public_ips)  # Create one attachment for each firewall
  target_group_arn = aws_lb_target_group.ssh_tg.arn
  target_id        = var.firewall_public_ips[count.index]  # Use the private IP of the firewall's public interface
  port             = 22  # Target port on the firewall
}

# RDP Target Group Attachments - Register firewall IPs as targets
# These attachments connect the firewall instances to the RDP target group
resource "aws_lb_target_group_attachment" "rdp_tg_attachment" {
  count            = length(var.firewall_public_ips)  # Create one attachment for each firewall
  target_group_arn = aws_lb_target_group.rdp_tg.arn
  target_id        = var.firewall_public_ips[count.index]  # Use the private IP of the firewall's public interface
  port             = 3389  # Target port on the firewall
}
