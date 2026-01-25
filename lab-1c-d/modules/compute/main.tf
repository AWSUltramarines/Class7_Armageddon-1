############################################
# Locals & Data
############################################
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-x86_64-gp2"
}
############################################
resource "aws_instance" "test_server" {
  ami             = data.aws_ssm_parameter.al2023.value
  instance_type   = var.instance_type
  subnet_id       = var.private_subnet_ids[0]
  security_groups = [var.compute_sg_id]

  user_data_base64     = filebase64("${path.root}/userdata.sh")
  iam_instance_profile = var.iam_instance_profile

  # no public ip
  associate_public_ip_address = false

  tags = {
    Name      = "${var.name_prefix}-web-server"
    Terraform = var.terraform_tag
  }

  # depends_on = [
  #   aws_secretsmanager_secret_version.db_credentials,
  #   aws_db_instance.mysql,
  #   aws_nat_gateway.main
  # ]
}


resource "aws_lb_target_group" "dev_tg" {
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.name_prefix}-target-group"
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.dev_tg.arn
  target_id        = aws_instance.test_server.id
  port             = 80
}

resource "aws_launch_template" "dev_lt" {
  image_id      = aws_instance.test_server.ami
  instance_type = var.instance_type

  # key_name = "MyLinuxBox"

  vpc_security_group_ids = [var.alb_sg_id]

  user_data = filebase64("${path.root}/userdata.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-launch-template-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}