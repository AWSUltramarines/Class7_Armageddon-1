# =============================================================================
# GENERAL
# =============================================================================

variable "aws_region" {
  description = "AWS region — Tokyo is the data-authority region (PHI lives here only)"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "Prefix for naming."
  type        = string
  default     = "jasongeddon"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "lab"
}

# =============================================================================
# NETWORKING
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.77.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones list (match count with subnets)"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

# =============================================================================
# LAB 3 — CROSS-REGION (Transit Gateway)
# =============================================================================

variable "liberdade_vpc_cidr" {
  description = "CIDR of the Liberdade (São Paulo) VPC — used for TGW routes and RDS SG rules"
  type        = string
  default     = "10.78.0.0/16"
}

variable "liberdade_tgw_id" {
  description = "Liberdade (São Paulo) Transit Gateway ID — passed from São Paulo output after first deploy"
  type        = string
  default     = "tgw-05f013bf1d8412b18"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.77.1.0/24", "10.77.2.0/24", "10.77.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.77.11.0/24", "10.77.12.0/24", "10.77.13.0/24"]
}

# =============================================================================
# EC2
# =============================================================================

# AMI is resolved dynamically via data "aws_ssm_parameter" in main.tf
# This uses AWS's public SSM parameter to find the latest AL2023 AMI for the current region.
# No hardcoded AMI ID needed — works automatically in any region.

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# =============================================================================
# RDS
# =============================================================================

variable "db_identifier" {
  description = "RDS instance identifier"
  type        = string
  default     = "labdb"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "labdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
  default     = "armageddon123!"
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0.43"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "db_backup_retention" {
  description = "Backup retention period in days"
  type        = number
  default     = 1
}

# =============================================================================
# SECRETS & PARAMETERS
# =============================================================================

variable "secret_name" {
  description = "Name for the Secrets Manager secret"
  type        = string
  default     = "jasongeddon/rds/mysql"
}

variable "ssm_parameter_prefix" {
  description = "Prefix for SSM Parameter Store paths"
  type        = string
  default     = "/lab/rds/mysql"
}

# =============================================================================
# CLOUDWATCH & ALERTING
# =============================================================================

variable "log_group_name" {
  description = "CloudWatch Log Group name for application logs"
  type        = string
  default     = "/lab/rdsapp"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 7
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "j.cramer2011@gmail.com"
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate for alarm"
  type        = number
  default     = 1
}

variable "alarm_period_seconds" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300
}

variable "alarm_threshold" {
  description = "Threshold for triggering the alarm"
  type        = number
  default     = 3
}

# =============================================================================
# TAGS
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Service   = "application1"
    ManagedBy = "terraform"
  }
}


#------------BONUS 1C VARIABLES--------------------------------


variable "domain_name" {
  description = "Base domain students registered (e.g., chewbacca-growl.com)."
  type        = string
  default     = "jason-cramer.com"
}

variable "app_subdomain" {
  description = "App hostname prefix (e.g., app.chewbacca-growl.com)."
  type        = string
  default     = "app"
}

variable "certificate_validation_method" {
  description = "ACM validation method. Students can do DNS (Route53) or EMAIL."
  type        = string
  default     = "DNS"
}

variable "enable_waf" {
  # Disabled — regional WAF on ALB replaced by CloudFront WAF (cf_waf01).
  # See lab2_cloudfront_shield_waf.tf for the new CLOUDFRONT-scoped WAF.
  description = "Toggle regional WAF creation on ALB."
  type        = bool
  default     = false
}

variable "alb_5xx_threshold" {
  description = "Alarm threshold for ALB 5xx count."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "CloudWatch alarm period."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for alarm."
  type        = number
  default     = 1
}


#-------------BONUS 1D VARIABLES------------------

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}

#------------------BONUS 1E VARIABLES-----------------------------

variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"   #"Choose ONE destination per WebACL: cloudwatch | s3 | firehose" #
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}

