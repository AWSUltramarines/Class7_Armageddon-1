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
################################
#### VPC
################################
variable "cidr_block" {
  description = "VPC CIDR Block"
  type        = string
}
variable "instance_tenancy" {
  description = "Instance Tenancy "
  type        = string
}
variable "enable_dns_hostnames" {
  description = "Enable DNS Hostnames "
  type        = string
}
variable "enable_dns_support" {
  description = "Enable DNS Support "
  type        = string
}
################################
#### Subnets
################################
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}
variable "azs" {
  description = "List of Availability Zones to use"
  type        = list(string)
}
################################
#### Security Groups
################################
variable "vpce_https_cidr_ipv4" {
  description = "HTTPS Ingress IPv4 CIDR"
  type        = string
}
variable "egress_cidr_ipv4" {
  description = "Egress IPv4 CIDR"
  type        = string
}
variable "generic_inbound_cidr_ipv4" {
  description = "Generic Inbound IPv4 CIDR"
  type        = string
}