# Parameter Store for RDS MySQL endpoint
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/lab/db/endpoint"
  description = "RDS MySQL endpoint"
  type        = "String"
  value       = aws_db_instance.rds-mysql.address

  tags = {
    Name = "/lab/db/port"
  }
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/lab/db/port"
  description = "RDS MySQL port"
  type        = "String"
  value       = tostring(aws_db_instance.rds-mysql.port)

tags = {
    Name = "/lab/db/port"
  }
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/lab/db/name"
  description = "RDS MySQL database name"
  type        = "String"
  value       = aws_db_instance.rds-mysql.db_name

tags = {
    Name = "/lab/db/port"
  }
}