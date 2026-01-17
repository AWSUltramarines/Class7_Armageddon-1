resource "aws_security_group" "sg-ec2-lab" {
  name        = "ec2-lab-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.armageddon.id

  tags = {
    Name = "armageddon-sg"
  }
}

# resource "aws_vpc_security_group_ingress_rule" "armageddon-sg-ssh" {
#   description       = "SSH"  
#   security_group_id = aws_security_group.sg-ec2-lab.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22

#   tags = {
#     Name = "SSH"
#   }
# }

resource "aws_vpc_security_group_ingress_rule" "armageddon-sg-http" {
  description       = "HTTP"  
  security_group_id = aws_security_group.sg-ec2-lab.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  tags = {
    Name = "HTTP"
  }
}

resource "aws_vpc_security_group_egress_rule" "armageddon-sg-egress" {
  security_group_id = aws_security_group.sg-ec2-lab.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_security_group" "sg-rds-lab" {
  name        = "rds-lab-sg"
  description = "Secure DB traffic"
  vpc_id      = aws_vpc.armageddon.id

  tags = {
    Name = "sg-rds-lab"
  }
}

resource "aws_vpc_security_group_ingress_rule" "armageddon-sg-ingress" {
  description                  = "DB"
  security_group_id            = aws_security_group.sg-rds-lab.id
  referenced_security_group_id = aws_security_group.sg-ec2-lab.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306

  tags = {
    Name = "db"
  }
}

resource "aws_vpc_security_group_egress_rule" "sg-rds-lab-egress" {
  security_group_id = aws_security_group.sg-rds-lab.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}