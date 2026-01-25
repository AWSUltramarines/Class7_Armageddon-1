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
#### Auto Scaling & Load Balancer
################################
variable "asg_name" {
  description = "Autoscaling Group Name"
  type        = string
}
variable "asg_min_size" {
  description = "ASG Min Size"
  type        = number
}
variable "asg_max_size" {
  description = "ASG Max Siz"
  type        = number
}
variable "asg_desired_size" {
  description = "ASG Desired Capacity"
  type        = number
}
variable "asg_hc_grace_period" {
  description = "ASG HC Grace Period"
  type        = number
}
variable "asg_policy_name" {
  description = "ASG Policy Name"
  type        = string
}
variable "asg_policy_instance_warmup" {
  description = "ASG Policy Estimated Instance Warmup"
  type        = number
}