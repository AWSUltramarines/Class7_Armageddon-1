output "target_group_arn" {
  value = aws_lb_target_group.dev_tg.arn
}
output "launch_template_id" {
  value = aws_launch_template.dev_lt.id
}
output "ec2_instance_id" {
  value = aws_instance.test_server.id
} 