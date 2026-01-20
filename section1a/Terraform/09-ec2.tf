resource "aws_instance" "web-lab-app" {
    ami = "ami-07ff62358b87c7116"
    associate_public_ip_address = true
    instance_type = "t3.micro"
    security_groups = [aws_security_group.web-lab-app-sg.id]
    iam_instance_profile = aws_iam_instance_profile.armageddon-ec2-db-profile.name
    subnet_id = aws_subnet.public-virginia-east1a.id
    user_data_base64 = filebase64("./scripts/user_data.sh")
}