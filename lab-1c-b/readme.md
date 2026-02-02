# Class 7 – Armageddon Lab 1c-b

## Goal Statements

### Concise:
Deploy a private EC2 instance running the Notes application, reachable only through SSM Session Manager, fronted by a public Application Load Balancer with TLS, WAF protection, and monitoring/alerting for production‑grade ingress.
### Infrastructure‑Focused:
Build a modern, enterprise‑style architecture that combines:
- Public ALB (internet‑facing) as the secure entry point
- Private EC2 targets with no public IPs
- TLS termination with ACM for website-name.com
- WAF Web ACL attached to the ALB
- CloudWatch Dashboard for visibility
- SNS alarm for ALB 5xx spikes
- Private RDS MySQL backend
- VPC Interface Endpoints for NAT‑less AWS API access
This lab extends the private‑compute pattern by adding a fully managed, secure, observable ingress layer.

---
Route53 Hosted Zone + DNS Records → ACM Certificate (DNS‑validated) → Public ALB (HTTPS) + WAF Web ACL → Private EC2 via VPC Interface Endpoints → Private RDS MySQL

---
### Code Change
+ Modular Code Base

### Infrastructure Change
+ Route53 Hosted Zone + DNS Records
+ ACM Certificate
+ Public ALB (HTTPS)
+ WAF Web ACL

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
This lab evolves the earlier EC2 → RDS private‑compute design by introducing a public, secure, monitored ingress layer. Instead of exposing EC2 directly, traffic now flows through:
- Route53 for DNS
- ACM for TLS
- Public ALB for HTTPS termination
- WAF for inspection and protection
- Private EC2 for application logic
- Private RDS for data storage

All infrastructure is provisioned using Terraform, including networking, endpoints, IAM, Secrets Manager, ALB, WAF, CloudWatch dashboards, and SNS alarms.

### Objectives
- Deploy a private EC2 instance with no public IP
- Access the instance exclusively through SSM Session Manager
- Add a public ALB that forwards traffic to private EC2
- Enable TLS using ACM for your domain
- Attach a WAF Web ACL to the ALB
- Enable WAF logging for visibility
- Add a CloudWatch Dashboard for ALB + WAF metrics
- Add an SNS alarm for ALB 5xx spikes
- Remove NAT dependency using VPC Interface Endpoints
- Maintain secure EC2 → RDS connectivity inside private subnets
- Enforce least‑privilege IAM for Secrets Manager + SSM



## Terraform‑Managed Resources
#### Networking
- VPC, private subnets, route tables
- S3 Gateway Endpoint
- Interface Endpoints for SSM, EC2Messages, SSMMessages, CloudWatch Logs, Secrets Manager, KMS
#### Ingress Layer
- Route53 hosted zone + DNS records
- ACM certificate for your domain
- Public ALB (internet‑facing)
- HTTPS listener with TLS termination
- WAF Web ACL + logging
- CloudWatch Dashboard
- SNS alarm for ALB 5xx spikes
#### Compute
- Private EC2 instance (no public IP)
- SSM access via VPC endpoints
- User data bootstraps the Notes application
#### Database
- RDS MySQL instance in private subnets
- Security group allowing EC2 → RDS
#### Security
- Security groups for ALB, EC2, and RDS
- IAM role with least‑privilege access to Secrets Manager + SSM
#### Secrets
- Secrets Manager secret containing DB credentials



### Deployment Flow (Terraform)
- Develop code for above resources in Terraform
- Use userdata.sh script provided in class
- Update variable values (region, CIDRs, instance types, secret names, etc.)
- Run terraform init
- Run terraform vaildate to confirm syntax and variables
- Run terraform plan to review changes
- Run terraform apply to deploy the full environment
- Validate DNS + TLS: dig app.website-name.com
- curl -I https://app.website-name.com
- Validate WAF + ALB metrics in CloudWatch


### Troubleshooting
All previous troubleshooting steps still apply (network checks, MySQL connectivity, secret retrieval, systemd logs). These are now used after Terraform deployment instead of manual setup.
