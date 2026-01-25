module "network" {
  source                    = "./modules/network"
  name_prefix               = var.name_prefix
  cidr_block                = var.cidr_block
  terraform_tag             = var.terraform_tag
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs      = var.private_subnet_cidrs
  azs                       = var.azs
  enable_dns_hostnames      = var.enable_dns_hostnames
  enable_dns_support        = var.enable_dns_support
  egress_cidr_ipv4          = var.egress_cidr_ipv4
  instance_tenancy          = var.instance_tenancy
  vpce_https_cidr_ipv4      = var.vpce_https_cidr_ipv4
  generic_inbound_cidr_ipv4 = var.generic_inbound_cidr_ipv4
}

module "iam" {
  source        = "./modules/iam"
  name_prefix   = var.name_prefix
  secret_name   = var.secret_name
  terraform_tag = var.terraform_tag
  log_group_arn = module.alerts.log_group_arn
  region        = var.region
}

module "vpc_endpoints" {
  source              = "./modules/vpc_endpoints"
  name_prefix         = var.name_prefix
  terraform_tag       = var.terraform_tag
  region              = var.region
  vpc_id              = module.network.vpc_id
  private_subnet_ids  = module.network.private_subnet_ids
  vpce_sg_id          = module.network.security_group_ids["vpce_sg"]
  private_route_table = module.network.private_route_table
}

module "compute" {
  source               = "./modules/compute"
  name_prefix          = var.name_prefix
  instance_type        = var.instance_type
  vpc_id               = module.network.vpc_id
  private_subnet_ids   = module.network.private_subnet_ids
  terraform_tag        = var.terraform_tag
  compute_sg_id        = module.network.security_group_ids["compute_sg"]
  alb_sg_id            = module.network.security_group_ids["alb_sg"]
  iam_instance_profile = module.iam.iam_instance_profile
}

module "database" {
  source               = "./modules/database"
  name_prefix          = var.name_prefix
  db_prefix            = var.db_prefix
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_engine            = var.db_engine
  db_engine_version    = var.db_engine_version
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  parameter_group_name = var.parameter_group_name
  skip_final_snapshot  = var.skip_final_snapshot
  publicly_accessible  = var.publicly_accessible
  terraform_tag        = var.terraform_tag
  rds_connection       = module.database.rds_connection
  rds_sg_id            = module.network.security_group_ids["rds_sg"]
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_group_name = module.network.db_subnet_group_name
}

module "load_balancer" {
  source                         = "./modules/load_balancer"
  name_prefix                    = var.name_prefix
  target_group_arn               = module.compute.target_group_arn
  launch_template_id             = module.compute.launch_template_id
  alb_sg_id                      = module.network.security_group_ids["alb_sg"]
  public_subnet_ids              = module.network.public_subnet_ids
  domain_name                    = var.domain_name
  certificate_arn                = module.route53.certificate_arn
  aws_acm_certificate_validation = module.route53.aws_acm_certificate_validation
}

module "autoscaling" {
  source                     = "./modules/autoscaling"
  name_prefix                = var.name_prefix
  domain_name                = var.domain_name
  target_group_arn           = module.compute.target_group_arn
  launch_template_id         = module.compute.launch_template_id
  asg_name                   = var.asg_name
  asg_min_size               = var.asg_min_size
  asg_max_size               = var.asg_max_size
  asg_desired_size           = var.asg_desired_size
  asg_hc_grace_period        = var.asg_hc_grace_period
  asg_policy_name            = var.asg_policy_name
  asg_policy_instance_warmup = var.asg_policy_instance_warmup
  public_subnet_ids          = module.network.public_subnet_ids
}

module "secrets" {
  source      = "./modules/secrets"
  name_prefix = var.name_prefix
  db_name     = var.db_name
  secret_name = var.secret_name
  db_username = var.db_username
  db_password = var.db_password
  rds_connection = {
    address = module.database.rds_connection.address
    port    = module.database.rds_connection.port
  }
}

module "route53" {
  source        = "./modules/route53"
  domain_name   = var.domain_name
  name_prefix   = var.name_prefix
  app_subdomain = var.app_subdomain
  alb_dns_name  = module.load_balancer.alb_dns_name
  alb_zone_id   = module.load_balancer.alb_zone_id
}

module "waf" {
  source      = "./modules/waf"
  name_prefix = var.name_prefix
  # enable_waf                 = var.enable_waf
  alb_arn       = module.load_balancer.alb_arn
  terraform_tag = var.terraform_tag
  region        = var.region
}

module "alerts" {
  source                = "./modules/alerts"
  name_prefix           = var.name_prefix
  sns_sub_endpoint      = var.sns_sub_endpoint
  sns_endpoint_protocol = var.sns_endpoint_protocol
  alb_arn_suffix        = module.load_balancer.alb_arn_suffix
  region                = var.region
  ec2_instance_id       = module.compute.ec2_instance_id
}

