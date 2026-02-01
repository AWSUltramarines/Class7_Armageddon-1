# Class 7 – Armageddon Lab 1c-c

## Goal Statements

### Concise:
Add Route53 DNS, ACM certificate validation, and HTTPS termination on the ALB using Terraform.
### Infrastructure‑Focused:
Extend the existing private EC2 → ALB → RDS architecture by managing Route53 hosted zones and DNS records in Terraform, validating ACM certificates via DNS, and configuring the ALB to terminate TLS using the ACM certificate. This module introduces conditional Route53 management, DNS validation records, and ALIAS routing for app.my-website-name.com.

---
Route53 Hosted Zone + DNS Records → ACM Certificate (DNS‑validated) → ALB with HTTPS Listener → Private EC2 via VPC Interface Endpoints → Private RDS MySQL

---

## File structure
|-- 00.provider.tf
|-- 01.main.tf
|-- 02.variables.tf
|-- 03.output.tf
|-- modules
|   |-- alerts
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- autoscaling
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- compute
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- database
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- iam
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- load_balancer
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- network
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- route53
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- secrets
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- vpc_endpoints
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   `-- waf
|       |-- main.tf
|       |-- output.tf
|       `-- variables.tf
|-- readme.md
`-- userdata.sh


### Overview
This lab enhances the previous private‑infrastructure deployment by adding Route53 DNS management, ACM certificate DNS validation, and HTTPS support on the Application Load Balancer. Terraform provisions the hosted zone (optional), DNS validation records, and ALIAS records that map your application domain to the ALB.

The ALB’s HTTPS listener is updated to use the ACM certificate directly, with Terraform dependencies ensuring that DNS validation completes before the listener is created.

This module integrates seamlessly with your existing Terraform environment.

---

Objectives
- Manage Route53 hosted zone and DNS records through Terraform 
- Create ACM certificate DNS validation records automatically
- Update ALB HTTPS listener to use the ACM certificate
- Add ALIAS record: app.my-website-name.com → ALB DNS name
- Support both DNS ACM validation workflows
- Provide outputs for domain names and ALB endpoints

Terraform‑Managed Resources
### Route53
- Optional creation of a new hosted zone
- Conditional logic to use an existing hosted zone if provided
- DNS validation records for ACM
- ALIAS record for app.chewbacca-growl.com → ALB
### ACM
- ACM certificate
- DNS validation resource
- Updated ALB HTTPS listener referencing the certificate directly
### ALB
- HTTPS listener using:
``` bash
certificate_arn = aws_acm_certificate.<resource-name>.arn
```
- [depends_on] ensuring DNS validation completes before listener creation

## New Updates
- Hosted zone creation
- ACM DNS validation records
- ALIAS record for app.my-website-name.com
- Updated HTTPS listener with correct certificate reference
- depends_on to ensure validation completes

## HTTPS Listener Update
Your previous listener referenced the certificate validation resource.
Now it should reference the certificate directly:
``` hcl
certificate_arn = aws_acm_certificate.<resource-name>.arn
```

And include:
``` hcl
depends_on = [
  aws_acm_certificate_validation.<resource-name>
]
```
This ensures the listener is not created until DNS validation succeeds.


## ALIAS Record (app → ALB)
Terraform creates:
``` hcl
resource "aws_route53_record" "app_alias" {
  zone_id = local.zone_id
  name    = local.app_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
```



