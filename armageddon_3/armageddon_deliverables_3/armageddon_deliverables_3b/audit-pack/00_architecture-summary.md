# Armageddon Lab 3 — Architecture Summary

> **Lab Type:** HIPAA-aware, cross-region AWS infrastructure  
> **Regions:** Tokyo (`ap-northeast-1`) · São Paulo (`sa-east-1`)  
> **Core Pattern:** Stateless compute in São Paulo reads persistent data from Tokyo via Transit Gateway peering

---

## What This Lab Builds

Lab 3 deploys a two-region architecture where each region plays a distinct role:

| | Tokyo ("Shinjuku") | São Paulo ("Liberdade") |
|---|---|---|
| **Region** | ap-northeast-1 | sa-east-1 |
| **Role** | Data authority | Public-facing compute |
| **VPC CIDR** | 10.77.0.0/16 | 10.78.0.0/16 |
| **Has RDS?** | ✅ MySQL 8.0.43, encrypted | ❌ Connects to Tokyo via TGW |
| **Has CloudFront?** | ❌ Disabled in Lab 3 | ✅ Owns distribution + Route53 |
| **Internet Access** | ALB accepts direct HTTPS | CloudFront → ALB with origin cloaking |

The two regions are connected via **AWS Transit Gateway peering** — a cross-region private backbone that keeps all database traffic off the public internet.

---

## How a Request Flows

```
User Request
    │
    ▼
CloudFront  (São Paulo — WAF enforced via us-east-1)
    │  Injects secret header: X-Jasongeddon-Growl
    ▼
ALB  (sa-east-1 — origin-cloaked, HTTPS only)
    │  Validates secret header → forwards to target group
    │  Rejects any request missing the header (403)
    ▼
EC2  (sa-east-1 — private subnet, Flask app)
    │  Fetches DB credentials from Secrets Manager
    │  Resolves Tokyo RDS host from secret
    ▼
VPC Route Table  (10.77.0.0/16 → TGW)
    │
    ▼
Liberdade TGW  (São Paulo Transit Gateway)
    │  Routes 10.77.0.0/16 → cross-region peering link
    ▼
TGW Peering Link  (cross-region, private)
    │
    ▼
Shinjuku TGW  (Tokyo Transit Gateway)
    │  Routes return traffic 10.78.0.0/16 → peering link
    ▼
RDS MySQL  (ap-northeast-1 — private subnet, encrypted)
    │  SG allows 10.78.0.0/16 on port 3306
    ▼
Response travels back the same path
```

---

## São Paulo (Liberdade) — sa-east-1

São Paulo is the customer-facing region. It owns CloudFront, the ALB, the EC2 compute tier, all caching logic, and monitoring.

### Networking

Eleven resources build out the VPC foundation: a `/16` VPC, three public subnets (for the ALB), three private subnets (for EC2 and TGW attachments), an Internet Gateway, a NAT Gateway with Elastic IP, and route tables wiring it all together. The private route table includes a static route sending all `10.77.0.0/16` traffic into the Transit Gateway.

### Origin Cloaking (CloudFront → ALB)

A core security feature of this lab is that the ALB is **not directly reachable** from the internet — only CloudFront can talk to it.

- The ALB security group only allows inbound HTTPS from the **CloudFront managed prefix list**
- CloudFront injects a secret header (`X-Jasongeddon-Growl`) on every request
- The ALB listener has two rules:
  - **Priority 10:** Forward to EC2 if the secret header matches
  - **Priority 99:** Return 403 for everything else

The secret value is a randomly generated 32-character string managed by Terraform.

### CloudFront Caching Behaviors

| Path | Caching | Notes |
|---|---|---|
| `/static/*` | Aggressive — 1-day default, up to 1 year | Adds `Cache-Control: immutable` |
| `/api/public-feed` | Origin-driven (respects `s-maxage`) | AllViewerExceptHostHeader ORP |
| `/api/*` | Disabled (TTL = 0) | Forwards all cookies, query strings, and headers |
| Default | Disabled (TTL = 0) | Same as `/api/*` |

### Flask Application (EC2)

The EC2 instance runs an Amazon Linux 2023 Flask app (`/opt/rdsapp/app.py`) that exposes:

| Endpoint | Action |
|---|---|
| `/init` | Creates the `labdb` database and `notes` table on Tokyo RDS |
| `/add?note=hello` | Inserts a note (write to Tokyo via TGW) |
| `/list` | Lists all notes (read from Tokyo via TGW) |
| `/api/public-feed` | Cacheable JSON (`s-maxage=30`) |
| `/api/user-feed` | Private JSON (`no-store`) |

### WAF

A `CLOUDFRONT`-scoped WAFv2 ACL (`cf_waf01`) is attached to the distribution, running the `AWSManagedRulesCommonRuleSet`. WAF logs can be shipped to CloudWatch Logs, S3, or Kinesis Firehose depending on the variable configuration.

### TLS Certificates

Two ACM certificates are provisioned — one in **us-east-1** (required for CloudFront) and one in **sa-east-1** (for the ALB) — both covering `jason-cramer.com` and `app.jason-cramer.com`. DNS validation is handled automatically via Route53 CNAME records.

### Route53

Both the apex domain and `app` subdomain point to the CloudFront distribution as A alias records. Tokyo has no Route53 records in Lab 3.

