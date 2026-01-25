output "rds_connection" {
  value = {
    address  = aws_db_instance.rds_instance.address
    port     = aws_db_instance.rds_instance.port
    endpoint = aws_db_instance.rds_instance.endpoint
  }
}
