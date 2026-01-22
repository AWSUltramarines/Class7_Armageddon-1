# 🚀 Secure Multi-Tier Cloud Architecture

**Engineer:** DaeQuan Britt

**Domain:** `daequanbritt.com` | **Environment:** `armage-dev`

This deployment implements a professional, secure entry pattern using **TLS 1.3 encryption**, **WAF protection**, and **automated DNS management**. The architecture follows a least-privilege security model with all compute and database resources isolated in private subnets, supplemented by **S3 Access Logging** for incident response.

## 🛡️ Enterprise Security Features

* **TLS 1.3 & ACM**: Secure HTTPS termination on Port 443 using the latest `TLS13-1-2-2021-06` security policy.


* **Managed Ingress (WAFv2)**: Regional Web ACL protection against SQL injection and Cross-Site Scripting (XSS) via AWS Managed Core Rules.


* **Zero-Trust Identity**: Uses IAM Instance Profiles with scoped policies for Secrets Manager and SSM Parameter Store access.


* **Automated DNS**: Dynamic Route 53 ALIAS record management for both the `app` subdomain and the **Zone Apex** (`daequanbritt.com`).


* **Audit Logging**: Automated delivery of ALB Access Logs to a secure S3 bucket for forensic analysis. WAF traffic logs delivered to CloudWatch for a complete "Incident Response" trail.



---

## 📂 File Structure

```text
.
├── 00-auth.tf          # Provider & S3 Remote State Backend
├── 01-IAM.tf           # Least-privilege roles & instance profiles 
├── 02-secrets.tf       # Dynamic Secrets & SSM Parameter Store
├── 03-network.tf       # VPC, Subnets, NAT GW, & Endpoints
├── 04-sg.tf            # Tiered Security Group rules (ALB -> EC2 -> RDS)
├── 05-main.tf          # Private Web Server & RDS MySQL Instance
├── 06-logging.tf       # CloudWatch Alarms, SNS, & ALB S3 Access Logs
├── 07-alb-dns.tf       # ALB, TLS Listener, & ACM Validation
├── 08-dashboard.tf     # Visual App Health Dashboard & 5xx Alarm
├── 09-waf.tf           # Web Application Firewall (WAFv2)
├── 98-outputs.tf       # Verification URLs, ARNs, and Zone IDs
└── 99-variables.tf     # Configurable project and domain parameters

```

---

# 📊 Deployment Verification

To verify the deployment, the following metrics were used (See `A-GRADEME.md`):

1. **Confirm Apex DNS Record Exists**: Zone Apex successfully points to the Application Load Balancer.


2. **Confirm ALB Access Logging is Enabled**: **Result:** 
`access_logs.s3.enabled` is set to `true`, 
`access_logs.s3.bucket` is set to `my bucket`,
`access_logs.s3.prefix` is set to `my prefix` 


3. **Connectivity**: `curl -I` confirms **`HTTP/2 200 OK`** over a secure connection.

* *Note: HTTP/2 is successfully negotiated due to the modern TLS 1.3 policy.*

4. **Audit**: ALB Access Logs successfully delivered to S3 bucket `armage-dev-alb-access-logs-app`.

5. **Apex Alias**: **Result:** Web server redirects traffic to `app.daequanbritt.com` subdomain.
---

# 🏗️ Infrastructure Architecture Overview

| AWS Service | Component Role | Enterprise Pattern |
| --- | --- | --- |
| **Route 53** | DNS & Domain Routing | <br>**Managed Ingress**: Uses dynamic data lookups for Hosted Zones and supports **Zone Apex** ALIAS records.|
| **S3** | Audit Storage | <br>**Forensics**: Secure bucket with policies allowing regional ELB service accounts to write access logs.|
| **ACM** | TLS/SSL Certificates | <br>**End-to-End Encryption**: Automates DNS validation and provides certificates for Port 443 termination. |
| **ALB** | Load Balancer | <br>**Secure Entry**: Enforces TLS 1.3, redirects HTTP to HTTPS, and pushes telemetry to S3. |
| **WAFv2** | Web Firewall | <br>**Edge Defense**: Protects the entry point from SQLi and XSS attacks using AWS Managed Core Rules. Also streams traffic "footprints" to CloudWatch for auditing |
| **EC2** | Private Compute | <br>**Isolated Logic**: Runs Flask in a private subnet with no direct internet access. |
| **RDS (MySQL)** | Managed DB | <br>**Data Privacy**: Isolated in a dedicated DB subnet group accessible only via Security Group references. |
| **CloudWatch** | Monitoring | <br>**Observability**: Real-time dashboards, WAF log storage, and 5xx error alarms linked to SNS email notifications. |
