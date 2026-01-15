resource "aws_instance" "test_server" {
  ami             = data.aws_ssm_parameter.al2023.value
  instance_type   = "t3.micro"
  subnet_id       = local.public_subnet_ids[0]
  security_groups = [aws_security_group.compute_sg.id]

  user_data_base64     = filebase64("${path.root}/userdata.sh")
  iam_instance_profile = aws_iam_instance_profile.compute2secrets_profile.name

  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name      = "${local.name_prefix}-web-server"
    Terraform = local.terraform_tag
  }
}

resource "aws_key_pair" "deployer" {
  public_key = file("${path.root}/${var.public_key}")
}