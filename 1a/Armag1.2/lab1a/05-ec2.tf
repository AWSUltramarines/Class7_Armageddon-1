#EC2 instance running the Flask notes application

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

# SAVE the private key to a local file
resource "local_file" "ssh_key" {
  content         = tls_private_key.ec2_ssh.private_key_pem
  filename        = "${path.module}/key.pem"
  file_permission = "0400" # Sets security permissions automatically
}

# Runs 'chmod 400' on your computer whenever the key changes (Best for detroying and rebuilding. LAB ONLY for now)
resource "null_resource" "fix_permissions" {
  # Makes the command run every time the key data changes
  triggers = {
    always_run = tls_private_key.ec2_ssh.private_key_pem
  }

  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/key.pem"
    
    # Ensures it uses Git Bash to run the command on Windows
    interpreter = ["bash", "-c"]
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
  # AMI ID hardcoded for the lab to match exsisting ec2 built in the AWS Console
  ami                    = "ami-07ff62358b87c7116"
  instance_type          = var.instance_type
  # Subnet hardcoded for the lab to match exsisting ec2 built in the AWS Console
  subnet_id              = "subnet-0d3095940f33e1a2c"
  # SG ID hardcoded for the lab to match exsisting ec2 built in the AWS Console
  vpc_security_group_ids = ["sg-04e352e9bcd676d86"]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  key_name = aws_key_pair.ec2.key_name

  # User data script to install and run Flask app
  user_data_base64 = filebase64("./1a_user_data.sh")

  # Root volume configuration
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = false
    delete_on_termination = true
  
  
}

   lifecycle {
    ignore_changes = [user_data, user_data_base64, user_data_replace_on_change]
}

  # Disable detailed monitoring for free tier
  monitoring = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only for security
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "armag1"
  }

  # Ensure secrets and RDS are available before EC2 starts
  depends_on = [
    aws_secretsmanager_secret_version.db_credentials,
    aws_db_instance.mysql
  ]
}
