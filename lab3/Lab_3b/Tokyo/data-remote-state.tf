data "aws_ec2_transit_gateway" "saopaulo_tgw" {
  provider = aws.saopaulo   # needs a provider alias for sa-east-1

  filter {
    name   = "tag:Name"
    values = ["liberdade-tgwlab3"]
  }

  filter {
    name   = "state"
    values = ["available", "pendingAcceptance"]
  }
}