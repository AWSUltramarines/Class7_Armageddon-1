############################################
# Bonus B - ALB Access Logs + Apex Domain
############################################

# Explanation: ALB logs are the black box recorder — when things explode, this tells you what the pilots saw.
# Real-world example: A security team investigating suspicious API calls can filter S3 logs by IP, path, and user-agent.

############################################
# S3 Bucket for ALB Access Logs
############################################

# Explanation: This bucket is the vault where every request gets logged—who, what, when, and how it went.
resource "aws_s3_bucket" "chewbacca_alb_logs_bucket01" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.project_name}-alb-logs-bucket01"
    Purpose = "ALB access logs for incident response and compliance"
  }
}

# Explanation: Block all public access—logs contain client IPs and paths that could leak sensitive patterns.
resource "aws_s3_bucket_public_access_block" "chewbacca_alb_logs_block01" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explanation: Lifecycle rules auto-delete old logs—keeps costs down and meets data retention policies.
# Real-world example: HIPAA requires 7 years, but most startups keep 90 days for cost reasons.
resource "aws_s3_bucket_lifecycle_configuration" "chewbacca_alb_logs_lifecycle01" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 90  # Adjust based on your compliance requirements
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"  # Move to cheaper storage after 30 days
    }
  }
}

# Explanation: Server-side encryption at rest—protects logs from disk-level attacks or AWS insider threats.
resource "aws_s3_bucket_server_side_encryption_configuration" "chewbacca_alb_logs_encryption01" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################################
# S3 Bucket Policy for ALB Write Access
############################################

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get ALB service account for the region
# Explanation: Different AWS regions use different service accounts for ALB logging
data "aws_elb_service_account" "main" {}

# Explanation: This policy is the security guard—only the ALB service can write, no one else.
# Real-world gotcha: Without this, ALB silently fails to log (no error, just missing data).
resource "aws_s3_bucket_policy" "chewbacca_alb_logs_policy01" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.chewbacca_alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].arn
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.chewbacca_alb_logs_block01]
}

############################################
# Route53 Apex Record (chewbacca-growl.com -> ALB)
############################################

# Explanation: Apex domain routing lets users type the short name—like typing "google.com" instead of "www.google.com".
# Real-world example: Marketing wants createmythoughts.com on business cards, not app.createmythoughts.com.
resource "aws_route53_record" "chewbacca_apex_dns" {
  zone_id = aws_route53_zone.chewbacca_zone.zone_id
  name    = var.domain_name  # This is the apex: createmythoughts.com
  type    = "A"

  alias {
    name                   = aws_lb.chewbacca_alb01.dns_name
    zone_id                = aws_lb.chewbacca_alb01.zone_id
    evaluate_target_health = true
  }
}

# Explanation: IPv6 support—some corporate networks and mobile carriers prefer IPv6.
resource "aws_route53_record" "chewbacca_apex_dns_ipv6" {
  zone_id = aws_route53_zone.chewbacca_zone.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_lb.chewbacca_alb01.dns_name
    zone_id                = aws_lb.chewbacca_alb01.zone_id
    evaluate_target_health = true
  }
}