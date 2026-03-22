# ================================================================ #
# Lab 3B — Audit Evidence Resources
# CloudTrail, CloudFront Logging, VPC Flow Logs, S3 Versioning
# ================================================================ #

# ---------------------------------------------------------------- #
# 1. CloudTrail — Multi-Region Trail for Change Evidence
# ---------------------------------------------------------------- #

# S3 bucket to store CloudTrail audit logs — long-term evidence for change tracking
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.project_name}-${var.environment}-cloudtrail-audit-logs"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-${var.environment}-cloudtrail-logs"
    Purpose = "AuditEvidence"
  }
}

# Enable versioning on CloudTrail bucket — prevents log tampering (immutability posture)
resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket policy granting CloudTrail service permission to read ACL and write logs to S3
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-${var.environment}-audit-trail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-${var.environment}-audit-trail"
          }
        }
      }
    ]
  })
}

# Multi-region CloudTrail trail — captures management events from all regions to S3
resource "aws_cloudtrail" "audit_trail" {
  name                          = "${var.project_name}-${var.environment}-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging                = true

  tags = {
    Name    = "${var.project_name}-${var.environment}-audit-trail"
    Purpose = "AuditEvidence"
    Lab     = "3B"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}

# ---------------------------------------------------------------- #
# 2. CloudFront Standard Logging — Edge Access Evidence
# ---------------------------------------------------------------- #

# S3 bucket for CloudFront standard access logs — records viewer requests (Hit/Miss/RefreshHit)
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = "${var.project_name}-${var.environment}-cloudfront-standard-logs"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-${var.environment}-cloudfront-logs"
    Purpose = "AuditEvidence"
  }
}

# Enable versioning on CloudFront logs bucket — prevents log tampering
resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Ownership controls — required so CloudFront can write logs via ACL on this bucket
resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Note: No canned ACL here — CloudFront manages its own ACL grants on the bucket
# when logging_config is applied to the distribution. The BucketOwnerPreferred
# ownership control above is sufficient. Using "log-delivery-write" would strip
# FULL_CONTROL from the bucket owner, causing CloudFront UpdateDistribution to fail.

# ---------------------------------------------------------------- #
# 3. VPC Flow Logs — Network Corridor Evidence (Tokyo)
# ---------------------------------------------------------------- #

# CloudWatch Log Group to receive VPC Flow Logs — network corridor evidence
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.project_name}-${var.environment}"
  retention_in_days = 14

  tags = {
    Name    = "${var.project_name}-${var.environment}-vpc-flow-logs"
    Purpose = "AuditEvidence"
  }
}

# IAM role allowing VPC Flow Logs service to write to CloudWatch Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name    = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
    Purpose = "AuditEvidence"
  }
}

# IAM policy granting CloudWatch Logs write permissions to the flow logs role
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

# VPC Flow Log — captures all network traffic metadata on the Tokyo VPC
resource "aws_flow_log" "vpc_flow_log" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn

  tags = {
    Name    = "${var.project_name}-${var.environment}-vpc-flow-log"
    Purpose = "AuditEvidence"
  }
}

# ---------------------------------------------------------------- #
# 4. S3 Versioning on ALB Logs Bucket (Immutability Posture)
# ---------------------------------------------------------------- #

# Enable versioning on ALB logs bucket — immutability posture for audit evidence
resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}
