# READ the existing VPC
data "aws_vpc" "armag1" {
  id = "vpc-06636904e621dfcf1"  # <--- REPLACE THIS with your actual VPC ID
}

# READ the existing Private Subnets
# This automatically finds all subnets in that VPC
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.armag1.id]
  }
  # If your private subnets have a specific tag (like "private"), uncomment this:
  # filter {
  #   name   = "tag:Name"
  #   values = ["*private*"]
  # }
}

# READ the existing Security Group (The one my EC2 uses)
data "aws_security_group" "app_sg" {
  filter {
    name   = "group-name"
    values = ["ec2_sg"]
  }
  vpc_id = data.aws_vpc.armag1.id
}

# DB Subnet Group - Modified to use the EXISTING subnets
resource "aws_db_subnet_group" "mysql" {
  name        = "armag1-subnet-group"
  description = "Subnet group for RDS MySQL"
  
  # Uses the data source ID, not the resource ID
  subnet_ids  = data.aws_subnets.private.ids

  tags = {
    Name = "armag1-subnet-group"
  }
}
