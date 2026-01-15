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
resource "aws_vpc" "helga_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}

# Explanation: Even Wookiees need to reach the wider galaxy—IGW is your door to the public internet.
resource "aws_internet_gateway" "helga_igw01" {
  vpc_id = aws_vpc.helga_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation: Public subnets are like docking bays—ships can land directly from space (internet).
resource "aws_subnet" "helga_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.helga_vpc01.id
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
  vpc_id            = aws_vpc.helga_vpc01.id
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
resource "aws_eip" "helga_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip01"
  }
}

# Explanation: NAT is helga’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "helga_nat01" {
  allocation_id = aws_eip.helga_nat_eip01.id
  subnet_id     = aws_subnet.helga_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.name_prefix}-nat01"
  }

  depends_on = [aws_internet_gateway.helga_igw01]
}

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table = “open lanes” to the galaxy via IGW.
resource "aws_route_table" "helga_public_rt01" {
  vpc_id = aws_vpc.helga_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

# Explanation: This route is the Kessel Run—0.0.0.0/0 goes out the IGW.
resource "aws_route" "helga_public_default_route" {
  route_table_id         = aws_route_table.helga_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.helga_igw01.id
}

# Explanation: Attach public subnets to the “public lanes.”
resource "aws_route_table_association" "helga_public_rta" {
  count          = length(aws_subnet.helga_public_subnets)
  subnet_id      = aws_subnet.helga_public_subnets[count.index].id
  route_table_id = aws_route_table.helga_public_rt01.id
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "helga_private_rt01" {
  vpc_id = aws_vpc.helga_vpc01.id

  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

# Explanation: Private subnets route outbound internet via NAT (helga-approved stealth).
resource "aws_route" "helga_private_default_route" {
  route_table_id         = aws_route_table.helga_private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.helga_nat01.id
}

# Explanation: Attach private subnets to the “stealth lanes.”
resource "aws_route_table_association" "helga_private_rta" {
  count          = length(aws_subnet.helga_private_subnets)
  subnet_id      = aws_subnet.helga_private_subnets[count.index].id
  route_table_id = aws_route_table.helga_private_rt01.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

# Explanation: EC2 SG is helga’s bodyguard—only let in what you mean to.
resource "aws_security_group" "helga_ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.helga_vpc01.id

  

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
    Name = "${local.name_prefix}-ec2-sg01"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "helga_rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.helga_vpc01.id

  # TODO: student adds inbound MySQL 3306 from aws_security_group.helga_ec2_sg01.id
  ingress {
    description      = "MySQL from EC2 SG"
    from_port        = var.db_port
    to_port          = var.db_port
    protocol         = "tcp"

    #SG to SG reference - Necessary Security Pattern
    security_groups  = [aws_security_group.helga_ec2_sg01.id]
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg01"
  }

}

############################################
# RDS Subnet Group
############################################

# Explanation: RDS hides in private subnets like the Rebel base on Hoth—cold, quiet, and not public.
resource "aws_db_subnet_group" "helga_rds_subnet_group01" {
  name       = "${local.name_prefix}-rds-subnet-group01"
  subnet_ids = aws_subnet.helga_private_subnets[*].id
  tags = {
    Name = "${local.name_prefix}-rds-subnet-group01"
  }
}

############################################
# RDS Instance (MySQL)
############################################

# Explanation: This is the holocron of state—your relational data lives here, not on the EC2.
resource "aws_db_instance" "helga_rds01" {
  identifier             = "${local.name_prefix}-rds01"
  engine                 = var.db_engine
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.helga_rds_subnet_group01.name
  vpc_security_group_ids = [aws_security_group.helga_rds_sg01.id]



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
    Name = "${local.name_prefix}-rds01"
  }
}

############################################
# IAM Role + Instance Profile for EC2
############################################

# Explanation: helga refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "helga_ec2_role01" {
  name = "${local.name_prefix}-ec2-role01"

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
  role       = aws_iam_role.helga_ec2_role01.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
resource "aws_iam_role_policy_attachment" "helga_ec2_secrets_attach" {
  role      = aws_iam_role.helga_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # TODO: student replaces w/ least privilege
}

# Explanation: CloudWatch logs are the “ship’s black box”—you need them when things explode.
resource "aws_iam_role_policy_attachment" "helga_ec2_cw_attach" {
  role      = aws_iam_role.helga_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Explanation: the ablity to obtain the log events on command.
###ADDED IN BY ME
/* resource "aws_iam_role_policy_attachment" "helga_ec2_getlogevents_attach" {
  role      = aws_iam_role.helga_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/GetLogEvents"
} */

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "helga_instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.helga_ec2_role01.name
}

############################################
# EC2 Instance (App Host)
############################################

# Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.
#THE ORIGINAL EC2 THAT WAS PUBLIC
/* resource "aws_instance" "helga_ec201" {
  ami                    = var.ec2_ami_id
  instance_type           = var.ec2_instance_type
  subnet_id               = aws_subnet.helga_public_subnets[0].id
  vpc_security_group_ids  = [aws_security_group.helga_ec2_sg01.id]
  iam_instance_profile    = aws_iam_instance_profile.helga_instance_profile01.name

  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec201"
  }
}
 */
############################################
# Parameter Store (SSM Parameters)
############################################

# Explanation: Parameter Store is helga’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "helga_db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.helga_rds01.address
  overwrite = true

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

# Explanation: Ports are boring, but even Wookiees need to know which door number to kick in.
resource "aws_ssm_parameter" "helga_db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.helga_rds01.port)
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

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################

# Explanation: Secrets Manager is helga’s locked holster—credentials go here, not in code.
resource "aws_secretsmanager_secret" "helga_db_secret01" {
  name = "${local.name_prefix}/rds/mysql"
}

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "helga_db_secret_version01" {
  secret_id = aws_secretsmanager_secret.helga_db_secret01.id

  secret_string = jsonencode({
    username = "admin"
    password = "i8$2>Iu]dQOh60lzzRG#iHJS1mg7"
    host     = "helga-rds01.chkce02amfxr.us-east-2.rds.amazonaws.com"
    port     = 3306
    dbname   = "t_labdb"
  })
}

############################################
# CloudWatch Logs (Log Group)
############################################

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "helga_log_group01" {
  name              = "/aws/ec2/${local.name_prefix}-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-group01"
  }
}

############################################
# Custom Metric + Alarm (Skeleton)
############################################

# Explanation: Metrics are helga’s growls—when they spike, something is wrong.
# NOTE: Students must emit the metric from app/agent; this just declares the alarm.
resource "aws_cloudwatch_metric_alarm" "helga_db_alarm01" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions       = [aws_sns_topic.helga_sns_topic01.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}

############################################
# SNS (PagerDuty simulation)
############################################

# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
resource "aws_sns_topic" "helga_sns_topic01" {
  name = "${local.name_prefix}-db-incidents"
}

# Explanation: Email subscription = “poor man’s PagerDuty”—still enough to wake you up at 3AM.
resource "aws_sns_topic_subscription" "helga_sns_sub01" {
  topic_arn = aws_sns_topic.helga_sns_topic01.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

############################################
# (Optional but realistic) VPC Endpoints (Skeleton)
############################################

# Explanation: Endpoints keep traffic inside AWS like hyperspace lanes—less exposure, more control.
# TODO: students can add endpoints for SSM, Logs, Secrets Manager if doing “no public egress” variant.
# resource "aws_vpc_endpoint" "helga_vpce_ssm" { ... }