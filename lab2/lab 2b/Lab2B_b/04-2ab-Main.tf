############################################
# BONUS D: ALB Access Logs S3 Bucket + Apex Record
############################################
# ============================================
# S3 Bucket for ALB Access Logs
# ============================================
# Explanation: Chewbacca keeps flight logs—this bucket stores ALB access logs for audits and incident response.
resource "aws_s3_bucket" "helga_alb_logs_bucketlab2a" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = "${var.project_name}-alb-logsv1-${data.aws_caller_identity.current.account_id}"
  tags = {
    Name = "${var.project_name}-alb-logsv1"
  }
}
 # Get current AWS account ID
data "aws_caller_identity" "current" {}
# Get the ELB service account for the region (required for ALB log delivery)
data "aws_elb_service_account" "main" {}
# Bucket policy to allow ALB to write logs
resource "aws_s3_bucket_policy" "helga_alb_logs_policylab2a" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.helga_alb_logs_bucketlab2a[0].id
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
        Resource = "${aws_s3_bucket.helga_alb_logs_bucketlab2a[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.helga_alb_logs_bucketlab2a[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
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
        Resource = aws_s3_bucket.helga_alb_logs_bucketlab2a[0].arn
      }
    ]
  })
} 
# ============================================
# Apex ALIAS Record: williebright.com -> ALB
# ============================================


resource "aws_lb" "helga_alblab2a" {
  name               = "${var.project_name}-alblab2a"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.helga_alb_sglab2a.id]
  
subnets            = [aws_subnet.helga_public_subnets[0].id, aws_subnet.helga_public_subnets[1].id]

  # ADD THIS BLOCK ⬇️
  access_logs {
    bucket  = var.enable_alb_access_logs ? aws_s3_bucket.helga_alb_logs_bucketlab2a[0].bucket : ""
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

  tags = {
    Name = "${var.project_name}-alblab2a"
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
     #this was the original linking to the data block to dynamically get the nameservers
    for_each = data.aws_route53_zone.helga_zone.name_servers
        
    content {
      name = name_server.value
    }
  }
}

############################################
# LAB 2A: ALB SECURITY GROUP (ORIGIN CLOAKING)
############################################
# BEFORE: Allowed 0.0.0.0/0 on 80/443
# AFTER: Only allows CloudFront prefix list

# Data source for CloudFront managed prefix list
/* data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
 */
resource "aws_security_group" "helga_alb_sglab2a" {
  name        = "${var.project_name}-alb-sglab2a"
  description = "ALB SG - CloudFront origin-facing only"
  vpc_id      = aws_vpc.helga_vpclab2a.id

  # HTTPS from CloudFront only
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
    description     = "HTTPS from CloudFront origin-facing IPs only"
  }

#This block commented out becuase it is not needed since we are using cloudfront with the ALB
 /*  # HTTP from CloudFront only (for redirect)
   ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
    description     = "HTTP from CloudFront origin-facing IPs only" 
  } */

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = { Name = "${var.project_name}-alb-sglab2a" }
}

############################################
# LAB 2A: HTTPS LISTENER WITH SECRET HEADER RULE
############################################

# HTTPS Listener - Default action is 403 (block direct access)
resource "aws_lb_listener" "helga_https_listenerlab2a" {
  load_balancer_arn = aws_lb.helga_alblab2a.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.helga_alb_cert_validationlab2a.certificate_arn

  # DEFAULT: Block all direct access with 403
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Direct access forbidden"
      status_code  = "403"
    }
  }
}

# --- 2. ALB & Target Group ---

/* resource "aws_lb" "helga_alblab2a" {
  name               = "${var.project_name}-alblab2a"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.helga_alb_sglab2a.id]
  subnets            = aws_subnet.helga_public_subnets[*].id
  tags               = { Name = "${var.project_name}-alblab2a" }
} */

resource "aws_lb_target_group" "helga_tglab2a" {
  name     = "${var.project_name}-tglab2a"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.helga_vpclab2a.id

  health_check {
    enabled             = true
    path                = "/" # Change to /health or /list if needed
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group_attachment" "helga_tg_attachlab2a" {
  target_group_arn = aws_lb_target_group.helga_tglab2a.arn
  target_id        = aws_instance.helga_ec2lab2a.id # Ensure this matches your Private EC2 resource name
  port             = 80
}


# Listener Rule: If secret header matches → forward to target group
resource "aws_lb_listener_rule" "helga_origin_verify_rulelab2a" {
  listener_arn = aws_lb_listener.helga_https_listenerlab2a.arn
  priority     = 1

  condition {
    http_header {
      http_header_name = var.origin_secret_header_name
      values           = [var.cloudfront_origin_secret]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.helga_tglab2a.arn
  }
}

# HTTP Listener - Redirect to HTTPS (unchanged)
resource "aws_lb_listener" "helga_http_listenerlab2a" {
  load_balancer_arn = aws_lb.helga_alblab2a.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
############################################
# ALB REGIONAL CERTIFICATE
############################################
# This is SEPARATE from the CloudFront cert (us-east-1)
# ALB needs a valid cert for CloudFront → ALB HTTPS connection

resource "aws_acm_certificate" "helga_alb_certlab2a" {
  domain_name               = var.domain_name
  subject_alternative_names = [local.helga_app_fqdn]
  validation_method         = "DNS"

  tags = { Name = "${var.project_name}-alb-certlab2a" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "helga_alb_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.helga_alb_certlab2a.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.helga_zone_id
}

resource "aws_acm_certificate_validation" "helga_alb_cert_validationlab2a" {
  certificate_arn         = aws_acm_certificate.helga_alb_certlab2a.arn
  validation_record_fqdns = [for record in aws_route53_record.helga_alb_cert_validation : record.fqdn]
}