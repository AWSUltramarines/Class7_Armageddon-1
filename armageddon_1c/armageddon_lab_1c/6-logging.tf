############################################
# Bonus B - WAF Logging (CloudWatch Logs OR S3 OR Firehose)
# One destination per Web ACL, choose via var.waf_log_destination.
############################################

############################################
# Option 1: CloudWatch Logs destination
############################################

# Explanation: WAF logs in CloudWatch are your “blaster-cam footage”—fast search, fast triage, fast truth.
resource "aws_cloudwatch_log_group" "waf_log_group01" {
  count = var.waf_log_destination == "cloudwatch" ? 1 : 0

  # NOTE: AWS requires WAF log destination names start with aws-waf-logs- (students must not rename this).
  name              = "aws-waf-logs-${var.project_name}-webacl01"
  retention_in_days = var.waf_log_retention_days

  tags = {
    Name = "${var.project_name}-waf-log-group01"
  }
}

# Explanation: This wire connects the shield generator to the black box—WAF -> CloudWatch Logs.
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging01" {
  count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

  resource_arn = aws_wafv2_web_acl.waf01[0].arn
  log_destination_configs = [
    aws_cloudwatch_log_group.waf_log_group01[0].arn
  ]

  # TODO: Students can add redacted_fields (authorization headers, cookies, etc.) as a stretch goal.
  # redacted_fields { ... }

  depends_on = [aws_wafv2_web_acl.waf01]
}

############################################
# Option 2: S3 destination (direct)
############################################

# Explanation: S3 WAF logs are the long-term archive—Chewbacca likes receipts that survive dashboards.
resource "aws_s3_bucket" "waf_logs_bucket01" {
  count = var.waf_log_destination == "s3" ? 1 : 0

  bucket = "aws-waf-logs-${var.project_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-waf-logs-bucket01"
  }
}

# Explanation: Public access blocked—WAF logs are not a bedtime story for the entire internet.
resource "aws_s3_bucket_public_access_block" "waf_logs_pab01" {
  count = var.waf_log_destination == "s3" ? 1 : 0

  bucket                  = aws_s3_bucket.waf_logs_bucket01[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explanation: Connect shield generator to archive vault—WAF -> S3.
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging_s3_01" {
  count = var.enable_waf && var.waf_log_destination == "s3" ? 1 : 0

  resource_arn = aws_wafv2_web_acl.waf01[0].arn
  log_destination_configs = [
    aws_s3_bucket.waf_logs_bucket01[0].arn
  ]

  depends_on = [aws_wafv2_web_acl.waf01]
}

############################################
# Option 3: Firehose destination (classic “stream then store”)
############################################

# Explanation: Firehose is the conveyor belt—WAF logs ride it to storage (and can fork to SIEM later).
resource "aws_s3_bucket" "firehose_waf_dest_bucket01" {
  count = var.waf_log_destination == "firehose" ? 1 : 0

  bucket = "${var.project_name}-waf-firehose-dest-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-waf-firehose-dest-bucket01"
  }
}

# Explanation: Firehose needs a role—Chewbacca doesn’t let random droids write into storage.
resource "aws_iam_role" "firehose_role01" {
  count = var.waf_log_destination == "firehose" ? 1 : 0
  name  = "${var.project_name}-firehose-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Explanation: Minimal permissions—allow Firehose to put objects into the destination bucket.
resource "aws_iam_role_policy" "firehose_policy01" {
  count = var.waf_log_destination == "firehose" ? 1 : 0
  name  = "${var.project_name}-firehose-policy01"
  role  = aws_iam_role.firehose_role01[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.firehose_waf_dest_bucket01[0].arn,
          "${aws_s3_bucket.firehose_waf_dest_bucket01[0].arn}/*"
        ]
      }
    ]
  })
}

# Explanation: The delivery stream is the belt itself—logs move from WAF -> Firehose -> S3.
resource "aws_kinesis_firehose_delivery_stream" "waf_firehose01" {
  count       = var.waf_log_destination == "firehose" ? 1 : 0
  name        = "aws-waf-logs-${var.project_name}-firehose01"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role01[0].arn
    bucket_arn = aws_s3_bucket.firehose_waf_dest_bucket01[0].arn
    prefix     = "waf-logs/"
  }
}

# Explanation: Connect shield generator to conveyor belt—WAF -> Firehose stream.
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging_firehose01" {
  count = var.enable_waf && var.waf_log_destination == "firehose" ? 1 : 0

  resource_arn = aws_wafv2_web_acl.waf01[0].arn
  log_destination_configs = [
    aws_kinesis_firehose_delivery_stream.waf_firehose01[0].arn
  ]

  depends_on = [aws_wafv2_web_acl.waf01]
}

############################################
# Bonus B - Route53 Zone Apex + ALB Access Logs to S3
############################################

############################################
# Route53: Zone Apex (root domain) -> ALB
############################################

# Explanation: The zone apex is the throne room—chewbacca-growl.com itself should lead to the ALB.
resource "aws_route53_record" "apex_alias01" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb01.dns_name
    zone_id                = aws_lb.alb01.zone_id
    evaluate_target_health = true
  }
}

############################################
# S3 bucket for ALB access logs
############################################

# Explanation: This bucket is Chewbacca’s log vault—every visitor to the ALB leaves footprints here.
resource "aws_s3_bucket" "alb_logs_bucket01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-alb-logs-bucket01"
  }
}

# Explanation: Block public access—Chewbacca does not publish the ship’s black box to the galaxy.
resource "aws_s3_bucket_public_access_block" "alb_logs_pab01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.alb_logs_bucket01[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Explanation: Bucket ownership controls prevent log delivery chaos—Chewbacca likes clean chain-of-custody.
resource "aws_s3_bucket_ownership_controls" "alb_logs_owner01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_logs_bucket01[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Explanation: TLS-only—Chewbacca growls at plaintext and throws it out an airlock.
resource "aws_s3_bucket_policy" "alb_logs_policy01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_logs_bucket01[0].id

  # NOTE: This is a skeleton. Students may need to adjust for region/account specifics.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.alb_logs_bucket01[0].arn,
          "${aws_s3_bucket.alb_logs_bucket01[0].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "AllowELBPutObject"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

############################################
# Enable ALB access logs (on the ALB resource)
############################################

# Explanation: Turn on access logs—Chewbacca wants receipts when something goes wrong.
# NOTE: This is a skeleton patch: students must merge this into aws_lb.alb01
# by adding/accessing the `access_logs` block. Terraform does not support "partial" blocks.
#
# Add this inside resource "aws_lb" "chewbacca_alb01" { ... } in bonus_b.tf:
#
# access_logs {
#   bucket  = aws_s3_bucket.alb_logs_bucket01[0].bucket
#   prefix  = var.alb_access_logs_prefix
#   enabled = var.enable_alb_access_logs
# }