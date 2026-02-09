
resource "aws_security_group" "ec2_web" {
  name        = "ec2"
  description = "Security group for EC2 web application instance"
  vpc_id      = aws_vpc.armageddon-VPC.id

tags = {
    Name    = "ec2"
  
  }
}

# EC2 Inbound: HTTP from allowed CIDRs

 resource "aws_vpc_security_group_ingress_rule" "ec2-http"  {
   security_group_id            = aws_security_group.ec2_web.id 
   referenced_security_group_id = aws_security_group.alb_sg.id # ONLY ALB can talk to EC2
   from_port                    = 80 
   ip_protocol                  = "tcp"
   to_port                      = 80

tags = {
    Name    = "http"
  }
 }

# EC2 Inbound: SSH from restricted CIDR (conditional)

# resource "aws_vpc_security_group_ingress_rule" "web_server_ssh" {
#     security_group_id = aws_security_group.ec2_web.id
#     description = "SSH from internet"
#     cidr_ipv4         = "0.0.0.0/0"
#     from_port         = 22
#     ip_protocol       = "tcp"
#     to_port           = 22
# }

# EC2 Outbound egress rule

resource "aws_vpc_security_group_egress_rule" "web_server_egress" {
    security_group_id = aws_security_group.ec2_web.id
    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1"                                        # all ports open
}

####################################################################################

# Create the security group for the RDS database
resource "aws_security_group" "rds-ec2-sg" {
    name        = "rds-ec2-sg"
    description = "Allow inbound traffic from application security group to RDS"
    vpc_id      = aws_vpc.armageddon-VPC.id # Reference your VPC ID here

    lifecycle {
        create_before_destroy = true
    }

    # Egress rule (allowing all outbound traffic is common practice for a DB)
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Define an ingress rule to allow access from a specific source security group (e.g., your application servers' SG)
resource "aws_vpc_security_group_ingress_rule" "rds-ec2-ingress" {
    security_group_id         = aws_security_group.rds-ec2-sg.id
    description               = "Allow application servers access to RDS"
    from_port                 = 3306                            # MySQL port
    to_port                   = 3306
    ip_protocol               = "tcp"
    
    referenced_security_group_id = aws_security_group.ec2_web.id
    #for_each                  = aws_security_group.application_sg.id # Reference your application security group ID
    #source_security_group_id  = each.value
}

# Define Common Endpoint Security Group
resource "aws_security_group" "endpoint_sg" {
  name        = "common-endpoint-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.armageddon-VPC.id

  tags = {
    Name = "Common-Endpoint-SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_vpc" {
  security_group_id = aws_security_group.endpoint_sg.id
  description       = "Allow HTTPS from within the VPC"
  
  cidr_ipv4   = "10.66.0.0/16"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_vpc" {
  security_group_id = aws_security_group.endpoint_sg.id
  description       = "Allow response traffic back to VPC"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}



