############################################
# SAO PAULO EC2 + IAM FOR TGW TESTING
# Stateless compute only - NO PHI storage
# Use SSM Session Manager to connect, then:
#   nc -vz <tokyo-rds-endpoint> 3306
############################################

# Latest Amazon Linux 2023 AMI for sa-east-1
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

############################################
# IAM Role for SSM Session Manager access
############################################

resource "aws_iam_role" "liberdade_ec2_rolelab3" {
  count = var.enable_tgw ? 1 : 0

  name = "${var.project_name}-ec2-rolelab3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-ec2-rolelab3"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "liberdade_ssm_policylab3" {
  count = var.enable_tgw ? 1 : 0

  role       = aws_iam_role.liberdade_ec2_rolelab3[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "liberdade_ec2_profilelab3" {
  count = var.enable_tgw ? 1 : 0

  name = "${var.project_name}-ec2-profilelab3"
  role = aws_iam_role.liberdade_ec2_rolelab3[0].name
}

############################################
# EC2 Instance in Private Subnet
# Connects to Tokyo RDS via TGW
############################################

resource "aws_instance" "liberdade_ec2lab3" {
  count = var.enable_tgw ? 1 : 0

  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.liberdade_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.liberdade_ec2_sglab3[0].id]
  iam_instance_profile   = aws_iam_instance_profile.liberdade_ec2_profilelab3[0].name

  tags = {
    Name       = "liberdade-ec2lab3"
    Project    = var.project_name
    Compliance = "APPI-stateless-compute"
  }
}
