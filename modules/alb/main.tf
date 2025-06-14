resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  
  subnets            = var.subnets
  security_groups    = var.security_groups
  
  enable_deletion_protection = false
  enable_http2               = true
  
  tags = {
    Name = var.name
  }
}

# Create target groups based on the input configuration
resource "aws_lb_target_group" "target_groups" {
  for_each = var.target_groups
  
  name        = each.value.name
  port        = each.value.backend_port
  protocol    = each.value.backend_protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type
  
  health_check {
    enabled             = each.value.health_check.enabled
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    matcher             = each.value.health_check.matcher
  }
  
  tags = {
    Name = each.value.name
  }
}

# Create HTTP listeners
resource "aws_lb_listener" "http_listeners" {
  for_each = var.http_listener_enabled ? var.http_listeners : {}
  
  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  
  default_action {
    type             = each.value.action_type
    target_group_arn = aws_lb_target_group.target_groups[each.value.target_group].arn
  }
}
