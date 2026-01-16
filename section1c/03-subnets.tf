# Public Subnets
# These subnets have direct internet access via the internet gateway

resource "aws_subnet" "public-ohio-east1a" {
  vpc_id                  = aws_vpc.armageddon-world-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "armegeddon-public-subnet-1"
    Type = "Public"
  }
}

resource "aws_subnet" "public-ohio-east2b" {
  vpc_id                  = aws_vpc.armageddon-world-vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "armageddon-public-subnet-2"
    Type = "Public"
  }
}

# Private Subnets
# These subnets do not have direct internet access
# They can reach the internet through the NAT gateway

resource "aws_subnet" "private-ohio-east1a" {
  vpc_id            = aws_vpc.armageddon-world.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "armageddon-private-subnet-1"
    Type = "Private"
  }
}

resource "aws_subnet" "private-ohio-east2b" {
  vpc_id            = aws_vpc.armageddon-world-vpc.id
  cidr_block        = "10.10.12.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "armageddon-private-subnet-2"
    Type = "Private"
  }
}
