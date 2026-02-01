/* ############################################
# BONUS C: Route53 Hosted Zone + DNS Validation + ALIAS
############################################

locals {
  helga_zone_id   = var.route53_hosted_zone_id #? aws_route53_zone.helga_zonelab3[0].zone_id : var.route53_hosted_zone_id
  helga_app_fqdn  = "${var.app_subdomain}.${var.domain_name}"
}

############################################
# Hosted Zone (if managed by Terraform)
############################################

resource "aws_route53_zone" "helga_zonelab3" {
  count = var.manage_route53_in_terraform ? 1 : 0
  name  = var.domain_name

  tags = { Name = "${var.project_name}-zonelab3" }
}
  #zone_id = "Z00908063NUR2ECTZKXUK" # Replace with your Route53 Hosted Zone ID

/* resource "aws_acm_certificate" "helga_cf_certlab3" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = [local.helga_app_fqdn]
  validation_method         = "DNS"

  tags = { Name = "${var.project_name}-cf-certlab3" }

  lifecycle {
    create_before_destroy = true
  }
} */

/* # DNS Validation Records
resource "aws_route53_record" "helga_cf_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.helga_cf_certlab3.domain_validation_options : dvo.domain_name => {
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
  zone_id         = local.helga_zone_id
}

resource "aws_acm_certificate_validation" "helga_cf_cert_validationlab3" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.helga_cf_certlab3.arn
  validation_record_fqdns = [for record in aws_route53_record.helga_cf_cert_validation : record.fqdn]
} 

############################################
# LAB 2A: ROUTE53 ALIAS RECORDS → CLOUDFRONT
############################################

# Apex record (williebright.com → CloudFront)
resource "aws_route53_record" "helga_apex_cf_aliaslab3" {
  zone_id = local.helga_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.helga_cf_distlab3.domain_name
    zone_id                = aws_cloudfront_distribution.helga_cf_distlab3.hosted_zone_id
    evaluate_target_health = false
  }
}

# App subdomain record (app.williebright.com → CloudFront)
resource "aws_route53_record" "helga_app_cf_alias01" {
  zone_id = local.helga_zone_id
  name    = local.helga_app_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.helga_cf_distlab3.domain_name
    zone_id                = aws_cloudfront_distribution.helga_cf_distlab3.hosted_zone_id
    evaluate_target_health = false
  }
} 
*/