# US-East-1 provider — required for CloudFront-scoped WAF and ACM certs
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

# AP-Northeast-1 is set as region on variables file

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
