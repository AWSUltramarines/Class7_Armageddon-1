# EC2 → RDS Labs: Infrastructure to Airgap Operations

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS_Provider-~%3E5.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Amazon Linux](https://img.shields.io/badge/Amazon_Linux-2023-FF9900?logo=amazon-aws)](https://aws.amazon.com/linux/amazon-linux-2023/)

A progressive three-lab series demonstrating the evolution from secure infrastructure deployment through production operations to **private compute with an offline, GPG-signed release pipeline**.

---

## Lab Overview

| Lab | Focus | Complexity | Time |
|-----|-------|------------|------|
| **[Lab 1a](1a/)** | Infrastructure & Security | Foundation | 30-45 min |
| **[Lab 1b](1b/)** | Operations & Incident Response | Advanced | 60-90 min |
| **[Lab 1c](1c/)** | Private Compute & Offline Pipeline | Expert | 2-3 hours |

---

## Lab 1a: Secure Infrastructure Foundation

**📂 Directory:** [`1a/`](1a/)

**Objective:** Deploy secure EC2-to-RDS architecture following AWS best practices.

### What You'll Build

- VPC with public/private subnets across 2 AZs
- EC2 instance running Flask application
- RDS MySQL database in private subnets
- Security group-to-security group references
- AWS Secrets Manager for credential management
- IAM instance profiles for secure AWS API access

### Key Features

- ✅ **Zero Static Credentials** - Secrets Manager + IAM roles
- ✅ **Network Isolation** - RDS in private subnets only
- ✅ **SG-to-SG References** - No CIDR-based database access
- ✅ **Encrypted Storage** - EBS and RDS encryption enabled
- ✅ **IMDSv2 Required** - Enhanced metadata security
- ✅ **Comprehensive Documentation** - Includes troubleshooting runbook

### Quick Start

```bash
cd 1a
terraform init
terraform apply

# Test the application
EC2_IP=$(terraform output -raw ec2_public_ip)
curl http://$EC2_IP/init
curl "http://$EC2_IP/add?note=Hello%20World"
curl http://$EC2_IP/list
```

### Learning Outcomes

- Secure VPC design with public/private subnet separation
- Security group architecture and SG-to-SG references
- AWS Secrets Manager integration patterns
- IAM roles and instance profiles
- EC2 user-data and application bootstrapping
- RDS deployment in private subnets

**📖 Full Documentation:** [1a/README.md](1a/README.md)

---

## Lab 1b: Production Operations & Incident Response

**📂 Directory:** [`1b/`](1b/)

**Objective:** Extend Lab 1a with observability, monitoring, alerting, and incident response capabilities.

### What's Added to Lab 1a

- **Dual Secret Storage** - Parameter Store for operational metadata
- **Centralized Logging** - CloudWatch Logs with real-time log shipping
- **Proactive Monitoring** - Metric filters detecting DB connection failures
- **Automated Alerting** - CloudWatch Alarms with SNS notifications
- **Incident Response** - Comprehensive runbook with recovery procedures
- **Chaos Engineering** - Controlled failure tests to validate monitoring

### Architecture Evolution

```diff
Lab 1a:
  EC2 → Secrets Manager → RDS

Lab 1b:
  EC2 → {Secrets Manager, Parameter Store, CloudWatch}
         │
         ├─ Get DB Credentials (Secrets Manager)
         ├─ Get DB Metadata (Parameter Store)
         ├─ Ship Application Logs (CloudWatch Logs)
         └─ Metric Filter → Alarm → SNS Email
```

### Monitoring Pipeline

1. Application logs `DB_CONNECTION_FAILURE` errors to `/var/log/notes-app.log`
2. CloudWatch Agent ships logs to CloudWatch Logs group
3. Metric Filter matches error pattern, increments custom metric
4. Alarm triggers when errors >= 3 in 5-minute window
5. SNS topic sends email notification to on-call engineer

### Quick Start

```bash
cd 1b
terraform init
terraform apply -var="alert_email=your@email.com"

# Verify CloudWatch integration
aws logs describe-log-streams \
  --log-group-name /aws/ec2/lab-rds-app \
  --order-by LastEventTime \
  --descending
```

### Learning Outcomes

- Dual secret management (Secrets Manager vs Parameter Store)
- CloudWatch Logs agent setup and configuration
- Log-based metric creation with metric filters
- CloudWatch Alarms with appropriate thresholds
- SNS topic integration for incident notifications
- Incident response procedures and runbooks
- Chaos engineering for resilience testing

### Incident Response Features

**3 Documented Failure Modes:**
1. **Credential Drift** - Password mismatch between Secrets Manager and RDS
2. **Network Isolation** - Missing security group rules
3. **Database Unavailability** - RDS instance stopped or crashed

**Each includes:**
- Step-by-step detection procedures
- Root cause analysis commands
- Recovery workflows
- Validation steps

**📖 Full Documentation:** [1b/README.md](1b/README.md)
**📘 Incident Runbook:** [1b/RUNBOOK.md](1b/RUNBOOK.md)

---

## Lab 1c: Private Compute with Offline Release Pipeline

**📂 Directory:** [`1c/`](1c/)

**Objective:** Deploy a fully private EC2-to-RDS architecture where all runtime dependencies are sourced from S3 via an immutable, GPG-signed release pipeline. SSH is eliminated entirely — access is exclusively via SSM Session Manager.

### What You'll Build

- Private VPC with no Internet Gateway, no NAT Gateway, no public subnets (airgap mode)
- 7 VPC endpoints (S3 Gateway + SSM, EC2Messages, SSMMessages, Logs, Secrets Manager, KMS)
- Immutable release pipeline with 5 purpose-built scripts
- 3-key GPG signing model with operator-owned chain of custody
- Channel-based promotion system (`dev` / `stage` / `prod`)
- Fail-closed EC2 bootstrap with SHA256 manifest verification
- Conditional Terraform resources supporting dual exposure modes

### Architecture Evolution

```
Lab 1b:
  Internet → EC2 (public, SSH) → RDS
               │
               └─ Secrets + Params + CloudWatch (via internet)

Lab 1c:
  Operator → SSM → EC2 (private, no SSH) → RDS
                     │
                     ├─ S3 Gateway Endpoint (signed offline artifacts)
                     ├─ VPC Endpoints (secrets, params, logs, kms)
                     ├─ 3-Key GPG Verification (manifest, repo, RPM)
                     ├─ Channel-Based Promotion (dev / stage / prod)
                     └─ Fail-Closed Bootstrap (no internet, no fallbacks)
```

### Key Features

- ✅ **Airgap Runtime** — No IGW, no NAT, no public subnets, no internet access
- ✅ **SSH Eliminated** — No key pairs, no port 22, no `.pem` files
- ✅ **3-Key GPG Signing** — Operator-owned trust root with end-to-end chain of custody
- ✅ **Immutable Releases** — Timestamped snapshots, never modified after build
- ✅ **Channel Promotion** — `dev` / `stage` / `prod` pointer-based promotion and rollback
- ✅ **Fail-Closed Bootstrap** — SHA256 manifest, strict mode, no fallbacks
- ✅ **VPC Endpoints** — All AWS API traffic stays within the AWS network
- ✅ **SSM Session Manager** — IAM-authenticated access with CloudTrail audit
- ✅ **Dual Exposure Modes** — Airgap (default) and public ALB for legacy comparison
- ✅ **Scoped IAM** — Every permission resource-specific, no wildcards

### Release Pipeline

```
Day-0: fetch-al2023-rpms.sh → 0-build_release.sh
         (CDN-restricted RPMs)    (3-key GPG sign + manifest)

Day-1: terraform apply → 1-upload_release.sh → 2-promote_channel.sh → terraform apply
       (infra, no EC2)    (sync to S3)          (point channel)         (deploy EC2)

Day-2+: promote higher | rollback | new release cycle
```

### Quick Start (Airgap Mode)

> **Prerequisite:** AL2023 RPMs must be fetched before building.
> See [1c/README.md — Day-0 Phase-1: Supply Chain Preparation](1c/README.md#al2023-rpm-source-constraint)
> for the CDN constraint and fetch procedure.

```bash
cd 1c

# Day-0 Phase-2: Build signed release (deps/ must already be populated)
RELEASE_ID=<ISO-8601-timestamp>
GPG_PASSPHRASE_FILE=/path/to/passphrase \
  ./tools/0-build_release.sh "$RELEASE_ID"

# Day-1 Phase-1: Deploy infrastructure (no EC2 yet)
terraform init
terraform apply -var="enable_ec2=false"

# Day-1 Phase-2 + Phase-3: Upload and promote
BUCKET=$(terraform output -raw deps_bucket_name)
./tools/1-upload_release.sh "$RELEASE_ID" "$BUCKET"
./tools/2-promote_channel.sh dev "$RELEASE_ID" "$BUCKET"

# Day-1 Phase-4: Deploy EC2 (set fingerprints from build output)
terraform apply \
  -var="enable_ec2=true" \
  -var="release_id=$RELEASE_ID" \
  -var="release_gpg_key_fingerprint=<40-hex>" \
  -var="repo_gpg_key_fingerprint=<40-hex>" \
  -var="rpm_gpg_key_fingerprint=<40-hex>"

# Access via SSM port-forward
aws ssm start-session --target $(terraform output -raw ec2_instance_id) \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["80"],"localPortNumber":["8080"]}'

# Test (in another terminal)
curl http://localhost:8080/health
curl http://localhost:8080/init
curl "http://localhost:8080/add?note=Airgap%20test"
curl http://localhost:8080/list
```

### Learning Outcomes

- Private VPC design with no internet dependency
- VPC endpoint architecture (Gateway vs Interface endpoints)
- SSH elimination via SSM Session Manager
- GPG key generation, signing, and fingerprint pinning
- Immutable release pipelines with channel-based promotion
- Fail-closed bootstrap with multi-layer verification
- Terraform conditional resources (`count` + `local.is_airgap`)
- Supply-chain security and chain of custody concepts

**📖 Full Documentation:** [1c/README.md](1c/README.md)
**📘 Operational Runbook:** [1c/RUNBOOK.md](1c/RUNBOOK.md)
**📕 Security Analysis:** [1c/SECURITY.md](1c/SECURITY.md)

---

## Lab Progression

### Recommended Learning Path

1. **Start with Lab 1a** - Build foundation understanding
   - Deploy secure infrastructure
   - Understand VPC networking patterns
   - Practice Secrets Manager integration
   - Verify application functionality

2. **Progress to Lab 1b** - Add operational capabilities
   - Enable centralized logging
   - Configure monitoring and alerting
   - Practice incident response procedures
   - Run chaos engineering tests

3. **Advance to Lab 1c** - Private compute and release engineering
   - Eliminate SSH, adopt SSM Session Manager
   - Build and sign offline release artifacts
   - Deploy to a fully airgapped VPC
   - Practice channel promotion and rollback

### Skills Developed

| Category | Lab 1a | Lab 1b | Lab 1c |
|----------|--------|--------|--------|
| **Infrastructure** | VPC, EC2, RDS, Security Groups | + Parameter Store, CloudWatch | + VPC Endpoints, S3 Gateway, ALB (conditional) |
| **Security** | Secrets Manager, IAM, Encryption | + Enhanced IAM policies | + GPG signing, SHA256 manifests, no SSH |
| **Networking** | Public/private subnets, IGW, SG-to-SG | Same | + Airgap (no IGW/NAT), VPC endpoint routing |
| **Access** | SSH key pair | SSH key pair | SSM Session Manager (IAM-only) |
| **Bootstrap** | Internet (user_data) | Internet (+ CW agent) | Offline signed artifacts from S3 |
| **Monitoring** | None | Logs, Metrics, Alarms, SNS | Same (via VPC endpoints) |
| **Operations** | Manual SSH troubleshooting | Automated detection + Runbook | + Release pipeline, channel promotion, rollback |
| **Testing** | Manual verification | Chaos engineering | + Supply-chain verification, drift checks |

---

## Key Differences: 1a vs 1b vs 1c

| Feature | Lab 1a | Lab 1b | Lab 1c |
|---------|--------|--------|--------|
| **Secret Storage** | Secrets Manager only | + Parameter Store | Same as 1b |
| **Logging** | Local file only | + CloudWatch Logs | Same (via VPC endpoint) |
| **Monitoring** | None | Metric Filter + Alarm + SNS | Same (via VPC endpoint) |
| **Instance Access** | SSH key pair | SSH key pair | SSM Session Manager |
| **Network** | Public EC2, IGW | Public EC2, IGW | Private EC2, no IGW, no NAT |
| **Bootstrap** | Internet downloads | Internet + CW agent | Offline signed S3 artifacts |
| **Package Verification** | None | None | GPG + SHA256 (fail-closed) |
| **Release Management** | N/A | N/A | Immutable pipeline + channels |
| **IAM Permissions** | Secrets Manager read | + SSM, CloudWatch | + S3 deps bucket (scoped) |
| **User-Data** | Basic Flask setup | + CloudWatch Agent | + GPG verify + offline install |
| **Incident Response** | Manual SSH diagnosis | Automated detection + Runbook | + Release rollback |
| **Terraform Resources** | ~18 | ~24 | ~37+ (conditional) |

---

## Architecture Comparison

### Lab 1a: Secure Infrastructure
```
┌─────────────────────────────────────────┐
│              VPC (10.0.0.0/16)          │
│                                         │
│  Public Subnet        Private Subnet    │
│  ┌──────────┐        ┌──────────┐       │
│  │   EC2    │─SG Ref─│   RDS    │       │
│  │  Flask   │        │  MySQL   │       │
│  └────┬─────┘        └──────────┘       │
│       │                                 │
└───────┼─────────────────────────────────┘
        │
     Internet
        ▲
        │
   IAM + Secrets Manager
```

### Lab 1b: Operations & Monitoring
```
┌─────────────────────────────────────────────────────┐
│              VPC (10.0.0.0/16)                      │
│                                                     │
│  Public Subnet        Private Subnet                │
│  ┌──────────┐        ┌──────────┐                   │
│  │   EC2    │─SG Ref─│   RDS    │                   │
│  │  Flask   │        │  MySQL   │                   │
│  │ + CW Agt │        └──────────┘                   │
│  └────┬─────┘                                       │
│       │                                             │
└───────┼─────────────────────────────────────────────┘
        │
     Internet
        ▲
        │
   IAM + Secrets + Params + CloudWatch
                              │
                              ├─ Logs
                              ├─ Metrics
                              └─ Alarms → SNS → Email
```

### Lab 1c: Private Compute (Airgap)
```
                              VPC (10.190.0.0/16)
                 No IGW · No NAT · No Public Subnets · No ALB
            ┌───────────────────────────────────────────────────────┐
            │                                                       │
            │       S3 Gateway              VPC Endpoints           │
            │       (signed artifacts)      (ssm, logs,             │
            │            │                   secrets, kms)          │
            │            ▼                        ▼                 │
            │       EC2 (private) ──3306──► RDS (private)           │
            │            ▲                                          │
            │       SSM Endpoints                                   │
            │       (ssm, ssmmessages, ec2messages)                 │
            └────────────┼──────────────────────────────────────────┘
                         ▲
                     Operator
                (IAM auth, port-forward)
```

---

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured (`aws configure`)
- Terraform >= 1.5.0 installed
- `jq` for JSON parsing (Lab 1b, 1c)
- Basic understanding of:
  - VPC networking concepts
  - Security groups
  - IAM roles and policies
  - RDS MySQL

**Lab 1c additionally requires:**
- GPG (GnuPG 2.2+) for signing
- `createrepo_c` for RPM repository creation
- `rpmsign` for RPM package signing
- Access to an AL2023 EC2 instance (one-time RPM fetch)

---

## Cost Considerations

All labs use **AWS Free Tier eligible** compute (Lab 1c's VPC endpoints are the exception):

| Resource | Type | Free Tier Limit | Lab 1a | Lab 1b | Lab 1c |
|----------|------|-----------------|--------|--------|--------|
| EC2 | t3.micro | 750 hours/month | ~$8/mo | ~$8/mo | ~$8/mo |
| RDS | db.t3.micro | 750 hours/month | ~$15/mo | ~$15/mo | ~$15/mo |
| EBS | gp3 8GB | 30 GB/month | $0.80 | $0.80 | $0.80 |
| Secrets Manager | 1 secret | 30-day trial | $0.40 | $0.40 | $0.40 |
| CloudWatch Logs | Ingestion | 5 GB/month free | — | ~$1/mo | ~$1/mo |
| CloudWatch Alarms | Standard | 10 alarms free | — | Free | Free |
| SNS | Notifications | 1,000 emails free | — | Free | Free |
| VPC Endpoints | 6 Interface | **Not free tier** | — | — | **~$44/mo** |
| S3 Gateway | Endpoint | Free | — | — | Free |

**Estimated monthly cost** (outside free tier):
- **Lab 1a:** ~$23/month
- **Lab 1b:** ~$25/month
- **Lab 1c:** ~$69/month (VPC endpoints are the primary cost driver)

**💡 Cost Optimization:**
- Destroy resources when not in use: `terraform destroy`
- All labs deploy in `us-east-1` (lowest AWS pricing region)

---

## Repository Structure

```
.
├── 1a/                          # Lab 1a: Secure Infrastructure
│   ├── 0-backend.tf             # S3 backend configuration
│   ├── 0-versions.tf            # Terraform/provider versions
│   ├── 0.1-locals.tf            # Local values
│   ├── 0.1-variables.tf         # Input variables
│   ├── 0.2-iam.tf               # IAM roles and policies
│   ├── 0.3-secrets.tf           # Secrets Manager
│   ├── 1-providers.tf           # AWS provider
│   ├── 2-network.tf             # VPC, subnets, IGW, routes
│   ├── 3-security_groups.tf     # EC2 and RDS security groups
│   ├── 4-ec2.tf                 # EC2 instance
│   ├── 5-rds.tf                 # RDS MySQL instance
│   ├── 6-outputs.tf             # Terraform outputs
│   ├── templates/
│   │   └── user_data.sh.tftpl   # EC2 bootstrap script
│   ├── evidence/                # Deployment screenshots
│   ├── README.md                # Lab 1a documentation
│   ├── RUNBOOK.md               # Troubleshooting guide
│   └── SECURITY.md              # Security considerations
│
├── 1b/                          # Lab 1b: Operations & Monitoring
│   ├── 0-backend.tf             # S3 backend configuration
│   ├── 0-versions.tf            # Terraform/provider versions
│   ├── 0.1-locals.tf            # Local values
│   ├── 0.1-variables.tf         # Input variables (+ monitoring vars)
│   ├── 0.2-iam.tf               # IAM roles (+ CloudWatch permissions)
│   ├── 0.3-secrets.tf           # Secrets Manager + Parameter Store
│   ├── 1-providers.tf           # AWS provider
│   ├── 2-network.tf             # VPC, subnets, IGW, routes
│   ├── 3-security_groups.tf     # EC2 and RDS security groups
│   ├── 4-ec2.tf                 # EC2 instance
│   ├── 5-rds.tf                 # RDS MySQL instance
│   ├── 6-cloudwatch.tf          # Logs, Metric Filters, Alarms, SNS (NEW)
│   ├── 7-outputs.tf             # Terraform outputs (+ monitoring outputs)
│   ├── templates/
│   │   └── user_data.sh.tftpl   # EC2 bootstrap + CloudWatch Agent
│   ├── evidence/                # Deployment + chaos test screenshots
│   ├── README.md                # Lab 1b documentation
│   ├── RUNBOOK.md               # Incident response + Chaos engineering
│   └── SECURITY.md              # Security considerations
│
├── 1c/                          # Lab 1c: Private Compute & Offline Pipeline
│   ├── 0-backend.tf             # S3 backend configuration
│   ├── 0-versions.tf            # Terraform/provider versions
│   ├── 0.1-locals.tf            # S3 prefixes, channel pointers, GPG paths
│   ├── 0.1-variables.tf         # Variables: exposure_mode, fingerprints
│   ├── 0.2-iam.tf               # EC2 role (SSM, S3, CloudWatch, Secrets)
│   ├── 0.3-secrets.tf           # Secrets Manager + Parameter Store
│   ├── 1-providers.tf           # AWS provider
│   ├── 2-network.tf             # VPC, subnets (conditional public)
│   ├── 2.1-vpc-endpoints.tf     # S3 Gateway + 6 Interface endpoints
│   ├── 3-security_groups.tf     # ALB (conditional), EC2, RDS, Endpoint SGs
│   ├── 4-ec2.tf                 # EC2 (conditional, mode-aware template)
│   ├── 4.1-alb.tf               # ALB (public_alb mode only)
│   ├── 4.2-s3-deps.tf           # S3 bucket + channel pointers
│   ├── 5-rds.tf                 # RDS MySQL instance
│   ├── 6-cloudwatch.tf          # CloudWatch Logs, Metrics, Alarms
│   ├── 7-outputs.tf             # Output values (mode-aware)
│   ├── templates/
│   │   ├── user_data.sh.tftpl         # Offline bootstrap (airgap mode)
│   │   └── user_data_legacy.sh.tftpl  # Internet bootstrap (public_alb mode)
│   ├── tools/
│   │   ├── fetch-al2023-rpms.sh       # day-0: Fetch AL2023 RPMs (EC2-only CDN)
│   │   ├── 0-build_release.sh         # day-0: Build + 3-key GPG sign
│   │   ├── 1-upload_release.sh        # day-1: Upload to S3
│   │   ├── 2-promote_channel.sh       # day-1: Channel promotion
│   │   └── 3-rollback_channel.sh      # day-2+: Rollback
│   ├── deps/                    # Cached RPMs, pip wheels, CW agent
│   ├── keys/                    # Exported GPG public keys (3 roles)
│   ├── out/                     # Build output (git-ignored)
│   ├── README.md                # Architecture & concepts
│   ├── RUNBOOK.md               # Operational procedures
│   ├── SECURITY.md              # Threat model & security controls
│   └── claude.md                # AI assistant context
│
├── claude.md                    # Top-level AI context
└── README.md                    # This file
```

---

## Getting Started

### Option 1: Sequential Learning (Recommended)

```bash
# Start with Lab 1a
cd 1a
terraform init
terraform apply
# Explore, test, understand
terraform destroy

# Progress to Lab 1b
cd ../1b
terraform init
terraform apply -var="alert_email=your@email.com"
# Run verification steps, trigger alarms, practice runbook
terraform destroy

# Advance to Lab 1c
cd ../1c
# Follow RUNBOOK.md day-0 through day-1 phases
```

### Option 2: Direct to Lab 1b

If you're already familiar with VPC/EC2/RDS basics:

```bash
cd 1b
terraform init
terraform apply -var="alert_email=your@email.com"
```

### Option 3: Direct to Lab 1c

If you're comfortable with VPC, EC2, RDS, CloudWatch, and want the full private compute experience:

```bash
cd 1c
# See 1c/RUNBOOK.md for the complete phased deployment workflow
```

**Note:** Each lab is standalone — you don't need to deploy earlier labs first.

---

## Documentation Links

### Lab 1a Resources
- **[README.md](1a/README.md)** - Complete lab documentation
- **[RUNBOOK.md](1a/RUNBOOK.md)** - Troubleshooting procedures
- **[SECURITY.md](1a/SECURITY.md)** - SSH key management and security

### Lab 1b Resources
- **[README.md](1b/README.md)** - Complete lab documentation
- **[RUNBOOK.md](1b/RUNBOOK.md)** - Incident response + chaos engineering
- **[SECURITY.md](1b/SECURITY.md)** - SSH key management and security

### Lab 1c Resources
- **[README.md](1c/README.md)** - Architecture, pipeline design, and concepts
- **[RUNBOOK.md](1c/RUNBOOK.md)** - Phased deployment and operational procedures
- **[SECURITY.md](1c/SECURITY.md)** - Threat model, supply-chain hardening, and security controls

---

## Common Issues & Solutions

### Issue: Terraform State Lock

**Error:** `Error locking state: resource temporarily unavailable`

**Solution:**
```bash
# If backend uses S3, check for stale locks
aws dynamodb describe-table --table-name terraform-state-lock

# Force unlock (use carefully)
terraform force-unlock <LOCK_ID>
```

### Issue: RDS Creation Timeout

**Symptom:** RDS takes > 10 minutes to create

**Explanation:** This is normal. RDS provisioning includes:
- Compute instance launch (~3 min)
- Storage allocation (~2 min)
- Backup configuration (~2 min)
- Multi-AZ standby setup (~3 min if enabled)

**Total:** 5-12 minutes is expected

### Issue: Application Not Responding

**Lab 1a:** See [1a/RUNBOOK.md](1a/RUNBOOK.md) for layer-by-layer diagnosis
**Lab 1b:** See [1b/RUNBOOK.md](1b/RUNBOOK.md) for incident response procedures
**Lab 1c:** See [1c/RUNBOOK.md](1c/RUNBOOK.md#troubleshooting) for bootstrap and connectivity diagnosis

### Issue: Multiple GPG Keys Found (Lab 1c)

**Error:** `Multiple GPG keys found; set RELEASE_GPG_KEY_ID explicitly`

**Solution:** See [1c/RUNBOOK.md — Resolving: Multiple GPG Keys Found](1c/RUNBOOK.md#resolving-multiple-gpg-keys-found)

### Issue: SSM Target Not Connected (Lab 1c)

**Symptom:** `aws ssm start-session` fails with "target is not connected"

**Solution:**
1. Verify VPC endpoints exist and are in `available` state
2. Check EC2 security group allows outbound HTTPS to endpoint SG
3. Reboot the instance: `aws ec2 reboot-instances --instance-ids <id>`
4. Wait 2-3 minutes for SSM agent reconnection

---

## Learning Resources

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [Amazon RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [CloudWatch Agent Configuration](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [GnuPG Documentation](https://gnupg.org/documentation/)

---

## License

This project is licensed under the MIT License - see the [LICENSE](1a/LICENSE) file for details.

## Acknowledgments

- Built for educational purposes demonstrating AWS best practices
- Follows [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)
- Implements patterns from AWS [Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- CloudWatch integration based on [AWS CloudWatch Agent documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
