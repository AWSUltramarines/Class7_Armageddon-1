resource "aws_route53_record" "flask_app" {
  zone_id = aws_route53_zone.app_dns.zone_id
  name    = var.app_subdomain 
  type    = "A"

# This allows Terraform to take over existing records
  allow_overwrite = true

alias {
    name                   = aws_lb.ras-colservices_alb.dns_name
    zone_id                = aws_lb.ras-colservices_alb.zone_id
    evaluate_target_health = true
  }
}
