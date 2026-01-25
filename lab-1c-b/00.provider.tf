provider "aws" {
  region = var.region
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
    bucket = "armageddon-test-2026" # free tier account
    # bucket = "armageddon-prod-2026" # production account
    key    = "path/to/armageddon1c-b/terraform.tfstate"
    region = "sa-east-1" # free tier account
    # region = "us-east-2" # production account
  }
}
