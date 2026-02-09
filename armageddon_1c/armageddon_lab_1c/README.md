# Armageddon Lab 1C — AWS Infrastructure Overview

**Project:** `jasongeddon` · **Region:** `us-east-1` · **Domain:** `jason-cramer.com`

---

## What This Deploys

This Terraform configuration stands up a secure, production-style web application on AWS. At its core is a **Flask-based notes app** running on a private EC2 instance, backed by an **RDS MySQL** database. Key design decisions:

- **No public IP on the EC2 instance** — all management access goes through SSM Session Manager via VPC Interface Endpoints.
- **TLS termination at the ALB** with an ACM certificate and enforced HTTPS redirects.
- **WAFv2** sits in front of the ALB using the AWS Managed Common Rule Set.
- **CloudWatch alarms, a dashboard, and SNS email alerts** provide monitoring and incident notification.

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

### Load Balancing & DNS

| Resource | Name | Details |
|---|---|---|
| ALB | `jasongeddon-alb01` | Internet-facing, across 3 public subnets |
| Target Group | `jasongeddon-tg01` | HTTP:80, health check on `/` |
| ALB Listener (HTTP) | Port 80 | 301 redirect → HTTPS |
| ALB Listener (HTTPS) | Port 443 | TLS 1.3, forwards to target group |
| ACM Certificate | `jasongeddon-acm-cert01` | `app.jason-cramer.com` + `jason-cramer.com`, DNS validated |
| Route 53 CNAME | `app.jason-cramer.com` | Points to ALB |
| Route 53 A (Alias) | `jason-cramer.com` | Alias to ALB |

### Security

| Resource | Name | Details |
|---|---|---|
| EC2 Security Group | `jasongeddon-ec2-sg01` | Ingress: HTTP (80) from ALB only |
| RDS Security Group | `jasongeddon-rds-sg` | Ingress: MySQL (3306) from EC2 SG only |
| ALB Security Group | `jasongeddon-alb-sg01` | Ingress: HTTP (80), HTTPS (443) |
| VPC Endpoint SG | `jasongeddon-vpce-sg` | Ingress: HTTPS (443) from VPC CIDR |
| WAFv2 Web ACL | `jasongeddon-waf01` | AWS Managed Common Rule Set |

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

### Logging (S3)

| Resource | Details |
|---|---|
| ALB Access Logs Bucket | `jasongeddon-alb-logs-{account_id}`, public access blocked |
| WAF Logs | Configurable: CloudWatch Logs / S3 / Kinesis Firehose (default: CloudWatch) |

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
