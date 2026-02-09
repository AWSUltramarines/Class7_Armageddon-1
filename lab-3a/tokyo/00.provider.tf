provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
terraform {
  backend "s3" {
    # bucket = "scales-test-bucket1" # free tier account
    bucket = "armageddon-prod-2026" # production account
    key    = "path/to/lab3a-tokyo/terraform.tfstate"
    # region = "sa-east-1" # free tier account
    region = "us-east-1" # production account
  }
}
