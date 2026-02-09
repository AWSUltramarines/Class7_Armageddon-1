# variables.tf - Input variable definitions
#
# Lab 1c changes:
# - Removed: ssh_allowed_cidr (no SSH access)
# - Removed: key_name (no SSH keys)
# - Added: exposure_mode toggle (airgap vs public_alb)
# - Added: enable_ec2 for phased deployment
# - Added: release management variables (release_id, channel, fingerprints)

# -----------------------------------------------------------------------------
# Exposure Mode
# -----------------------------------------------------------------------------

variable "exposure_mode" {
  description = "Network exposure mode: 'airgap' (no IGW/ALB, SSM-only) or 'public_alb' (legacy with ALB)"
  type        = string
  default     = "airgap"

  validation {
    condition     = contains(["airgap", "public_alb"], var.exposure_mode)
    error_message = "exposure_mode must be 'airgap' or 'public_alb'."
  }
}

# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "ec2-rds-notes-lab"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "lab"
}

# -----------------------------------------------------------------------------
# Feature Toggles
# -----------------------------------------------------------------------------

variable "enable_ec2" {
  description = "Enable EC2 instance creation. In airgap mode, set to true after release pipeline setup."
  type        = bool
  default     = true
}

variable "enable_dnf_update" {
  description = "Run dnf update from offline repo during bootstrap (airgap mode only)"
  type        = bool
  default     = false
}

variable "enable_kms_endpoint" {
  description = "Enable KMS VPC endpoint (recommended for production)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Release Management (airgap mode)
# -----------------------------------------------------------------------------

variable "release_id" {
  description = "Immutable release identifier (e.g., 2026-01-29T1800Z). Required in airgap mode."
  type        = string
  default     = "initial"
}

variable "channel" {
  description = "Deployment channel (dev/stage/prod). EC2 instances consume artifacts from this channel."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.channel)
    error_message = "Channel must be one of: dev, stage, prod."
  }
}

variable "release_gpg_key_fingerprint" {
  description = "GPG fingerprint (40 hex chars) of the release manifest signing key. Required in airgap mode."
  type        = string
  default     = ""

  validation {
    condition     = var.release_gpg_key_fingerprint == "" || can(regex("^[A-Fa-f0-9]{40}$", var.release_gpg_key_fingerprint))
    error_message = "GPG key fingerprint must be empty or exactly 40 hexadecimal characters."
  }
}

variable "repo_gpg_key_fingerprint" {
  description = "GPG fingerprint (40 hex chars) of the repo metadata signing key. Required in airgap mode."
  type        = string
  default     = ""

  validation {
    condition     = var.repo_gpg_key_fingerprint == "" || can(regex("^[A-Fa-f0-9]{40}$", var.repo_gpg_key_fingerprint))
    error_message = "GPG key fingerprint must be empty or exactly 40 hexadecimal characters."
  }
}

variable "rpm_gpg_key_fingerprint" {
  description = "GPG fingerprint (40 hex chars) of the RPM package signing key. Required in airgap mode."
  type        = string
  default     = ""

  validation {
    condition     = var.rpm_gpg_key_fingerprint == "" || can(regex("^[A-Fa-f0-9]{40}$", var.rpm_gpg_key_fingerprint))
    error_message = "GPG key fingerprint must be empty or exactly 40 hexadecimal characters."
  }
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC (10.190.0.0/16 - convention: 0-85=internet, 86-170=backend, 171-255=hosts)"
  type        = string
  default     = "10.190.0.0/16"
}

variable "allowed_http_cidrs" {
  description = "List of CIDR blocks allowed for HTTP access to ALB (public_alb mode only)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -----------------------------------------------------------------------------
# EC2
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type (free-tier: t2.micro, t3.micro)"
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class (free-tier: db.t3.micro, db.t4g.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the MySQL database to create"
  type        = string
  default     = "notesdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_username" {
  description = "Master username for RDS MySQL"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_port" {
  description = "MySQL port"
  type        = number
  default     = 3306
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS (free-tier: 20)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "secret_name" {
  description = "Name for the Secrets Manager secret"
  type        = string
  default     = "lab/rds/mysql"
}

# -----------------------------------------------------------------------------
# CloudWatch & Monitoring
# -----------------------------------------------------------------------------

variable "log_group_name" {
  description = "CloudWatch Logs log group name for application logs"
  type        = string
  default     = "/aws/ec2/lab-rds-app"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch Logs"
  type        = number
  default     = 7
}

variable "alarm_error_threshold" {
  description = "Number of DB connection errors to trigger alarm"
  type        = number
  default     = 3
}

variable "alarm_evaluation_period" {
  description = "Number of periods to evaluate for alarm (each period is 1 minute)"
  type        = number
  default     = 5
}

variable "sns_topic_name" {
  description = "SNS topic name for incident notifications"
  type        = string
  default     = "lab-db-incidents"
}

variable "alert_email" {
  description = "Email address for alarm notifications (requires confirmation)"
  type        = string
  default     = ""

  validation {
    condition     = var.alert_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Must be a valid email address or empty string to skip email subscription."
  }
}

# -----------------------------------------------------------------------------
# ALB (public_alb mode only)
# -----------------------------------------------------------------------------

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds (public_alb mode only)"
  type        = number
  default     = 60
}
