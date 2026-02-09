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

variable "domain_name" {
  description = "The root domain name"
  type        = string
  default     = "rascollectiveservices.click"
}

variable "app_subdomain" {
  description = "The subdomain for the flask app"
  type        = string
  default     = "app.rascollectiveservices.click"
}

variable "manage_route53_in_terraform" {
  description = "If true, create/manage Route53 hosted zone + records in Terraform."
  type        = bool
  default     = true
}

variable "route53_hosted_zone_id" {
  description = "If manage_route53_in_terraform=false, provide existing Hosted Zone ID for domain."
  type        = string
  default     = "Z011619411G3BJBS8ER7U"
}