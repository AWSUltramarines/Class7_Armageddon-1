output "ip_address" {
    value = aws_instance.lab-ec2-app.public_ip

}

output "website_url" {
    value = aws_instance.lab-ec2-app.public_dns

}

output "website_url2" {
    value = "http://${aws_instance.lab-ec2-app.public_dns}"
}
