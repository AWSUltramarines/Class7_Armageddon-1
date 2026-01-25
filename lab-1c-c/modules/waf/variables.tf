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