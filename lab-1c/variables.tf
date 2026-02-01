################################
#### Project
################################
variable "region" {
  description = "Default AWS region"
  type        = string
}
variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

################################
#### VPC
################################
variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR Block"
  type        = string
}


variable "enable_dns_hostnames" {
  description = "Enable DNS Hostnames "
  type        = string
}

variable "enable_dns_support" {
  description = "Enable DNS Support "
  type        = string
}

variable "instance_tenancy" {
  description = "Instance Tenancy "
  type        = string
}

################################
#### Subnets
################################
variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    type              = string # "public" or "private"
  }))
}

################################
#### Route Table
################################
variable "public_route_cidr" {
  description = "Public Route CIDR"
  type        = string
}
variable "private_route_cidr" {
  description = "Private Route CIDR"
  type        = string
}

################################
#### Security Groups
################################
variable "sg_name" {
  description = "Web Server Security Group Name"
  type        = string
}

variable "sg_http_cidr_ipv4" {
  description = "SSH Ingress IPv4 CIDR"
  type        = string
}
variable "sg_ssh_cidr_ipv4" {
  description = "HTTP Ingress IPv4 CIDR"
  type        = string
}
variable "sg_icmp_cidr_ipv4" {
  description = "ICMP Ingress IPv4 CIDR"
  type        = string
}
variable "egress_cidr_ipv4" {
  description = "Egress IPv4 CIDR"
  type        = string
}
variable "rds_sg_name" {
  description = "RDS Security Group Name"
  type        = string
}
variable "rds_sg_cidr_ipv4" {
  description = "MySQL Ingress IPv4 CIDR"
  type        = string
}

################################
#### Instance
################################
variable "public_key" {
  description = "Public Key for EC2 Key Pair"
  type        = string
}

################################
#### RDS
################################
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
#### SNS
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