######################################
### Data Sources
######################################
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}
######################################
######### Request an SSL Certificate from ACM
resource "aws_acm_certificate" "cert" {
  domain_name       = "app.${data.aws_route53_zone.main.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS records to validate that you own the domain
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Wait for the certificate to be issued
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Creating Route53 record to point to the ALB
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.${data.aws_route53_zone.main.name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}