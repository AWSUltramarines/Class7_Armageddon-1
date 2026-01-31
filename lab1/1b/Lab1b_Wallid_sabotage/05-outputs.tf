# Explanation: Outputs are your mission report—what got built and where to find it.
output "helga_vpc_id" {
  value = aws_vpc.helga_vpc01.id
}

output "helga_public_subnet_ids" {
  value = aws_subnet.helga_public_subnets[*].id
}

output "helga_private_subnet_ids" {
  value = aws_subnet.helga_private_subnets[*].id
}

output "helga_ec2_instance_id" {
  value = aws_instance.helga_ec201.id
}

output "helga_rds_endpoint" {
  value = aws_db_instance.helga_rds01.address
}

output "helga_sns_topic_arn" {
  value = aws_sns_topic.helga_sns_topic01.arn
}

output "helga_log_group_name" {
  value = aws_cloudwatch_log_group.helga_log_group01.name
}

#Bonus B Outputs for ALB and Target Group
output "helga_alb_dns_name" {
  value = aws_lb.helga_alb01.dns_name
}

output "helga_app_fqdn" {
  value = "${var.app_subdomain}.${var.domain_name}"
}