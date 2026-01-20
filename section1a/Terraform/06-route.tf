# Public Route Table
# Routes traffic from public subnets to the internet gateway
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.armageddon-world-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "armageddon-world-vpc public route"
        Type = "Public"
    }
}

# Private Route Table
# Routes traffic from private subnets to the NAT gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.armageddon-world-vpc.id


  tags = {
    Name = "armageddon-world-vpc private route"
    Type = "Private"
  }
}

# Route table associations for public subnets
resource "aws_route_table_association" "public-virginia-east1a" {
  subnet_id      = aws_subnet.public-virginia-east1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-virginia-east1b" {
  subnet_id      = aws_subnet.public-virginia-east1b.id
  route_table_id = aws_route_table.public.id
}

# Route table associations for private subnets
resource "aws_route_table_association" "private-virginia-east1a" {
  subnet_id      = aws_subnet.private-virginia-east1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-virginia-east1b" {
  subnet_id      = aws_subnet.private-virginia-east1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_db_subnet_group" "db_mysql_subnet" {
  name = "db_mysql_subnet"
  description = "Subnet for RDS (MySQL) on private network"
  subnet_ids = [aws_subnet.private-virginia-east1a.id, aws_subnet.private-virginia-east1b.id]
}

