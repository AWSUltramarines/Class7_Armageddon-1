# Terraform configuration block
# This defines the minimum Terraform version and required providers
terraform {
  required_version = ">= 1.0" 
    
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

#AWS Provider configuration
#This tells Terraform how to connect to aws

provider "aws" { 
  region = "us-east-1"
  profile = "default"


# Default tags are applied to all resources created by this provider
# default_tags {
#   tags = {
#        Project = "vpc-demo"
#        Environmental = "dev"
#        ManagedBy     = "Terraform"
#      } 
#    }
}