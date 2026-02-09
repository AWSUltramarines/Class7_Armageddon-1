data "aws_caller_identity" "current" {}

locals {
  services = ["ssm", "ssmmessages", "ec2messages", "logs", "secretsmanager", "kms"]
}