resource "aws_instance" "arm_ec2" {
  ami           = "ami-07ff62358b87c7116" # us-east-1
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_web.id]
  subnet_id = aws_subnet.public-us-east-1a.id
  associate_public_ip_address = true 
  iam_instance_profile = aws_iam_instance_profile.flask_profile.name
  user_data = file("user_data.sh")

tags = {
    Name = "Flask-App-Instance"
  }
}

