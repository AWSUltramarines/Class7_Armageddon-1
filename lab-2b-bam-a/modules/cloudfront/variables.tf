################################
#### Project
################################
variable "name_prefix" {
  description = "Project Name Prefix"
  type        = string
}
variable "terraform_tag" {
  description = "Terraform Tag"
  type        = string
}
variable "domain_name" {
  description = "The domain name for the Route53 Hosted Zone"
  type        = string
}
variable "app_subdomain" {
  description = "The subdomain for the application (e.g., 'app' for app.example.com)"
  type        = string
}
################################
#### Load Balancer
################################
variable "alb_dns_name" {
  description = "Load Balancer resource"
  type        = string
}
################################
#### Cloudfront
################################
variable "certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront"
  type        = string
}
################################
#### WAF
################################
variable "cf_waf_acl_arn" {
  description = "Cloudfront WAF ACL ARN"
  type        = string
}
################################
#### CloudFront
################################
variable "cf_header_pw" {
  description = "HTTP Header PW"
  type        = string
}
