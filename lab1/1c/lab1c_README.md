# Lab 1C: Terraform Infrastructure as Code

**Helga Stack — Full IaC Implementation (us-east-2)**

---

## What I Built

Converted all manual ClickOps infrastructure from Labs 1A + 1B into a fully Terraform-managed stack using the **helga** naming convention, deployed in **us-east-2 (Ohio)**. The base lab plus seven bonus rounds produced an enterprise-grade architecture: private compute, TLS ingress, WAF protection, multi-destination logging, and a full incident response runbook.

---

## Base Infrastructure (Terraform)

| Resource | Name / Detail |
| --- | --- |
| **VPC** | `helga-vpc01` — `10.241.0.0/16` (DNS support + hostnames enabled) |
| **Public Subnets (3)** | `helga-public-subnet01/02/03` — `10.241.1.0/24`, `10.241.2.0/24`, `10.241.3.0/24` across us-east-2a/b/c |
| **Private Subnets (3)** | `helga-private-subnet01/02/03` — `10.241.101.0/24`, `10.241.102.0/24`, `10.241.103.0/24` |
| **IGW** | `helga-igw01` |
| **NAT Gateway** | `helga-nat01` in public-subnet01 with EIP `helga-nat-eip01` |
| **Route Tables** | `helga-public-rt01` (0.0.0.0/0 → IGW) · `helga-private-rt01` (0.0.0.0/0 → NAT) |
| **EC2** | `helga-ec201` (t3.micro) — Flask notes app bootstrapped via `user_data.sh` |
| **IAM Role** | `helga-ec2-role01` with SSM, SecretsManager, and CloudWatch policies → `helga-instance-profile01` |
| **RDS** | `helga-rds01` (db.t3.micro, MySQL) — private, single-AZ, db: `t_labdb` |
| **RDS Subnet Group** | `helga-rds-subnet-group01` (all 3 private subnets) |
| **Security Groups** | `helga-ec2-sg01` (HTTP 80, SSH 22 from `185.141.119.79/32`) · `helga-rds-sg01` (MySQL 3306 from EC2 SG — SG-to-SG reference) |
| **SSM Parameters** | `/lab/db/endpoint` · `/lab/db/port` · `/lab/db/name` (all with `overwrite = true`) |
| **Secrets Manager** | `helga/rds/mysql` — `{username, password, host, port, dbname}` |
| **CloudWatch Logs** | `/aws/ec2/helga-rds-app` (7-day retention) · `/helga/ec2/user-data` · `/helga/notes-app` |
| **CloudWatch Alarm** | `helga-db-connection-failure` — `DBConnectionErrors ≥ 3` (namespace: Lab/RDSApp, period: 300s) |
| **SNS** | `helga-db-incidents` → email subscription to [`brightwillie21@gmail.com`](mailto:brightwillie21@gmail.com) |

---

## Key Challenges Solved — The Road to Success

**Timeline:** January 11, 2026  

**Reality:** This was not a clean single-pass deploy. Multiple `terraform apply` cycles, troubleshooting sessions, and a full tear-down-and-rebuild were required.

### 1. Subnet CIDR Conflict (State Collision)

**Problem:** Labs 1A/1B subnets still existed at `10.212.x.x`. Terraform tried to create overlapping resources.

**Root Cause:** Mixing ClickOps resources (Labs 1A/1B) with Terraform-managed resources without cleaning up first.

**Fix:** Changed the entire VPC CIDR to `10.241.0.0/16` to avoid overlap.

**Lesson:** When migrating from ClickOps to IaC, either destroy the old stack first or import existing resources into Terraform state. Half-measures cause drift.

---

### 2. AMI/Instance Architecture Mismatch

**Problem:** ARM64 AMI (`ami-0abcdef1234567890`) paired with x86_64 instance type (`t3.micro`).

**Error Message:** `Unsupported architecture for instance type`

**Fix:** Switched to the correct x86_64 AMI (`ami-06f1fc9ae5ae7f31e`).

**Lesson:** Always verify AMI architecture matches instance type family. ARM instances (Graviton) require ARM AMIs.

---

### 3. SSM Parameters Already Existed

**Problem:** Parameters `/lab/db/endpoint`, `/lab/db/port`, `/lab/db/name` left over from Lab 1B blocked Terraform creation.

**Error Message:** `ParameterAlreadyExists`

**Fix:** Deleted manually, then added `overwrite = true` to all `aws_ssm_parameter` resources to prevent recurrence.

**Lesson:** Terraform `create` without `overwrite` fails if the resource name already exists. Use `overwrite = true` for idempotency.

---

### 4. ENI Detach AuthFailure (RDS Cleanup Race)

**Problem:** Terraform tried to delete an RDS-managed ENI before RDS finished cleaning up.

**Error Message:** `AuthFailure: You are not authorized to perform this operation`

