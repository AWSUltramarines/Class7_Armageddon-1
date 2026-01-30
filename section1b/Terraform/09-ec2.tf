resource "aws_instance" "web-lab-app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  associate_public_ip_address = true
  instance_type               = var.INSTANCE_TYPE
  security_groups             = [aws_security_group.web-lab-app-sg.id]
  iam_instance_profile        = aws_iam_instance_profile.armageddon-ec2-db-profile.name
  subnet_id                   = aws_subnet.public-virginia-east1a.id
  user_data                   = templatefile("./scripts/user_data.sh", {
    ENV_AWS_REGION = var.AWS_REGION,
    ENV_SECRET_NAME = var.SECRET_NAME,
    ENV_DB_NAME = var.DB_NAME
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-lab-app"
    }
  )
}