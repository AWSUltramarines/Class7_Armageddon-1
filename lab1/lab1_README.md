# Lab 1 Execution Record - Helga Stack (us-east-2)
**EC2 → RDS Integration with Operations, Observability & Terraform IaC**
---
## Overview
This is the execution record for Lab 1, completed across three phases:
- **Lab 1A:** Manual deployment of VPC, EC2, RDS with Secrets Manager integration
- **Lab 1B:** Operations and incident response - dual secret storage, CloudWatch logging, alarms, and live sabotage exercise
- **Lab 1C:** Full Terraform IaC conversion plus seven bonus rounds (private compute, TLS/ALB, Route53, WAF, multi-destination logging, incident runbooks)

**Timeline:** January 2026 – February 2026  
**Region:** us-east-2 (Ohio)  
**AWS Account:** <Account ID>  
**Naming Convention:** helga
---
## Architecture Evolution
### Lab 1A: Foundation
- VPC "Helga" (`10.212.0.0/16`) with public/private subnets across us-east-2a
- Public EC2 (t3.micro) running Flask notes app
- Private RDS MySQL (`labdb`)
- Security Groups with SG-to-SG reference (EC2 → RDS on port 3306)
- Secrets Manager (`lab/rds/mysql`) with IAM role-based access

### Lab 1B: Operations Layer
- SSM Parameter Store for configuration (`/lab/db/endpoint`, `/lab/db/port`, `/lab/db/name`)
- CloudWatch Logs (`/aws/ec2/lab-rds-app`) with ERROR filtering
- CloudWatch Alarm (`lab-db-connection-failure-alarm`)
- SNS email notifications
- **Live sabotage exercise** - group lead performed 3 attacks (typo, prefix injection, username poison) requiring detection via logs and recovery using stored config

### Lab 1C: Enterprise-Grade IaC
- Full Terraform conversion of Labs 1A + 1B
- Updated VPC CIDR to `10.241.0.0/16` (avoiding conflict)
- 3 public + 3 private subnets across us-east-2a/b/c
- **Bonus A:** Private EC2 with 6 VPC Endpoints (SSM, EC2Messages, SSMMessages, Logs, Secrets Manager, S3)
- **Bonus B:** Internet-facing ALB with TLS 1.3, ACM certificate, WAF, CloudWatch Dashboard
- **Bonus C:** Route53 hosted zone with DNS validation for `app.williebright.com`
- **Bonus D:** Apex domain + ALB access logs to S3
- **Bonus E:** WAF logging to CloudWatch/S3/Firehose (variable-driven)
- **Bonus F:** CloudWatch Logs Insights query pack + 4-step incident correlation runbook
---
## Actual Resources Deployed
### Networking
| Resource | Value |
|---|---|
| **VPC** | `helga-vpc01` - `10.241.0.0/16` |
| **Public Subnets** | `helga-public-subnet01/02/03` - `.1.0/24`, `.2.0/24`, `.3.0/24` |
| **Private Subnets** | `helga-private-subnet01/02/03` - `.101.0/24`, `.102.0/24`, `.103.0/24` |
| **IGW** | `helga-igw01` |
| **NAT Gateway** | `helga-nat01` with EIP `helga-nat-eip01` |

### Compute & Database
| Resource | Value |
|---|---|
| **EC2** | `helga-ec201` (t3.micro, private subnet, Flask app at `/opt/rdsapp`) |
| **IAM Role** | `helga-ec2-role01` → SSM, Secrets Manager, CloudWatch policies |
| **RDS** | `helga-rds01` (db.t3.micro, MySQL, private, single-AZ) |
| **RDS Endpoint** | `helga-rds01.chkce02amfxr.us-east-2.rds.amazonaws.com` |
| **Database** | `t_labdb` |

### Security
| Resource | Value |
|---|---|
| **EC2 SG** | `helga-ec2-sg01` - HTTP 80, SSH 22 from `185.141.119.79/32` |
| **RDS SG** | `helga-rds-sg01` - MySQL 3306 from `helga-ec2-sg01` (SG-to-SG reference) |
| **ALB SG** | `helga-alb-sg01` - HTTP 80, HTTPS 443 from `0.0.0.0/0` |
| **VPC Endpoint SG** | `helga-vpce-sg01` - HTTPS 443 from EC2 SG |

