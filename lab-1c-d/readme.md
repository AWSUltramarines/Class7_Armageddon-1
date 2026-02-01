# Class 7 – Armageddon Lab 1c-d

## Goal Statements

## Concise:
Add zone‑apex DNS routing and ALB access logging to enhance observability and production realism.
## Infrastructure‑Focused:
Extend the existing Route53 + ALB + ACM deployment by mapping the zone apex (my-website-name.com) directly to the ALB using an ALIAS record, enabling ALB access logs to an S3 bucket with the required bucket policy, and providing verification commands to validate DNS and logging functionality.


---
Route53 Zone Apex + app Records → ACM DNS Validation → ALB with HTTPS Listener + WAF Logging → Private EC2 (SSM‑only) via VPC Interface Endpoints → Private RDS MySQL

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
|   |-- s3bucket
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
This lab builds on the previous Route53 + ACM + ALB configuration by introducing two major production‑grade enhancements:
- Zone Apex Routing
  - The root domain (my-website-name.com) now resolves directly to the ALB using an ALIAS record. This ensures users can reach the application even when they forget the app.my-website-name.subdomain.
- ALB Access Logging to S3
  - The ALB is updated to deliver access logs to an S3 bucket. This is essential for audits, troubleshooting, WAF investigations, and incident response.

Terraform requires modifying the existing ALB resource to add the access_logs block.

---

Objectives
- Create an ALIAS record for the zone apex → ALB
- Enable ALB access logs to an S3 bucket
- Apply the required bucket policy for ALB log delivery
- Patch the existing ALB resource to include the access_logs block
- Provide outputs for the apex HTTPS URL and log bucket name
---


Terraform‑Managed Resources
### Route53 (Apex Domain)
- Zone apex ALIAS record:
  - my-website-name.com → ALB
- Conditional creation of hosted zone (based on manage_route53_in_terraform)
- DNS routing for both:
  - app.my-website-name.com
  - my-website-name.com (apex)
### S3 (ALB Access Logs)
  - S3 bucket dedicated to ALB access logs
  - Required bucket policy allowing ALB log delivery
  - Optional enable/disable via variable toggle
  - Configurable prefix for log organization
### ALB Enhancements
  - Updated ALB resource with access_logs block
  - HTTPS listener continues to use ACM certificate
  - ALIAS routing from apex and app subdomain
### ACM
  - Certificate already created in previous lab
  - DNS validation still required before HTTPS listener creation
  - Listener depends on DNS validation when enabled
### Outputs
  - Apex HTTPS URL
  - Log bucket name
  - Any additional DNS or ALB outputs appended to outputs.tf



## New Updates
1. Zone Apex ALIAS → ALB
Users can now reach the application by typing the root domain:
https://my-website-name.com


This is a common real‑world requirement since many users forget subdomains.
2. ALB Access Logging to S3
The ALB now delivers access logs to an S3 bucket for:
- Audit trails
- Incident response
- WAF troubleshooting
- 4xx/5xx investigations
- Performance analysis





