resource "aws_subnet" "dev" {
  for_each = var.subnets

  vpc_id            = aws_vpc.dev.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  # Check if subnet type is == public
  # Ternary logic: if the condition is true return true, else false
  map_public_ip_on_launch = each.value.type == "public" ? true : false

  tags = {
    # Return map key found in main.tf and add text to tag for each subnet
    # Return subnet type for each subnet
    Name      = "${local.name_prefix}-${each.key}"
    Type      = each.value.type
    Terraform = local.terraform_tag
  }
}