### Secrets & Configuration
| Resource | Value |
|---|---|
| **Secrets Manager** | `helga/rds/mysql` - `{username, password, host, port, dbname}` |
| **SSM Parameters** | `/lab/db/endpoint`, `/lab/db/port`, `/lab/db/name` |

### Load Balancing & DNS
| Resource | Value |
|---|---|
| **ALB** | `helga-alb01` (internet-facing, across 3 public subnets) |
| **Target Group** | `helga-tg01` (port 80, health check: `/` → 200-399) |
| **ACM Certificate** | `helga-cert01` - `williebright.com` • `app.williebright.com` (DNS validated) |
| **Route53 Zone** | `williebright.com` (`helga-zone01`) |
| **DNS Records** | A (ALIAS) `app.williebright.com` → ALB · A (ALIAS) `williebright.com` → ALB |

### WAF & Observability
| Resource | Value |
|---|---|
| **WAF** | `helga-waf01` (REGIONAL) - `AWSManagedRulesCommonRuleSet` |
| **WAF Logs** | `aws-waf-logs-helga-webacl01` (30-day retention) |
| **App Logs** | `/aws/ec2/helga-rds-app`, `/helga/ec2/user-data`, `/helga/notes-app` |
| **Alarm** | `helga-db-connection-failure` - `DBConnectionErrors ≥ 3` (period: 300s) |
| **ALB Logs** | S3 bucket `helga-alb-logs-<Account ID>` |
| **Dashboard** | `helga-dashboard01` - ALB RequestCount, 5XX, Target Response Time |
---
## Key Challenges Solved
### Lab 1A Troubleshooting
1. **Subnet routing** - EC2 couldn't reach internet for User Data bootstrap; fixed by adding `0.0.0.0/0 → IGW` route
2. **Secret structure** - Initial secret missing `host` field; recreated using "Credentials for RDS database" type
3. **IAM permissions** - Role lacked `secretsmanager:GetSecretValue`; added scoped inline policy
4. **Flask binding** - App bound to `127.0.0.1` instead of `0.0.0.0`; fixed in `user_data.sh`

### Lab 1B Operations
1. **SSM access denied** - Role lacked `ssm:GetParameter`; added inline policy `lab-ssm-read`
2. **Log redirection** - Flask logs went to journald; redirected to `/var/log/rdsapp/app.log` via systemd
3. **ERROR logging** - App didn't explicitly log `ERROR` keyword; modified `get_conn()` function
4. **CloudWatch IAM** - `DescribeLogStreams` vs `DescribeLogGroups` require different resource scopes
5. **Git Bash path conversion** - Prefixed all commands with `MSYS_NO_PATHCONV=1`

**Live Sabotage Exercise:**
- Group lead performed 3 attacks: typo in endpoint (`he1ga` vs `helga`), prefix injection in DB name (`t_labdb`), username poison (`adm1n` vs `admin`)
- Detected via CloudWatch Logs showing exact error messages
- Recovered using stored SSM/Secrets Manager values without redeploying

