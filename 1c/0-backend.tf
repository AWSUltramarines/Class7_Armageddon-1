terraform {
  backend "s3" {
    bucket = "walid-backend-089.com"
    key    = "lab1c-terraform.tfstate"
    region = "us-east-1"
  }
}
