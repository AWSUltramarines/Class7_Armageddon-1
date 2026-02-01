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
#### Secrets Manager
################################
variable "secret_name" {
  description = "Secrets Manager Secret Name"
  type        = string
}
################################
#### Cloud Watch Log Group
################################
variable "log_group_arn" {
  description = "CloudWatch Log Group ARN"
  type        = string
}