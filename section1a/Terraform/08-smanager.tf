# Data source to read the RDS-managed secret
# (RDS creates this automatically when manage_master_user_password = true)
data "aws_secretsmanager_secret" "rds_master_secret" {
    arn = aws_db_instance.rds-lab-mysql.master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "rds_master_secret_version" {
    secret_id = data.aws_secretsmanager_secret.rds_master_secret.id
}

# Create the application secret that your Flask app uses
resource "aws_secretsmanager_secret" "app_db_secret" {
    name        = "db-secret-cred"
    description = "Secret for lab MySQL database"

    tags = {
        Project     = "Armageddon"
        Environment = "Development"
    }
}

# Populate the application secret with RDS connection details
resource "aws_secretsmanager_secret_version" "app_db_secret_version" {
    secret_id = aws_secretsmanager_secret.app_db_secret.id

    # Parse the RDS secret and add the connection details
    secret_string = jsonencode({
        username = jsondecode(data.aws_secretsmanager_secret_version.rds_master_secret_version.secret_string)["username"]
        password = jsondecode(data.aws_secretsmanager_secret_version.rds_master_secret_version.secret_string)["password"]
        host     = aws_db_instance.rds-lab-mysql.address
        port     = aws_db_instance.rds-lab-mysql.port
        database = aws_db_instance.rds-lab-mysql.db_name
    })
}

