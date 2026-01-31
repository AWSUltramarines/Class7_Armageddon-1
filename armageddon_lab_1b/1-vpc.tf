# VPC resource
# This creates the virtual private cloud
resource "aws_vpc" "armageddon" {
  
  # region = ""
  
  cidr_block           = "10.77.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
  
  tags = {
    Name = "Armageddon-vpc"
  }

}