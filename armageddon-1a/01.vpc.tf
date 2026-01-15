resource "aws_vpc" "dev" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name      = "${local.name_prefix}-vpc"
    Terraform = local.terraform_tag
  }
}

# resource "aws_vpc_endpoint" "vpce_ssm" {
#   vpc_id            = aws_vpc.dev.id
#   service_name      = "com.amazonaws.${var.region}.ssm"
#   vpc_endpoint_type = "Interface"
#   subnet_ids        = values(local.private_subnets)[*].id
#   security_group_ids = [
#     aws_security_group.dev.id,
#   ]

#   tags = {
#     Name      = "${local.name_prefix}-vpce-ssm"
#     Terraform = local.terraform_tag
#   }
# }