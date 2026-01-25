######################################
### Data Sources & Locals
######################################
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

locals {
  app_fqdn  = "${var.app_subdomain}.${var.domain_name}"
  zone_name = var.domain_name
  zone_id   = data.aws_route53_zone.main.zone_id
}
######################################
######### Request an SSL Certificate from ACM for domain and subdomain
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = [local.app_fqdn]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS records to validate that you own the domain
resource "aws_route53_record" "cert_validation" {
  for_each = var.certificate_validation_method == "DNS" ? {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Wait for the certificate to be issued
resource "aws_acm_certificate_validation" "cert" {
  count = var.certificate_validation_method == "DNS" ? 1 : 0

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Create Route53 Record to point to ALB
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.app_fqdn
  type    = "A"

  alias {
    name                   = var.alb.dns_name
    zone_id                = var.alb.zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "apex_alias" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb.dns_name
    zone_id                = var.alb.zone_id
    evaluate_target_health = true
  }
}