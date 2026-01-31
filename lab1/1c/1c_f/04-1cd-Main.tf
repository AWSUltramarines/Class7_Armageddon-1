/* ############################################
# BONUS D: ALB Access Logs S3 Bucket + Apex Record
############################################
# ============================================
# S3 Bucket for ALB Access Logs
# ============================================
# Explanation: Chewbacca keeps flight logs—this bucket stores ALB access logs for audits and incident response.
resource "aws_s3_bucket" "helga_alb_logs_bucket01" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"
  tags = {
    Name = "${var.project_name}-alb-logs"
  }
}
# Get current AWS account ID
data "aws_caller_identity" "current" {}
# Get the ELB service account for the region (required for ALB log delivery)
data "aws_elb_service_account" "main" {}
# Bucket policy to allow ALB to write logs
resource "aws_s3_bucket_policy" "helga_alb_logs_policy01" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.helga_alb_logs_bucket01[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ALBAccessLogDelivery"
        Effect    = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.helga_alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.helga_alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.helga_alb_logs_bucket01[0].arn
      }
    ]
  })
}
# ============================================
# Apex ALIAS Record: williebright.com -> ALB
# ============================================
# Explanation: This is the front gate—humans type this when they forget subdomains.
resource "aws_route53_record" "helga_apex_alias01" {
  zone_id = local.helga_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_lb.helga_alb01.dns_name
    zone_id                = aws_lb.helga_alb01.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb" "helga_alb01" {
  name               = "${var.project_name}-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.helga_alb_sg01.id]
  
subnets            = [aws_subnet.helga_public_subnets[0].id, aws_subnet.helga_public_subnets[1].id]

  # ADD THIS BLOCK ⬇️
  access_logs {
    bucket  = var.enable_alb_access_logs ? aws_s3_bucket.helga_alb_logs_bucket01[0].bucket : ""
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

  tags = {
    Name = "${var.project_name}-alb01"
  }
}

# ============================================
# Sync Domain Nameservers to Hosted Zone
# ============================================
data "aws_route53_zone" "helga_zone" {
  zone_id = local.helga_zone_id
}

resource "aws_route53domains_registered_domain" "williebright" {
  domain_name = var.domain_name

  dynamic "name_server" {
    for_each = data.aws_route53_zone.helga_zone.name_servers
    content {
      name = name_server.value
    }
  }
}

resource "aws_acm_certificate" "helga_cert01" {
  domain_name               = "williebright.com"
  subject_alternative_names = ["app.williebright.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
*/