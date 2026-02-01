resource "aws_secretsmanager_secret" "db_secret" {
  name = var.secret_name

  # Takes secrets 7 days to be deleted once requested
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.rds_instance.address
    port     = aws_db_instance.rds_instance.port
    dbname   = var.db_name
  })

  # Takes secrets 7 days to be deleted once requested
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}