# Sao Paulo provider
provider "aws" {
  alias  = "saopaulo"
  region = "sa-east-1"
}

# US-East-1 provider — required for CloudFront-scoped WAF and ACM certs
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}


# Provider Variable

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
