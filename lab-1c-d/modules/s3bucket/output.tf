output "s3_bucket" {
  value = aws_s3_bucket.alb_logs_bucket[0].bucket
}