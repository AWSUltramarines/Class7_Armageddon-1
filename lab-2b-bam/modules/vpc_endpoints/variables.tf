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
#### VPC
################################
variable "vpc_id" {
  description = "VPC ID where VPC Endpoints will be created"
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
variable "vpce_sg_id" {
  description = "VPC Endpoint Security Group ID"
  type        = string
}
################################
#### Route Tables
################################
variable "private_route_table" {
  description = "Private Route Table ID"
  type        = string
}