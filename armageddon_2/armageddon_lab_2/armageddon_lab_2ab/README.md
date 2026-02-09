# Armageddon Lab 2A & B — AWS Infrastructure Overview

**Project:** `jasongeddon` · **Region:** `us-east-1` · **Domain:** `jason-cramer.com`

---

## What This Deploys

This Terraform configuration builds on Lab 1C by placing a **CloudFront CDN** in front of the entire stack, making it the sole public entry point. A **Flask-based notes app** runs on a private EC2 instance, backed by an **RDS MySQL** database. Key design decisions:

- **CloudFront is the only public doorway** — DNS for both `jason-cramer.com` and `app.jason-cramer.com` points to CloudFront, not the ALB.
- **Origin cloaking** — the ALB security group only permits traffic from CloudFront's managed prefix list, and a secret custom header (`X-Jasongeddon-Growl`) must be present or the ALB returns 403.
- **WAF moved to the edge** — a `CLOUDFRONT`-scoped WAFv2 Web ACL with the AWS Managed Common Rule Set filters requests before they reach the VPC. The regional ALB WAF is disabled by default.
- **Cache correctness** — separate cache policies for static assets (aggressive, 1-day default TTL) and API routes (caching disabled), with dedicated origin request and response headers policies.
- **No public IP on the EC2 instance** — all management access goes through SSM Session Manager via VPC Interface Endpoints.
- **TLS termination at both CloudFront and the ALB** with an ACM certificate covering both domain names.
- **CloudWatch alarms, a dashboard, and SNS email alerts** provide monitoring and incident notification.
- **Three WAF logging options** — CloudWatch Logs, S3, or Kinesis Firehose (configurable via variable, default: CloudWatch).

---

## Resource Inventory

### Networking

| Resource | Name | Details |
|---|---|---|
| VPC | `jasongeddon-vpc` | `10.77.0.0/16`, DNS support enabled |
| Public Subnets (×3) | `jasongeddon-public-subnet01‑03` | `10.77.1‑3.0/24` across 3 AZs |
| Private Subnets (×3) | `jasongeddon-private-subnet01‑03` | `10.77.11‑13.0/24` across 3 AZs |
| Internet Gateway | `jasongeddon-igw` | Attached to VPC |
| NAT Gateway | `jasongeddon-nat01` | In public subnet, with Elastic IP |
| Route Tables (×2) | `public-rt01`, `private-rt01` | Public → IGW, Private → NAT |

### Compute & Database

| Resource | Name | Details |
|---|---|---|
| EC2 Instance | `jasongeddon-ec201` | `t3.micro`, Amazon Linux 2023, private subnet, no public IP |
| RDS Instance | `jasongeddon-rds01` | MySQL 8.0.43, `db.t3.micro`, 20 GB gp2, encrypted |
| RDS Subnet Group | `jasongeddon-rds-subnet-group01` | Spans all 3 private subnets |

### CloudFront (CDN & Edge Security)

| Resource | Name | Details |
|---|---|---|
| CloudFront Distribution | `jasongeddon-cf01` | IPv6 enabled, HTTPS redirect, aliases for both domains |
| CloudFront WAF (Web ACL) | `jasongeddon-cf-waf01` | `CLOUDFRONT` scope, AWS Managed Common Rule Set |
| Cache Policy (Static) | `jasongeddon-cache-static01` | `/static/*`, 1-day default TTL, gzip + brotli |
| Cache Policy (API) | `jasongeddon-cache-api-disabled01` | `/api/*` + default, all TTLs = 0 (no caching) |
| Origin Request Policy (API) | `jasongeddon-orp-api01` | Forwards all cookies, query strings, plus `Content-Type`/`Origin`/`Host` |
| Origin Request Policy (Static) | `jasongeddon-orp-static01` | Forwards nothing (minimal) |
| Response Headers Policy (Static) | `jasongeddon-rsp-static01` | Adds `Cache-Control: public, max-age=86400, immutable` |

### Origin Cloaking

| Resource | Name | Details |
|---|---|---|
| Secret Header Value | `origin_header_value01` | 32-char random password (`X-Jasongeddon-Growl`) |
| ALB Ingress Rule | `alb_ingress_cf44301` | HTTPS (443) from CloudFront managed prefix list only |
| Listener Rule (Allow) | `require_origin_header01` | Priority 10 — forward if secret header matches |
| Listener Rule (Block) | `default_block01` | Priority 99 — 403 for everything else |

### Load Balancing & DNS

