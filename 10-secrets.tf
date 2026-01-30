resource "aws_secretsmanager_secret" "secret" {
  name        = "lab/rds/mysql1"
  description = "RDS database credentials"
}

resource "aws_secretsmanager_secret_version" "rds_secret_value" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    username = "admin"
    password = "armageddon1"
    engine   = "mysql"
    host     = aws_db_instance.lab-mysql.address
    port     = 3306
    dbname   = "labdb"
  })
}