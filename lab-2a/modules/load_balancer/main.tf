############################################
# Locals & Data
############################################
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}
#####################################################
##### RANDOM PASSWORD FOR CLOUDFRONT
#####################################################
resource "random_password" "origin_header" {
  length  = 32
  special = false
}
#####################################################
##### LOAD BALANCER
#####################################################
resource "aws_lb" "dev_alb" {
  name                       = "${var.name_prefix}-app-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = var.public_subnet_ids[*]
  enable_deletion_protection = false
  #Lots of death and suffering here, make sure it's false

  access_logs {
    bucket  = var.s3_bucket
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

  tags = {
    Name = "${var.name_prefix}-load-balancer"
  }
}

resource "aws_lb_listener" "redirect" {
  load_balancer_arn = aws_lb.dev_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.dev_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied: Direct ALB access is prohibited."
      status_code  = "403"
    }
    #   depends_on = [
    #   aws_acm_certificate_validation.cert
    # ]
  }
}
resource "aws_lb_listener_rule" "require_origin_header" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  condition {
    http_header {
      http_header_name = "X-Custom-Header"
      values           = [random_password.origin_header.result]
    }
  }
}

resource "aws_lb_listener_rule" "default_block" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 99

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern { values = ["*"] }
  }
}
# resource "aws_lb_listener_certificate" "apex_cert" {
#   listener_arn = aws_lb_listener.https.arn
#   # Using .certificate_arn from the validation resource creates a hard dependency
#   certificate_arn = var.certificate_validation_cert_arn
# }