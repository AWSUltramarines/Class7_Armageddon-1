output "alb_arn_suffix" {
  value = aws_lb.dev_alb.arn_suffix
}
output "alb_arn" {
  value = aws_lb.dev_alb.arn
}
output "alb_dns_name" {
  value = aws_lb.dev_alb.dns_name
}
output "alb_zone_id" {
  value = aws_lb.dev_alb.zone_id
}