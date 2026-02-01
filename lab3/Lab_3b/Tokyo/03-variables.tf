variable "aws_region" {
  description = "AWS Region for the helga fleet to patrol."
  type        = string
  default     = "ap-northeast-1"
}


variable "project_name" {
  description = "Prefix for naming. Students should change from 'helga' to their own."
  type        = string
  default     = "helga"
}

variable "vpc_cidr" {
  description = "VPC CIDR (use 10.x.x.x/xx as instructed)."
  type        = string
  default     = "10.241.0.0/16" # TODO: student supplies
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.241.1.0/24", "10.241.2.0/24", "10.241.3.0/24"] # TODO: student supplies
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.241.101.0/24", "10.241.102.0/24", "10.241.103.0/24"] # TODO: student supplies
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"] # TODO: student supplies
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-03d1820163e6b9f5d" # TODO
#ami-03d1820163e6b9f5d (Amazon Linux 2 in ap-northeast-1)
#ami-07ff62358b87c7116 (Amazon Linux 2 in us-east-1)

}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "db_engine" {
  description = "RDS engine."
  type        = string
  default     = "mysql"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "t_labdb" # Students can change
}

variable "db_username" {
  description = "DB master username (students should use Secrets Manager in 1B/1C)."
  type        = string
  default     = "admin" # TODO: student supplies
}

variable "db_password" {
  description = "DB master password (DO NOT hardcode in real life; for lab only)."
  type        = string
  sensitive   = true
  default     = "i8$2>Iu]dQOh60lzzRG#iHJS1mg7" # TODO: student supplies
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "brightwillie21@gmail.com" # TODO: student supplies
}

variable "db_port" {
  description = "Port for the RDS database."
  type        = number
  default     = 3306
  }

  
#1C_bonus_B_Variables_Start  
variable "domain_name" {
  type    = string
  default = "williebright.com"
}

variable "app_subdomain" {
  type    = string
  default = "app" # This makes your app accessible at app.williebright.com
}

variable "certificate_validation_method" {
  type    = string
  default = "DNS"
}

variable "enable_waf" {
  type    = bool
  default = true
  description = "Enable WAF Web ACL attachment to ALB"
}

variable "manage_route53_in_terraform" {
  type        = bool
  default     = true
  description = "Set to true to create the Hosted Zone via Terraform. Set to false if you already have a Hosted Zone ID."
}

variable "route53_hosted_zone_id" {
  type        = string
  default     = "Z076499737UY78K9J1ZVE" # Only required if manage_route53_in_terraform is false
  description = "The ID of your existing Route53 Hosted Zone"
}

variable "alb_5xx_evaluation_periods" {
  type    = number
  default = 1
}

variable "alb_5xx_threshold" {
  type    = number
  default = 0
}

variable "alb_5xx_period_seconds" {
  type    = number
  default = 60
}

variable "waf_log_destination" {
  type    = string
  default = "cloudwatch" # Options: cloudwatch, s3, firehose
}

variable "waf_log_retention_days" {
  type    = number
  default = 30
}

# ============================================
# BONUS D: ALB Access Logging Variables
# ============================================
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

# ============================================
# BONUS E: WAF Logging Variables
# ============================================

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}

# ============================================
# Lab 2A: Origin Cloaking Variables
# ============================================

variable "cloudfront_origin_secret" {
  description = "Secret header value CloudFront sends to ALB for origin verification. Generate a strong random string."
  type        = string
  sensitive   = true
  # NO DEFAULT - must be provided via terraform.tfvars or TF_VAR_
  # Example: openssl rand -base64 32
}

variable "origin_secret_header_name" {
  description = "HTTP header name for origin cloaking (CloudFront → ALB)"
  type        = string
  default     = "X-Helga-Origin-Verify"
}

############################################
# LAB 3 VARIABLES - ADD TO EXISTING FILE
############################################

variable "tokyo_vpc_cidr" {
  description = "Tokyo VPC CIDR block (your Lab 2 VPC)"
  type        = string
  default     = "10.241.0.0/16"  # Your Tokyo VPC
}

variable "saopaulo_vpc_cidr" {
  description = "São Paulo VPC CIDR block (must not overlap)"
  type        = string
  default     = "10.214.0.0/16"  # Your São Paulo VPC
}

variable "tokyo_private_subnet_cidrs" {
  description = "Tokyo private subnet CIDRs"
  type        = list(string)
  default     = ["10.241.11.0/24", "10.241.12.0/24"]
}

variable "tokyo_public_subnet_cidrs" {
  description = "Tokyo public subnet CIDRs (for NAT Gateway)"
  type        = list(string)
  default     = ["10.241.1.0/24", "10.241.2.0/24"]
}

# São Paulo Variables

variable "saopaulo_private_subnet_cidrs" {
  description = "São Paulo private subnet CIDRs"
  type        = list(string)
  default     = ["10.214.11.0/24", "10.214.12.0/24"]
}

variable "saopaulo_public_subnet_cidrs" {
  description = "São Paulo public subnet CIDRs (for NAT Gateway)"
  type        = list(string)
  default     = ["10.214.1.0/24", "10.214.2.0/24"]
}

variable "saopaulo_tgw_id" {
  description = "São Paulo TGW ID (populated after Phase 2)"
  type        = string
  default     = ""
}

variable "enable_tgw" {
  description = "Enable Transit Gateway for Lab 3"
  type        = bool
  default     = true
}