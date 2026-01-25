resource "aws_subnet" "dev" {
  for_each = var.subnets

  vpc_id            = aws_vpc.dev.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    # Return map key found in main.tf and add text to tag for each subnet
    # Return subnet type for each subnet
    Name      = "${local.name_prefix}-${each.key}"
    Type      = each.value.type
    Terraform = local.terraform_tag
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${local.name_prefix}-rds-subnet-group"
  subnet_ids = values(local.private_subnets)[*].id

  tags = {
    Name      = "${local.name_prefix}-db-subnet-group"
    Terraform = local.terraform_tag
  }
}