**Root Cause:** RDS creates hidden ENIs in your subnets. Terraform can't delete them directly — only RDS can.

**Fix:** Waited for RDS deletion to complete, then retried `terraform destroy`.

**Lesson:** Some AWS resources have hidden dependencies. Always check for lingering ENIs/SGs after destroying databases.

---

### 5. Secret Scheduled for Deletion (30-Day Limbo)

**Problem:** Deleted secret `helga/rds/mysql` was in 30-day recovery window. Terraform couldn't recreate it.

**Error Message:** `InvalidRequestException: You can't create this secret because a secret with this name is already scheduled for deletion`

**Fix:**

```bash
aws secretsmanager delete-secret \
  --secret-id helga/rds/mysql \
  --force-delete-without-recovery
```

**Lesson:** Secrets Manager defaults to 30-day soft delete. Use `--force-delete-without-recovery` for dev/test environments.

---

### 6. DB Subnet Group Reference Issue

**Problem:** Terraform couldn't find `helga-rds-subnet-group01` during apply.

**Root Cause:** Case sensitivity mismatch + missing subnets from partial applies.

**Fix:** Ensured all three private subnet IDs were present in the subnet group and matched exactly in the RDS resource reference.

**Lesson:** AWS resource names are case-sensitive. Partial applies leave incomplete state.

---

### 7. Port Mismatch (Flask vs Security Group)

**Problem:** Flask app ran on port 5000 by default, but SG only allowed port 80.

**Error:** `curl` requests timed out.

**Fix:** Added port 5000 inbound to EC2 SG, later standardized Flask to run on port 80 via environment variable.

**Lesson:** Always verify application port matches security group rules and target group health check port.

---

### 8. Secret Name Mismatch (Terraform vs User Data)

**Problem:** Terraform created `helga/rds/mysql` but `user_data.sh` still referenced `lab/rds/mysql`.

**Additional Problem:** Secret JSON had wrong RDS endpoint (old Lab 1A host vs new `helga-rds01` host).

**Fix:** Updated `user_data.sh` to use `helga/rds/mysql` and corrected the `host` field in the secret JSON.

**Lesson:** User data scripts must reference the same resource names as Terraform. Always validate secret contents match actual infrastructure.

---

### 9. CloudWatch Broken References

**Problem:** Undefined `log` function in `user_data.sh` caused bootstrap failures. Log path mismatch (`/var/log/notes-app.log` vs `/var/log/notes-app/*.log`) prevented CloudWatch Agent from finding logs.

**Fix:** Corrected function name and standardized log path in both user data and CloudWatch Agent config.

**Lesson:** User data errors are silent unless you explicitly log to CloudWatch. Always test bootstrap scripts independently before embedding in Terraform.

---

### 10. User Data Only Runs Once (The Hidden Truth)

**Problem:** Edited `user_data.sh` in Terraform multiple times. Changes had no effect on running EC2 instance.

**Root Cause:** AWS user data executes **only on first boot**. Changing the script in Terraform does not update running instances.

**Fix:** Must `terraform destroy` → `terraform apply` to relaunch instance with updated user data. Alternatively, use `terraform taint` to force replacement.

**Cost:** Multiple debugging cycles before this clicked.

**Lesson:** User data is not configuration management. For iterative changes, use Systems Manager Run Command, Ansible, or bake AMIs.

---

### Resolution: Fresh Start

After accumulating state drift from partial applies and manual fixes, the cleanest path was:

1. `terraform destroy` (clean up all managed resources)
2. Clear lingering resources manually (ENIs, secrets, parameters)
3. `terraform init` (reinitialize providers)
4. `terraform apply` (deploy from scratch)

This eliminated drift and gave a known-good baseline. **Total time to working stack:** ~6 hours including all troubleshooting.

---

## Bonus Progression

| Bonus | Focus | Completed | Key Challenge |
| --- | --- | --- | --- |
| **A** | Private EC2 + VPC Endpoints (no public IP) | Jan 11, 2026 | Full SSM stack requires **three** endpoints (ssm, ec2messages, ssmmessages) — missing one breaks Session Manager |
| **B** | Public ALB + TLS (ACM) + WAF + Dashboard | Jan 17, 2026 | Adapted skeleton from `chewbacca` naming to `helga`; wired ALB → private EC2 targets with SG-to-SG rules |
| **C** | Route53 DNS + ACM DNS Validation | Jan 17, 2026 | Created hosted zone for `williebright.com` validated cert via DNS, ALIAS `app.williebright.com` → ALB |
| **D** | Apex Domain + ALB Access Logs to S3 | Jan 17, 2026 | Certificate only covered `app.williebright.com` — had to add apex `williebright.com` as SAN + nameserver sync |
| **E** | WAF Logging (CloudWatch / S3 / Firehose) | Jan 17, 2026 | AWS requires WAF log destinations start with `aws-waf-logs-`; built all 3 options as variable-driven toggles |
| **F** | CloudWatch Logs Insights Query Pack + Incident Runbook | Jan 17, 2026 | No new Terraform — pure runbook. Discovered Git Bash path conversion issue (`MSYS_NO_PATHCONV=1` fix) |
| **G** | Bedrock Auto-IR Pipeline (Template) | Templated | Alarm → Lambda → Logs Insights + Bedrock → S3 report → SNS notification |

