#--------------LOCALS-----------------

locals {
  name_prefix = var.project_name
}

# ---------------VPC----------------------

resource "aws_vpc" "armageddon" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

#----------------SUBNETS--------------------

# PUBLIC SUBNET

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.armageddon.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
     Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
  }
}

# PRIVATE SUBNET

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.armageddon.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
  }
}

#---------------INTERNET GATEWAY (IGW)-----------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.armageddon.id

  tags = {
    Name    = "${local.name_prefix}-igw"
  }
}


#----------------- NETWORK ADDRESS TRANSLATION (NAT) GATEWAY & ELASTIC IP-------------------------

resource "aws_eip" "nat01" {

  tags = {
    Name = "${local.name_prefix}-nat01"
  }
}

resource "aws_nat_gateway" "nat01" {
  allocation_id = aws_eip.nat01.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${local.name_prefix}-nat01"
  }

  depends_on = [aws_internet_gateway.igw]
}


#------------------- ROUTE TABLES------------------------------------------

# PUBLIC SUBNET ASSIGNMENT 
resource "aws_route_table" "public_rt01" {
  vpc_id = aws_vpc.armageddon.id

  # route {
  #     cidr_block                 = "0.0.0.0/0"
  #     gateway_id                 = aws_internet_gateway.igw.id

    
  #   }
  
  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public-us-east-1a" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt01.id
}

# PRIVATE SUBNET ASSIGNMENT

resource "aws_route_table" "private_rt01" {
  vpc_id = aws_vpc.armageddon.id

  # route {
  #     cidr_block                 = "0.0.0.0/0"
  #     nat_gateway_id             = aws_nat_gateway.nat.id


  #   }
  
  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

resource "aws_route" "chewbacca_private_default_route" {
  route_table_id         = aws_route_table.private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat01.id
}

resource "aws_route_table_association" "private-us-east-1a" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt01.id
}


#----------------SECURITY GROUPS-----------------------


resource "aws_security_group" "sg-ec2-lab" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.armageddon.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

# SSH rule disabled — EC2 is now in a private subnet with no public IP.
# Access is provided via SSM Session Manager through VPC endpoints.
# resource "aws_vpc_security_group_ingress_rule" "armageddon-sg-ssh" {
#   description       = "SSH"
#   security_group_id = aws_security_group.sg-ec2-lab.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
#
#   tags = {
#     Name = "SSH"
#   }
# }

resource "aws_vpc_security_group_ingress_rule" "armageddon-sg-http" {
  description       = "HTTP"
  security_group_id = aws_security_group.sg-ec2-lab.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  tags = {
    Name = "HTTP"
  }
}

