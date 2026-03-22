# Required provider versions — pins AWS, TLS, and Random to specific versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.18.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Primary AWS provider — deploys resources in the Tokyo region (ap-northeast-1)
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# Secondary provider specifically for the CloudFront Certificate
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# Remote state backend — stores Tokyo Terraform state in S3 (us-east-2)
terraform {
  backend "s3" {
    bucket = "rds-secret-config"
    key    = "states/tokyo3a/terraform.tfstate" # path to the state file inside the S3 bucket
    region = "us-east-2"
  }
}