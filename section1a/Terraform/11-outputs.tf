output "ip_address" {
    value = aws_instance.web-lab-app.public_ip  
}

output "website_user" {
    value = "http://${aws_instance.web-lab-app.public_dns}"
}