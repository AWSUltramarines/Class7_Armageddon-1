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
################################
#### Route53
################################
variable "certificate_arn" {
  description = "The ARN of the ACM certificate to use with the Load Balancer"
  type        = string
}
variable "aws_acm_certificate_validation" {
  description = "The ACM certificate validation object"
  type        = any
}
