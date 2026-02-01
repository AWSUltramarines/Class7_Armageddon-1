###################################
#### FILL IN FOR YOUR ARCHITECTURE
###################################

###############################
# Project and Account Info
################################
name_prefix   = "armageddon-class7"
terraform_tag = "Made in Terraform"

################################
#### VPC
################################
cidr_block           = "10.45.0.0/16"
enable_dns_hostnames = true
enable_dns_support   = true
instance_tenancy     = "default"

################################
#### Network
################################
# region = "sa-east-1"
region = "us-east-1"

################################
#### Subnets
################################
public_subnet_cidrs  = ["10.45.1.0/24", "10.45.2.0/24"]
private_subnet_cidrs = ["10.45.11.0/24", "10.45.12.0/24"]
# azs                  = ["sa-east-1a", "sa-east-1b"]
azs = ["us-east-1a", "us-east-1b"]
################################
#### Security Groups
################################
generic_inbound_cidr_ipv4 = "0.0.0.0/0"
vpce_https_cidr_ipv4      = "0.0.0.0/0"
egress_cidr_ipv4          = "0.0.0.0/0"
# 24.99.204.240/32

################################
#### Instance
################################
instance_type = "t3.micro"
public_key    = "key/mykey.pub"

################################
#### Auto Scaling & Load Balancer
################################
asg_name                   = "dev-auto-scaling-group-"
asg_min_size               = 3
asg_max_size               = 9
asg_desired_size           = 6
asg_hc_grace_period        = 300
asg_policy_name            = "dev-cpu-target"
asg_policy_instance_warmup = 120
alb_arn_suffix             = "app/armageddon-class7-alb/50dc6c495c0c9188"

################################
#### RDS
################################
db_name              = "lab-mysql"
db_prefix            = "armageddon-class7"
db_username          = "admin"
db_password          = "S1lencer!23"
db_engine            = "mysql"
db_engine_version    = "8.0"
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 10
parameter_group_name = "default.mysql8.0"
publicly_accessible  = false
skip_final_snapshot  = true

################################
#### SNS
################################
sns_endpoint_protocol = "email"
sns_sub_endpoint      = "jescalesjr1987@gmail.com"

################################
#### Secrets Manager 
################################
secret_name = "classarm7/rds/mysql"