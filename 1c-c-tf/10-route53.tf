# Point app.daequanbritt.com to the ALB
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.${data.aws_route53_zone.main.name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Hosted Zone Management
# If manage_route53_in_terraform is true, we create a new zone.
# Otherwise, we look up the existing one.
resource "aws_route53_zone" "daequan_zone" {
  count = var.manage_route53_in_terraform ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${var.project_name}-${var.environment}-hosted-zone"
  }
}

locals {
  # Logic to determine which Zone ID to use
  daequan_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.daequan_zone[0].zone_id : data.aws_route53_zone.main.zone_id
  daequan_app_fqdn = "${var.subdomain_name}.${var.domain_name}"
}

# ALIAS Record: app.daequanbritt.com -> ALB
# This is the "holographic sign" pointing users to your secure entry point.
resource "aws_route53_record" "daequan_app_alias" {
  zone_id = local.daequan_zone_id
  name    = local.daequan_app_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}