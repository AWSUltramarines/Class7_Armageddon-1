resource "aws_db_instance" "rds-lab-mysql" {
    allocated_storage    = 10
    db_name              = "labmysql"
    license_model        = "general-public-license" #o
    engine               = "mysql"
    engine_version       = "8.4"
    instance_class       = "db.t3.micro"
    manage_master_user_password = true
    username             = "admin"
    #password             = "SomeSuperPassword123!@!"
    vpc_security_group_ids = [aws_security_group.rds-ec2-sg.id]
    db_subnet_group_name = "db_mysql_subnet"
    skip_final_snapshot  = true
}