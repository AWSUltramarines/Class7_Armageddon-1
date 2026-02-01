/* data "aws_ec2_transit_gateway" "tokyo_tgw" {
  provider = aws.tokyo

  filter {
    name   = "tag:Name"
    values = ["shinjuku-tgwlab3"]
  }

  filter {
    name   = "state"
    values = ["available", "pendingAcceptance"]
  }
} */