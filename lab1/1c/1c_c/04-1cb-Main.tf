/* locals {
  helga_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

# --- 1. Security Groups ---

resource "aws_security_group" "helga_alb_sg01" {
  name        = "${var.project_name}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.helga_vpc01.id

  # Inbound HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to everywhere (for health checks/forwarding)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg01" }
}

# Allow ALB to reach EC2
resource "aws_security_group_rule" "helga_ec2_ingress_from_alb01" {
  type                     = "ingress"
  security_group_id        = aws_security_group.helga_ec2_sg01.id # Ensure this matches your EC2 SG name
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.helga_alb_sg01.id
}

# --- 2. ALB & Target Group ---

 resource "aws_lb" "helga_alb01" {
  name               = "${var.project_name}-alb01"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.helga_alb_sg01.id]
  subnets            = aws_subnet.helga_public_subnets[*].id
  tags               = { Name = "${var.project_name}-alb01" }
} 

resource "aws_lb_target_group" "helga_tg01" {
  name     = "${var.project_name}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.helga_vpc01.id

  health_check {
    enabled             = true
    path                = "/" # Change to /health or /list if needed
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group_attachment" "helga_tg_attach01" {
  target_group_arn = aws_lb_target_group.helga_tg01.arn
  target_id        = aws_instance.helga_ec201.id # Ensure this matches your Private EC2 resource name
  port             = 80
}

# --- 3. TLS Certificate ---

resource "aws_acm_certificate" "helga_acm_cert01" {
  domain_name       = local.helga_fqdn
  validation_method = var.certificate_validation_method
  tags              = { Name = "${var.project_name}-acm-cert01" }
}

resource "aws_acm_certificate_validation" "helga_acm_validation01" {
  certificate_arn = aws_acm_certificate.helga_acm_cert01.arn
  # We will define the validation records in the Route53 file
}

# --- 4. Listeners ---

resource "aws_lb_listener" "helga_http_listener01" {
  load_balancer_arn = aws_lb.helga_alb01.arn
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

resource "aws_lb_listener" "helga_https_listener01" {
  load_balancer_arn = aws_lb.helga_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
   #This is for the 1cb certificate line
  certificate_arn   = aws_acm_certificate.helga_acm_cert01.arn
 
#This is for the 1cd certificate line
# Point to the new cert that covers both domains
  certificate_arn   = aws_acm_certificate.helga_cert01.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.helga_tg01.arn
  }
} 


#4-1C Updating the HTTPS Listener to depend on DNS validation when Route53 is managed by Terraform
/* resource "aws_lb_listener" "helga_https_listener01" {
  load_balancer_arn = aws_lb.helga_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.helga_acm_cert01.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.helga_tg01.arn
  }
  # Ensure DNS validation completes before listener creation
  depends_on = [
    aws_acm_certificate_validation.helga_acm_validation01_dns
  ]
} */

#4-1D: ALB Access Logs S3 Bucket + Apex Record
# ============================================
# S3 Bucket for ALB Access Logs
# ============================================
# Explanation: Chewbacca keeps flight logs—this bucket stores ALB access logs for audits and incident response.
/* resource "aws_s3_bucket" "helga_alb_logs_bucket01" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"
  tags = {
    Name = "${var.project_name}-alb-logs"
  }
} */
/* # Get current AWS account ID
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
} */
# ============================================
# Apex ALIAS Record: williebright.com -> ALB
# ============================================
# Explanation: This is the front gate—humans type this when they forget subdomains.
/* resource "aws_route53_record" "helga_apex_alias01" {
  zone_id = local.helga_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_lb.helga_alb01.dns_name
    zone_id                = aws_lb.helga_alb01.zone_id
    evaluate_target_health = true
  }
}
 

# --- 5. WAF Web ACL ---

resource "aws_wafv2_web_acl" "helga_waf01" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.project_name}-waf01"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf01"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-waf-common"
      sampled_requests_enabled   = true
    }
  }

  tags = { Name = "${var.project_name}-waf01" }
}

resource "aws_wafv2_web_acl_association" "helga_waf_assoc01" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.helga_alb01.arn
  web_acl_arn  = aws_wafv2_web_acl.helga_waf01[0].arn
}

# --- 6. CloudWatch Alarm: ALB 5xx -> SNS ---

resource "aws_cloudwatch_metric_alarm" "helga_alb_5xx_alarm01" {
  alarm_name          = "${var.project_name}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.helga_alb01.arn_suffix
  }

  alarm_actions = [aws_sns_topic.helga_sns_topic01.arn]

  tags = { Name = "${var.project_name}-alb-5xx-alarm01" }
}

# --- 7. CloudWatch Dashboard ---

resource "aws_cloudwatch_dashboard" "helga_dashboard01" {
  dashboard_name = "${var.project_name}-dashboard01"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.helga_alb01.arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", aws_lb.helga_alb01.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Helga ALB: Requests + 5XX"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.helga_alb01.arn_suffix]
          ]
          period = 300
          stat   = "Average"
           region = var.aws_region
          title  = "Helga ALB: Target Response Time"
        }
      }
    ]
  })
}
*/ 