# 🚀 Secure Multi-Tier Cloud Architecture

**Engineer:** DaeQuan Jamal Britt

**Domain:** `daequanbritt.com` | **Environment:** `armage-dev` 

This deployment implements a professional, secure entry pattern using **TLS 1.3 encryption**, **WAF protection**, and **automated DNS management**. The architecture follows a least-privilege security model with all compute and database resources isolated in private subnets.

## 🛡️ Enterprise Security Features

*  **TLS 1.3 & ACM**: Secure HTTPS termination on Port 443 using the latest `TLS13-1-2-2021-06` security policy.


*  **Managed Ingress (WAFv2)**: Regional Web ACL protection against SQL injection and Cross-Site Scripting (XSS) via AWS Managed Core Rules.


*  **Zero-Trust Identity**: Uses IAM Instance Profiles with scoped policies for Secrets Manager and SSM Parameter Store access.


*  **Automated DNS**: Dynamic Route 53 ALIAS record management pointing `app.daequanbritt.com` directly to the ALB.



---

## 📂 File Structure

```
.
├── 00-auth.tf          # Provider & S3 Remote State Backend
├── 01-IAM.tf           # Least-privilege roles & instance profiles 
├── 02-secrets.tf       # Dynamic Secrets & SSM Parameter Store
├── 03-network.tf       # VPC, Subnets, NAT GW, & Endpoints
├── 04-sg.tf            # Tiered Security Group rules (ALB -> EC2 -> RDS)
├── 05-main.tf          # Private Web Server & RDS MySQL Instance
├── 06-logging.tf       # SNS Alerts & CloudWatch Log Metric Filters
├── 07-alb-dns.tf       # ALB, TLS Listener, & ACM Validation
├── 08-dashboard.tf     # Visual App Health Dashboard & 5xx Alarm
├── 09-waf.tf           # Web Application Firewall (WAFv2)
└── 98-outputs.tf       # Verification URLs, ARNs, and Zone IDs

```

---

# 📊 Deployment Verification

To verify the deployment, the following metrics were used (See `A-GRADEME.md`):

1. **Identity**: ACM Certificate Status: **`ISSUED`**.


2. **Routing**: Route 53 A-Record for `app.daequanbritt.com` successfully resolves to the ALB.


3. **Connectivity**: `curl -I` confirms **`HTTP/2 200 OK`** over a secure connection.
* *Note: HTTP/2 is successfully negotiated due to the modern TLS 1.3 policy.*



---

### 🛠️ Usage

1. Ensure you have a Public Hosted Zone in Route 53 for your domain.


2. Configure your `terraform.tfvars`:

```hcl
project_name = "armage"
environment  = "dev"
domain_name  = "daequanbritt.com"
alert_emails = ["your-email@example.com"]

```

3. Initialize and apply:

```bash
terraform init
terraform apply

```
___

# 🏗️ Infrastructure Architecture Overview

| AWS Service | Component Role | Enterprise Pattern |
| --- | --- | --- |
| **Route 53** | DNS & Domain Routing | <br>**Managed Ingress**: Uses dynamic data lookups for Hosted Zones to ensure zero-conflict subdomain management.|
| **ACM** | TLS/SSL Certificates | <br>**End-to-End Encryption**: Automates DNS validation and provides certificates for Port 443 termination. |
| **ALB** | Application Load Balancer | <br>**Secure Entry**: Enforces a modern TLS 1.3 security policy and redirects all HTTP traffic to HTTPS. |
| **WAFv2** | Web Application Firewall | <br>**Edge Defense**: Protects the entry point from SQLi and XSS attacks using AWS Managed Core Rule Sets. |
| **EC2** | Private Compute | <br>**Isolated Logic**: Runs the Flask application in a private subnet with no direct internet access. |
| **RDS (MySQL)** | Managed Database | <br>**Data Privacy**: Isolated in a dedicated DB subnet group; accessible only via Security Group-to-SG references. |
| **NAT Gateway** | Outbound Connectivity | <br>**Controlled Access**: Allows private resources to securely fetch patches and Python packages without being exposed. |
| **CloudWatch** | Monitoring & Logging | <br>**Observability**: Real-time health dashboards and automated metric filters for database connection monitoring. |
___
