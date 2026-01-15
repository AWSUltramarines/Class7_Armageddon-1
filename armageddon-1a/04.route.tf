resource "aws_route_table" "private" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block     = var.private_route_cidr
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name      = "${local.name_prefix}-rt-private"
    Terraform = local.terraform_tag
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = var.public_route_cidr
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "${local.name_prefix}-rt-public"
    Terraform = local.terraform_tag
  }
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.dev[each.key].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id = aws_subnet.dev[each.key].id

  route_table_id = aws_route_table.public.id
}