| Resource | Name | Details |
|---|---|---|
| ALB | `jasongeddon-alb01` | Internet-facing, across 3 public subnets, access logs to S3 |
| Target Group | `jasongeddon-tg01` | HTTP:80, health check on `/` |
| ALB Listener (HTTP) | Port 80 | 301 redirect → HTTPS |
| ALB Listener (HTTPS) | Port 443 | TLS 1.3, default action: 403 (requires CF header) |
| ACM Certificate | `jasongeddon-acm-cert01` | `app.jason-cramer.com` + `jason-cramer.com`, DNS validated |
| Route 53 A (Alias) | `jason-cramer.com` | Points to CloudFront |
| Route 53 A (Alias) | `app.jason-cramer.com` | Points to CloudFront |

### Security

| Resource | Name | Details |
|---|---|---|
| EC2 Security Group | `jasongeddon-ec2-sg01` | Ingress: HTTP (80) from ALB SG only |
| RDS Security Group | `jasongeddon-rds-sg` | Ingress: MySQL (3306) from EC2 SG only |
| ALB Security Group | `jasongeddon-alb-sg01` | Ingress: HTTPS (443) from CloudFront prefix list only |
| VPC Endpoint SG | `jasongeddon-vpce-sg` | Ingress: HTTPS (443) from VPC CIDR |
| Regional WAF (Web ACL) | `jasongeddon-waf01` | Conditional (`enable_waf = false` by default), replaced by CF WAF |

### VPC Endpoints (Private Connectivity)

| Endpoint | Type | Purpose |
|---|---|---|
| SSM | Interface | Session Manager |
| SSM Messages | Interface | Session Manager |
| EC2 Messages | Interface | Session Manager |
| Secrets Manager | Interface | DB credential retrieval |
| CloudWatch Logs | Interface | Application logging |
| S3 | Gateway | General S3 access |

### IAM

| Resource | Name | Details |
|---|---|---|
| IAM Role | `jasongeddon-ec2-role01` | EC2 assume-role |
| Instance Profile | `jasongeddon-ec2-profile` | Attached to EC2 |
| Inline Policy | `jasongeddon-ec2-policy` | Secrets Manager, SSM Params, CloudWatch Logs, RDS Describe |
| Managed Policy | `AmazonSSMManagedInstanceCore` | SSM Session Manager access |

### Secrets & Parameters

| Resource | Name | Details |
|---|---|---|
| Secrets Manager Secret | `jasongeddon/rds/mysql` | DB username, password, host, port, dbname |
| SSM Parameter | `/lab/rds/mysql/endpoint` | RDS endpoint address |
| SSM Parameter | `/lab/rds/mysql/port` | RDS port |
| SSM Parameter | `/lab/rds/mysql/dbname` | Database name |

### Monitoring & Alerting

| Resource | Name | Details |
|---|---|---|
| CloudWatch Log Group | `/lab/rdsapp` | 7-day retention |
| Metric Filter | `jasongeddon-db-failure-filter` | Pattern: `"Database connection failed"` |
| CloudWatch Alarm | `jasongeddon-db-failure-alarm` | ≥ 3 DB failures in 5 min |
| CloudWatch Alarm | `jasongeddon-alb-5xx-alarm01` | ≥ 10 ALB 5xx errors in 5 min |
| SNS Topic | `jasongeddon-db-incidents` | Email alerts |
| CloudWatch Dashboard | `jasongeddon-dashboard01` | ALB requests, 5xx count, response time |

### Logging (S3 & WAF)

| Resource | Name | Details |
|---|---|---|
| ALB Access Logs Bucket | `jasongeddon-alb-logs-{account_id}` | Public access blocked, TLS-only policy |
| WAF Logs (CloudWatch) | `aws-waf-logs-jasongeddon-webacl01` | 14-day retention (default option) |
| WAF Logs (S3) | `aws-waf-logs-jasongeddon-{account_id}` | Public access blocked (optional) |
| WAF Logs (Firehose) | `aws-waf-logs-jasongeddon-firehose01` | Streams to S3 via Kinesis Firehose (optional) |

---

## Application

The Flask app runs on EC2 port 80 as a **systemd** service.

| Component | Details |
|---|---|
| Runtime | Python 3 |
| Libraries | Flask, PyMySQL, Boto3, Watchtower (CloudWatch logging) |

**Endpoints:**

| Route | Description |
|---|---|
| `GET /` | Home page |
| `GET /init` | Creates the database and table |
| `GET /add?note=` | Inserts a new note |
| `GET /list` | Lists all notes |
