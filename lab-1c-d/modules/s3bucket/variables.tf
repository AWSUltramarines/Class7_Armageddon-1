################################
#### Project
################################
variable "name_prefix" {
  description = "Project Name Prefix"
  type        = string
}
variable "terraform_tag" {
  description = "Tag to identify Terraform managed resources"
  type        = string
}
variable "domain_name" {
  description = "The domain name for the Route53 Hosted Zone"
  type        = string
}
# ################################
# #### Access Logs
# ################################
variable "enable_alb_access_logs" {
  description = "Enable ALB Access Logs"
  type        = bool
  default     = true
}
variable "alb_access_logs_prefix" {
  description = "Prefix for ALB Access Logs in the S3 Bucket"
  type        = string
  default     = "alb-access-logs"
}