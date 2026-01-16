EC2 instance running the Flask notes application

# Generate SSH key pair for EC2 access
resource "tls_private_key" "ec2_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "ec2" {
  key_name   = "ec2-key"
  public_key = tls_private_key.ec2_ssh.public_key_openssh

  tags = {
    Name = "ec2-key"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    # This wildcard finds the latest version of AL2023 for standard x86 processors
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = aws_key_pair.ec2.key_name

  # User data script to install and run Flask app
  user_data_base64 = filebase64("./1a_user_data_tf.sh")

  # Root volume configuration
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Disable detailed monitoring for free tier
  monitoring = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only for security
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "web"
  }

  # Ensure secrets and RDS are available before EC2 starts
  depends_on = [
    aws_secretsmanager_secret_version.db_credentials,
    aws_db_instance.mysql
  ]
}
