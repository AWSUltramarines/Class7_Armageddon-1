# locals.tf - Local values for repeated references and computed values

locals {
    # Naming prefix for all resources
    name_prefix = var.PROJECT_NAME != "" ? var.PROJECT_NAME : "lab"

    # Common tags applied to resources (in addition to provider default_tags)
    common_tags = {
        Project = var.PROJECT_NAME
        Environment = var.ENVIRONMENT
    }

    # Availability zones - use first two in the region
    azs = slice(data.aws_availability_zones.available.names, 0, 2)

    # Subnet CIDR calculations
#    public_subnet_cidrs  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i)]
#    private_subnet_cidrs = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 100)]

    # SSH enabled flag
#    ssh_enabled = var.ssh_allowed_cidr != ""
    
    # ARNs for IAM policy variables
    db_secret_arn = "arn:aws:secretsmanager:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:secret:${var.SECRET_NAME}*"
    parmstore_arn = "arn:aws:ssm:${var.AWS_REGION}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
}
# Who is the current AWS caller?
data "aws_caller_identity" "current" {}

# What is the current AWS region?
data "aws_region" "current" {}


# Data source to get available AZs
data "aws_availability_zones" "available" {
    state = "available"

    filter {
        name   = "opt-in-status"
        values = ["opt-in-not-required"]
    }
}

# Data source to get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["al2023-ami-2023.*-x86_64"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
}