# Security Considerations — Lab 1c

Lab 1c implements a **private compute architecture** with enterprise-grade security patterns.
In airgap mode, EC2 instances operate with **no internet access** and bootstrap entirely
from **signed, hash-verified offline artifacts**.

For architecture and deployment procedures, see [README.md](README.md) and [RUNBOOK.md](RUNBOOK.md).

---

## Threat Model

| Threat | Airgap Mitigation | Public ALB Mitigation |
|--------|--------------------|-----------------------|
| Network intrusion via internet | No IGW, no NAT, no public subnets | ALB SG restricts to `allowed_http_cidrs` |
| Supply chain tampering | 3-key GPG signing + SHA256 manifest | None (internet bootstrap) |
| Credential theft via SSH | SSH eliminated entirely | SSH eliminated entirely |
| Lateral movement from EC2 | SG egress restricted to endpoints + RDS | Same |
| Package injection | Strict mode: extra files fail verification | None |
| Secrets exfiltration | VPC endpoint only, scoped IAM | Same |
| Brute force access | No open ports (SSM via IAM) | No SSH; ALB is HTTP only |

---

## SSH Elimination

SSH has been **removed entirely**. No key pairs, no port 22, no `.pem` files.

| Risk Category | Lab 1b (SSH) | Lab 1c (SSM) |
|---------------|--------------|--------------|
| Private keys in Terraform state | Yes | **N/A** |
| Key files on disk | After extraction | **N/A** |
| Port 22 exposure | Conditional | **Removed** |
| Key rotation complexity | Manual | **N/A (IAM handles access)** |
| Brute force attack surface | Port 22 | **None** |

---

## Session Manager Security Model

### Authentication & Authorization

- IAM credentials (supports MFA enforcement)
- No SSH keys, passwords, or certificates
- IAM policy scopes: `ssm:StartSession` on instance resource
- Full CloudTrail audit logging for every session

### Session Data Flow

```
Operator -> AWS CLI -> SSM Service (IAM validation)
    -> VPC Endpoint (ssmmessages) -> EC2 SSM Agent
    -> Encrypted WebSocket session (TLS)
```

---

## Supply-Chain Hardening (Airgap Mode)

### 3-Key GPG Signing Model

Trust is rooted in an **operator-generated signing key** — the operator controls key
generation, signing, and fingerprint pinning, establishing an unbroken chain of custody
from build through deployment. Three distinct signing roles partition that trust so
compromise of one role does not automatically compromise the others. All three may use
the same physical key (auto-resolved when only one secret key exists).

| Key | Signs | Verified By |
|-----|-------|-------------|
| Release Key | Manifest `.json.sig` | EC2 bootstrap (`gpg --verify`) |
| Repo Metadata Key | `repomd.xml.asc` | DNF (`repo_gpgcheck=1`) |
| RPM Packages Key | Individual `.rpm` files | DNF (`gpgcheck=1`) |

For production, use separate keys per role.

### Bootstrap Verification Chain

EC2 bootstrap in airgap mode performs these checks **in order, fail-closed**:

1. **Key fingerprint pinning** — 3 GPG public keys embedded in the EC2 template via
   `file()`. Fingerprints verified via `gpg --show-keys` BEFORE import, compared
   against Terraform-pinned values.

2. **Manifest signature verification** — Release manifest verified against its GPG
   signature (`.json.sig`) using the release signing key.

3. **Manifest fingerprint cross-check** — Python snippet reads
   `manifest.signing.{release,repo,rpm}_key_fingerprint` and compares against
   Terraform-pinned values. Any mismatch aborts.

4. **SHA256 artifact verification** — Python script verifies SHA256 of **every**
   artifact in the manifest. **Strict mode**: files on disk NOT in the manifest
   cause failure (injection detection).

5. **DNF repo configuration** — Offline RPM repo configured with `gpgcheck=1` and
   `repo_gpgcheck=1`, requiring both package and metadata signatures.

6. **repomd.xml.asc presence check** — Explicit check that detached signature exists
   before running `dnf makecache`.

7. **DNF makecache preflight** — `dnf clean all` + `dnf makecache` runs before any
   install. Bad signatures abort the entire bootstrap.