### IAM

The EC2 instance role grants the minimum permissions needed:
- `secretsmanager:GetSecretValue` — fetch DB credentials
- `ssm:GetParameter*` — read RDS endpoint/port/dbname
- `logs:*` and `cloudwatch:DescribeAlarms` — observability
- `rds:DescribeDBInstances` — health checks
- `AmazonSSMManagedInstanceCore` — SSM Session Manager access (no SSH keys needed)

### Monitoring

| Resource | What It Watches |
|---|---|
| CloudWatch Log Group | `/lab/rdsapp`, 7-day retention |
| Metric Filter | `"Database connection failed"` → `DBConnectionFailures` metric |
| Alarm: `db_alarm01` | Fires if `DBConnectionFailures ≥ 3` in 5 minutes |
| Alarm: `alb_5xx_alarm01` | Fires if ALB 5XX count `≥ 10` in 5 minutes |
| SNS Topic | `jasongeddon-db-incidents` → email alert |
| Dashboard | ALB RequestCount, 5XX errors, TargetResponseTime |

---

## Tokyo (Shinjuku) — ap-northeast-1

Tokyo's job is simple: store the data securely and accept connections from São Paulo.

### Networking

Mirrors São Paulo's structure with the same subnet layout, IGW, NAT, and route tables — but using the `10.77.0.0/16` CIDR across AZs `ap-northeast-1a`, `1c`, and `1d`. The private route table sends all `10.78.0.0/16` traffic into the Tokyo TGW.

### Database

| Setting | Value |
|---|---|
| Engine | MySQL 8.0.43 |
| Instance | db.t3.micro |
| Storage | 20 GB gp2, encrypted at rest |
| Placement | Private subnet only — not publicly accessible |
| Access | RDS security group allows port 3306 from `10.78.0.0/16` |

Because security group referencing doesn't work cross-VPC, the RDS ingress rule is CIDR-based — explicitly allowing the entire São Paulo VPC address space.

### ALB (No Origin Cloaking)

In Lab 3, Tokyo's ALB is intentionally simpler — it accepts direct HTTPS traffic from `0.0.0.0/0` without the secret header enforcement used in São Paulo. There is no CloudFront distribution, no WAF, and no Route53 records in Tokyo.

### Naming Conventions

Tokyo resources use a `-shinjuku` suffix where needed to avoid naming collisions with São Paulo resources in the same AWS account:
- IAM role: `jasongeddon-shinjuku-ec2-role01`
- S3 bucket: `jasongeddon-shinjuku-alb-logs-{account}`

---

## Cross-Region Connectivity — Transit Gateway Peering

Connecting two VPCs across regions requires configuration at three distinct layers. Missing any one of them breaks connectivity.

### Layer 1 — TGW Peering (Control Plane)

Tokyo **initiates** the peering request; São Paulo **accepts** it.

```
Tokyo TGW  ──── peering request ────►  São Paulo TGW
 (shinjuku_tgw01)                       (liberdade_tgw01)
                                         accepter resource
```

### Layer 2 — TGW Route Tables (Data Plane at TGW Level)

TGW peering does **not** auto-propagate routes. Both sides need explicit static routes:

| TGW | Route | Next Hop |
|---|---|---|
| Tokyo TGW RT | `10.78.0.0/16` | peering attachment |
| São Paulo TGW RT | `10.77.0.0/16` | peering attachment |

### Layer 3 — VPC Route Tables (Data Plane at VPC Level)

Each VPC's private route table must direct cross-region traffic into its local TGW:

| VPC | Route | Next Hop |
|---|---|---|
| Tokyo private RT | `10.78.0.0/16` | shinjuku_tgw01 |
| São Paulo private RT | `10.77.0.0/16` | liberdade_tgw01 |

---

## 3-Step Deployment Process

Because the two Terraform root modules can't reference each other's state directly, they communicate through **output values passed as input variables**. Some resources use `count` expressions so they're only created once the cross-region values are available.

| Step | Region | What Happens | Output Produced |
|---|---|---|---|
| **1** | São Paulo | Initial deploy — creates TGW | `liberdade_tgw_id` |
| **2** | Tokyo | Full deploy using SP TGW ID | `shinjuku_peering_attachment_id`, `shinjuku_rds_endpoint` |
| **3** | São Paulo | Redeploy — accepts peering, creates SSM param | *(final state)* |

Resources gated on cross-region values use `count = var.shinjuku_peering_attachment_id != "" ? 1 : 0` to safely skip creation until Step 3.

---

## Resource Count Summary

| Category | São Paulo | Tokyo |
|---|---|---|
| Networking | 11 | 11 |
| Transit Gateway | 5 | 4–5 |
| Security Groups | 4 | 3 + 1 cross-region rule |
| VPC Endpoints | 6 | 6 |
| Compute (EC2) | 1 | 1 |
| Load Balancer + Rules | 7 | 6 |
| TLS Certificates | 6 | 2 |
| CloudFront + WAF | ~10 | 0 |
| Route53 | 2 | 0 |
| IAM | 4 | 4 |
| Secrets + Parameters | 5 | 5 |
| Monitoring | 7 | 7 |
| Database (RDS) | 0 | 2 |
| **Total (approx.)** | **~68** | **~51** |

---


