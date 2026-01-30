variable "AWS_REGION" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "RDS_DB_NAME" {
  description = "The name of the RDS database"
  type        = string
  default     = "rds-lab-mysql"
}

variable "DB_USERNAME" {
  description = "The master username for the RDS database"
  type        = string
  default     = "admin"
}

# variable "DB_PASSWORD" {
#   description = "The master password for the RDS database"
#   type        = string
#   sensitive   = true
#   default     = random_password.db_password.result
# }

variable "EC2_AMI_ID" {
  description = "The AMI ID for the EC2 instance"
  type        = string  
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  
}

variable "PROJECT_NAME" {
  description = "The project name used for resource naming"
  type        = string
  default     = "armageddon"  
}

variable "ENVIRONMENT" {
  description = "The environment name (e.g., Development, Staging, Production)"
  type        = string
  default     = "development"
}

variable "DB_NAME" {
  description = "Name of the MySQL database to create"
  type        = string
  default     = "notes"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.DB_NAME))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "DB_PORT" {
  description = "MySQL port"
  type        = number
  default     = 3306
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS (free-tier: 20)"
  type        = number
  default     = 20
}

variable "DB_ENGINE_VERSION" {
  description = "MySQL engine version"
  type        = string
  default     = "8.4"
}

variable "INSTANCE_TYPE" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "SECRET_NAME" {
  description = "Name for the Secrets Manager secret"
  type        = string
  default     = "lab/rds/mysql"
}