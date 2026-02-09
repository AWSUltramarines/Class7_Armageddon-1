################################
#### Project
################################
variable "region" {
  description = "Default AWS region"
  type        = string
}
variable "name_prefix" {
  description = "Project Name Prefix"
  type        = string
}
variable "terraform_tag" {
  description = "Terraform Tag"
  type        = string
}

################################
#### VPC
################################
variable "cidr_block" {
  description = "VPC CIDR Block"
  type        = string
}
variable "enable_dns_hostnames" {
  description = "Enable DNS Hostnames"
  type        = string
}
variable "enable_dns_support" {
  description = "Enable DNS Support"
  type        = string
}
variable "instance_tenancy" {
  description = "Instance Tenancy"
  type        = string
}

################################
#### Subnets
################################
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}
variable "azs" {
  description = "List of Availability Zones to use"
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

################################
#### Security Groups
################################
variable "vpce_https_cidr_ipv4" {
  description = "HTTPS Ingress IPv4 CIDR"
  type        = string
}
variable "egress_cidr_ipv4" {
  description = "Egress IPv4 CIDR"
  type        = string
}
variable "generic_inbound_cidr_ipv4" {
  description = "Generic Inbound IPv4 CIDR"
  type        = string
}

################################
#### Compute
################################
variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
}

####################################
#### Auto Scaling & Load Balancer
####################################
variable "asg_name" {
  description = "Autoscaling Group Name"
  type        = string
}
variable "asg_min_size" {
  description = "ASG Min Size"
  type        = number
}
variable "asg_max_size" {
  description = "ASG Max Size"
  type        = number
}
variable "asg_desired_size" {
  description = "ASG Desired Capacity"
  type        = number
}
variable "asg_hc_grace_period" {
  description = "ASG HC Grace Period"
  type        = number
}
variable "asg_policy_name" {
  description = "ASG Policy Name"
  type        = string
}
variable "asg_policy_instance_warmup" {
  description = "ASG Policy Estimated Instance Warmup"
  type        = number
}

################################
#### RDS
################################
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

################################
#### Alerts
################################
variable "sns_endpoint_protocol" {
  description = "SNS Topic Subscription Protocol"
  type        = string
}
variable "sns_sub_endpoint" {
  description = "SNS Topic Subscription Endpoint"
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
#### Route53
################################
variable "domain_name" {
  description = "The root domain name purchased in Route 53"
  type        = string
}
variable "app_subdomain" {
  description = "The subdomain for the application"
  type        = string
  default     = "app"
}

################################
#### Access Logs
################################
variable "enable_alb_access_logs" {
  description = "Enable ALB Access Logs"
  type        = bool
  default     = true
}
variable "alb_access_logs_prefix" {
  description = "Prefix for ALB Access Logs in the S3 Bucket"
  type        = string
  default     = "alb-access-logs"
}

################################
#### WAF Logs
################################
variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}

################################
#### CloudFront
################################
variable "cf_header_pw" {
  description = "HTTP Header PW"
  type        = string
}

############################################
# Lab 3A: Transit Gateway Variables
############################################
variable "enable_tgw" {
  description = "Enable Transit Gateway for Lab 3A cross-region connectivity"
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Project name for TGW naming convention (shinjuku for Tokyo)"
  type        = string
  default     = "shinjuku"
}

variable "saopaulo_tgw_id" {
  description = "Sao Paulo TGW ID (set after Sao Paulo Phase 1 deploy)"
  type        = string
  default     = ""
}

variable "saopaulo_vpc_cidr" {
  description = "Sao Paulo VPC CIDR for cross-region routing"
  type        = string
  default     = "10.214.0.0/16"
}

variable "create_tgw_peering" {
  description = "Create TGW peering attachment to Sao Paulo"
  type        = bool
  default     = true
}

variable "tgw_peering_accepted" {
  description = "Set to true AFTER Sao Paulo Phase 3 accepts the peering (enables TGW route)"
  type        = bool
  default     = true
}
