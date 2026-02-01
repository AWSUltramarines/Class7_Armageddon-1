################################
#### Project and Account Info
################################
variable "name_prefix" {
  description = "Project Name Prefix"
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
#### RDS
################################
variable "rds_connection" {
  description = "RDS Instance Connection Details"
  type = object({
    address = string
    port    = number
  })
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

