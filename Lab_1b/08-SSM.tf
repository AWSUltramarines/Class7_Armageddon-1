resource "aws_ssm_parameter" "db_endpoint" {
  name  = local.ssm_db_endpoint_name
  type  = "String"
  value = var.db_endpoint
}

resource "aws_ssm_parameter" "db_port" {
  name  = local.ssm_db_port_name
  type  = "String"
  value = tostring(var.db_port)
}

resource "aws_ssm_parameter" "db_name" {
  name  = local.ssm_db_name_name
  type  = "String"
  value = var.db_name
}

