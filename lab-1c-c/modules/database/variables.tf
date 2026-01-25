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
#### Subnets
################################
variable "private_subnet_cidrs" {
  description = "List of Private Subnet CIDRs"
  type        = list(string)
}
variable "db_subnet_group_name" {
  description = "RDS Subnet Group Name"
  type        = string
}
################################
#### Security Groups
################################
variable "rds_sg_id" {
  description = "RDS Security Group ID"
  type        = string
}
################################
#### RDS
################################
variable "rds_connection" {
  type = object({
    address = string
    port    = number
  })
}
variable "db_prefix" {
  description = "RDS Database Prefix"
  type        = string
}
variable "db_name" {
  description = "RDS Database Name"
  type        = string
}
variable "db_username" {
  description = "RDS Database Username"
  type        = string
}
variable "db_password" {
  description = "RDS Database Password"
  type        = string
  sensitive   = true
}
variable "db_allocated_storage" {
  description = "RDS Database Allocated Storage (in GB)"
  type        = number
}
variable "db_instance_class" {
  description = "RDS Database Instance Class"
  type        = string
}
variable "db_engine_version" {
  description = "RDS Database Engine Version"
  type        = string
}
variable "db_engine" {
  description = "RDS Database Engine"
  type        = string
}
variable "parameter_group_name" {
  description = "RDS Parameter Group Name"
  type        = string
}
variable "publicly_accessible" {
  description = "RDS Publicly Accessible"
  type        = bool
}
variable "skip_final_snapshot" {
  description = "RDS Skip Final Snapshot"
  type        = bool
}