---

## Bonus A: Private EC2 + VPC Endpoints

Moved EC2 from public to private subnet. Created 5 Interface Endpoints and 1 Gateway Endpoint:

- **Interface:** `helga-vpce-ssm`, `helga-vpce-ec2messages`, `helga-vpce-ssmmessages`, `helga-vpce-logs`, `helga-vpce-secretsmanager` — all with `helga-vpce-sg01` (HTTPS 443 from EC2 SG)
- **Gateway:** `helga-vpce-s3` (attached to both route tables)
- Removed SSH ingress, switched to SSM Session Manager
- Tightened IAM: scoped `GetSecretValue` to the specific secret ARN, `GetParameter` to `/lab/db/*` path only

---

## Bonus B: ALB + TLS + WAF

- **ALB:** `helga-alb01` (internet-facing) across all 3 public subnets
- **SG:** `helga-alb-sg01` — inbound HTTP 80 + HTTPS 443 from `0.0.0.0/0`
- **Target Group:** `helga-tg01` (port 80, health check: `/` → 200-399)
- **Listeners:** Port 80 → 301 redirect to HTTPS · Port 443 → forward to TG (TLS 1.3 policy: `ELBSecurityPolicy-TLS13-1-2-2021-06`)
- **ACM:** `helga-cert01` — primary `williebright.com`, SAN `app.williebright.com`, DNS validation
- **WAF:** `helga-waf01` (REGIONAL) — `AWSManagedRulesCommonRuleSet` (Priority 1), default action ALLOW
- **Alarm:** `helga-alb-5xx-alarm01` — `HTTPCode_ELB_5XX_Count ≥ 0` (period: 60s)
- **Dashboard:** `helga-dashboard01` — ALB RequestCount + 5XX + Target Response Time

---

## Bonus C + D: Route53 + Apex + ALB Logs

- **Hosted Zone:** `williebright.com` (`helga-zone01`) with nameserver sync via `aws_route53domains_registered_domain`
- **Records:** CNAME for ACM validation · A (ALIAS) `app.williebright.com` → ALB · A (ALIAS) `williebright.com` → ALB
- **ALB Access Logs:** S3 bucket `helga-alb-logs-<Account ID>` (prefix: `alb-access-logs/`)
- Logs confirmed flowing every 5 minutes after first traffic

---

## Bonus E: WAF Logging

- Destination: CloudWatch Logs `aws-waf-logs-helga-webacl01` (30-day retention)
- Built all three destination options (CloudWatch, S3, Firehose) as variable-driven toggles (`var.waf_log_destination`)
- Immediately captured real-world scanner traffic from France, Portugal, and US-based cloud hosts — all ALLOWED (no rule violations)

---

## Bonus F: Logs Insights Query Pack + Incident Runbook

Documented and tested a full query pack across two log groups:

- **WAF queries** (`aws-waf-logs-helga-webacl01`): action breakdown, top IPs, blocked requests, rule analysis, country breakdown, suspicious scanner patterns
- **App queries** (`/helga/notes-app`): errors over time, DB failure triage, error classification (creds vs network vs port)
- **Incident response runbook** with 4-step correlation workflow: confirm signal timing → decide attack vs backend → classify root cause → verify recovery

---

## Repository Structure

```jsx
lab1c/
├── 01-version.tf
├── 02-providers.tf
├── 03-variables.tf            # Base + Bonus variables
├── 04-main.tf                 # VPC, subnets, EC2, RDS, IAM, SGs, SSM, Secrets, CW, SNS
├── 04-1cb-Main.tf             # Bonus B: ALB, TLS, WAF, Dashboard
├── 04-1cc-route53.tf          # Bonus C: Route53 + ACM DNS validation
├── 04-1cd-logging-apex.tf     # Bonus D: Apex record + ALB access logs to S3
├── 04-1ce-Main.tf             # Bonus E: WAF logging (CW/S3/Firehose)
├── 05-outputs.tf
├── terraform.tfvars
└── user_data.sh               # Flask app + CloudWatch Agent bootstrap
```

---

## Skills Demonstrated

