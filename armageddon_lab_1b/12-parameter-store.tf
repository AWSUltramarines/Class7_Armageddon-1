# SSM Parameter Store - Non-sensitive DB connection values
# Validate with: aws ssm get-parameters-by-path --path "/lab/rds/mysql" --query "Parameters[*].[Name,Value]" --output table

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/lab/rds/mysql/endpoint"
  description = "RDS db endpoint"
  type        = "String"
  value       = aws_db_instance.lab-mysql.address

}

resource "aws_ssm_parameter" "db_port" {
  name        = "/lab/rds/mysql/port"
  description = "RDS db port"
  type        = "String"
  value       = tostring(aws_db_instance.lab-mysql.port)

}

resource "aws_ssm_parameter" "db_name" {
  name        = "/lab/rds/mysql/dbname"
  description = "RDS db name"
  type        = "String"
  value       = "labdb"

}
