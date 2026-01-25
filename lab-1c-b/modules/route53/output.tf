output "acm_certificate_status" {
  description = "The status of the SSL certificate"
  value       = aws_acm_certificate.cert.status
}