data "aws_caller_identity" "current" {}

locals {
  services = ["ssm", "ssmmessages", "ec2messages", "logs", "secretsmanager", "kms"]
}

data "aws_route53_zone" "main" {
  name         = "rascollectiveservices.click"
  private_zone = false
}