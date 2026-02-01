################################
#### Project
################################
variable "name_prefix" {
  description = "Project Name Prefix"
  type        = string
}
variable "terraform_tag" {
  description = "Terraform Tag"
  type        = string
}
################################
#### VPC
################################
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
################################
#### Instance
################################
variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
}
################################
#### Instance Profile
################################
variable "iam_instance_profile" {
  description = "IAM Instance Profile Name"
  type        = string
}
################################
#### Subnets
################################
variable "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  type        = list(string)
}
################################
#### Security Groups
################################
variable "compute_sg_id" {
  description = "Compute Security Group ID"
  type        = string
}
variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}