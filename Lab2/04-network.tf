############################################
# Locals (naming convention: helga-*)
############################################
locals {
  name_prefix = var.project_name
}

############################################
# VPC + Internet Gateway
############################################

# Explanation: helga needs a hyperlane—this VPC is the Millennium Falcon’s flight corridor.
resource "aws_vpc" "helga_vpclab2a" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpclab2a"
  }
}

# Explanation: Even Wookiees need to reach the wider galaxy—IGW is your door to the public internet.
resource "aws_internet_gateway" "helga_igwlab2a" {
  vpc_id = aws_vpc.helga_vpclab2a.id

  tags = {
    Name = "${local.name_prefix}-igwlab2a"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation: Public subnets are like docking bays—ships can land directly from space (internet).
resource "aws_subnet" "helga_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.helga_vpclab2a.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
  }
}

# Explanation: Private subnets are the hidden Rebel base—no direct access from the internet.
resource "aws_subnet" "helga_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.helga_vpclab2a.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
  }
}

############################################
# NAT Gateway + EIP
############################################

# Explanation: helga wants the private base to call home—EIP gives the NAT a stable “holonet address.”
resource "aws_eip" "helga_nat_eiplab2a" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eiplab2a"
  }
}

# Explanation: NAT is helga’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "helga_natlab2a" {
  allocation_id = aws_eip.helga_nat_eiplab2a.id
  subnet_id     = aws_subnet.helga_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.name_prefix}-natlab2a"
  }

  depends_on = [aws_internet_gateway.helga_igwlab2a]
}

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table = “open lanes” to the galaxy via IGW.
resource "aws_route_table" "helga_public_rtlab2a" {
  vpc_id = aws_vpc.helga_vpclab2a.id

  tags = {
    Name = "${local.name_prefix}-public-rtlab2a"
  }
}

# Explanation: This route is the Kessel Run—0.0.0.0/0 goes out the IGW.
resource "aws_route" "helga_public_default_route" {
  route_table_id         = aws_route_table.helga_public_rtlab2a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.helga_igwlab2a.id
}

