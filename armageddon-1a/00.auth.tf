provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket = "scales-test-bucket1"
    # bucket = "rvp-web-images"
    key    = "path/to/1626/key"
    region = "sa-east-1"
  }

}
