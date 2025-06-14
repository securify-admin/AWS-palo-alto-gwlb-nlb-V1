resource "aws_lb" "gwlb" {
  name                             = var.gwlb_name
  load_balancer_type               = "gateway"
  subnets                          = var.gwlb_subnet_ids
  enable_cross_zone_load_balancing = true

  tags = {
    Name = var.gwlb_name
  }
}

resource "aws_lb_target_group" "firewall_tg" {
  name        = "${var.gwlb_name}-tg"
  port        = 6081
  protocol    = "GENEVE"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    port                = 443
    protocol            = "HTTPS"
    path                = "/php/login.php"
    interval            = 5
    timeout             = 3
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "gwlb_listener" {
  load_balancer_arn = aws_lb.gwlb.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.firewall_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "firewall_tg_attachment" {
  count            = length(var.firewall_target_ips)
  target_group_arn = aws_lb_target_group.firewall_tg.arn
  target_id        = var.firewall_target_ips[count.index]
  port             = 6081
}

# GWLB Endpoint Service - create this first
resource "aws_vpc_endpoint_service" "gwlb_endpoint_service" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]

  tags = {
    Name = "${var.gwlb_name}-endpoint-service"
  }
}

# GWLB Endpoints in Security VPC
resource "aws_vpc_endpoint" "security_vpc_gwlb_endpoints" {
  count             = length(var.security_vpc_endpoint_subnet_ids)
  service_name      = aws_vpc_endpoint_service.gwlb_endpoint_service.service_name
  subnet_ids        = [var.security_vpc_endpoint_subnet_ids[count.index]]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = var.vpc_id

  tags = {
    Name = "${var.gwlb_name}-security-endpoint-${count.index + 1}"
  }
  
  depends_on = [aws_vpc_endpoint_service.gwlb_endpoint_service]
}

# In a true centralized model, we don't deploy GWLB endpoints in Spoke VPCs
