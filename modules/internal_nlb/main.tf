resource "aws_lb" "internal_nlb" {
  name               = var.nlb_name
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  tags = {
    Name = var.nlb_name
  }
}

# Target group for HTTP traffic (port 80)
resource "aws_lb_target_group" "http_tg" {
  name     = "${var.nlb_name}-http-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
  }

  tags = {
    Name = "${var.nlb_name}-http-tg"
  }
}

# Listener for HTTP traffic
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_tg.arn
  }
}

# Target group attachment for HTTP - using the web server instance IDs
resource "aws_lb_target_group_attachment" "http_tg_attachment" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.http_tg.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 80
}
