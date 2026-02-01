output "cf_distro_dns_name" {
  value = aws_cloudfront_distribution.cf_distro.domain_name
}
output "cf_distro_zone_id" {
  value = aws_cloudfront_distribution.cf_distro.hosted_zone_id
}