resource "aws_vpc_security_group_egress_rule" "armageddon-sg-egress" {
  security_group_id = aws_security_group.sg-ec2-lab.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "sg-rds-lab" {
  name        = "${var.project_name}-rds-sg"
  description = "Secure DB traffic"
  vpc_id      = aws_vpc.armageddon.id

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "armageddon-sg-ingress" {
  description                  = "DB"
  security_group_id            = aws_security_group.sg-rds-lab.id
  referenced_security_group_id = aws_security_group.sg-ec2-lab.id
  from_port                    = var.db_port
  ip_protocol                  = "tcp"
  to_port                      = var.db_port

  tags = {
    Name = "db"
  }
}

resource "aws_vpc_security_group_egress_rule" "sg-rds-lab-egress" {
  security_group_id = aws_security_group.sg-rds-lab.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


#----------------VPC ENDPOINT SECURITY GROUP-----------------------

resource "aws_security_group" "sg-vpce" {
  name        = "${local.name_prefix}-vpce-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.armageddon.id

  tags = {
    Name = "${local.name_prefix}-vpce-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpce-https-ingress" {
  description       = "HTTPS from VPC"
  security_group_id = aws_security_group.sg-vpce.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443

  tags = {
    Name = "HTTPS-from-VPC"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpce-egress" {
  security_group_id = aws_security_group.sg-vpce.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#----------------VPC ENDPOINTS-----------------------

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.armageddon.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnets[0].id]
  security_group_ids  = [aws_security_group.sg-vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-ssm"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.armageddon.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnets[0].id]
  security_group_ids  = [aws_security_group.sg-vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.armageddon.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnets[0].id]
  security_group_ids  = [aws_security_group.sg-vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-ec2messages"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.armageddon.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnets[0].id]
  security_group_ids  = [aws_security_group.sg-vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-secretsmanager"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.armageddon.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnets[0].id]
  security_group_ids  = [aws_security_group.sg-vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-vpce-logs"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.armageddon.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt01.id]

  tags = {
    Name = "${local.name_prefix}-vpce-s3"
  }
}


#----------------------ELASTIC COMPUTE CLOUD (EC2)-----------------------------


resource "aws_instance" "lab-ec201" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  vpc_security_group_ids      = [aws_security_group.sg-ec2-lab.id]
  subnet_id                   = aws_subnet.private_subnets[0].id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile01.name

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec201"
  }
}


#----------------------RELATIONAL DATABASE SERVICE (RDS)--------------------------


resource "aws_db_instance" "rds01" {
  allocated_storage          = var.db_allocated_storage
  db_name                    = var.db_name
  identifier                 = "${local.name_prefix}-rds01"
  engine                     = var.db_engine
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  username                   = var.db_username
  password                   = var.db_password
  vpc_security_group_ids     = [aws_security_group.sg-rds-lab.id]
  parameter_group_name       = "default.mysql8.0"
  storage_type               = "gp2"   
  performance_insights_enabled = false
  db_subnet_group_name       = aws_db_subnet_group.rds_subnet_group01.name
  publicly_accessible        = false
  port                       = var.db_port
  backup_retention_period    = var.db_backup_retention
  storage_encrypted          = true
  skip_final_snapshot        = true
  auto_minor_version_upgrade = true
}

resource "aws_db_subnet_group" "rds_subnet_group01" {
  name = "${local.name_prefix}-rds-subnet-group01"
  subnet_ids = aws_subnet.private_subnets[*].id


   tags = {
    Name = "${local.name_prefix}-rds01"
}
}

#--------------------IDENTITY AND ACCESS MANAGEMENT (IAM)---------------------

data "aws_caller_identity" "current" {}

# Assume role policy - allows EC2 service to assume this role
data "aws_iam_policy_document" "ec2_assume_role" {
  
  version   = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# EC2 PERMISSIONS POLICY

data "aws_iam_policy_document" "ec2_permissions" {
  statement {
    sid     = "ReadSpecificSecret"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}*"
    ]
  }
    statement {
    sid    = "ReadSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_prefix}",
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_prefix}/*"
    ]
  }

  statement {
    sid    = "WriteCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DescribeCloudWatchAlarms"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DescribeRDSInstances"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# # Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
# resource "aws_iam_role_policy_attachment" "ec2_secrets_attach" {
#   role      = aws_iam_role.ec2_role01.name
#   policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # TODO: student replaces w/ least privilege
# }

# # Explanation: CloudWatch logs are the “ship’s black box”—you need them when things explode.
# resource "aws_iam_role_policy_attachment" "ec2_cw_attach" {
#   role      = aws_iam_role.ec2_role01.name
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# }

# EC2 INSTANCE PROFILE
resource "aws_iam_instance_profile" "ec2_profile01" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role01.name
}

# IAM ROLE

resource "aws_iam_role" "ec2_role01" {
  name               = "${var.project_name}-ec2-role01"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# ASSIGN PERMISSIONS POLICY TO ROLE

resource "aws_iam_role_policy" "secrets_access_policy" {
  name   = "${var.project_name}-ec2-policy"
  role   = aws_iam_role.ec2_role01.id
  policy = data.aws_iam_policy_document.ec2_permissions.json
}








#----------------SECRETS MANAGER--------------------------

resource "aws_secretsmanager_secret" "secret" {
  name        = "${local.name_prefix}/rds/mysql"
}

resource "aws_secretsmanager_secret_version" "secret_version01" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = var.db_engine
    host     = aws_db_instance.rds01.address
    port     = aws_db_instance.rds01.port
    dbname   = var.db_name
  })
}



#----------------SSM PARAMETER STORE------------------------------------------

resource "aws_ssm_parameter" "db_endpoint_param" {
  name        = "${var.ssm_parameter_prefix}/endpoint"
  type        = "String"
  value       = aws_db_instance.rds01.address

    tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

resource "aws_ssm_parameter" "db_port_param" {
  name        = "${var.ssm_parameter_prefix}/port"
  type        = "String"
  value       = tostring(aws_db_instance.rds01.port)

    tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

resource "aws_ssm_parameter" "db_name_param" {
  name        = "${var.ssm_parameter_prefix}/dbname"
  type        = "String"
  value       = var.db_name

    tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}





# -----------------------CLOUDWATCH AND SNS----------------------------------

resource "aws_cloudwatch_log_group" "log_group01" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

    tags = {
    Name = "${local.name_prefix}-log-group01"
  }
}

# METRIC FILTER PATTERN: Looks for error patterns in the logs
resource "aws_cloudwatch_log_metric_filter" "db_failure" {
  name           = "${var.project_name}-db-failure-filter"
  pattern        = "\"Database connection failed\""
  log_group_name = aws_cloudwatch_log_group.log_group01.name

  metric_transformation {
    name      = "DBConnectionFailures"
    namespace = "${var.environment}/${var.project_name}"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_sns_topic" "sns_topic01" {
  name         = "${local.name_prefix}-db-incidents"
}

# Email subscription for SNS Alerts
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.sns_topic01.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch alarm
resource "aws_cloudwatch_metric_alarm" "db_alarm01" {
  alarm_name          = "${local.name_prefix}-db-failure-alarm"
  alarm_description   = "Triggers when DB connection failures occur"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "DBConnectionFailures"
  namespace           = "${var.environment}/${var.project_name}"
  statistic           = "Sum"
  threshold           = var.alarm_threshold
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.sns_topic01.arn]
  ok_actions    = [aws_sns_topic.sns_topic01.arn]

    tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}


############################################
# Bonus B - ALB (Public) -> Target Group (Private EC2) + TLS + WAF + Monitoring
############################################

locals {
  app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

############################################
# Route53 Hosted Zone (data source)
############################################

data "aws_route53_zone" "zone" {
  name         = var.domain_name
  private_zone = false
}

############################################
# Security Group: ALB
############################################

resource "aws_security_group" "alb_sg01" {
  name        = "${var.project_name}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.armageddon.id

  tags = {
    Name = "${var.project_name}-alb-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb-http-ingress" {
  description       = "HTTP from internet"
  security_group_id = aws_security_group.alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  tags = {
    Name = "ALB-HTTP"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb-https-ingress" {
  description       = "HTTPS from internet"
  security_group_id = aws_security_group.alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443

  tags = {
    Name = "ALB-HTTPS"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb-egress" {
  security_group_id = aws_security_group.alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Allow ALB -> EC2 on app port 80
resource "aws_security_group_rule" "ec2_ingress_from_alb01" {
  type                     = "ingress"
  security_group_id        = aws_security_group.sg-ec2-lab.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg01.id
}

############################################
# Application Load Balancer
############################################

resource "aws_lb" "alb01" {
  name               = "${var.project_name}-alb01"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb_sg01.id]
  subnets         = aws_subnet.public_subnets[*].id

  access_logs {
    bucket  = aws_s3_bucket.alb_logs_bucket01[0].bucket
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

  depends_on = [aws_s3_bucket_policy.alb_logs_policy01]

  tags = {
    Name = "${var.project_name}-alb01"
  }
}

############################################
# Target Group + Attachment
############################################

resource "aws_lb_target_group" "tg01" {
  name     = "${var.project_name}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.armageddon.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg01"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach01" {
  target_group_arn = aws_lb_target_group.tg01.arn
  target_id        = aws_instance.lab-ec201.id
  port             = 80
}

############################################
# ACM Certificate (TLS) for app.jason-cramer.com
############################################

resource "aws_acm_certificate" "acm_cert01" {
  domain_name               = local.app_fqdn
  subject_alternative_names = [var.domain_name]
  validation_method         = var.certificate_validation_method

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-acm-cert01"
  }
}

# DNS validation records in Route53
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.acm_cert01.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "acm_validation01" {
  certificate_arn         = aws_acm_certificate.acm_cert01.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

############################################
# Route53 CNAME: app.jason-cramer.com -> ALB
############################################

resource "aws_route53_record" "app_cname" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.app_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.alb01.dns_name]
}

############################################
# ALB Listeners: HTTP -> HTTPS redirect, HTTPS -> TG
############################################

resource "aws_lb_listener" "http_listener01" {
  load_balancer_arn = aws_lb.alb01.arn
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

resource "aws_lb_listener" "https_listener01" {
  load_balancer_arn = aws_lb.alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.acm_validation01.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg01.arn
  }

  depends_on = [aws_acm_certificate_validation.acm_validation01]
}

############################################
# WAFv2 Web ACL (Basic managed rules)
############################################

resource "aws_wafv2_web_acl" "waf01" {
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

  tags = {
    Name = "${var.project_name}-waf01"
  }
}

resource "aws_wafv2_web_acl_association" "waf_assoc01" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.alb01.arn
  web_acl_arn  = aws_wafv2_web_acl.waf01[0].arn
}

############################################
# CloudWatch Alarm: ALB 5xx -> SNS
############################################

resource "aws_cloudwatch_metric_alarm" "alb_5xx_alarm01" {
  alarm_name          = "${var.project_name}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.alb01.arn_suffix
  }

  alarm_actions = [aws_sns_topic.sns_topic01.arn]

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm01"
  }
}

############################################
# CloudWatch Dashboard
############################################

resource "aws_cloudwatch_dashboard" "dashboard01" {
  dashboard_name = "${var.project_name}-dashboard01"

  dashboard_body = jsonencode({
    widgets = [
      {
        type  = "metric"
        x     = 0
        y     = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.alb01.arn_suffix ],
            [ ".", "HTTPCode_ELB_5XX_Count", ".", aws_lb.alb01.arn_suffix ]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB: Requests + 5XX"
        }
      },
      {
        type  = "metric"
        x     = 12
        y     = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.alb01.arn_suffix ]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB: Target Response Time"
        }
      }
    ]
  })
}


#-----------------------------------END------------------------------------------------------------