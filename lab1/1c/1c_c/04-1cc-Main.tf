/*############################################
# BONUS C: Route53 Hosted Zone + DNS Validation + ALIAS
############################################

locals {
  helga_zone_id   = var.manage_route53_in_terraform ? aws_route53_zone.helga_zone01[0].zone_id : var.route53_hosted_zone_id
  helga_app_fqdn  = "${var.app_subdomain}.${var.domain_name}"
}

############################################
# Hosted Zone (if managed by Terraform)
############################################

resource "aws_route53_zone" "helga_zone01" {
  count = var.manage_route53_in_terraform ? 1 : 0
  name  = var.domain_name

  tags = { Name = "${var.project_name}-zone01" }
}

############################################
# ACM DNS Validation Records
############################################

resource "aws_route53_record" "helga_acm_validation_records01" {
  for_each = var.manage_route53_in_terraform ? {
    for dvo in aws_acm_certificate.helga_acm_cert01.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = local.helga_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "helga_acm_validation01_dns" {
  count = var.manage_route53_in_terraform ? 1 : 0

  certificate_arn         = aws_acm_certificate.helga_acm_cert01.arn
  validation_record_fqdns = [for record in aws_route53_record.helga_acm_validation_records01 : record.fqdn]
}

############################################
# ALIAS Record: app.williebright.com → ALB
############################################

resource "aws_route53_record" "helga_app_alias01" {
  zone_id = "Z00908063NUR2ECTZKXUK" # Replace with your Route53 Hosted Zone ID
  name    = "app.williebright.com"
  type    = "A"

  alias {
    name                   = aws_lb.helga_alb01.dns_name
    zone_id                = aws_lb.helga_alb01.zone_id
    evaluate_target_health = true
  }
}
*/
