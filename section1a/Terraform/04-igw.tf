##internet gateway##
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.armageddon-world-vpc.id

    tags = {
        Name = "igw"
    }
}