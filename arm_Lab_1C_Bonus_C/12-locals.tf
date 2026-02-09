data "aws_caller_identity" "current" {}

locals {
  services = ["ssm", "ssmmessages", "ec2messages", "logs", "secretsmanager", "kms"]
}

data "aws_route53_zone" "main" {
  name         = "rascollectiveservices.click"
  private_zone = false
}

locals {
  # Logic to determine which Zone ID to use
  rascollectiveservices_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.app_dns[0].zone_id : var.route53_hosted_zone_id
  rascollectiveservices_app_fqdn = "${var.app_subdomain}"
}

