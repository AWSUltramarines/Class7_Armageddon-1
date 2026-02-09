# ALB Security Group (Internet -> ALB)
resource "aws_security_group" "alb_sg" {
  name        = "ras-colservices-alb-sg"
  vpc_id      = aws_vpc.armageddon-VPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The Load Balancer
resource "aws_lb" "ras-colservices_alb" {
  name               = "ras-colservices-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public-us-east-1a.id, aws_subnet.public-us-east-1b.id]
}

# Target Group (ALB -> EC2)
resource "aws_lb_target_group" "flask_tg" {
  name     = "flask-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.armageddon-VPC.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attachment
resource "aws_lb_target_group_attachment" "flask_attachment" {
  target_group_arn = aws_lb_target_group.flask_tg.arn
  target_id        = aws_instance.arm_ec2.id
  port             = 80
}