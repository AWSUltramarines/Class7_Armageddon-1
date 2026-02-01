locals {
  name_prefix = var.project_name
}

resource "aws_vpc" "liberdade_vpclab3" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name       = "liberdade-vpclab3"
    Compliance = "APPI-compute-only"
  }
}

resource "aws_internet_gateway" "liberdade_igwlab3" {
  vpc_id = aws_vpc.liberdade_vpclab3.id
  tags = { Name = "liberdade-igwlab3" }
}

resource "aws_subnet" "liberdade_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.liberdade_vpclab3.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "liberdade-public-subnet0${count.index + 1}" }
}

resource "aws_subnet" "liberdade_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.liberdade_vpclab3.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = { Name = "liberdade-private-subnet0${count.index + 1}" }
}

resource "aws_eip" "liberdade_nat_eiplab3" {
  domain = "vpc"
  tags = { Name = "liberdade-nat-eiplab3" }
}

resource "aws_nat_gateway" "liberdade_natlab3" {
  allocation_id = aws_eip.liberdade_nat_eiplab3.id
  subnet_id     = aws_subnet.liberdade_public_subnets[0].id
  tags = { Name = "liberdade-natlab3" }
  depends_on = [aws_internet_gateway.liberdade_igwlab3]
}

resource "aws_route_table" "liberdade_public_rtlab3" {
  vpc_id = aws_vpc.liberdade_vpclab3.id
  tags = { Name = "liberdade-public-rtlab3" }
}

resource "aws_route" "liberdade_public_default_route" {
  route_table_id         = aws_route_table.liberdade_public_rtlab3.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.liberdade_igwlab3.id
}

resource "aws_route_table_association" "liberdade_public_rta" {
  count          = length(aws_subnet.liberdade_public_subnets)
  subnet_id      = aws_subnet.liberdade_public_subnets[count.index].id
  route_table_id = aws_route_table.liberdade_public_rtlab3.id
}

resource "aws_route_table" "liberdade_private_rtlab3" {
  vpc_id = aws_vpc.liberdade_vpclab3.id
  tags = { Name = "liberdade-private-rtlab3" }
}

resource "aws_route" "liberdade_private_default_route" {
  route_table_id         = aws_route_table.liberdade_private_rtlab3.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.liberdade_natlab3.id
}

resource "aws_route_table_association" "liberdade_private_rta" {
  count          = length(aws_subnet.liberdade_private_subnets)
  subnet_id      = aws_subnet.liberdade_private_subnets[count.index].id
  route_table_id = aws_route_table.liberdade_private_rtlab3.id
}