8. **Pip hash verification** — `pip install --require-hashes -r requirements.lock`
   verifies SHA256 of every wheel.

### Self-Contained Signing

All GPG and rpmsign operations use a **temporary GNUPGHOME**:
- Copies of `pubring.kbx`, `pubring.gpg`, `trustdb.gpg`
- Symlink to `private-keys-v1.d` (read-only access to private keys)
- `allow-loopback-pinentry` written only in temp dir

The real `~/.gnupg` is **never modified**. A post-build mtime + SHA256 assertion
verifies isolation. Everything cleaned up on exit.

### No Fallbacks

The airgap bootstrap is **fail-closed everywhere**:
- No internet fallback if S3 artifacts fail
- No unsigned package installation
- No hash bypass
- No partial installs
- `set -euo pipefail` throughout

---

## Network Security

### VPC Endpoint Security

| Benefit | Description |
|---------|-------------|
| No Internet Exposure | AWS API traffic stays within AWS network |
| Security Group Control | Endpoints have dedicated security groups |
| Private DNS | Traffic automatically routes to private endpoints |
| Reduced Blast Radius | Compromised instance cannot reach arbitrary internet destinations |
| Egress Control | No NAT Gateway means no general internet egress |

### Security Group Rules

**VPC Endpoint SG:**
- Inbound: HTTPS (443) from VPC CIDR

**EC2 SG:**
- Outbound HTTPS: Only to endpoint security group
- Outbound MySQL: Only to RDS security group
- Outbound S3: Only via S3 prefix list
- Inbound (airgap): None
- Inbound (public_alb): HTTP from ALB SG only

### Airgap Mode Security Chain

```
No Internet (no IGW, no NAT)
    |
+-------------------------------+
|  EC2 Security Group           |
|  - Ingress: NONE              |
|  - Egress: HTTPS to Endpoints |
|  - Egress: MySQL to RDS       |
|  - Egress: HTTPS to S3        |
+-------------------------------+
    |
+-------------------------------+
|  RDS Security Group           |
|  - Ingress: MySQL from EC2    |
+-------------------------------+
```

### Public ALB Mode Security Chain

```
Internet
    |
+-------------------------------+
|  ALB Security Group           |
|  - Ingress: HTTP/80 from      |
|    allowed CIDRs              |
|  - Egress: HTTP/80 to EC2 SG  |
+-------------------------------+
    |
+-------------------------------+
|  EC2 Security Group           |
|  - Ingress: HTTP/80 from      |
|    ALB SG only                |
|  - Egress: HTTPS to Endpoints |
|  - Egress: MySQL to RDS       |
|  - Egress: HTTPS to S3        |
+-------------------------------+
    |
+-------------------------------+
|  RDS Security Group           |
|  - Ingress: MySQL from EC2    |
+-------------------------------+
```

### Defense in Depth

| Component | Layer 1 | Layer 2 | Layer 3 |
|-----------|---------|---------|---------|
| EC2 | Private subnet | No public IP | SG (no inbound in airgap) |
| RDS | Private subnet | SG (EC2 only) | Not publicly accessible |
| Secrets | VPC endpoint | IAM policy | Secret-level policy |
| Artifacts | Signed manifest | SHA256 hashes | GPG package signatures |

---

## S3 Bucket Security

- **Versioning enabled** — Protects against accidental overwrites
- **Public access blocked** — All four public access settings blocked
- **Bucket policy** — Access restricted to:
  - VPC endpoint (EC2 reads via gateway endpoint)
  - Account principal (Terraform/operator management)
- **No public URLs** — All access through VPC endpoint or authenticated AWS CLI

---

## IAM Least Privilege

### EC2 Role Permissions

| Policy | Permissions | Scope |
|--------|-------------|-------|
| `AmazonSSMManagedInstanceCore` | SSM agent operations | AWS-managed |
| `CloudWatchAgentServerPolicy` | CloudWatch agent operations | AWS-managed |
| `secrets-access` | `secretsmanager:GetSecretValue` | Specific secret ARN only |
| `ssm-params-access` | `ssm:GetParameter(s)` | Specific parameter paths only |
| `cloudwatch-logs-access` | `logs:CreateLogStream, PutLogEvents` | Specific log group only |
| `cloudwatch-metrics-access` | `cloudwatch:PutMetricData` | Specific namespace only |
| `s3-deps-read` | `s3:GetObject, s3:ListBucket` | Deps bucket only |

