resource "aws_route_table" "private" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name      = "${local.name_prefix}-rt-private"
    Terraform = local.terraform_tag
  }
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.dev[each.key].id
  route_table_id = aws_route_table.private.id
}