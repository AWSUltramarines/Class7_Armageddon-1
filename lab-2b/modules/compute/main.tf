############################################
# Locals & Data
############################################
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-x86_64-gp2"
}
############################################
# EC2 Instance
############################################
resource "aws_instance" "test_server" {
  ami             = data.aws_ssm_parameter.al2023.value
  instance_type   = var.instance_type
  subnet_id       = var.private_subnet_ids[0]
  security_groups = [var.compute_sg_id]

  user_data_base64 = base64encode(templatefile("${path.root}/userdata-caching.sh", {
    cf_header_pw = var.cf_header_pw
    secret_name  = var.secret_name
  }))

  iam_instance_profile = var.iam_instance_profile

  # no public ip
  associate_public_ip_address = false

  tags = {
    Name      = "${var.name_prefix}-web-server"
    Terraform = var.terraform_tag
  }

}
############################################
# Target Group
############################################
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
############################################
# Launch Template
############################################
resource "aws_launch_template" "dev_lt" {
  image_id      = aws_instance.test_server.ami
  instance_type = var.instance_type

  # key_name = "MyLinuxBox"

  vpc_security_group_ids = [var.compute_sg_id]

  user_data = base64encode(templatefile("${path.root}/userdata-caching.sh", {
    cf_header_pw = var.cf_header_pw
    secret_name  = var.secret_name
  }))

  iam_instance_profile {
    name = var.iam_instance_profile
  }

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