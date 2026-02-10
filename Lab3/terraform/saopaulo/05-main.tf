# EC2 instance running the Flask notes application
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

# Private EC2 instance running the Flask web app — connects to Tokyo RDS via Transit Gateway
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private[0].id

  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # no public ip
  associate_public_ip_address = false

  # User data script to install and run Flask app
  user_data_base64 = filebase64("./scripts/user_data.sh")

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
    Name = "${var.project_name}-${var.environment}-web"
  }

  # Ensure secrets, RDS, and NAT Gateway are available before EC2 starts
  depends_on = [
    aws_secretsmanager_secret_version.db_credentials,
    # aws_db_instance.mysql,
    aws_nat_gateway.main
  ]
}

# ================================================================ #
# REMOTE STATE - Read Tokyo Outputs
# ================================================================ #

# Read Tokyo's Terraform outputs (RDS endpoint, TGW ID, etc.) from remote state
data "terraform_remote_state" "tokyo" {
  backend = "s3"

  config = {
    bucket = "rds-secret-config"
    key    = "states/tokyo3a/terraform.tfstate"
    region = "us-east-2"
  }
}
