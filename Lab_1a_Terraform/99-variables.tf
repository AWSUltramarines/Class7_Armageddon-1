variable "region" {
  description = "The region for this deployment"
  type        = string
  default     = "us-east-1"
}

variable "secret_name" {
  description = "The name of the secret"
  type        = string
  default     = "lab/rds/mysql"
}

variable "db_name" {
  description = "Name of the MySQL database to create"
  type        = string
  default     = "labmysql"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "cidr" {
  description = "The cidr block for the vpc"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  # Example default:
  default = ["10.10.30.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  # Example default:
  default = ["10.10.20.0/24", "10.10.10.0/24"]
}

variable "azs" {
  description = "List of Availability Zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "allowed_http_cidrs" {
  description = "List of CIDR blocks allowed for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access. Empty string disables SSH access."
  type        = number
  default     = 22
}

variable "db_port" {
  description = "MySQL port"
  type        = number
  default     = 3306
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.4.7"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS (free-tier: 20)"
  type        = number
  default     = 20
}
