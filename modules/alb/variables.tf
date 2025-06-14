variable "name" {
  description = "Name for the Application Load Balancer"
  type        = string
}

variable "internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be deployed"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs where the ALB will be deployed"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs to assign to the ALB"
  type        = list(string)
}

variable "http_listener_enabled" {
  description = "Whether to create a HTTP listener"
  type        = bool
  default     = false
}

variable "target_groups" {
  description = "Map of target group configurations"
  type        = map(object({
    name            = string
    backend_protocol = string
    backend_port    = number
    target_type     = string
    health_check    = object({
      enabled             = bool
      path                = string
      port                = number
      protocol            = string
      interval            = number
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
      matcher             = string
    })
  }))
  default     = {}
}

variable "http_listeners" {
  description = "Map of HTTP listener configurations"
  type        = map(object({
    port        = number
    protocol    = string
    target_group = string
    action_type = string
  }))
  default     = {}
}
