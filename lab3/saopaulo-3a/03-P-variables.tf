############################################
# SÃO PAULO VARIABLES
############################################

variable "aws_region" {
  description = "AWS Region for São Paulo"
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "liberdade"
}

variable "vpc_cidr" {
  description = "São Paulo VPC CIDR"
  type        = string
  default     = "10.214.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "São Paulo public subnet CIDRs (for NAT Gateway)"
  type        = list(string)
  default     = ["10.214.1.0/24", "10.214.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "São Paulo private subnet CIDRs (for TGW attachment)"
  type        = list(string)
  default     = ["10.214.101.0/24", "10.214.102.0/24"]
}

variable "azs" {
  description = "São Paulo AZs"
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b"]
}

# Cross-region references (from Tokyo Phase 1 outputs)
variable "tokyo_vpc_cidr" {
  description = "Tokyo VPC CIDR for routing"
  type        = string
  default     = "10.241.0.0/16"
}

variable "tokyo_tgw_id" {
  description = "Tokyo TGW ID (from Phase 1 output)"
  type        = string
  # Set in terraform.tfvars after Phase 1
}

variable "tokyo_rds_endpoint" {
  description = "Tokyo RDS endpoint (from Phase 1 output)"
  type        = string
  sensitive   = true
  default     = ""
  # Set in terraform.tfvars
}

variable "ec2_ami_id" {
  description = "AMI ID for São Paulo EC2 (Amazon Linux 2023)"
  type        = string
  default     = "ami-0c820c196a818d66a"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "enable_tgw" {
  description = "Enable Transit Gateway for Lab 3"
  type        = bool
  default     = true
}