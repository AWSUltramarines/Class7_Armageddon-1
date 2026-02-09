# Operational Runbook — Lab 1c

This runbook documents operational workflows for Lab 1c's private compute architecture.
For architecture and pipeline design, see [README.md](README.md).
For security controls and threat model, see [SECURITY.md](SECURITY.md).

Lab 1c supports two exposure modes:
- **airgap** (default): Offline bootstrap, SSM port-forward access, no internet
- **public_alb**: Legacy comparison mode with ALB internet-facing access

---

## Day-0 Phase-1 — Supply Chain Preparation

### `tools/fetch-al2023-rpms.sh`

```bash
./tools/fetch-al2023-rpms.sh [output_dir]
```

**Expected output:**
```
[FETCH] Downloading python3-pip and dependencies...
[FETCH] Running createrepo_c...
[FETCH] Done. Output in /tmp/al2023-rpms/
[FETCH] Copy to your dev machine:
[FETCH]   scp -r ec2-user@<this-instance>:/tmp/al2023-rpms/* deps/rpm/al2023-minrepo/
```

**Produces:**
```
deps/rpm/al2023-minrepo/
├── *.rpm                    # AL2023 packages (python3-pip + dependencies)
└── repodata/                # Repository metadata (createrepo_c output)
```

**Operational notes:**
- Runs on a **temporary AL2023 EC2 instance** (CDN restricts RPM access to EC2 only)
- Requires **outbound internet access** (public ENI or NAT gateway)
- Instance is **terminated immediately** after RPMs are staged
- Runtime EC2 instances never require internet access

**When to run:**
- Initial setup (one-time)
- Security patch updates to base packages
- Adding new system dependencies

---

## Day-0 Phase-2 — Build Signed Release

### `tools/0-build_release.sh`

```bash
# Non-interactive (CI/CD) — recommended
GPG_PASSPHRASE_FILE=/path/to/passphrase \
./tools/0-build_release.sh <ISO-8601-timestamp>

# Interactive (with timeout safety)
./tools/0-build_release.sh <ISO-8601-timestamp>
```

**Release ID format:** ISO 8601 timestamp (e.g., `2026-02-09T0939Z`)
- Ensures chronological ordering
- Filesystem-safe characters only
- Immutable reference for promotion/rollback

