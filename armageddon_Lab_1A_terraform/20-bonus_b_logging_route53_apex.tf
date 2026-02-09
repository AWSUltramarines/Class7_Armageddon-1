# 1. Create the Treasure Chest (S3 Bucket) for logs
resource "aws_s3_bucket" "ras-colservices_alb_logs_bucket01" {
  count         = var.enable_alb_access_logs ? 1 : 0
  bucket        = "ras-colservices-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allows deleting the bucket even if it has logs in it
}

# 2. The Permission Slip - This lets the ALB talk to the S3 bucket
resource "aws_s3_bucket_policy" "allow_alb_logging" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.ras-colservices_alb_logs_bucket01[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.ras-colservices_alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::914215748428:root" # AWS Log Delivery account for us-east-1
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.ras-colservices_alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/*"
      }
    ]
  })
}

# 3. The Shortcut - Directing the main domain (Apex) to the ALB
resource "aws_route53_record" "apex_alias" {
  provider = aws.dns_account
  zone_id = var.route53_hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.ras-colservices_alb.dns_name
    zone_id                = aws_lb.ras-colservices_alb.zone_id
    evaluate_target_health = true
  }
}