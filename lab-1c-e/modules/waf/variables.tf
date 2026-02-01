################################
#### Project and Account Info
################################
variable "name_prefix" {
  description = "Project Name Prefix"
  type        = string
}
variable "terraform_tag" {
  description = "Terraform Tag"
  type        = string
}
variable "region" {
  description = "AWS Region"
  type        = string
}
################################
#### Load Balancer Info
################################
variable "alb_arn" {
  description = "ALB ARN"
  type        = string
}
variable "waf_log_destination" {
  description = "WAF Log Destination: 'cloudwatch' or 's3'"
  type        = string
  default     = "cloudwatch" # or "s3"
}
################################
#### Logging Info
################################
# variable "app_logs" {
#   description = "Application CloudWatch Log Groups"
#   type        = list(object({
#     arn = string
#   }))
#   default     = []
# }
# variable "s3_bucket" {
#   description = "S3 Bucket for WAF Logs"
#   type        = list(object({
#     arn = string
#   }))
#   default     = []
# }
