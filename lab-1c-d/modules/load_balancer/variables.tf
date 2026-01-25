################################
#### Project
################################
variable "name_prefix" {
  description = "Project Name Prefix"
  type        = string
}
variable "domain_name" {
  description = "The domain name for the Route53 Hosted Zone"
  type        = string
}
################################
#### Subnets
################################
variable "public_subnet_ids" {
  description = "List of Public Subnet IDs"
  type        = list(string)
}
################################
#### Security Groups
################################
variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}
################################
#### Target Group
################################
variable "target_group_arn" {
  description = "Load Balancer Target Group ARN"
  type        = string
}
variable "launch_template_id" {
  description = "Launch Template ID"
  type        = string
}
######################################
#### ALB Access Logs
######################################
variable "alb_access_logs_prefix" {
  description = "Prefix for ALB Access Logs in S3 Bucket"
  type        = string
  default     = "alb-access-logs"
}
variable "enable_alb_access_logs" {
  description = "Enable ALB Access Logs"
  type        = bool
  default     = true
}
######################################
#### ACM Certificate
######################################
variable "acm_certificate_arn" {
  description = "ACM Certificate ARN for the ALB"
  type        = string
}
######################################
#### S3 Bucket for ALB Access Logs
######################################
variable "s3_bucket" {
  description = "S3 Bucket for ALB Access Logs"
  type        = string
}

