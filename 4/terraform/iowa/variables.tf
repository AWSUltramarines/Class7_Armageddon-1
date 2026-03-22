variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

# Iowa VPC CIDRs
variable "nihonmachi_vpc_cidr" {
  type    = string
  default = "10.16.0.0/16"
}

variable "nihonmachi_subnet_cidr" {
  type    = string
  default = "10.16.1.0/24"
}

# Who is allowed to access the ILB (Tokyo VPC CIDR over VPN)
variable "allowed_vpn_cidrs" {
  type    = list(string)
  default = ["10.14.0.0/16"] # Tokyo VPC CIDR
}

# Tokyo RDS endpoint (private resolvable/reachable over VPN)
variable "tokyo_rds_host" {
  type    = string
  default = "akihabara-dev-mysql.cvgusgs2mgvn.ap-northeast-1.rds.amazonaws.com"
}

variable "tokyo_rds_port" {
  type    = number
  default = 3306
}

# DB user is OK to store as plain var; password should not be in TF state (use Secret Manager)
variable "tokyo_rds_user" {
  type    = string
  default = "devsecopsengineer"
}

# Secret name holding DB password (created outside TF or by TF—your choice)
variable "db_password_secret_name" {
  type    = string
  default = "nihonmachi-tokyo-rds-password"
}

# AWS VPN outside IPs — set AFTER AWS VPN connections are deployed (Stage 5)
# Retrieve from: aws ec2 describe-vpn-connections --region ap-northeast-1
variable "aws_vpn_outside_ip_1" {
  description = "AWS VPN Connection 1 outside IP (tunnel1) — from AWS VPN console after Stage 5"
  type        = string
  default     = ""
}

variable "aws_vpn_outside_ip_2" {
  description = "AWS VPN Connection 2 outside IP (tunnel1) — from AWS VPN console after Stage 5"
  type        = string
  default     = ""
}
