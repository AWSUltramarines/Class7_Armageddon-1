################################
#### Parameter Store
################################
resource "aws_ssm_parameter" "db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = var.rds_connection.address

  tags = {
    Name = "${var.name_prefix}-param-db-endpoint"
  }
}
resource "aws_ssm_parameter" "db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(var.rds_connection.port)

  tags = {
    Name = "${var.name_prefix}-param-db-port"
  }
}
resource "aws_ssm_parameter" "db_name_param" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${var.name_prefix}-param-db-name"
  }
}
################################
#### Secrets Manager
################################
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
    host     = var.rds_connection.address
    port     = var.rds_connection.port
    dbname   = var.db_name
  })

  # Takes secrets 7 days to be deleted once requested
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}