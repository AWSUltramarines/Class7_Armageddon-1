############################################
# Secrets Manager Configuration
# Updates RDS credentials after database creation
############################################

# This resource updates the Secrets Manager secret with actual RDS endpoint
# after the database is created. The Flask app reads from this secret.

resource "aws_secretsmanager_secret_version" "helga_rds_secret_update" {
  secret_id = data.aws_secretsmanager_secret.helga_db_secretlab2a.id
  
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.helga_rdslab2a.address
    port     = aws_db_instance.helga_rdslab2a.port
    dbname   = var.db_name
  })

  # Ensure RDS is created before updating secret
  depends_on = [aws_db_instance.helga_rdslab2a]
}
