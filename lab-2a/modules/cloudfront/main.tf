#####################################################
##### CLOUDFRONT
#####################################################
resource "aws_cloudfront_distribution" "cf_distro" {
  enabled             = true
  is_ipv6_enabled     = true
  # comment             = "Some comment"
  web_acl_id  = var.cf_waf_acl_arn
  price_class = "PriceClass_100"

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "${var.name_prefix}-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    custom_header {
      name  = "X-Custom-Header"
      value = var.cf_header_pw
    }
  }

  default_cache_behavior {
    target_origin_id       = "${var.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}