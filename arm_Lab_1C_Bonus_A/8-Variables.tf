variable "secret_name" {
  description = "The name of the secret"
  type        = string
  default     = "lab/rds/mysql"
}


variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "The custom password for the resource"
  type        = string
  default     = "8(cjEQC6|PP2M(<5dZ91vQg?9F()"
  sensitive   = true
}

variable "db_name" {
  description = "Name of the MySQL database to create"
  type        = string
  default     = "labdb"
}
