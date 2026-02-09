#####################################################
##### DATA VARIABLE
#####################################################
data "aws_ec2_managed_prefix_list" "cf_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
#####################################################
##### CLOUDFRONT SG
#####################################################
resource "aws_security_group" "alb_cf" {
  name        = "${var.name_prefix}-alb-cf-sg"
  description = "ALB CF Security Group"
  vpc_id      = aws_vpc.dev.id

  tags = {
    Name      = "${var.name_prefix}-alb-cf-sg"
    Terraform = var.terraform_tag
  }
}
resource "aws_security_group_rule" "alb_ingress_cf443" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_cf.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"

  prefix_list_ids = [
    data.aws_ec2_managed_prefix_list.cf_origin_facing.id
  ]
}
resource "aws_vpc_security_group_egress_rule" "alb_egress_cf" {
  security_group_id = aws_security_group.alb_cf.id
  cidr_ipv4         = var.egress_cidr_ipv4
  ip_protocol       = "-1"
}