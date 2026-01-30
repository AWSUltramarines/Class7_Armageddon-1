resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.armageddon.id

  tags = {
    Name = "armageddon_IGW"
  }
}