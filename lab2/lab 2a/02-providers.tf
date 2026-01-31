provider "aws" {
  region = "us-east-1"
  # We need an alias for CloudFront (global service)
  alias  = "us_east_1"
  
}

