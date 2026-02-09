#  Request Public Certificate
resource "aws_acm_certificate" "acm-cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = [var.app_subdomain]

lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = "Development"
  }
}

#  The Validation Logic (The "Gate")
resource "aws_acm_certificate" "cert_valid" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    var.app_subdomain
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "flask-app-cert"
    Environment = "Development"
  }
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

/*
Note: This is a generated HCL content from the JSON input which is based on the latest API version available.
To import the resource, please run the following command:
terraform import azapi_resource. ?api-version=TODO

Or add the below config:
import {
  id = "?api-version=TODO"
  to = azapi_resource.
}
*/

