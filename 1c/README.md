# Lab 1c — Private Compute with Offline Release Pipeline

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS_Provider-~%3E5.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Amazon Linux](https://img.shields.io/badge/Amazon_Linux-2023-FF9900?logo=amazon-aws)](https://aws.amazon.com/linux/amazon-linux-2023/)
[![SSM](https://img.shields.io/badge/AWS-Session_Manager-red?logo=amazon-aws)](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
[![GPG Signed](https://img.shields.io/badge/GPG-GNU_Privacy_Guard-blue?logo=gnuprivacyguard)](https://gnupg.org/)

Private EC2 + RDS environment with **all runtime dependencies sourced from S3** via an immutable release pipeline with channel-based promotion. Two exposure modes: airgap (default) and public ALB (legacy comparison).

For operational procedures, see [RUNBOOK.md](RUNBOOK.md).
For security controls, see [SECURITY.md](SECURITY.md).

---

## What's New in Lab 1c

### Architecture Changes from 1b

```diff
+ Dual Exposure Modes (airgap / public_alb)
+ Private-Only Compute
+   - No Internet Gateway (airgap)
+   - No Public Subnets (airgap)
+   - No NAT Gateway (either mode)
+   - No Public IP on EC2
+ SSH Eliminated Entirely
+   - No key pairs, no port 22, no .pem files
+   - SSM Session Manager replaces SSH
+ VPC Endpoints (7 total)
+   - S3 Gateway Endpoint (artifact delivery)
+   - Interface: ssm, ec2messages, ssmmessages
+   - Interface: logs, secretsmanager, kms
+ Immutable Release Pipeline
+   - fetch-al2023-rpms.sh (CDN-restricted RPMs)
+   - 0-build_release.sh (3-key GPG signing)
+   - 1-upload_release.sh (S3 sync + verification)
+   - 2-promote_channel.sh (channel pointer update)
+   - 3-rollback_channel.sh (instant rollback)
+ 3-Key GPG Signing Model
+   - Release key -> manifest .json.sig
+   - Repo key -> repomd.xml.asc
+   - RPM key -> individual .rpm files
+ Channel-Based Promotion (dev / stage / prod)
+ SHA256 Artifact Manifest (strict mode)
+ Fail-Closed Bootstrap (no fallbacks)
+ Self-Contained Signing (temp GNUPGHOME)
+ base64gzip User Data (fits 16KB limit)
+ Application Load Balancer (public_alb mode)
+ Conditional Terraform Resources (count-based)
- SSH Key Pairs (removed)
- Public EC2 IP (removed)
- Internet Gateway (removed in airgap)
- Direct Internet Bootstrap (removed in airgap)
```

### Features

- ✅ **Private Compute** — EC2 in private subnets, no public IP, no IGW (airgap)
- ✅ **SSH Eliminated** — No key pairs, no port 22, no `.pem` files. 
- ✅ **3-Key GPG Signing** — Operator-owned trust root with end-to-end chain of custody
- ✅ **Immutable Releases** — Timestamped snapshots, never modified after build
- ✅ **Channel Promotion** — `dev` / `stage` / `prod` pointer-based promotion and rollback
- ✅ **SHA256 Manifest** — Every artifact hash-verified, strict mode detects injected files
- ✅ **Fail-Closed Bootstrap** — No unsigned installs, no hash bypass, no internet fallback
- ✅ **Self-Contained Signing** — Temp GNUPGHOME, real `~/.gnupg` never modified
- ✅ **VPC Endpoints** — All AWS API traffic stays within the AWS network. 
- ✅ **SSM Session Manager** — IAM-authenticated access with CloudTrail audit. 
- ✅ **Dual Exposure Modes** — Airgap (default) and public ALB for legacy comparison
- ✅ **Scoped IAM** — Every permission resource-specific, no wildcards. 
- ✅ **Encrypted Storage** — EBS and RDS encryption enabled
- ✅ **IMDSv2 Required** — Enhanced instance metadata security

---

## Exposure Modes

| Property | Airgap (default) | Public ALB |
|----------|-------------------|------------|
| Internet Gateway | **None** | Present |
| Public Subnets | **None** | Present |
| ALB | **None** | Internet-facing |
| NAT Gateway | **None** | **None** |
| EC2 Public IP | No | No |
| EC2 Bootstrap | Signed offline artifacts | Internet downloads |
| Application Access | SSM port-forward only | ALB HTTP |
| Admin Access | SSM Session Manager | SSM Session Manager |
| SSH | **Removed** | **Removed** |
| VPC Endpoints | 7 endpoints | 7 endpoints |
| Release Pipeline | Required | Not needed |

---

## Architecture

### Airgap Mode (Default)

```
                                         VPC (10.190.0.0/16)
                            No IGW · No NAT · No Public Subnets · No ALB
                       ┌────────────────────────────────────────────────────────┐
                       │                                                        │
                       │          ┌───────────────┐       ┌────────────────┐    │
                       │          │  S3 Gateway   │       │ VPC Endpoints  │    │
                       │          │   Endpoint    │    ├─►│ logs, secrets  │    │
                       │          │  (deps bucket)│    │  │ kms            │    │
                       │          └───────────────┘    │  └───────┬────────┘    │
                       │                  ▲ signed     │          │ AWS         │
                       │                  │ artifacts  │          │ APIs        │
                       │                  │            │          ▼             │
  No Internet          │          ┌───────┴──────┐─────┴  ┌────────────┐        │
    Access             │          │     EC2      │──────► │    RDS     │        │
                       │          │  Flask App   │ 3306   │   MySQL    │        │
                       │          │  (private)   │        │  (private) │        │
                       │          │  .171.0/24   │        │  .172.0/24 │        │
                       │          └──────────────┘        └────────────┘        │
                       │                  ▲                                     │
                       │          ┌───────┴──────┐                              │
                       │          │ SSM Endpoints│                              │
                       │          │ ssm, msgs    │                              │
                       │          │ ec2messages  │                              │
                       │          └──────────────┘                              │
                       └──────────────────┼─────────────────────────────────────┘
                                          ▲
                                      Operator
                               (IAM auth, port-forward)
```

### Public ALB Mode (Legacy Comparison)

```
                                         VPC (10.190.0.0/16)
                       ┌──────────────────────────────────────────────────────────────┐
                       │                                                              │
                       │                  ┌───────────────┐     ┌────────────────┐    │
                       │                  │  S3 Gateway   │     │ VPC Endpoints  │    │
                       │                  │   Endpoint    │     │ ssm, logs      │    │
                       │                  └───────┬───────┘     │ secrets, kms   │    │
                       │                          │             └───────┬────────┘    │
                       │                          ▼                     ▼             │
                       │  ┌────────────────┐  ┌─────────────┐   ┌────────────┐        │
Internet ───HTTP─────► │  │┌─────┐   ALB   │─►│    EC2      │──►│    RDS     │        │
                       │  ││ IGW │ (public)│  │  Flask App  │   │   MySQL    │        │
                       │  │└─────┘  .0.0/24│  │  (private)  │   │  (private) │        │
                       │  │         .1.0/24│  │  .171.0/24  │   │  .172.0/24 │        │
                       │  └────────────────┘  └─────────────┘   └────────────┘        │
                       │                                                              │
                       └──────────────────────────────────────────────────────────────┘
```

### Traffic Flows

| Flow | Airgap Mode | Public ALB Mode |
|------|-------------|-----------------|
| **App Access** | Operator -> SSM port forward -> EC2 | Internet -> ALB -> EC2 |
| **Instance Access** | Operator -> SSM -> VPC Endpoint -> EC2 | Same |
| **AWS API Calls** | EC2 -> VPC Endpoint -> AWS Service | Same |
| **Database** | EC2 -> RDS (private) | Same |
| **Logs** | EC2 -> logs endpoint -> CloudWatch | Same |
| **Bootstrap** | EC2 -> S3 endpoint -> signed artifacts | EC2 -> Internet |

---

## S3 Repository Layout

```
s3://<bucket>/
├── repo/
│   ├── rpm/
│   │   ├── releases/<release_id>/x86_64/
│   │   │   ├── repodata/
│   │   │   └── *.rpm
│   │   └── channels/
│   │       ├── dev      (pointer -> releases/<id>/x86_64/)
│   │       ├── stage    (pointer -> releases/<id>/x86_64/)
│   │       └── prod     (pointer -> releases/<id>/x86_64/)
│   ├── pip/
│   │   ├── releases/<release_id>/py39/
│   │   │   ├── wheels/*.whl
│   │   │   ├── requirements.lock
│   │   │   └── requirements.lock.sha256
│   │   └── channels/
│   │       ├── dev, stage, prod
│   └── cw-agent/
│       ├── releases/<release_id>/
│       │   └── amazon-cloudwatch-agent.rpm
│       └── channels/
│           ├── dev, stage, prod
├── manifests/
│   ├── <release_id>.json
│   ├── <release_id>.json.sig
│   └── <release_id>.json.sha256
└── keys/
    ├── release-signing-public.gpg
    ├── repo-metadata-signing-public.gpg
    └── rpm-packages-signing-public.gpg
```

---

## Release Pipeline Overview

### Release ID Convention

Release identifiers use an **ISO 8601 timestamp format** (e.g., `2026-02-09T0939Z`) to ensure:

- **Chronological ordering** — Releases sort naturally by creation time
- **Immutability** — Each release is a unique, timestamped snapshot
- **Filesystem safety** — Only alphanumeric characters, dots, underscores, and hyphens

### Pipeline Tools

| Script | Phase | Purpose |
|--------|-------|---------|
| `tools/fetch-al2023-rpms.sh` | day-0_phase-1 | Fetch AL2023 RPMs from CDN (runs on EC2) |
| `tools/0-build_release.sh` | day-0_phase-2 | Build signed release artifacts |
| `tools/1-upload_release.sh` | day-1_phase-2 | Upload release to S3 |
| `tools/2-promote_channel.sh` | day-1_phase-3 | Point channel to release |
| `tools/3-rollback_channel.sh` | day-2+ | Roll back channel to previous release |

For detailed usage of each tool, see [RUNBOOK.md](RUNBOOK.md).

### Channel Model

Releases are immutable snapshots. Channels (`dev`, `stage`, `prod`) are mutable pointers
to releases. Promotion and rollback operations update pointers without modifying artifacts.

```
dev   ──────► 2026-02-09T0939Z
stage ──────► 2026-02-09T0822Z
prod  ──────► 2026-02-08T1400Z
```

Rollback = pointer move to a previous release. No artifacts are modified or deleted.

### Control Plane vs Data Plane

Terraform owns the **control plane** (VPC, IAM, endpoints, S3 bucket, EC2 lifecycle).
Scripts own the **data plane** (release artifacts, channel pointer content).

```
        Mutable (small)                          Immutable (big)
┌─────────────────────────┐             ┌─────────────────────────────────┐
│ repo/*/channels/<chan>  │  ───────►   │ repo/*/releases/<release_id>/...│
│  (pointer object)       │             │  (never modified in place)      │
└─────────────────────────┘             └─────────────────────────────────┘
                 ▲
                 │
   2-promote_channel.sh (only thing that mutates pointers)
                 │
Terraform seeds pointers once, then lifecycle { ignore_changes } prevents drift.
```

### End-to-End Pipeline Walkthrough

```
Day-0_phase-1: tools/fetch-al2023-rpms.sh (runs on a temporary internet-connected EC2)
  |
  +--> downloads AL2023 RPMs from cdn.amazonlinux.com (EC2-only access):
  |      deps/rpm/al2023-minrepo/*.rpm
  |
  +--> downloads pip wheels + CloudWatch agent RPM:
         deps/pip/*.whl
         deps/cw-agent/amazon-cloudwatch-agent.rpm

  (handoff: "deps/ directory populated" — can now build offline)


Day-0_phase-2: tools/0-build_release.sh <release_id>
  |
  +--> creates temp GNUPGHOME (real ~/.gnupg never modified):
  |      copies pubring.kbx, trustdb.gpg
  |      symlinks private-keys-v1.d (read-only)
  |
  +--> generates immutable release tree locally:
  |      out/repo/rpm/releases/<release_id>/x86_64/...
  |      out/repo/pip/releases/<release_id>/py39/...
  |      out/repo/cw-agent/releases/<release_id>/...
  |
  +--> signs RPMs + repo metadata (3-key model):
  |      rpms signed (RPM_GPG_KEY_ID)
  |      repodata/repomd.xml.asc signed (REPO_GPG_KEY_ID)
  |
  +--> creates signed release manifest:
  |      out/manifests/<release_id>.json        (SHA256 of every artifact)
  |      out/manifests/<release_id>.json.sig    (signed by RELEASE_GPG_KEY_ID)
  |      out/manifests/<release_id>.json.sha256
  |
  +--> exports public keys for distribution:
  |      keys/release-signing-public.gpg
  |      keys/repo-metadata-signing-public.gpg
  |      keys/rpm-packages-signing-public.gpg
  |
  +--> post-build assertion: real ~/.gnupg mtime + SHA256 unchanged

  (handoff: release tree exists locally + keys exported + 3 fingerprints printed)


Day-1_phase-1: terraform apply -var="enable_ec2=false" -var="release_id=<release_id>"
  |
  +--> provisions VPC + private subnets (2-network.tf):
  |      no IGW, no NAT, no public subnets (airgap mode)
  |
  +--> provisions VPC endpoints (2.1-vpc-endpoints.tf):
  |      S3 Gateway + ssm, ec2messages, ssmmessages, logs, secretsmanager, kms
  |
  +--> provisions S3 deps bucket + hardening (4.2-s3-deps.tf):
  |      bucket + versioning + public access block
  |      bucket policy: reads must come via S3 VPC endpoint
  |
  +--> seeds channel pointer objects ONCE:
  |      repo/rpm/channels/{dev,stage,prod}
  |      repo/pip/channels/{dev,stage,prod}
  |      repo/cw-agent/channels/{dev,stage,prod}
  |
  +--> freezes channel pointer drift:
  |      lifecycle { ignore_changes } on content/etag/metadata
  |
  +--> provisions RDS, Secrets Manager, IAM, CloudWatch

  (handoff: infrastructure exists + S3 bucket ready + pointers seeded)


Day-1_phase-2: tools/1-upload_release.sh <release_id> <deps_bucket>
  |
  +--> uploads immutable release artifacts (no --delete):
  |      out/repo/...     -> s3://<bucket>/repo/...
  |      out/manifests/   -> s3://<bucket>/manifests/...
  |
  +--> uploads public keys:
  |      keys/*.gpg       -> s3://<bucket>/keys/...
  |
  +--> runs 8 verification checks:
         manifest exists, signature exists, rpm repodata exists,
         pip requirements.lock exists, cw-agent rpm exists,
         keys uploaded, no extraneous files, checksums match

  (handoff: release exists in S3 + keys available in S3)


Day-1_phase-3: tools/2-promote_channel.sh <channel> <release_id> <deps_bucket>
  |
  +--> fail-closed validation (release must be real + signed):
  |      manifests/<release_id>.json exists
  |      manifests/<release_id>.json.sig exists (and not UNSIGNED)
  |      rpm prefix contains repodata/
  |      pip prefix contains requirements.lock
  |      cw-agent rpm exists
  |
  +--> updates ONLY the tiny mutable pointer objects:
  |      repo/rpm/channels/<channel>      -> repo/rpm/releases/<release_id>/x86_64/
  |      repo/pip/channels/<channel>      -> repo/pip/releases/<release_id>/py39/
  |      repo/cw-agent/channels/<channel> -> repo/cw-agent/releases/<release_id>/
  |
  +--> writes promotion metadata:
         x-amz-meta-release-id=<release_id>
         x-amz-meta-promoted-at=<UTC timestamp>

  (handoff: channel now points at the desired immutable release)


Day-1_phase-4: terraform apply -var="enable_ec2=true" -var="channel=<ch>" + 3 fingerprints
  |
  +--> creates IAM role + instance profile (0.2-iam.tf):
  |      S3 read-only to deps bucket
  |      SSM Managed Instance Core
  |      CloudWatch Agent + Logs + Metrics
  |      Secrets Manager (scoped to specific ARN)
  |
  +--> creates aws_instance.web[0] (4-ec2.tf):
  |      private subnet, no public IP
  |      IMDSv2 required
  |      depends_on: VPC endpoints (S3, SSM, Logs, Secrets)
  |      preconditions: all 3 fingerprints MUST be non-empty
  |
  +--> AWS boots instance (AL2023 AMI)
  |
  +--> cloud-init runs rendered user_data.sh.tftpl:
         |
         +--> reads S3 channel pointers (must exist, promoted already):
         |      repo/rpm/channels/<channel>
         |      repo/pip/channels/<channel>
         |      repo/cw-agent/channels/<channel>
         |
         +--> resolves release_id from pointer content
         |
         +--> downloads signed manifest set:
         |      manifests/<release_id>.json
         |      manifests/<release_id>.json.sig
         |      manifests/<release_id>.json.sha256
         |
         +--> verifies embedded trust anchors (3 keys pinned at deploy time):
         |      writes embedded public keys to disk
         |      gpg --show-keys: computed fingerprint == terraform-pinned fingerprint
         |      imports keys ONLY after fingerprint match
         |
         +--> verifies manifest integrity:
         |      SHA256 of manifest matches .sha256
         |      gpg --verify .sig using release signing key
         |      manifest signing.* fingerprints cross-checked against embedded keys
         |
         +--> syncs artifacts from immutable release prefixes:
         |      repo/rpm/releases/<release_id>/x86_64/...
         |      repo/pip/releases/<release_id>/py39/...
         |      repo/cw-agent/releases/<release_id>/...
         |
         +--> strict SHA256 hash verification (fail-closed):
         |      every downloaded file must match manifest hash
         |      extra files not in manifest cause abort (injection detection)
         |
         +--> configures offline RPM repo with DNF enforcement:
         |      repo_gpgcheck=1 (repodata signature via repo metadata key)
         |      gpgcheck=1 (RPM signatures via RPM key)
         |      repomd.xml.asc presence check before makecache
         |      dnf clean all + dnf makecache (fail-closed preflight)
         |
         +--> installs system deps + CW agent RPM (offline, no fallback)
         |
         +--> installs Python deps (pip install --require-hashes, offline)
         |
         +--> writes Flask app + systemd unit + CloudWatch agent config
         |
         +--> starts + enables services
         |
         +--> app serving on private instance (SSM port-forward for access)

  (result: private instance deterministically converges from
   pointers -> verified release -> running service)
```

---

## AL2023 RPM Source Constraint

Amazon Linux 2023 packages are hosted on `cdn.amazonlinux.com`, which **restricts access
to EC2 instances only**. Requests from outside AWS receive HTTP 403 Forbidden.

This constraint requires a two-phase approach:
1. **Day-0 Phase-1:** Fetch RPMs from a temporary EC2 instance with internet access
2. **Day-0 Phase-2:** Build releases locally using cached RPMs

For the fetch procedure, see [RUNBOOK.md — Day-0 Phase-1](RUNBOOK.md#day-0-phase-1--supply-chain-preparation).

EC2 instances in this lab run in a **private VPC with no internet access**. The AL2023 AMI
does not include `python3-pip` by default. Without the offline RPM repository, bootstrap
cannot install pip, and Python package installation fails.

---

## GPG Signing (3-Key Model)

The release pipeline establishes a **chain of custody** rooted in an operator-generated
signing key. Three role-specific signing responsibilities ensure that manifests, repository
metadata, and RPM packages are independently verifiable — from key ceremony through build,
upload, and runtime verification. All three roles may use the same physical key
(auto-resolved when only one secret key exists).

| Role | Signs | Purpose |
|------|-------|---------|
| Release | Manifest (`.json.sig`) | Authenticates the release manifest |
| Repo metadata | `repomd.xml` (`.xml.asc`) | Authenticates DNF repository metadata |
| RPM packages | Individual `.rpm` files | Authenticates each package |

### Key Flow

```
   Build Machine                        EC2 Instance
   ──────┬──────                        ────────────
         │                                   ▲
         ▼                                   │
┌─────────────────┐                 ┌────────┴────────┐
│ Private Keys    │                 │ Public Keys     │
│ (in ~/.gnupg)   │                 │ (embedded in    │
│                 │                 │  user_data)     │
└────────┬────────┘                 └─────────────────┘
         │                                   ▲
         ▼                                   │
┌─────────────────┐    S3 Upload    ┌────────┴────────┐
│ Sign artifacts  │ ──────────────► │ Verify sigs     │
│ Export pub keys │                 │ Pin fingerprints│
└─────────────────┘                 └─────────────────┘
```

For self-contained signing implementation, see [SECURITY.md — Self-Contained Signing](SECURITY.md#self-contained-signing).
For resolving multiple GPG keys, see [RUNBOOK.md — Resolving: Multiple GPG Keys Found](RUNBOOK.md#resolving-multiple-gpg-keys-found).

---

## Bootstrap Security Model

The EC2 bootstrap script (`templates/user_data.sh.tftpl`) implements a **fail-closed**
security model. The script is ~29KB with embedded GPG keys; Terraform compresses it
via `base64gzip()` to fit AWS's 16KB user_data limit.

### Verification Chain

For the complete 8-step verification chain with implementation details, see
[SECURITY.md — Bootstrap Verification Chain](SECURITY.md#bootstrap-verification-chain).

### Fail-Fast Conditions

The bootstrap aborts on any of the following:

**Key verification:**
- Embedded key fingerprint doesn't match expected value
- Key import fails

**Manifest verification:**
- Channel pointer missing or unreadable
- Manifest SHA256 checksum mismatch
- Manifest unsigned (placeholder signature)
- GPG signature verification fails
- Manifest `signing.*` fingerprints don't match embedded keys

**Artifact verification:**
- Any artifact SHA256 hash mismatch
- Path traversal attempt detected
- Unexpected extra files found (injection attempt)
- `repomd.xml.asc` missing or empty

**Installation:**
- DNF makecache fails (repo metadata or signature issue)
- DNF install fails (no `rpm --nodeps` fallback)
- `requirements.lock` not found
- `pip install --require-hashes` fails (no unverified fallback)

**No fallbacks exist. Every failure aborts the bootstrap.**

---

## Airgap Boundary: Runtime vs Build Host

| Layer | Network | Description |
|-------|---------|-------------|
| **Runtime (EC2)** | Fully airgapped | No IGW, no NAT, no public subnets. All installs from S3 via VPC endpoint. |
| **Build host** | Network optional | If `deps/` is pre-seeded (RPMs, pip wheels, CW agent), the build is offline. Otherwise, `fetch-al2023-rpms.sh` and pip downloads require internet. |

This is an intentional architectural boundary. The runtime is unconditionally
airgapped. The build host can be made offline by pre-caching `deps/` from a
previous run or a secure artifact mirror.

---

## Project Structure

```
1c/
├── 0-backend.tf              # S3 backend configuration
├── 0-versions.tf             # Terraform/provider versions
├── 0.1-locals.tf             # S3 prefixes, channel pointers, GPG paths
├── 0.1-variables.tf          # Variables: exposure_mode, release_id, fingerprints
├── 0.2-iam.tf                # EC2 role (SSM, S3, CloudWatch, Secrets)
├── 0.3-secrets.tf            # Secrets Manager and Parameter Store
├── 1-providers.tf            # AWS provider configuration
├── 2-network.tf              # VPC, subnets (conditional public), route tables
├── 2.1-vpc-endpoints.tf      # S3 Gateway + Interface endpoints
├── 3-security_groups.tf      # ALB (conditional), EC2, RDS, Endpoint SGs
├── 4-ec2.tf                  # EC2 instance (conditional, mode-aware template)
├── 4.1-alb.tf                # Application Load Balancer (public_alb only)
├── 4.2-s3-deps.tf            # S3 bucket + channel pointers
├── 5-rds.tf                  # RDS MySQL instance
├── 6-cloudwatch.tf           # CloudWatch Logs, Metrics, Alarms
├── 7-outputs.tf              # Output values (mode-aware)
├── templates/
│   ├── user_data.sh.tftpl         # Offline bootstrap (airgap mode)
│   └── user_data_legacy.sh.tftpl  # Internet bootstrap (public_alb mode)
├── tools/
│   ├── fetch-al2023-rpms.sh       # day-0_phase-1: Fetch RPMs
│   ├── 0-build_release.sh         # day-0_phase-2: Build release
│   ├── 1-upload_release.sh        # day-1_phase-2: Upload to S3
│   ├── 2-promote_channel.sh       # day-1_phase-3: Promote channel
│   └── 3-rollback_channel.sh      # day-2+: Rollback
├── deps/
│   └── rpm/al2023-minrepo/        # Cached AL2023 RPMs
├── keys/
│   ├── release-signing-public.gpg
│   ├── repo-metadata-signing-public.gpg
│   └── rpm-packages-signing-public.gpg
├── out/                           # Build output (git-ignored)
├── terraform.tfvars.example       # Example variable values
├── README.md                      # This file (architecture, concepts)
├── RUNBOOK.md                     # Operational procedures
├── SECURITY.md                    # Security considerations
└── claude.md                      # AI assistant context
```

---

## Terraform Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `exposure_mode` | `airgap` | `airgap` or `public_alb` |
| `enable_ec2` | `true` | Toggle EC2 instance creation |
| `release_id` | `initial` | ISO 8601 timestamp (e.g., `2026-02-09T0939Z`) |
| `channel` | `dev` | Deployment channel: dev, stage, prod |
| `release_gpg_key_fingerprint` | `""` | 40-hex fingerprint of manifest signing key (required for EC2) |
| `repo_gpg_key_fingerprint` | `""` | 40-hex fingerprint of repo metadata signing key (required for EC2) |
| `rpm_gpg_key_fingerprint` | `""` | 40-hex fingerprint of RPM package signing key (required for EC2) |
| `aws_region` | `us-east-1` | AWS region |
| `project_name` | `ec2-rds-notes-lab` | Resource naming prefix |
| `instance_type` | `t3.micro` | EC2 instance type |
| `secret_name` | `lab/rds/mysql` | Secrets Manager secret name |
| `enable_dnf_update` | `false` | Run dnf update during bootstrap |
| `enable_kms_endpoint` | `true` | Create KMS VPC endpoint |
| `allowed_http_cidrs` | `["0.0.0.0/0"]` | ALB access CIDRs (public_alb only) |
| `alert_email` | `""` | Email for alarm notifications |

---

## Cost Considerations

| Resource | Cost |
|----------|------|
| S3 Gateway Endpoint | Free |
| Interface Endpoints (6) | ~$44/month |
| EC2 t3.micro | ~$8/month |
| RDS db.t3.micro | ~$15/month |
| S3 Storage | Minimal |

---

## Getting Started

For step-by-step deployment instructions, see [RUNBOOK.md](RUNBOOK.md):

1. [Day-0 Phase-1: Supply Chain Preparation](RUNBOOK.md#day-0-phase-1--supply-chain-preparation) — Fetch AL2023 RPMs
2. [Day-0 Phase-2: Build Signed Release](RUNBOOK.md#day-0-phase-2--build-signed-release) — Build and sign artifacts
3. [Day-1 Phase-1: Infrastructure Prep](RUNBOOK.md#day-1-phase-1--infrastructure-prep-no-ec2) — Deploy VPC, S3, RDS, endpoints
4. [Day-1 Phase-2: Upload Release](RUNBOOK.md#day-1-phase-2--upload-release) — Sync to S3
5. [Day-1 Phase-3: Promote Channel](RUNBOOK.md#day-1-phase-3--promote-channel) — Point channel to release
6. [Day-1 Phase-4: Deploy EC2](RUNBOOK.md#day-1-phase-4--deploy-ec2) — Launch instance
7. [Day-2+: Operations](RUNBOOK.md#day-2--rollback-operations) — Promotion, rollback, new releases
8. [Cleanup](RUNBOOK.md#cleanup--destroy-infrastructure) — Destroy all resources

---

## Troubleshooting

For common issues and resolution steps, see [RUNBOOK.md — Troubleshooting](RUNBOOK.md#troubleshooting).
