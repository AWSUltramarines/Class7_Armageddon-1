locals {
  # Parameter Store paths
  ssm_db_endpoint_name = "/lab/db/endpoint"
  ssm_db_port_name     = "/lab/db/port"
  ssm_db_name_name     = "/lab/db/name"

  # Secrets Manager name required by lab text
  secrets_name = "lab/rds/mysql"
}
