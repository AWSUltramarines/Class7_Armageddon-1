resource "aws_instance" "lab-ec2-app" {
  ami           = "ami-083b3f53cbda7e5a4" # us-east-2 (Ohio).  I had to go into the console to check this AMI ID for Amazon Linux
  instance_type = "t3.micro"
  security_groups = [aws_security_group.ec2-lab.id]
  subnet_id = aws_subnet.public_a.id
  associate_public_ip_address = true # unsure if this is needed, if subnet has a public IP mapping
  #public_dns = true

  user_data = file("user_data.sh")

  tags = {
    Name = "ec2"
  }

  }
