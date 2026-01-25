resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront for ${var.domain_name}"
  aliases         = [var.domain_name, "app.${var.domain_name}"]
  web_acl_id      = aws_wafv2_web_acl.cloudfront_waf.arn

  # Added: This is often required even for SPAs/Flask apps
  # default_root_object = "index.html"                     #####################################

  origin {
    domain_name = aws_lb.main.dns_name # Ensure your ALB resource is named 'main'
    origin_id   = "ALB-Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Custom-Header"
      value = random_password.origin_header.result
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-Origin"

    # Standard "No Caching" behavior for dynamic Flask apps
    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Accept"] # Crucial for ALB/App logic
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert_us_east_1.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}