### Explicitly NOT Allowed

- `*:*` (full access)
- `ssm:*` (broad SSM access)
- `secretsmanager:*` (broad secrets access)
- `ec2:*` (no EC2 management from instance)
- `iam:*` (no IAM management from instance)

---

## Secrets Management

| Store | Contains | Access Path |
|-------|----------|-------------|
| Secrets Manager | DB credentials (user/pass) | VPC endpoint -> IAM-scoped policy |
| Parameter Store | DB endpoint, port, name (non-sensitive) | VPC endpoint -> IAM-scoped policy |

- Application logs connection info, never credentials
- EC2 can only read its own secret (scoped IAM)
- Secrets never traverse internet (VPC endpoint)
- CloudTrail logs all access

---

## Airgap Boundary

See [README.md — Airgap Boundary: Runtime vs Build Host](README.md#airgap-boundary-runtime-vs-build-host).

---

## Risk Assessment

### Airgap Mode Security Posture

| Security Control | Level | Notes |
|-----------------|-------|-------|
| SSH key exposure | N/A | SSH eliminated |
| Internet exposure (EC2) | Strong | No IGW, no NAT, no public subnet |
| Supply chain integrity | Strong | 3-key signing + SHA256 hashes |
| Bootstrap determinism | Strong | Offline, version-pinned |
| Instance access audit | Strong | CloudTrail logging |
| Network boundary | Strong | VPC endpoints only |
| Package authenticity | Strong | GPG signatures verified by DNF |
| Manifest integrity | Strong | GPG signature + SHA256 |

### Comparison with Public ALB Mode

| Control | Airgap | Public ALB |
|---------|--------|------------|
| Internet Gateway | **None** | Present |
| Bootstrap source | **Signed S3 artifacts** | Internet |
| ALB attack surface | **None** | Exposed |
| Package verification | **GPG + SHA256** | None (pip/dnf from internet) |

---

## Incident Response

For operational incident procedures (SSM offline, endpoint failure, app unreachable), see
[RUNBOOK.md — Incident Response](RUNBOOK.md#incident-response).

### If Instance is Compromised

1. **Isolate:** (airgap mode has no ALB to deregister from)
2. **Preserve evidence:** Create AMI for forensics
3. **Rotate credentials:** `aws secretsmanager rotate-secret --secret-id lab/rds/mysql`
4. **Review audit logs:** CloudTrail, CloudWatch Logs
5. **Rebuild:** `terraform taint 'aws_instance.web[0]' && terraform apply`

### If Secrets are Exposed

1. **Rotate immediately:** `aws secretsmanager rotate-secret --secret-id lab/rds/mysql`
2. **Review access logs:** `aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=lab/rds/mysql`
3. **Check for unauthorized access:** RDS logs, application logs

---

## Security Checklist

For verification commands, see [RUNBOOK.md — Verification](RUNBOOK.md#verification).

### Before Deployment

- [ ] Using encrypted remote backend (S3 + KMS)?
- [ ] Using a non-production AWS account?
- [ ] GPG keys generated with adequate key size? (airgap)
- [ ] Fingerprints verified independently? (airgap)

### After Deployment

- [ ] Verified EC2 has no public IP?
- [ ] Verified no SSH resources exist (no port 22 rules)?
- [ ] Verified Session Manager works?
- [ ] Verified VPC endpoints are available?
- [ ] Verified no Internet Gateway? (airgap)
- [ ] Verified no NAT Gateway? (airgap)
- [ ] Tested application works?
- [ ] Reviewed CloudWatch logs for sensitive data?

### For Production Use

- [ ] Enable MFA for Session Manager access
- [ ] Configure session logging (CloudWatch/S3)
- [ ] Enable VPC endpoint policies
- [ ] Enable Secrets Manager automatic rotation
- [ ] Implement VPC Flow Logs
- [ ] Enable GuardDuty for threat detection
- [ ] Separate GPG keys per signing role (not degenerate)
- [ ] Store GPG private keys in HSM or Secrets Manager
