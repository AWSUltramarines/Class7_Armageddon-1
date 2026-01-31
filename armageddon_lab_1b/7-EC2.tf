resource "aws_instance" "lab-ec2-app" {
  ami           = "ami-0cae6d6fe6048ca2c" # us-east-1
  instance_type = "t3.micro"
  security_groups = [aws_security_group.sg-ec2-lab.id]
  subnet_id = aws_subnet.public-us-east-1a.id
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name


  user_data = file("user_data.sh")

    tags = {
    Name = "ec2"
    }

}