resource "aws_vpc" "armageddon" {
  cidr_block       = "10.97.0.0/16"
  instance_tenancy = "default" #optional. default option is setting this argument to default
  enable_dns_hostnames = true
  enable_dns_support = true # (Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults to true.

  tags = {
    Name = "armageddon-vpc"
  }
}

