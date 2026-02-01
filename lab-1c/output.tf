output "vpc_id" {
  value = aws_vpc.dev.id
}

output "public_subnet_ids" {
  value = local.public_subnets[*]
}

output "private_subnet_ids" {
  value = local.private_subnets[*]
}

output "ec2_instance_id" {
  value = aws_instance.test_server.id
}

output "rds_endpoint" {
  value = aws_db_instance.rds_instance.address
}

output "sns_topic_arn" {
  value = aws_sns_topic.sns_topic.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.log_group.name
}