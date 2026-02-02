# VPC

resource "aws_vpc" "armageddon-VPC" {
  cidr_block           = "10.66.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc"
  }
}

# Internet Gateway for public subnet internet access

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.armageddon-VPC.id

  tags = {
    Name    = "igw"
  }
}

#This is a public subnet

resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.armageddon-VPC.id
  cidr_block              = "10.66.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "public-us-east-1a"
  
  }
}

resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = aws_vpc.armageddon-VPC.id
  cidr_block              = "10.66.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "public-us-east-1b"
  
  }
}


#This is a private subnet

resource "aws_subnet" "private-us-east-1a" {
  vpc_id                  = aws_vpc.armageddon-VPC.id
  cidr_block              = "10.66.11.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    Name    = "private-us-east-1a"
  
  }
}

resource "aws_subnet" "private-us-east-1b" {
  vpc_id                  = aws_vpc.armageddon-VPC.id
  cidr_block              = "10.66.12.0/24"
  availability_zone       = "us-east-1b"

  tags = {
    Name    = "private-us-east-1b"
  
  }
}


# Public route table with internet gateway route

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.armageddon-VPC.id

  tags = {
    Name = "public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public.id
}

# Private route table - no internet route 

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.armageddon-VPC.id

  tags = {
    Name = "private"
  }
}

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private-us-east-1b.id
  route_table_id = aws_route_table.private.id
}

# DB Subnet Group for RDS - requires subnets in at least 2 AZs

resource "aws_db_subnet_group" "db_mysql_subnet1" {
  name       = "db-subnet-group"
  description = "Subnet group for RDS MySQL in private subnets"
  subnet_ids = [aws_subnet.private-us-east-1b.id, aws_subnet.private-us-east-1a.id]

  tags = {
    Name = "My DB subnet group"
  }
}





