# alb.tf - Application Load Balancer (public_alb mode only)
#
# In public_alb mode: ALB provides internet-facing access to EC2 in private subnet
# In airgap mode: ALB resources are NOT created (access via SSM port forwarding)

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "app" {
  count = local.is_airgap ? 0 : 1

  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
  idle_timeout               = var.alb_idle_timeout

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

# -----------------------------------------------------------------------------
# Target Group
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "app" {
  count = local.is_airgap ? 0 : 1

  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tg"
  })
}

# -----------------------------------------------------------------------------
# Target Group Attachment (requires both ALB and EC2)
# -----------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "ec2" {
  count = (!local.is_airgap && var.enable_ec2) ? 1 : 0

  target_group_arn = aws_lb_target_group.app[0].arn
  target_id        = aws_instance.web[0].id
  port             = 80
}

# -----------------------------------------------------------------------------
# HTTP Listener
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  count = local.is_airgap ? 0 : 1

  load_balancer_arn = aws_lb.app[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-listener-http"
  })
}
