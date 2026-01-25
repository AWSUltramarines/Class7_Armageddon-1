################################
#### Route53
################################
variable "name_prefix" {
  description = "Prefix for naming resources"
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
variable "certificate_validation_method" {
  description = "ACM validation method. Students can do DNS (Route53) or EMAIL."
  type        = string
  default     = "DNS"
}
################################
#### Load Balancer
################################
variable "alb" {
  description = "The Application Load Balancer resource"
  type        = any
}
