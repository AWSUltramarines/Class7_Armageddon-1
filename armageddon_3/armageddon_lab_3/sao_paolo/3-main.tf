#--------------LOCALS-----------------

locals {
  name_prefix = var.project_name
}

# Explanation: Auto-resolve the latest AL2023 AMI for the current region — no hardcoded AMI ID needed.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
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

# REMOVED — No local RDS in Liberdade. All DB traffic goes to Shinjuku (Tokyo) via TGW.


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
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.ec2_instance_type
  vpc_security_group_ids      = [aws_security_group.sg-ec2-lab.id]
  subnet_id                   = aws_subnet.private_subnets[0].id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile01.name

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "${local.name_prefix}-ec201"
  }
}


# REMOVED — RDS lives in Shinjuku (Tokyo) only. Liberdade connects via TGW.

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
    host     = var.shinjuku_rds_endpoint
    port     = var.db_port
    dbname   = var.db_name
  })
}



#----------------SSM PARAMETER STORE------------------------------------------

resource "aws_ssm_parameter" "db_endpoint_param" {
  count       = var.shinjuku_rds_endpoint != "" ? 1 : 0
  name        = "${var.ssm_parameter_prefix}/endpoint"
  type        = "String"
  value       = var.shinjuku_rds_endpoint

    tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

resource "aws_ssm_parameter" "db_port_param" {
  name        = "${var.ssm_parameter_prefix}/port"
  type        = "String"
  value       = tostring(var.db_port)

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


#-----------------------------------END------------------------------------------------------------