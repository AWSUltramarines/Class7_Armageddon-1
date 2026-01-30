# Elastic IP setup (required)
resource "aws_eip" "eip" {
  domain           = "vpc"
  
  tags = {
    Name = "armageddon-eip-for-nat"

  }

  depends_on = [ aws_internet_gateway.igw ] # explicit dependency 
}

#And now, the NAT gateway setup
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id # implicit dependency
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "armageddon-nat-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}