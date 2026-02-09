#  Request Public Certificate
resource "aws_acm_certificate" "acm-cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = [var.app_subdomain]

  lifecycle {
    create_before_destroy = true
  }
}

#  The Validation Logic (The "Gate")
resource "aws_acm_certificate_validation" "cert_valid" {
  certificate_arn         = "arn:aws:acm:us-east-1:914215748428:certificate/4d2a7208-eefc-4532-b30c-743ee3dddd37"
  # Ensure your validation_record_fqdns are also updated if necessary
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}



#  Hosted Zone (Assuming it's already created or creating new)
resource "aws_route53_zone" "app_dns" {
  name         = var.domain_name 
  count = var.manage_route53_in_terraform ? 1 : 0

  tags = {
    Project     = "Armageddon"
    Environment = "Development"
  }
}

#  Validation Record
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.acm-cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.main.id
}

# 4. ALB Alias Record (app.chewbacca-growl.com -> ALB)
resource "aws_route53_record" "app_dns" {
  zone_id = local.rascollectiveservices_zone_id
  name    = var.app_subdomain
  type    = "A"

  alias {
    name                   = aws_lb.ras-colservices_alb.dns_name
    zone_id                = aws_lb.ras-colservices_alb.zone_id
    evaluate_target_health = true
  }
}