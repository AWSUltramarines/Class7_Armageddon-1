# locals.tf - Local values for repeated references and computed values
#
# Lab 1c: exposure_mode toggle + release management locals

locals {
  # ---------------------------------------------------------------------------
  # Exposure Mode
  # ---------------------------------------------------------------------------
  is_airgap = var.exposure_mode == "airgap"

  # ---------------------------------------------------------------------------
  # Naming and Tags
  # ---------------------------------------------------------------------------
  name_prefix = var.project_name

  common_tags = {
    Lab = "EC2-RDS-Notes-1c"
  }

  # ---------------------------------------------------------------------------
  # Availability Zones
  # ---------------------------------------------------------------------------
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Subnet CIDR calculations
  # Convention: 0-85=internet (public), 86-170=backend, 171-255=hosts (private)
  public_subnet_cidrs  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i)]       # 10.190.0.0/24, 10.190.1.0/24
  private_subnet_cidrs = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 171)] # 10.190.171.0/24, 10.190.172.0/24

  # ---------------------------------------------------------------------------
  # Secrets / Parameters
  # ---------------------------------------------------------------------------
  db_secret = {
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.mysql.address
    port     = var.db_port
    dbname   = var.db_name
  }

  ssm_param_db_endpoint = "/lab/db/endpoint"
  ssm_param_db_port     = "/lab/db/port"
  ssm_param_db_name     = "/lab/db/name"

  # ---------------------------------------------------------------------------
  # VPC Interface Endpoint Services
  # ---------------------------------------------------------------------------
  vpc_endpoint_services = {
    ssm            = "com.amazonaws.${var.aws_region}.ssm"
    ec2messages    = "com.amazonaws.${var.aws_region}.ec2messages"
    ssmmessages    = "com.amazonaws.${var.aws_region}.ssmmessages"
    logs           = "com.amazonaws.${var.aws_region}.logs"
    secretsmanager = "com.amazonaws.${var.aws_region}.secretsmanager"
  }

  vpc_endpoint_services_with_kms = var.enable_kms_endpoint ? merge(local.vpc_endpoint_services, {
    kms = "com.amazonaws.${var.aws_region}.kms"
  }) : local.vpc_endpoint_services

  s3_endpoint_service = "com.amazonaws.${var.aws_region}.s3"

  # ---------------------------------------------------------------------------
  # S3 Repository Structure (Immutable Releases + Channels)
  # ---------------------------------------------------------------------------
  # Layout:
  #   repo/rpm/releases/<release_id>/x86_64/
  #   repo/rpm/channels/{dev,stage,prod}
  #   repo/pip/releases/<release_id>/py39/
  #   repo/pip/channels/{dev,stage,prod}
  #   repo/cw-agent/releases/<release_id>/
  #   repo/cw-agent/channels/{dev,stage,prod}
  #   manifests/<release_id>.json + .sig + .sha256
  #   keys/{release,repo-metadata,rpm-packages}-signing-public.gpg

  channel_prefix_rpm      = "repo/rpm/channels"
  channel_prefix_pip      = "repo/pip/channels"
  channel_prefix_cw_agent = "repo/cw-agent/channels"

  release_prefix_rpm      = "repo/rpm/releases/${var.release_id}/x86_64"
  release_prefix_pip      = "repo/pip/releases/${var.release_id}/py39"
  release_prefix_cw_agent = "repo/cw-agent/releases/${var.release_id}"

  manifest_prefix = "manifests"
  keys_prefix     = "keys"

  # Channel pointer content (all channels initialized to current release_id)
  channel_pointers = {
    "${local.channel_prefix_rpm}/dev"        = "${local.release_prefix_rpm}/"
    "${local.channel_prefix_rpm}/stage"      = "${local.release_prefix_rpm}/"
    "${local.channel_prefix_rpm}/prod"       = "${local.release_prefix_rpm}/"
    "${local.channel_prefix_pip}/dev"        = "${local.release_prefix_pip}/"
    "${local.channel_prefix_pip}/stage"      = "${local.release_prefix_pip}/"
    "${local.channel_prefix_pip}/prod"       = "${local.release_prefix_pip}/"
    "${local.channel_prefix_cw_agent}/dev"   = "${local.release_prefix_cw_agent}/"
    "${local.channel_prefix_cw_agent}/stage" = "${local.release_prefix_cw_agent}/"
    "${local.channel_prefix_cw_agent}/prod"  = "${local.release_prefix_cw_agent}/"
  }

  # Content type mapping for S3 objects
  content_type_map = {
    ".rpm"    = "application/x-rpm"
    ".whl"    = "application/zip"
    ".xml"    = "application/xml"
    ".gz"     = "application/gzip"
    ".zst"    = "application/zstd"
    ".txt"    = "text/plain"
    ".json"   = "application/json"
    ".sig"    = "application/pgp-signature"
    ".sha256" = "text/plain"
    ".gpg"    = "application/pgp-keys"
    ".lock"   = "text/plain"
  }

  # ---------------------------------------------------------------------------
  # GPG Key Paths (3-key model)
  # ---------------------------------------------------------------------------
  gpg_release_key_path = "${path.module}/keys/release-signing-public.gpg"
  gpg_repo_key_path    = "${path.module}/keys/repo-metadata-signing-public.gpg"
  gpg_rpm_key_path     = "${path.module}/keys/rpm-packages-signing-public.gpg"
  gpg_keys_exist = alltrue([
    fileexists("${path.module}/keys/release-signing-public.gpg"),
    fileexists("${path.module}/keys/repo-metadata-signing-public.gpg"),
    fileexists("${path.module}/keys/rpm-packages-signing-public.gpg"),
  ])
}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
