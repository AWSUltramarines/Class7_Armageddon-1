################################
#### Project and Account Info
################################
variable "name_prefix" {
  description = "Project Name Prefix"
  type        = string
}
variable "region" {
  description = "Default AWS region"
  type        = string
}

################################
#### Load Balancer Info
################################
variable "alb_arn_suffix" {
  description = "ALB ARN Suffix"
  type        = string
}

################################
#### SNS Topic Subscription
################################
variable "sns_sub_endpoint" {
  description = "SNS Subscription Endpoint"
  type        = string
}
variable "sns_endpoint_protocol" {
  description = "SNS Subscription Endpoint Protocol"
  type        = string
}
##################################
###### Instance
##################################
variable "ec2_instance_id" {
  description = "EC2 Instance ID to monitor"
  type        = string
}