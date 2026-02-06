# ================================================================ #
# CLOUDFRONT CACHE POLICIES - REMOVED FOR SÃO PAULO
# ================================================================ #
# São Paulo uses Tokyo's CloudFront as the global entry point,
# so no CloudFront cache policies are needed here.
# ================================================================ #

# resource "aws_cloudfront_cache_policy" "static_optimized" { ... }
# resource "aws_cloudfront_cache_policy" "api_disabled" { ... }
# resource "aws_cloudfront_origin_request_policy" "api_request" { ... }
# resource "aws_cloudfront_response_headers_policy" "static_security" { ... }
# data "aws_cloudfront_cache_policy" "managed_optimized" { ... }
