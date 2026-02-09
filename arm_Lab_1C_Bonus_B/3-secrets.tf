# # Generate a random PW
# resource "random_password" "password" {
#   length           = 16
#   special          = true
#   lower            = true
#   upper            = true
#   numeric          = true

#   override_special = "!#$%&*()-_=+[]{}<>:?"
# }

# Build container to hold secret
resource "aws_secretsmanager_secret" "db_cradentials" {
  name                    = var.secret_name
  description             = "Flask App DB Credential"
  kms_key_id              = aws_kms_key.secrets_key.arn 
  recovery_window_in_days = 0

tags = {
    Name = "db-secret"
  }
}

# Insert username & PW inside the container

resource "aws_secretsmanager_secret_version" "db_cradentials" {
  secret_id     = aws_secretsmanager_secret.db_cradentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    port     = 3306
    host     = aws_db_instance.rds-mysql.address
    dbname   = var.db_name
  })
}

#####################################################################################

# Data source to read the RDS-managed secret
# (RDS creates this automatically when manage_master_user_password = true)
data "aws_secretsmanager_secret" "rds_master_secret" {
    arn = one(aws_db_instance.rds-mysql.master_user_secret[*].secret_arn)
}

data "aws_secretsmanager_secret_version" "rds_master_secret_version" {
    secret_id = data.aws_secretsmanager_secret.rds_master_secret.id
}

# Create the application secret that your Flask app uses
resource "aws_secretsmanager_secret" "app_db_secret1" {
    name_prefix = "db-secret-cred-"
    description = "Secret for lab MySQL database"

    tags = {
        Project     = "Armageddon"
        Environment = "Development"
    }
}

# Populate the application secret with RDS connection details
resource "aws_secretsmanager_secret_version" "app_db_secret_version" {
    secret_id = aws_secretsmanager_secret.app_db_secret1.id

    # Parse the RDS secret and add the connection details
    secret_string = jsonencode({
        username = jsondecode(data.aws_secretsmanager_secret_version.rds_master_secret_version.secret_string)["username"]
        password = jsondecode(data.aws_secretsmanager_secret_version.rds_master_secret_version.secret_string)["password"]
        host     = aws_db_instance.rds-mysql.address
        port     = aws_db_instance.rds-mysql.port
        database = aws_db_instance.rds-mysql.db_name
    })
}

# Create the KMS Key for encrypting Secrets Manager data
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for encrypting Flask app database secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Project     = "Armageddon"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}



# Create an alias for the key to make it easier to identify in the console
resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/flask-app-secrets-key"
  target_key_id = aws_kms_key.secrets_key.key_id
}
