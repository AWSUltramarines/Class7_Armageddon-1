# ec2.tf - EC2 instance running the Flask notes application
#
# Lab 1c:
# - EC2 in PRIVATE subnet (no public IP, no SSH)
# - Gated by enable_ec2 for phased deployment
# - airgap mode: offline bootstrap with signed manifest verification
# - public_alb mode: legacy internet-based bootstrap

resource "aws_instance" "web" {
  count = var.enable_ec2 ? 1 : 0

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = false

  # Template selection based on exposure mode
  user_data_base64 = local.is_airgap ? base64gzip(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    aws_region                  = var.aws_region
    secret_name                 = var.secret_name
    log_group                   = aws_cloudwatch_log_group.app_logs.name
    deps_bucket_name            = aws_s3_bucket.deps.id
    channel                     = var.channel
    enable_dnf_update           = var.enable_dnf_update ? "true" : "false"
    release_public_key          = file("${path.module}/keys/release-signing-public.gpg")
    repo_metadata_public_key    = file("${path.module}/keys/repo-metadata-signing-public.gpg")
    rpm_packages_public_key     = file("${path.module}/keys/rpm-packages-signing-public.gpg")
    release_gpg_key_fingerprint = var.release_gpg_key_fingerprint
    repo_gpg_key_fingerprint    = var.repo_gpg_key_fingerprint
    rpm_gpg_key_fingerprint     = var.rpm_gpg_key_fingerprint
    })) : base64encode(templatefile("${path.module}/templates/user_data_legacy.sh.tftpl", {
    aws_region  = var.aws_region
    secret_name = var.secret_name
    log_group   = aws_cloudwatch_log_group.app_logs.name
  }))

  root_block_device {
    volume_size           = local.is_airgap ? 20 : 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  monitoring = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
    Mode = var.exposure_mode
  })

  depends_on = [
    aws_secretsmanager_secret_version.db_credentials,
    aws_ssm_parameter.db_endpoint,
    aws_ssm_parameter.db_port,
    aws_ssm_parameter.db_name,
    aws_db_instance.mysql,
    aws_cloudwatch_log_group.app_logs,
    aws_vpc_endpoint.interface,
    aws_vpc_endpoint.s3
  ]

  # Preconditions: airgap mode requires GPG fingerprints and keys
  lifecycle {
    precondition {
      condition     = var.exposure_mode != "airgap" || var.release_gpg_key_fingerprint != ""
      error_message = "release_gpg_key_fingerprint is required when exposure_mode=airgap and enable_ec2=true."
    }
    precondition {
      condition     = var.exposure_mode != "airgap" || var.repo_gpg_key_fingerprint != ""
      error_message = "repo_gpg_key_fingerprint is required when exposure_mode=airgap and enable_ec2=true."
    }
    precondition {
      condition     = var.exposure_mode != "airgap" || var.rpm_gpg_key_fingerprint != ""
      error_message = "rpm_gpg_key_fingerprint is required when exposure_mode=airgap and enable_ec2=true."
    }
    precondition {
      condition     = var.exposure_mode != "airgap" || local.gpg_keys_exist
      error_message = "GPG public keys must exist in keys/ directory when exposure_mode=airgap. Run tools/0-build_release.sh first."
    }
    precondition {
      condition     = var.exposure_mode != "airgap" || var.release_id != "initial"
      error_message = "release_id must be set to an actual release ID (not 'initial') when exposure_mode=airgap."
    }
  }
}
