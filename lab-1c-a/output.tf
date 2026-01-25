# Explanation: Outputs are your mission report—what got built and where to find it.
output "vpc_id" {
  value = aws_vpc.dev.id
}
output "private_subnet_ids" {
  value = local.private_subnets[*]
}

output "ec2_instance_id" {
  value = aws_instance.test_server.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.sns_topic.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.log_group.name
}

output "vpce_ssm_id" {
  value = aws_vpc_endpoint.vpce_ssm.id
}

output "vpce_logs_id" {
  value = aws_vpc_endpoint.vpce_logs.id
}

output "vpce_secrets_id" {
  value = aws_vpc_endpoint.vpce_secrets.id
}
output "vpce_kms_id" {
  value = aws_vpc_endpoint.vpce_kms.id
}
output "vpce_s3_id" {
  value = aws_vpc_endpoint.vpce_s3_gw.id
}