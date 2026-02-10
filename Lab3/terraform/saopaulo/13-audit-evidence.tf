# ================================================================ #
# Lab 3B — Audit Evidence Resources (São Paulo)
# VPC Flow Logs + S3 Versioning
# ================================================================ #
# CloudTrail: Covered by Tokyo's multi-region trail
# CloudFront: Only exists in Tokyo (global entry point)
# ================================================================ #

# ---------------------------------------------------------------- #
# 1. VPC Flow Logs — Network Corridor Evidence (São Paulo)
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

# VPC Flow Log — captures all network traffic metadata on the São Paulo VPC
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
# 2. S3 Versioning on ALB Logs Bucket (Immutability Posture)
# ---------------------------------------------------------------- #

# Enable versioning on ALB logs bucket — immutability posture for audit evidence
resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}
# ---------------------------------------------------------------- #
# 3. CloudTrail — Change Evidence (São Paulo)
# ---------------------------------------------------------------- #
# Records ALL management API calls in this region.
# "Who changed the security group? Who modified the WAF?"
# Event History gives 90 days free, but a Trail sends to S3 for long-term storage.

# S3 Bucket for CloudTrail logs — long-term immutable storage for audit evidence
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.project_name}-${var.environment}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Lab setting: allows easy teardown

  tags = {
    Name    = "${var.project_name}-${var.environment}-cloudtrail-logs"
    Purpose = "AuditEvidence"
  }
}

# Enable versioning on CloudTrail bucket — prevents log tampering
resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket policy required by CloudTrail to write logs to S3
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
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# The CloudTrail Trail itself — captures management events in São Paulo
resource "aws_cloudtrail" "saopaulo_trail" {
  name                       = "${var.project_name}-${var.environment}-saopaulo-trail"
  s3_bucket_name             = aws_s3_bucket.cloudtrail_logs.bucket
  include_global_service_events = false  # Tokyo handles global events (IAM, etc.)
  is_multi_region_trail      = false     # São Paulo only — Tokyo has its own trail
  enable_logging             = true

  # Management events = who created/deleted/modified AWS resources
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-saopaulo-trail"
    Purpose = "AuditEvidence"
    Region  = "sa-east-1"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}