> **Multiple GPG keys?** If your keyring has more than one secret key, the script
> will exit with `Multiple GPG keys found; set ... explicitly`. See
> [Resolving: Multiple GPG Keys Found](#resolving-multiple-gpg-keys-found) for how
> to set `RELEASE_GPG_KEY_ID`, `REPO_GPG_KEY_ID`, and `RPM_GPG_KEY_ID`.

**Environment variables:**

| Variable | Required | Description |
|----------|----------|-------------|
| `GPG_PASSPHRASE_FILE` | No | Path to file containing GPG passphrase (preferred) |
| `GPG_PASSPHRASE` | No | Passphrase string (fallback; avoid in CI — visible in process list) |
| `SIGN_TIMEOUT` | No | Timeout per signing operation in seconds (default: 30) |
| `RELEASE_GPG_KEY_ID` | If >1 key | GPG key for manifest signing |
| `REPO_GPG_KEY_ID` | If >1 key | GPG key for repomd.xml signing |
| `RPM_GPG_KEY_ID` | If >1 key | GPG key for RPM package signing |

**Expected output (trimmed):**
```
[BUILD] Checking required tools...
[BUILD] Required tools verified (createrepo, python3, pip, gpg, rpmsign, timeout, sha256sum)
[BUILD] Resolving GPG signing keys...
[BUILD] Release manifest key: 1AA87D650A49F630 (fpr: 563287DB9F783749FCF110411AA87D650A49F630)
[BUILD] Repo metadata key:    1AA87D650A49F630 (fpr: 563287DB9F783749FCF110411AA87D650A49F630)
[BUILD] RPM packages key:     1AA87D650A49F630 (fpr: 563287DB9F783749FCF110411AA87D650A49F630)
...
[BUILD] Running artifact self-check...
[BUILD] Artifact self-check PASSED

[BUILD] Signing keys (3-key model):
[BUILD]   Release manifest:  563287DB9F783749FCF110411AA87D650A49F630
[BUILD]   Repo metadata:     563287DB9F783749FCF110411AA87D650A49F630
[BUILD]   RPM packages:      563287DB9F783749FCF110411AA87D650A49F630

[BUILD] Set in Terraform:
[BUILD]   release_gpg_key_fingerprint = "563287DB9F783749FCF110411AA87D650A49F630"
[BUILD]   repo_gpg_key_fingerprint    = "563287DB9F783749FCF110411AA87D650A49F630"
[BUILD]   rpm_gpg_key_fingerprint     = "563287DB9F783749FCF110411AA87D650A49F630"

[BUILD] Next (day-1_phase-1): Add fingerprints to terraform.tfvars, then: terraform apply
[BUILD] Then (day-1_phase-2): ./tools/1-upload_release.sh <release_id> $BUCKET_NAME
```

**Produces:**
```
out/
├── repo/
│   ├── rpm/releases/<release_id>/x86_64/
│   │   ├── *.rpm                        # Signed RPM packages
│   │   └── repodata/
│   │       ├── repomd.xml
│   │       └── repomd.xml.asc           # Signed repo metadata
│   ├── pip/releases/<release_id>/py39/
│   │   ├── wheels/*.whl                 # Python wheels
│   │   ├── requirements.lock
│   │   └── requirements.lock.sha256
│   └── cw-agent/releases/<release_id>/
│       └── amazon-cloudwatch-agent.rpm
├── manifests/
│   ├── <release_id>.json                # Release manifest
│   ├── <release_id>.json.sig            # GPG signature
│   └── <release_id>.json.sha256         # SHA256 checksum
└── keys/
    ├── release-signing-public.gpg       # Manifest signing key
    ├── repo-metadata-signing-public.gpg # repomd.xml signing key
    └── rpm-packages-signing-public.gpg  # RPM signing key
```

**Prerequisites:**
- GPG signing key in keyring (`gpg --list-secret-keys`)
- Tools: `createrepo_c`, `python3`, `pip`, `gpg`, `rpmsign`, `sha256sum`
- Pre-populated `deps/rpm/al2023-minrepo/` (see Day-0 Phase-1)

**Exit code semantics:** Exit 0 = success (`Artifact self-check PASSED`).
Non-zero = real build failure. Cleanup warnings never change the exit code.

---

## Day-1 Phase-1 — Infrastructure Prep (No EC2)

### Terraform Apply

```bash
terraform init   # First time only
```

**Using terraform.tfvars (recommended):**
```bash
cat > terraform.tfvars << 'EOF'
aws_region                  = "us-east-1"
project_name                = "ec2-rds-notes-lab"
environment                 = "lab"
exposure_mode               = "airgap"
enable_ec2                  = false
channel                     = "dev"
release_id                  = "2026-02-09T0939Z"
release_gpg_key_fingerprint = "563287DB9F783749FCF110411AA87D650A49F630"
repo_gpg_key_fingerprint    = "563287DB9F783749FCF110411AA87D650A49F630"
rpm_gpg_key_fingerprint     = "563287DB9F783749FCF110411AA87D650A49F630"
EOF

terraform apply
```

**GPG fingerprints must be persisted to `terraform.tfvars`:**
- Fingerprints are printed by `0-build_release.sh` at end of build
- Required for both `apply` and `destroy` operations
- If using same key for all 3 roles, all 3 values are identical
- For complete variable descriptions and defaults, see [README.md — Terraform Variables](README.md#terraform-variables)

**Expected output (trimmed):**
```
Plan: 37 to add, 0 to change, 0 to destroy.

Apply complete! Resources: 37 added, 0 changed, 0 destroyed.

Outputs:

deps_bucket_name = "ec2-rds-notes-lab-deps-89e5e08f"
```

**Produces:**
- VPC with private subnets (no public subnets, no IGW in airgap)
- VPC endpoints (S3 Gateway, SSM, SSMMessages, EC2Messages, Secrets Manager, Logs, KMS)
- S3 bucket for releases with channel pointers seeded
- RDS MySQL instance
- IAM roles and policies
- Secrets Manager secret + Parameter Store entries
- CloudWatch log group and alarm

---

## Day-1 Phase-2 — Upload Release

### `tools/1-upload_release.sh`

```bash
BUCKET=$(terraform output -raw deps_bucket_name)
./tools/1-upload_release.sh <release_id> $BUCKET
```

**Example:**
```bash
./tools/1-upload_release.sh 2026-02-09T0939Z ec2-rds-notes-lab-deps-89e5e08f
```

**Expected output (trimmed):**
```
[UPLOAD] Validating release: 2026-02-09T0939Z
[UPLOAD] Checking required GPG public keys...
[UPLOAD]   ✓ keys/release-signing-public.gpg
[UPLOAD]   ✓ keys/repo-metadata-signing-public.gpg
[UPLOAD]   ✓ keys/rpm-packages-signing-public.gpg
[UPLOAD] Uploading to bucket: ec2-rds-notes-lab-deps-89e5e08f
[UPLOAD] Syncing RPM repository...
[UPLOAD] Syncing pip repository...
[UPLOAD] Syncing CloudWatch agent...
[UPLOAD] Syncing manifest files...
[UPLOAD] Syncing GPG public keys...
[UPLOAD] Verifying uploads...
[UPLOAD] Done. Release 2026-02-09T0939Z uploaded to ec2-rds-notes-lab-deps-89e5e08f
```

**Produces (in S3):** Release artifacts, manifests, and public keys synced to the bucket.
See [README.md — S3 Repository Layout](README.md#s3-repository-layout) for complete structure.

---

## Day-1 Phase-3 — Promote Channel

### `tools/2-promote_channel.sh`

```bash
./tools/2-promote_channel.sh <channel> <release_id> <bucket>
```

**Example:**
```bash
./tools/2-promote_channel.sh dev 2026-02-09T0939Z ec2-rds-notes-lab-deps-89e5e08f
```

**Expected output:**
```
[PROMOTE] Promoting release 2026-02-09T0939Z to channel: dev
[PROMOTE] Verifying release exists in S3...
[PROMOTE]   ✓ Manifest found
[PROMOTE]   ✓ RPM release found
[PROMOTE]   ✓ Pip release found
[PROMOTE]   ✓ CW agent release found
[PROMOTE] Updating channel pointers...
[PROMOTE]   rpm/channels/dev -> releases/2026-02-09T0939Z/x86_64
[PROMOTE]   pip/channels/dev -> releases/2026-02-09T0939Z/py39
[PROMOTE]   cw-agent/channels/dev -> releases/2026-02-09T0939Z
[PROMOTE] Done. Channel 'dev' now points to 2026-02-09T0939Z
```

**Valid channels:** `dev`, `stage`, `prod`

---

## Day-1 Phase-4 — Deploy EC2

### Terraform Apply (enable_ec2=true)

Edit `terraform.tfvars` manually — set `enable_ec2 = true`:

```bash
terraform apply
```

**Expected output (trimmed):**
```
Plan: 1 to add, 3 to change, 0 to destroy.

Apply complete! Resources: 1 added, 3 changed, 0 destroyed.

Outputs:

ec2_instance_id = "i-07c281d7ac421fd63"
```

**Produces:**
- EC2 instance in private subnet
- Instance bootstraps automatically via user_data (offline, signed artifacts)

**Verify deployment:**
```bash
INSTANCE_ID=$(terraform output -raw ec2_instance_id)

# Check instance state
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].State.Name' --output text

# Check SSM agent
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --query "InstanceInformationList[0].PingStatus"

# Connect via SSM
aws ssm start-session --target "$INSTANCE_ID"

# Port forward for app access
aws ssm start-session --target "$INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["80"],"localPortNumber":["8080"]}'

# Test (in another terminal)
curl -s http://localhost:8080/health
curl -s http://localhost:8080/init
curl -s "http://localhost:8080/add?note=test"
curl -s http://localhost:8080/list
```

---

## Public ALB Mode (Legacy Comparison)

Public ALB mode does not use the release pipeline. EC2 bootstraps from the internet.

```bash
# Edit terraform.tfvars:
#   exposure_mode = "public_alb"
#   enable_ec2    = true

terraform init && terraform apply

ALB_DNS=$(terraform output -raw alb_dns_name)
curl -s "http://$ALB_DNS/health"
```

---

## Day-2+ — Promote to Higher Environments

### Promote existing release to stage/prod

```bash
BUCKET=$(terraform output -raw deps_bucket_name)

./tools/2-promote_channel.sh stage 2026-02-09T0939Z $BUCKET
./tools/2-promote_channel.sh prod 2026-02-09T0939Z $BUCKET
```

**Redeploy EC2 to pick up new channel:**
```bash
# Edit terraform.tfvars: channel = "prod" (manual edit)
terraform taint 'aws_instance.web[0]'
terraform apply
```

---

## Day-2+ — Rollback Operations

### `tools/3-rollback_channel.sh`

```bash
./tools/3-rollback_channel.sh <channel> <previous_release_id> <bucket>
```

**Example:**
```bash
./tools/3-rollback_channel.sh prod 2026-02-09T0822Z ec2-rds-notes-lab-deps-89e5e08f
```

**Expected output:**
```
[ROLLBACK] Rolling back channel 'prod' to release: 2026-02-09T0822Z
[ROLLBACK] Verifying release exists in S3...
[ROLLBACK]   ✓ Manifest found
[ROLLBACK]   ✓ RPM release found
[ROLLBACK]   ✓ Pip release found
[ROLLBACK]   ✓ CW agent release found
[ROLLBACK] Updating channel pointers...
[ROLLBACK]   rpm/channels/prod -> releases/2026-02-09T0822Z/x86_64
[ROLLBACK]   pip/channels/prod -> releases/2026-02-09T0822Z/py39
[ROLLBACK]   cw-agent/channels/prod -> releases/2026-02-09T0822Z
[ROLLBACK] Done. Channel 'prod' rolled back to 2026-02-09T0822Z
```

**Rollback is a pointer move:**
- Previous releases remain immutable in S3
- Channel pointer is updated to reference the previous release
- No artifacts are modified or deleted

**Redeploy EC2 after rollback:**
```bash
# Edit terraform.tfvars: release_id = "<previous_id>" (manual edit)
terraform taint 'aws_instance.web[0]'
terraform apply
```

---

## Day-2+ — New Release Deployment

### Full workflow for deploying a new release

```bash
# 1. Build new release
GPG_PASSPHRASE_FILE=/path/to/passphrase \
./tools/0-build_release.sh 2026-02-10T0900Z

# 2. Upload to S3
BUCKET=$(terraform output -raw deps_bucket_name)
./tools/1-upload_release.sh 2026-02-10T0900Z $BUCKET

# 3. Promote to dev (test first)
./tools/2-promote_channel.sh dev 2026-02-10T0900Z $BUCKET

# 4. Edit terraform.tfvars: release_id = "2026-02-10T0900Z" (manual edit)
terraform taint 'aws_instance.web[0]'
terraform apply

# 5. Verify, then promote to prod
./tools/2-promote_channel.sh prod 2026-02-10T0900Z $BUCKET

# 6. Redeploy prod
terraform taint 'aws_instance.web[0]'
terraform apply
```

---

## Cleanup — Destroy Infrastructure

### `terraform destroy`

```bash
terraform destroy
```

GPG fingerprint variables default to empty strings, so `destroy` works without them.
Fingerprints are only required when deploying EC2 (`enable_ec2=true`).

> **Note:** A suspended Terraform process (Ctrl-Z) can leave a stale state lock.
> If you see "Error acquiring the state lock", check for zombie processes:
> `pgrep -a terraform` then `kill -9 <pid>`

### Scope of Destruction

`terraform destroy` removes all managed resources:

| Resource Type | What Is Deleted |
|---------------|-----------------|
| EC2 | Application instance and security group |
| S3 | Dependencies bucket **including all release artifacts** |
| VPC | Subnets, route tables, internet gateway (if public_alb) |
| VPC Endpoints | S3, SSM, SSMMessages, EC2Messages, Secrets Manager, Logs, KMS |
| RDS | MySQL database and all data |
| IAM | EC2 instance role, instance profile, policy attachments |
| CloudWatch | Log group and all historical logs |
| Secrets Manager | DB credentials secret |

**Data loss:**
- All uploaded releases in S3 are permanently deleted
- RDS database and all data are permanently deleted
- CloudWatch logs are permanently deleted
- No backup is created automatically

**Before destroying production:**
1. Verify no active workloads depend on this infrastructure
2. Export CloudWatch logs if needed (`aws logs create-export-task`)
3. Back up S3 artifacts if needed (`aws s3 sync s3://<bucket> ./backup/`)
4. Back up RDS if needed (create final snapshot)

---

## Verification

### Common Verification (Both Modes)

```bash
INSTANCE_ID=$(terraform output -raw ec2_instance_id)
VPC_ID=$(terraform output -raw vpc_id)
LOG_GROUP=$(terraform output -raw log_group_name)

# EC2 is private (no public IP)
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query "Reservations[].Instances[].PublicIpAddress"
# Expected: null

# SSM connectivity
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --query "InstanceInformationList[].PingStatus"
# Expected: "Online"

# VPC endpoints
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "VpcEndpoints[].{Service:ServiceName,State:State}" \
  --output table

# CloudWatch logs
aws logs tail "$LOG_GROUP" --since 10m

# Alarm state
aws cloudwatch describe-alarms \
  --alarm-names $(terraform output -raw alarm_name) \
  --query "MetricAlarms[0].StateValue"
```

### Airgap Mode Verification

```bash
# No Internet Gateway
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways"
# Expected: []

# No NAT Gateway
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query "NatGateways[].NatGatewayId"
# Expected: []

# No SSH (port 22) rules on EC2 security group
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$(terraform output -raw ec2_security_group_id)" \
  --query "SecurityGroupRules[?FromPort==\`22\`]"
# Expected: empty

# App via SSM port forward
aws ssm start-session --target "$INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["80"],"localPortNumber":["8080"]}'

# In another terminal:
curl -s http://localhost:8080/health | jq .
curl -s http://localhost:8080/init | jq .
curl -s http://localhost:8080/list | jq .
```

### Public ALB Mode Verification

```bash
ALB_DNS=$(terraform output -raw alb_dns_name)

curl -s "http://$ALB_DNS/health" | jq .
curl -s "http://$ALB_DNS/init" | jq .
curl -s "http://$ALB_DNS/list" | jq .

# Target group health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_target_group_arn) \
  --query "TargetHealthDescriptions[].{Target:Target.Id,Health:TargetHealth.State}"
```

### Instance Access (SSM Session)

```bash
# Start shell session
aws ssm start-session --target $(terraform output -raw ec2_instance_id)

# Inside session:
systemctl status notes-app
journalctl -u notes-app -n 50

# Verify AWS API access via endpoints
aws ssm get-parameter --name /lab/db/endpoint
aws secretsmanager get-secret-value --secret-id lab/rds/mysql --query SecretString --output text | jq .
```

### Monitoring

```bash
LOG_GROUP=$(terraform output -raw log_group_name)

# Tail logs
aws logs tail "$LOG_GROUP" --since 10m

# Filter errors
aws logs filter-log-events --log-group-name "$LOG_GROUP" --filter-pattern "ERROR"

# Check alarm
aws cloudwatch describe-alarms \
  --alarm-names $(terraform output -raw alarm_name) \
  --query "MetricAlarms[0].StateValue"

# SNS notifications
terraform apply -var="alert_email=your-email@example.com"
```

---

## Troubleshooting

### Check Bootstrap Logs

```bash
# Tail CloudWatch logs
aws logs tail $(terraform output -raw log_group_name) --since 5m

# Or via SSM
aws ssm start-session --target $(terraform output -raw ec2_instance_id)

# On instance
cat /var/log/notes-app.log
journalctl -u notes-app
systemctl status notes-app
```

### Verify Release on Instance

```bash
INSTANCE_ID=$(terraform output -raw ec2_instance_id)

# Check deployed release
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["ls -la /opt/offline/manifests/"]' \
  --output text

# Check app health
aws ssm send-command \
  --instance-ids $INSTANCE_ID \
  --document-name AWS-RunShellScript \
  --parameters 'commands=["curl -s http://localhost/health"]' \
  --output text
```

### Common Issues

| Error | Cause | Resolution |
|-------|-------|------------|
| `Failed to read RPM channel pointer` | Channel not promoted | Run `2-promote_channel.sh` |
| `Manifest checksum mismatch` | Corrupted upload | Rebuild and re-upload release |
| `Bad passphrase` | Wrong GPG passphrase | Check `GPG_PASSPHRASE_FILE` content |
| `signal Terminated` | Signing timeout | Increase `SIGN_TIMEOUT` or fix passphrase |
| `fingerprint is required when enable_ec2=true` | Empty fingerprint | Add fingerprints to `terraform.tfvars` |
| `Error acquiring state lock` | Zombie terraform process | `pgrep -a terraform` then `kill -9 <pid>` |
| `Key fingerprint mismatch` | Wrong key in tfvars | Update fingerprints from build output |
| `ISOLATION BREACH` | Build env issue | Report bug; rebuild |
| `Multiple GPG keys found` | >1 secret key in keyring | Set key ID explicitly; see section below |
| `DB_CONNECTION_FAILURE` | RDS unreachable | Check RDS status, SG, Secrets Manager |
| `target is not connected` (SSM) | Agent offline | Check VPC endpoints, reboot EC2 |
| `502/503` from ALB (public_alb) | EC2 not healthy | Check app status, target group health |
| S3 pointer AccessDenied on apply | Bucket policy propagation delay | Fixed by `depends_on`; re-run `terraform apply` |

### Build Returns Non-Zero After Fix

`0-build_release.sh` captures exit code before cleanup. If exit code is still non-zero:
- The build itself failed — scroll up to find the first error
- Check: `gpg --list-secret-keys`, `createrepo_c --version`, `rpmsign --version`
- Check passphrase: verify `GPG_PASSPHRASE_FILE` or `GPG_PASSPHRASE` is set
- A successful build always prints `Artifact self-check PASSED` and exits 0

---

## Resolving: Multiple GPG Keys Found

When the keyring contains more than one secret key, `0-build_release.sh` refuses to
guess which key to use and exits with (see [SECURITY.md — 3-Key GPG Signing Model](SECURITY.md#3-key-gpg-signing-model) for role definitions):

```
[ERROR] Multiple GPG keys found; set RELEASE_GPG_KEY_ID explicitly.
```

The same error applies to `REPO_GPG_KEY_ID` and `RPM_GPG_KEY_ID`. Each variable
controls a different signing role:

| Variable | Signs |
|----------|-------|
| `RELEASE_GPG_KEY_ID` | Release manifest (`.json.sig`) |
| `REPO_GPG_KEY_ID` | Repository metadata (`repomd.xml.asc`) |
| `RPM_GPG_KEY_ID` | Individual RPM packages (`rpmsign`) |

### Find the long key ID

List secret keys and note the 16-character long key ID on the `sec` line:

```bash
gpg --list-secret-keys --keyid-format long
```

Example output:

```
sec   ed25519/1AA87D650A49F630 2025-09-29 [SC]
      563287DB9F783749FCF110411AA87D650A49F630
uid                 [ultimate] wally
```

The long key ID is `1AA87D650A49F630` (after the `/`). Use this value, not the
40-character fingerprint.

### Set inline (one-off)

```bash
RELEASE_GPG_KEY_ID=1AA87D650A49F630 \
REPO_GPG_KEY_ID=1AA87D650A49F630 \
RPM_GPG_KEY_ID=1AA87D650A49F630 \
GPG_PASSPHRASE_FILE=/path/to/passphrase \
./tools/0-build_release.sh 2026-02-10T0900Z
```

### Set via export (once per shell session)

```bash
export RELEASE_GPG_KEY_ID=1AA87D650A49F630
export REPO_GPG_KEY_ID=1AA87D650A49F630
export RPM_GPG_KEY_ID=1AA87D650A49F630

./tools/0-build_release.sh 2026-02-10T0900Z
```

If all three roles use the same key, all three variables take the same value.
If roles use distinct keys, set each to the appropriate long key ID.

---

## Incident Response

### Incident: Application Unreachable

**Severity:** P2

**Response:**

1. Check EC2 status: `aws ec2 describe-instance-status --instance-ids "$INSTANCE_ID"`
2. Access via SSM: `aws ssm start-session --target "$INSTANCE_ID"`
3. Check app: `systemctl status notes-app`
4. Restart if needed: `sudo systemctl restart notes-app`
5. If unrecoverable: `terraform taint 'aws_instance.web[0]' && terraform apply`

### Incident: SSM Agent Offline

**Severity:** P2

**Response:**

1. Verify EC2 running: `aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[].Instances[].State.Name"`
2. Check VPC endpoints: `aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID"`
3. Reboot EC2: `aws ec2 reboot-instances --instance-ids "$INSTANCE_ID"`
4. Wait 2-3 minutes for agent reconnection

### Incident: VPC Endpoint Failure

**Severity:** P1

**Response:**

1. Identify failed endpoints:
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters "Name=vpc-id,Values=$VPC_ID" \
     --query "VpcEndpoints[?State!='available']"
   ```
2. Recreate: `terraform apply`
3. Check AWS service health for the region

---

## Chaos Engineering

### Chaos Test 1: Simulate RDS Failure

**Objective:** Verify alarm triggers on DB connection errors

```bash
# Temporarily remove RDS security group rule
RDS_SG=$(terraform output -raw rds_security_group_id)
RULE_ID=$(aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$RDS_SG" \
  --query "SecurityGroupRules[?FromPort==\`3306\`].SecurityGroupRuleId" \
  --output text)

aws ec2 revoke-security-group-ingress \
  --group-id "$RDS_SG" \
  --security-group-rule-ids "$RULE_ID"

# Generate errors (airgap mode: via port-forward at localhost:8080)
for i in {1..5}; do curl -s http://localhost:8080/list; sleep 5; done

# Verify alarm triggers
aws cloudwatch describe-alarms --alarm-names $(terraform output -raw alarm_name)

# Restore
terraform apply
```

### Chaos Test 2: Simulate SSM Endpoint Failure

**WARNING:** This will prevent Session Manager access.

```bash
ENDPOINT_SG=$(terraform output -raw vpc_endpoints_security_group_id)

# Block HTTPS to endpoints
aws ec2 revoke-security-group-ingress \
  --group-id "$ENDPOINT_SG" \
  --protocol tcp --port 443 --cidr 10.190.0.0/16

# Observe: SSM sessions fail, logs stop, app may still serve (cached secrets)

# Restore
terraform apply
```

---

## Failure Mode Reference

| Failure Mode | Symptoms | Cause | Recovery |
|--------------|----------|-------|----------|
| VPC Endpoint Unavailable | AWS API timeouts; logs stop; SSM offline | Endpoint deleted, SG misconfigured | `terraform apply` |
| SSM Agent Not Registered | start-session fails | Endpoint issues, IAM missing | Check endpoints; restart agent |
| ALB Target Unhealthy (public_alb) | 502/503 errors | EC2 not responding on port 80 | Check EC2 SG; verify app running |
| S3 Gateway Route Missing | Package installs fail | Gateway not associated with private RT | `terraform apply` |
| Endpoint SG Blocks HTTPS | All AWS API calls fail | SG ingress rule missing | `terraform apply` |
| Airgap Bootstrap Failure | EC2 offline, no SSM | Bad manifest, missing artifacts | Check console output; rebuild release |
| GPG Fingerprint Mismatch | Bootstrap aborts | Wrong fingerprint in tfvars | Update fingerprints from build output |
| Channel Not Promoted | Bootstrap aborts | Channel pointer missing | Run `2-promote_channel.sh` |
| Build Exit Non-Zero | Exit 1 despite artifacts | Real build failure (not cleanup) | Check for `Artifact self-check PASSED` |
| S3 Pointer AccessDenied | Apply fails reading pointer | Bucket policy propagation delay | Fixed by `depends_on`; re-run apply |

---

## Quick Reference

| Phase | Script/Command | Purpose |
|-------|----------------|---------|
| day-0_phase-1 | `tools/fetch-al2023-rpms.sh` | Fetch AL2023 RPMs (on EC2) |
| day-0_phase-2 | `tools/0-build_release.sh` | Build signed release |
| day-1_phase-1 | `terraform apply` (enable_ec2=false) | Deploy infrastructure |
| day-1_phase-2 | `tools/1-upload_release.sh` | Upload release to S3 |
| day-1_phase-3 | `tools/2-promote_channel.sh` | Promote channel |
| day-1_phase-4 | `terraform apply` (enable_ec2=true) | Deploy EC2 |
| day-2+ | `tools/2-promote_channel.sh` | Promote to higher env |
| day-2+ | `tools/3-rollback_channel.sh` | Roll back release |
| day-2+ | `terraform destroy` | Teardown infrastructure (irreversible) |
