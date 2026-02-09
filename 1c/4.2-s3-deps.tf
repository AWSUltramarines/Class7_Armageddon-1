#------------------------------------------------------------------------------
# 4.2-s3-deps.tf - S3 Bucket for Offline Dependencies (Immutable Releases)
#------------------------------------------------------------------------------
# Stores signed releases uploaded by ./tools/1-upload_release.sh.
# Always created (cheap) to allow mode switching without state changes.
#
# S3 Layout:
#   repo/rpm/releases/<release_id>/x86_64/   - RPM packages + repodata
#   repo/rpm/channels/{dev,stage,prod}       - Channel pointers (text files)
#   repo/pip/releases/<release_id>/py39/     - Wheels + requirements.lock
#   repo/pip/channels/{dev,stage,prod}       - Channel pointers
#   repo/cw-agent/releases/<release_id>/     - CloudWatch agent RPM
#   repo/cw-agent/channels/{dev,stage,prod}  - Channel pointers
#   manifests/<release_id>.json              - Release manifest
#   manifests/<release_id>.json.sig          - GPG signature
#   manifests/<release_id>.json.sha256       - SHA256 checksum
#   keys/release-signing-public.gpg          - Release manifest signing key
#   keys/repo-metadata-signing-public.gpg    - Repo metadata signing key
#   keys/rpm-packages-signing-public.gpg     - RPM packages signing key
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Random suffix for globally unique bucket name
#------------------------------------------------------------------------------

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

#------------------------------------------------------------------------------
# S3 Bucket
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "deps" {
  bucket        = "${var.project_name}-deps-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-deps-bucket"
    Purpose = "offline-dependencies"
  })
}

#------------------------------------------------------------------------------
# Bucket Versioning
#------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "deps" {
  bucket = aws_s3_bucket.deps.id

  versioning_configuration {
    status = "Enabled"
  }
}

#------------------------------------------------------------------------------
# Block Public Access
#------------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "deps" {
  bucket = aws_s3_bucket.deps.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#------------------------------------------------------------------------------
# Bucket Policy - Restrict access to VPC Endpoint + account
#------------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "deps" {
  bucket = aws_s3_bucket.deps.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowVPCEndpointAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.deps.arn,
          "${aws_s3_bucket.deps.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.s3.id
          }
        }
      },
      {
        Sid       = "AllowTerraformManagement"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.deps.arn,
          "${aws_s3_bucket.deps.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.deps]
}

#------------------------------------------------------------------------------
# Channel Pointer Objects (small text files pointing to release prefixes)
#------------------------------------------------------------------------------
# On initial apply, all channels point to the same release_id.
# Use tools/2-promote_channel.sh to update individual channels later.

resource "aws_s3_object" "channel_pointers" {
  for_each = local.channel_pointers

  bucket       = aws_s3_bucket.deps.id
  key          = each.key
  content      = each.value
  content_type = "text/plain"

  tags = {
    UploadedBy = "terraform"
    Type       = "channel-pointer"
  }

  # Ensure bucket policy and all configuration are fully applied before
  # creating pointer objects. Without this, the provider's read-after-write
  # verification can hit a transient AccessDenied from the VPCE-conditioned
  # bucket policy before it has fully propagated.
  depends_on = [
    aws_s3_bucket_policy.deps,
    aws_s3_bucket_public_access_block.deps,
    aws_s3_bucket_versioning.deps,
  ]

  # CRITICAL: After initial creation, Terraform must NOT modify these objects.
  # Channel pointers are exclusively managed by:
  #   - tools/2-promote_channel.sh (updates pointer to new release)
  #   - tools/3-rollback_channel.sh (reverts pointer to previous release)
  lifecycle {
    ignore_changes = [
      content,
      source,
      etag,
      metadata,
      content_type,
    ]
  }
}
