terraform{
    required_version = ">= 1.0"

    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
      }
    }
}

terraform {
  backend "s3" {
    bucket = "11-29-2025-i-am-learning-terraform"
    key = "path/to/my/key/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}