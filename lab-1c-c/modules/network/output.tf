output "vpc_id" {
  value = aws_vpc.dev.id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "db_subnet_group_name" {
  value = aws_db_subnet_group.default.name
}
output "security_group_ids" {
  value = {
    rds_sg     = aws_security_group.rds_sg.id
    compute_sg = aws_security_group.compute_sg.id
    vpce_sg    = aws_security_group.vpce_sg.id
    alb_sg     = aws_security_group.alb_sg.id
  }
}
output "private_route_table" {
  value = aws_route_table.private.id
}