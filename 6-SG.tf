resource "aws_security_group" "rds-lab" {
  name        = "rds-lab"
  description = "secure traffic for RDS database"
  vpc_id      = aws_vpc.armageddon.id

  tags = {
    Name = "rds-lab"
  }
}

resource "aws_security_group" "ec2-lab" {
  name        = "ec2-lab"
  description = "secure traffic for EC2"
  vpc_id      = aws_vpc.armageddon.id

  tags = {
    Name = "armageddon-sg"
  }
}

#Inbound rule #1 EC2*******
resource "aws_vpc_security_group_ingress_rule" "ec2-ssh" {

  security_group_id = aws_security_group.ec2-lab.id
  description       = "ssh"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

  tags = {             # this resource tag block is optional. 
    Name = "SSH"       # it just here to remind us that this inbound rule is for SSH.  Like a description
  }
}

resource "aws_vpc_security_group_ingress_rule" "armageddon-sg-ingress" {
  description                  = "DB"
  security_group_id            = aws_security_group.rds-lab.id
  referenced_security_group_id = aws_security_group.ec2-lab.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306

  tags = {
    Name = "db"
  }
}

#Outbound rule 1 RDS
resource "aws_vpc_security_group_egress_rule" "rds-lab-egress" {
  security_group_id = aws_security_group.rds-lab.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#Inbound  rule #1 EC2
resource "aws_vpc_security_group_ingress_rule" "armageddon-sg-http" {

  security_group_id = aws_security_group.ec2-lab.id
  description       = "http"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  tags = {             # this resource tag block is optional. 
    Name = "HTTP"       # it just here to remind us that this inbound rule is for SSH.  Like a description
  }
}

#Outbound rule 2
resource "aws_vpc_security_group_egress_rule" "armageddon-sg-egress" {
  security_group_id = aws_security_group.ec2-lab.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

