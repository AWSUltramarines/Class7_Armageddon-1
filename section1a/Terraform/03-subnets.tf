# Public Subnets
# These subnets have direct internet access via the internet gateway

resource "aws_subnet" "public-virginia-east1a" {
  vpc_id                  = aws_vpc.armageddon-world-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "armegeddon public-virginia-east1a"
    Type = "Public"
  }
}

resource "aws_subnet" "public-virginia-east1b" {
  vpc_id                  = aws_vpc.armageddon-world-vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "armageddon public-virginia-east1b"
    Type = "Public"
  }
}

# Private Subnets
# These subnets do not have direct internet access
# They can reach the internet through the NAT gateway

resource "aws_subnet" "private-virginia-east1a" {
  vpc_id            = aws_vpc.armageddon-world-vpc.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "armageddon private-virginia-east1a"
    Type = "Private"
  }
}

resource "aws_subnet" "private-virginia-east1b" {
  vpc_id            = aws_vpc.armageddon-world-vpc.id
  cidr_block        = "10.10.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "armageddon private-virginia-east1b"
    Type = "Private"
  }
}
