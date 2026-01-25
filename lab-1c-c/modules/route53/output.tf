output "acm_certificate_status" {
  description = "The status of the SSL certificate"
  value       = aws_acm_certificate.cert.status
}
output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate.cert.arn
}
output "aws_acm_certificate_validation" {
  description = "Cert Validation"
  value       = aws_acm_certificate_validation.cert
}