# Explanation: Attach public subnets to the “public lanes.”
resource "aws_route_table_association" "helga_public_rta" {
  count          = length(aws_subnet.helga_public_subnets)
  subnet_id      = aws_subnet.helga_public_subnets[count.index].id
  route_table_id = aws_route_table.helga_public_rtlab2a.id
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "helga_private_rtlab2a" {
  vpc_id = aws_vpc.helga_vpclab2a.id

  tags = {
    Name = "${local.name_prefix}-private-rtlab2a"
  }
}

# Explanation: Private subnets route outbound internet via NAT (helga-approved stealth).
resource "aws_route" "helga_private_default_route" {
  route_table_id         = aws_route_table.helga_private_rtlab2a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.helga_natlab2a.id
}

# Explanation: Attach private subnets to the “stealth lanes.”
resource "aws_route_table_association" "helga_private_rta" {
  count          = length(aws_subnet.helga_private_subnets)
  subnet_id      = aws_subnet.helga_private_subnets[count.index].id
  route_table_id = aws_route_table.helga_private_rtlab2a.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

# Explanation: EC2 SG is helga’s bodyguard—only let in what you mean to.
resource "aws_security_group" "helga_ec2_sglab2a" {
  name        = "${local.name_prefix}-ec2-sglab2a"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.helga_vpclab2a.id

  

  # TODO: student adds inbound rules (HTTP 80, SSH 22 from their IP)
  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["185.141.119.79/32"]
  }

  # TODO: student ensures outbound allows DB port to RDS SG (or allow all outbound)
  egress {
    description      = "allow outbound MySQL to RDS SG"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
}

  tags = {
    Name = "${local.name_prefix}-ec2-sglab2a"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "helga_rds_sglab2a" {
  name        = "${local.name_prefix}-rds-sglab2a"
  description = "RDS security group"
  vpc_id      = aws_vpc.helga_vpclab2a.id

  # TODO: student adds inbound MySQL 3306 from aws_security_group.helga_ec2_sglab2a.id
  ingress {
    description      = "MySQL from EC2 SG"
    from_port        = var.db_port
    to_port          = var.db_port
    protocol         = "tcp"

    #SG to SG reference - Necessary Security Pattern
    security_groups  = [aws_security_group.helga_ec2_sglab2a.id]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sglab2a"
  }

}

############################################
# RDS Subnet Group FOR LAB 2a it says it already exists. 
############################################

 # Explanation: RDS hides in private subnets like the Rebel base on Hoth—cold, quiet, and not public.
resource "aws_db_subnet_group" "helga_rds_subnet_grouplab2a" {
  name       = "${local.name_prefix}-rds-subnet-grouplab2a"
  subnet_ids = aws_subnet.helga_private_subnets[*].id
  tags = {
    Name = "${local.name_prefix}-rds-subnet-grouplab2a"
  }
} 

############################################
# RDS Instance (MySQL)
############################################

# Explanation: This is the holocron of state—your relational data lives here, not on the EC2.
resource "aws_db_instance" "helga_rdslab2a" {
  identifier             = "${local.name_prefix}-rdslab2a"
  engine                 = var.db_engine
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.helga_rds_subnet_grouplab2a.name
  vpc_security_group_ids = [aws_security_group.helga_rds_sglab2a.id]



  # TODO: student sets multi_az / backups / monitoring as stretch goals
  publicly_accessible    = false #RDS must not be exposed to the internet
  skip_final_snapshot    = true #allows for quick teardown
  deletion_protection    = false #Setting will allow terraform destroy
  multi_az               = false #single AZ for lab cost savings
   
  backup_retention_period = 0

  #performance insights are disabled in the free tier
  performance_insights_enabled = false

  #Allows minor upgrades
  auto_minor_version_upgrade = true
  tags = {
    Name = "${local.name_prefix}-rdslab2a"
  }
}

############################################
# IAM Role + Instance Profile for EC2
############################################

# Explanation: helga refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "helga_ec2_rolelab2a" {
  name = "${local.name_prefix}-ec2-rolelab2a"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Explanation: These policies are your Wookiee toolbelt—tighten them (least privilege) as a stretch goal.
resource "aws_iam_role_policy_attachment" "helga_ec2_ssm_attach" {
  role       = aws_iam_role.helga_ec2_rolelab2a.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
resource "aws_iam_role_policy_attachment" "helga_ec2_secrets_attach" {
  role      = aws_iam_role.helga_ec2_rolelab2a.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # TODO: student replaces w/ least privilege
}

# Explanation: CloudWatch logs are the “ship’s black box”—you need them when things explode.
resource "aws_iam_role_policy_attachment" "helga_ec2_cw_attach" {
  role      = aws_iam_role.helga_ec2_rolelab2a.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Explanation: the ablity to obtain the log events on command.
###ADDED IN BY ME
/* resource "aws_iam_role_policy_attachment" "helga_ec2_getlogevents_attach" {
  role      = aws_iam_role.helga_ec2_rolelab2a.name
  policy_arn = "arn:aws:iam::aws:policy/GetLogEvents"
} */

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "helga_instance_profilelab2a" {
  name = "${local.name_prefix}-instance-profilelab2a"
  role = aws_iam_role.helga_ec2_rolelab2a.name
}
 
############################################
# Parameter Store (SSM Parameters)
############################################

# Explanation: Parameter Store is helga’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "helga_db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.helga_rdslab2a.address
  overwrite = true

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

# Explanation: Ports are boring, but even Wookiees need to know which door number to kick in.
resource "aws_ssm_parameter" "helga_db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.helga_rdslab2a.port)
  overwrite = true

  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

# Explanation: DB name is the label on the crate—without it, you’re rummaging in the dark.
resource "aws_ssm_parameter" "helga_db_name_param" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name
  overwrite = true
  region = "us-east-1"

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################



# In your lab config (destroyable)
data "aws_secretsmanager_secret" "helga_db_secretlab2a" {
  name = "helga/rds/mysqlv2"  # or whatever the name is
}

data "aws_secretsmanager_secret_version" "helga_db_secret_versionlab2a" {
  secret_id = data.aws_secretsmanager_secret.helga_db_secretlab2a.id
}


# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "helga_db_secret_versionlab2a" {
  secret_id = data.aws_secretsmanager_secret.helga_db_secretlab2a.id

  secret_string = jsonencode({
    username = "admin"
    password = "i8$2>Iu]dQOh60lzzRG#iHJS1mg7"
    host     = "helga-rdslab2a.chkce02amfxr.us-east-1.rds.amazonaws.com"
    port     = 3306
    dbname   = "t_labdb"
  })
}

############################################
# CloudWatch Logs (Log Group)
############################################

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "helga_log_grouplab2a" {
  name              = "/aws/ec2/${local.name_prefix}-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-grouplab2a"
  }
}

############################################
# Custom Metric + Alarm (Skeleton)
############################################

# Explanation: Metrics are helga’s growls—when they spike, something is wrong.
# NOTE: Students must emit the metric from app/agent; this just declares the alarm.
resource "aws_cloudwatch_metric_alarm" "helga_db_alarmlab2a" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions       = [aws_sns_topic.helga_sns_topiclab2a.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}

############################################
# SNS (PagerDuty simulation)
############################################

# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
resource "aws_sns_topic" "helga_sns_topiclab2a" {
  name = "${local.name_prefix}-db-incidents"
}

# Explanation: Email subscription = “poor man’s PagerDuty”—still enough to wake you up at 3AM.
resource "aws_sns_topic_subscription" "helga_sns_sublab2a" {
  topic_arn = aws_sns_topic.helga_sns_topiclab2a.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
  region    = "us-east-1"
}

############################################
# (Optional but realistic) VPC Endpoints (Skeleton)
############################################

# Explanation: Endpoints keep traffic inside AWS like hyperspace lanes—less exposure, more control.
# TODO: students can add endpoints for SSM, Logs, Secrets Manager if doing “no public egress” variant.
# resource "aws_vpc_endpoint" "helga_vpce_ssm" { ... }