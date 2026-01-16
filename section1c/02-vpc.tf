resource "aws_vpc" "armageddon-world-vpc" {
    cidr_block = "10.10.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name="armageddon-world-vpc"
        Service="vpc"
        Owner="Jamal O.Waring"
    }
}