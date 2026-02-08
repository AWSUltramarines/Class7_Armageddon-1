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
