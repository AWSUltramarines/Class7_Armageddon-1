# Explanation: CloudFront is the only public doorway — Chewbacca stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-cf01"

  origin {
    origin_id   = "${var.project_name}-alb-origin01"
    domain_name = aws_lb.alb01.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Explanation: CloudFront whispers the secret growl — the ALB only trusts this.
    custom_header {
      name  = "X-Jasongeddon-Growl"
      value = random_password.origin_header_value01.result
    }
  }

  # Default behavior is conservative — assumes dynamic/API until proven static.
  default_cache_behavior {
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api01.id

    # Replaced by cache_policy_id and origin_request_policy_id above —
    # forwarded_values and cache policies are mutually exclusive in CloudFront.
    # forwarded_values {
    #   query_string = true
    #   headers      = ["*"]
    #   cookies { forward = "all" }
    # }
  }

  # Static behavior is the speed lane — aggressive caching for /static/* assets.
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.rsp_static01.id
  }

  # Honors: Public feed uses origin-driven caching — CloudFront honors Cache-Control from origin.
  # If origin sends s-maxage=30, CloudFront caches 30s. No Cache-Control = no caching.
  ordered_cache_behavior {
    path_pattern           = "/api/public-feed"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.use_origin_cache_headers01.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.orp_all_viewer_except_host01.id
  }

  # API catch-all — safe default (no caching), forwards all needed context.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.orp_api01.id
  }

  # Explanation: Attach WAF at the edge — now WAF moved to CloudFront.
  web_acl_id = aws_wafv2_web_acl.cf_waf01.arn

  # TODO: students set aliases for chewbacca-growl.com and app.chewbacca-growl.com
  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  # Using existing ACM cert (acm_cert01) directly — it already covers both
  # app.jason-cramer.com and jason-cramer.com, and is in us-east-1 as CloudFront requires.
  # Original template used var.cloudfront_acm_cert_arn, but a separate variable is unnecessary.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.acm_validation01.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Variable below not needed — using existing acm_cert01 which already covers
# both domains and is in us-east-1 (required by CloudFront).
# variable "cloudfront_acm_cert_arn" {
#   description = "ACM certificate ARN in us-east-1 for CloudFront."
#   type        = string
# }