### Lab 1C Terraform Journey
1. **Subnet CIDR conflict** - Labs 1A/1B subnets existed at `10.212.0.0/16`; changed VPC to `10.241.0.0/16`
2. **AMI architecture mismatch** - ARM64 AMI with x86_64 instance type; switched to correct AMI
3. **User data only runs once** - Editing `user_data.sh` doesn't update running instances; must terminate and relaunch
4. **Secret name drift** - Terraform created `helga/rds/mysql`, `user_data.sh` referenced `lab/rds/mysql`
5. **RDS endpoint mismatch** - Secret contained old Lab 1A endpoint; updated to `helga-rds01` endpoint
6. **Session Manager requires 3 endpoints** - SSM, EC2Messages, SSMMessages all needed for connectivity
7. **WAF log destination naming** - Must start with `aws-waf-logs-` per AWS requirement
8. **State drift from partial applies** - Resolved with `terraform destroy` → clean `apply`
---
## Skills Demonstrated
- **Security Groups** - SG-to-SG references (not IP-based), least privilege inbound rules
- **IAM** - Role-based access with scoped policies, troubleshooting `AccessDeniedException`
- **Secrets Management** - Dual storage pattern (Parameter Store for config, Secrets Manager for credentials)
- **Observability** - Centralized logging, metric filters, symptom-based alarms
- **Incident Response** - Detection via logs, diagnosis via stored config, recovery without redeploy
- **Infrastructure as Code** - Full Terraform implementation with modular structure, variable-driven configurations
- **Private Networking** - VPC Endpoints for AWS service access without internet routes
- **TLS & DNS** - ACM certificate provisioning with DNS validation, Route53 ALIAS records
- **WAF & Logging** - Web application firewall with multi-destination logging (CloudWatch, S3, Firehose)
- **Real-World Troubleshooting** - Character substitution attacks, path conversion issues, timing/synchronization failures
---
## Interview Talk Track
> "I built a secure EC2-to-RDS architecture starting with manual deployment to understand the components, then added operational resilience with dual secret storage and CloudWatch observability. After surviving a live sabotage exercise where I had to detect and recover from three credential/config poisoning attacks using only logs and stored values, I converted the entire stack to Terraform IaC and extended it with enterprise features: private compute with VPC endpoints, internet-facing ALB with TLS 1.3 and WAF protection, Route53 DNS with cert validation, multi-destination logging, and a documented incident response runbook. The biggest lessons were that user data only runs once, Session Manager needs all three endpoints, and symptom-based alarms catch more failure modes than cause-based alarms."
---
## Repository Structure
```jsx
lab1/
├── 01-version.tf
├── 02-providers.tf
├── 03-variables.tf
├── 04-main.tf                   # Base: VPC, EC2, RDS, IAM, SSM, Secrets, CW, SNS
├── 04-1cb-Main.tf               # Bonus B: ALB, TLS, WAF, Dashboard
├── 04-1cc-route53.tf              # Bonus C: Route53 + ACM DNS validation
├── 04-1cd-logging-apex.tf    # Bonus D: Apex record + ALB logs to S3
├── 04-1ce-Main.tf           # Bonus E: WAF logging (CW/S3/Firehose)
├── 05-outputs.tf
├── terraform.tfvars
└── user_data.sh       # Flask app + CloudWatch Agent bootstrap


```
### Terraform State

```bash
terraform output
terraform state list
```

### EC2 & IAM

```bash
aws ec2 describe-instances --instance-ids <ID> --query "Reservations[].Instances[].{State:State.Name,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress,Role:IamInstanceProfile.Arn}"

aws ec2 describe-instances --instance-ids <ID> --query "Reservations[].Instances[].IamInstanceProfile.Arn"
```

### RDS

```bash
aws rds describe-db-instances --db-instance-identifier helga-rds01 --query "DBInstances[].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,AZ:AvailabilityZone}"
```

### Security Groups

```bash
aws ec2 describe-security-groups --group-ids sg-01f5bc3e6b016dbb2 --query "SecurityGroups[].IpPermissions"
```

### Secrets & Parameters

```bash
aws secretsmanager get-secret-value --secret-id helga/rds/mysql --query "SecretString" --output text | jq .

aws ssm get-parameters --names /lab/db/endpoint /lab/db/port /lab/db/name --with-decryption
```

### VPC Endpoints

```bash
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=<VPC_ID>" --query "VpcEndpoints[].{Service:ServiceName,State:State,ID:VpcEndpointId}"
```

### ALB & Target Health

```bash
aws elbv2 describe-load-balancers --names helga-alb01 --query "LoadBalancers[].{DNS:DNSName,State:State.Code,AZs:AvailabilityZones[].ZoneName}"

aws elbv2 describe-target-health --target-group-arn <TG_ARN>
```

### WAF

```bash
aws wafv2 get-web-acl-for-resource --resource-arn <ALB_ARN> --scope REGIONAL --region us-east-2
```

### Logs & Alarms

```bash
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/lab-rds-app

aws logs filter-log-events --log-group-name /aws/ec2/lab-rds-app --filter-pattern "ERROR" --limit 10

aws cloudwatch describe-alarms --alarm-names helga-db-connection-failure --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Metric:MetricName}"
```

### Application Endpoints

```bash
# Public ALB (Bonus B+)
curl -I https://app.williebright.com
curl -I https://williebright.com

# Direct EC2 (Lab 1A/1B only)
curl http://<EC2_PUBLIC_IP>/init
curl "http://<EC2_PUBLIC_IP>/add?note=test"
curl http://<EC2_PUBLIC_IP>/list
```