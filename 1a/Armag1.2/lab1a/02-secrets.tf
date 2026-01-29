# Generate a random password for the database
resource "random_password" "db_password" {
  length           = 26
  lower            = true
  upper            = true
  numeric          = true
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Builds container intended to hold secrets gained from block #3
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = var.secret_name
  description             = "Database credentials for RDS MySQL"
  recovery_window_in_days = 0 # Lab setting: immediate deletion on destroy

  tags = {
    Name = "lab/rds/mysql"
  }
}

# Puts the actual username and password inside the container built in block #2
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    dbname   = var.db_name
    host     = aws_db_instance.mysql.address # "mysql" should matches RDS resource name
    port     = var.db_port
  })
}