- **Infrastructure as Code (IaC)** — Converted 100% of ClickOps infrastructure to Terraform, achieving repeatable deployments
- **State Management** — Handled Terraform state drift, resource conflicts, and clean destroy/rebuild cycles
- **AWS Networking** — Built multi-AZ VPC with public/private subnets, NAT Gateway, IGW, route tables, and VPC endpoints
- **Private Compute Architecture** — Deployed EC2 in private subnet with SSM Session Manager access (no SSH, no public IP)
- **Security Group Design** — SG-to-SG references for EC2→RDS and ALB→EC2 communication
- **Secret Management at Scale** — Terraform-managed SSM Parameters and Secrets Manager with proper resource naming
- **Application Load Balancer (ALB)** — Internet-facing ALB with target groups, health checks, and HTTP→HTTPS redirect
- **TLS/SSL** — ACM certificate with DNS validation, multi-domain SANs, and TLS 1.3 enforcement
- **DNS Management** — Route53 hosted zone creation, nameserver sync, ALIAS records for apex and subdomain
- **Web Application Firewall (WAF)** — AWS Managed Rules integration, regional WAF, ALB association
- **Observability Engineering** — CloudWatch Logs, metric filters, alarms, SNS notifications, and ALB access logs to S3
- **WAF Logging** — Multi-destination logging (CloudWatch, S3, Firehose) with variable-driven toggles
- **Incident Response Runbooks** — CloudWatch Logs Insights queries for WAF analysis and application diagnostics
- **Troubleshooting** — Debugged AMI mismatches, ENI cleanup races, secret deletion windows, user data execution timing
- **Git Bash Quirks** — Handled Windows-specific path conversion issues (`MSYS_NO_PATHCONV=1`)
- **Terraform Best Practices** — Used `overwrite = true`, `force_overwrite_replica_secret`, proper dependency ordering
- **Bonus Progression** — Executed 7 bonus rounds (A→G) building from base to enterprise-grade architecture

---

## Interview Talk Track

> "In Lab 1C, I converted the entire manual infrastructure from Labs 1A and 1B into Terraform, achieving full Infrastructure as Code. This wasn't a clean single-pass deployment — I hit 10 distinct challenges including CIDR conflicts from leftover ClickOps resources, AMI architecture mismatches, Secrets Manager 30-day deletion windows, and the hidden truth that user data only runs once. The biggest lesson was about state management: mixing ClickOps and Terraform without proper cleanup creates drift that's hard to debug. After multiple partial applies, I did a full destroy-and-rebuild to establish a clean baseline.
> 

> 
> 

> I then completed seven bonus rounds: Bonus A moved EC2 to a private subnet with VPC endpoints for SSM Session Manager access — no SSH, no public IP. Bonus B added an internet-facing ALB with TLS, ACM certificate, and WAF with AWS Managed Rules. Bonus C integrated Route53 with DNS validation and ALIAS records. Bonus D added the apex domain and ALB access logs to S3. Bonus E implemented multi-destination WAF logging (CloudWatch, S3, Firehose) as variable-driven toggles. Bonus F was a pure runbook exercise — no new Terraform, just CloudWatch Logs Insights query packs for incident response. And Bonus G was a Bedrock auto-IR template for future automation.
> 

> 
> 

> The final result was an enterprise-grade stack: private compute, public ALB with TLS 1.3, WAF protection, centralized logging, and full observability — all managed as code. The repo is structured to separate base infrastructure from bonus features, making it easy to deploy incrementally. Total time including all troubleshooting: about 6 hours for the base stack, then another day for all seven bonus rounds. This lab proved I can migrate ClickOps infrastructure to IaC, debug complex Terraform state issues, and build production-grade AWS architectures with proper security controls."
> 

---

## Verification Commands

```bash
# Terraform outputs
terraform output

# EC2 private (no public IP)
aws ec2 describe-instances --instance-ids <ID> --query "Reservations[].Instances[].PublicIpAddress"

# VPC endpoints active
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=vpc-063d1e6ab946920e6" --query "VpcEndpoints[].ServiceName"

# ALB healthy targets
aws elbv2 describe-target-health --target-group-arn <TG_ARN>

# HTTPS works on both domains
curl -I https://app.williebright.com
curl -I https://williebright.com

# WAF attached
aws wafv2 get-web-acl-for-resource --resource-arn <ALB_ARN>

# WAF logs flowing
aws logs filter-log-events --log-group-name aws-waf-logs-helga-webacl01 --max-items 5

# ALB access logs in S3
aws s3 ls s3://helga-alb-logs-<Account ID>/alb-access-logs/ --recursive | head

# ACM cert issued with both domains
aws acm describe-certificate --certificate-arn <CERT_ARN> --query "Certificate.SubjectAlternativeNames"

# Secrets accessible
aws secretsmanager get-secret-value --secret-id helga/rds/mysql --query "SecretString" --output text | jq .

# App functional
curl localhost/health
curl localhost/init
curl "localhost/add?note=test"
curl localhost/list
```