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

module "alerts" {
  source                = "./modules/alerts"
  name_prefix           = var.name_prefix
  sns_sub_endpoint      = var.sns_sub_endpoint
  sns_endpoint_protocol = var.sns_endpoint_protocol
  alb_arn_suffix        = module.load_balancer.alb_arn_suffix
  region                = var.region
  ec2_instance_id       = module.compute.ec2_instance_id
}

module "secrets" {
  source      = "./modules/secrets"
  name_prefix = var.name_prefix
  db_name     = var.db_name
  secret_name = var.secret_name
  db_username = var.db_username
  db_password = var.db_password
  # parameter_group_name = var.parameter_group_name
  rds_connection = {
    address = module.database.rds_connection.address
    port    = module.database.rds_connection.port
  }

}

module "iam" {
  source        = "./modules/iam"
  name_prefix   = var.name_prefix
  secret_name   = var.secret_name
  terraform_tag = var.terraform_tag
  log_group_arn = module.alerts.log_group_arn
  region        = var.region
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
  userdata_path        = "${path.module}/userdata-caching.sh"
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  name_prefix         = var.name_prefix
  target_group_arn    = module.compute.target_group_arn
  launch_template_id  = module.compute.launch_template_id
  alb_sg_id           = module.network.security_group_ids["alb_sg"]
  public_subnet_ids   = module.network.public_subnet_ids
  domain_name         = var.domain_name
  s3_bucket           = module.s3bucket.s3_bucket
  acm_certificate_arn = module.route53.certificate_arn
  cf_header_pw        = var.cf_header_pw
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
module "waf" {
  source              = "./modules/waf"
  name_prefix         = var.name_prefix
  alb_arn             = module.load_balancer.alb_arn
  terraform_tag       = var.terraform_tag
  region              = var.region
  waf_log_destination = var.waf_log_destination
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
  # s3_bucket           = module.s3bucket.s3_bucket
  # app_logs            = module.alerts.app_logs

  # app_logs = [
  #   { arn = "${module.alerts.log_group_arn}:*" }
  # ]

  # s3_bucket = []
}

module "route53" {
  source                = "./modules/route53"
  domain_name           = var.domain_name
  name_prefix           = var.name_prefix
  app_subdomain         = var.app_subdomain
  alb                   = module.load_balancer.alb
  cf_distro_domain_name = module.cloudfront.cf_distro_domain_name
  cf_distro_zone_id     = module.cloudfront.cf_distro_zone_id
}

module "s3bucket" {
  source                 = "./modules/s3bucket"
  name_prefix            = var.name_prefix
  terraform_tag          = var.terraform_tag
  enable_alb_access_logs = var.enable_alb_access_logs
  alb_access_logs_prefix = var.alb_access_logs_prefix
  domain_name            = var.domain_name
}

############################################
# ACM Certificate in us-east-1 for CloudFront
# (CloudFront requires certs in us-east-1)
############################################
resource "aws_acm_certificate" "cf_cert" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = ["${var.app_subdomain}.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cf_cert" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cf_cert.arn

  # DNS validation records are already created by the route53 module
  # ACM DNS validation is domain-based, so the same records work across regions
}

module "cloudfront" {
  source          = "./modules/cloudfront"
  name_prefix     = var.name_prefix
  terraform_tag   = var.terraform_tag
  domain_name     = var.domain_name
  app_subdomain   = var.app_subdomain
  cf_waf_acl_arn  = module.waf.cf_waf_acl_arn
  alb_dns_name    = module.load_balancer.alb_dns_name
  certificate_arn = aws_acm_certificate_validation.cf_cert.certificate_arn
  cf_header_pw    = var.cf_header_pw
  providers = {
    aws = aws.us_east_1
  }

}

############################################
# LAB 3A: TOKYO TRANSIT GATEWAY (HUB)
# Shinjuku Station - Data corridor hub
############################################

resource "aws_ec2_transit_gateway" "shinjuku_tgwlab3" {
  count       = var.enable_tgw ? 1 : 0
  description = "shinjuku-tgw01 (Tokyo hub for APPI-compliant architecture)"

  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name    = "shinjuku-tgwlab3"
    Role    = "Hub"
    Project = var.project_name
  }
}

############################################
# TOKYO VPC ATTACHMENT TO TGW
# Attaches to PRIVATE subnets only (via network module)
############################################

resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_attach_tokyo_vpclab3" {
  count              = var.enable_tgw ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].id

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name    = "shinjuku-attach-tokyo-vpclab3"
    Project = var.project_name
  }
}
data "aws_caller_identity" "self" {}

resource "aws_ec2_transit_gateway_peering_attachment" "tokyo_saopaulo" {
  count                   = var.create_tgw_peering ? 1 : 0
  peer_account_id         = data.aws_caller_identity.self.account_id
  peer_region             = "sa-east-1"
  peer_transit_gateway_id = var.saopaulo_tgw_id
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].id

  tags = {
    Name = "${var.name_prefix}-tgw-peering-tokyo-saopaulo"
    Side = "Creator"
  }
}

############################################
# TGW PEERING ATTACHMENT (Tokyo → São Paulo)
# Shinjuku opens corridor to Liberdade
# Tokyo (10.241.0.0/16) ↔ São Paulo (10.214.0.0/16)
############################################

# resource "aws_ec2_transit_gateway_peering_attachment" "shinjuku_to_liberdade_peer01" {
#   count                   = var.enable_tgw && var.saopaulo_tgw_id != "" ? 1 : 0
#   transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].id
#   peer_region             = "sa-east-1"
#   peer_transit_gateway_id = var.saopaulo_tgw_id
#   #peer_transit_gateway_id = data.aws_ec2_transit_gateway.saopaulo_tgw.id

#   tags = {
#     Name = "shinjuku-to-liberdade-peer01"
#     Type = "Cross-Region-Peering"
#   }
# }

############################################
# TGW ROUTE TABLE ENTRY FOR PEERING
# Route to São Paulo CIDR (10.214.0.0/16)
############################################

resource "aws_ec2_transit_gateway_route" "shinjuku_route_to_liberdade" {
  count                  = var.tgw_peering_accepted ? 1 : 0
  destination_cidr_block = var.saopaulo_vpc_cidr # 10.214.0.0/16
  # transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].association_default_route_table_id
  # Claude change
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tokyo_saopaulo[0].id
}

############################################
# TOKYO RETURN ROUTES TO SÃO PAULO
# Destination: 10.214.0.0/16 → TGW
############################################

resource "aws_route" "shinjuku_to_sp_route01" {
  count = var.enable_tgw ? 1 : 0

  route_table_id         = module.network.private_route_table
  destination_cidr_block = var.saopaulo_vpc_cidr # 10.214.0.0/16
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgwlab3[0].id
}

############################################
# RDS SECURITY GROUP RULE FOR SÃO PAULO
# Allows São Paulo compute (10.214.0.0/16) to access Tokyo RDS on 3306
############################################

resource "aws_security_group_rule" "shinjuku_rds_ingress_from_liberdade01" {
  count = var.enable_tgw ? 1 : 0

  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = [var.saopaulo_vpc_cidr] # 10.214.0.0/16
  description = "MySQL from Sao Paulo VPC via TGW"

  security_group_id = module.network.security_group_ids["rds_sg"]
}
