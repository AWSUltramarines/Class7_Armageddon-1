############################################
# Locals & Data
############################################
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}
############################################
# Load Balancer
############################################
resource "aws_lb" "dev_alb" {
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = var.public_subnet_ids[*]
  enable_deletion_protection = false
  #Lots of death and suffering here, make sure it's false

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
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  depends_on = [
    var.aws_acm_certificate_validation
  ]
}
