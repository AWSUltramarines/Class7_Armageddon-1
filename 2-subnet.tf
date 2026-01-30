##########Public subnets################ (Public Subnets for EC2)
resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.armageddon.id # get VPC ID and add it here
# step 1: make VPC
# step 2: get VPC ID
# step 3: add VPC ID into vpc_id argument in this subnet
  # which VPC to create subnet in

  cidr_block = "10.97.1.0/24"
  availability_zone = "us-east-2a" # specify az
  map_public_ip_on_launch = true # allow public IPs to be assigned
  tags = {
    Name = "public-subnet-us-east-2a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.armageddon.id # get VPC ID and add it here
# step 1: make VPC
# step 2: get VPC ID
# step 3: add VPC ID into vpc_id argument in this subnet

  # which VPC to create subnet in

  cidr_block = "10.97.2.0/24"
  availability_zone = "us-east-2b" # specify az
  map_public_ip_on_launch = true # allow public IPs to be assigned
  tags = {
    Name = "public-subnet-us-east-2b"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id     = aws_vpc.armageddon.id # get VPC ID and add it here
# step 1: make VPC
# step 2: get VPC ID
# step 3: add VPC ID into vpc_id argument in this subnet

  # which VPC to create subnet in

  cidr_block = "10.97.3.0/24"
  availability_zone = "us-east-2c" # specify az
  map_public_ip_on_launch = true # allow public IPs to be assigned
  tags = {
    Name = "public-subnet-us-east-2c"
  }
}
##########Private subnets################ (For RDS database)
resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.armageddon.id # get VPC ID and add it here
# step 1: make VPC
# step 2: get VPC ID
# step 3: add VPC ID into vpc_id argument in this subnet
  # which VPC to create subnet in

  cidr_block = "10.97.11.0/24"
  availability_zone = "us-east-2a" # specify az
  map_public_ip_on_launch = false  # allow public IPs to be assigned
  tags = {
    Name = "private-subnet-us-east-2a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.armageddon.id # get VPC ID and add it here
# step 1: make VPC
# step 2: get VPC ID
# step 3: add VPC ID into vpc_id argument in this subnet

  # which VPC to create subnet in

  cidr_block = "10.97.12.0/24"
  availability_zone = "us-east-2b" # specify az
  map_public_ip_on_launch = false 
  tags = {
    Name = "private-subnet-us-east-2b"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id     = aws_vpc.armageddon.id # get VPC ID and add it here
# step 1: make VPC
# step 2: get VPC ID
# step 3: add VPC ID into vpc_id argument in this subnet

  # which VPC to create subnet in

  cidr_block = "10.97.13.0/24"
  availability_zone = "us-east-2c" # specify az
  map_public_ip_on_launch = false 
  tags = {
    Name = "private-subnet-us-east-2c"
  }
}

