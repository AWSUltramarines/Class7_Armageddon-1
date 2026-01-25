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