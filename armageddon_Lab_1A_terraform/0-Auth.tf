# Terraform configuration block
# This defines the minimum Terraform version and required providers
terraform {
  required_version = ">= 1.0" 
    
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
 # Add this block if you actually need azapi
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.0" 
    }
  }
}

#AWS Provider configuration
#This tells Terraform how to connect to aws

provider "aws" { 
  region = "us-east-1"
  profile = "default"

}
provider "aws" {
  alias  = "dns_account"
  region = "us-east-1" # or whatever region you used
  # ... include necessary auth/profile details
}