# Class7_Armageddon-1 - Team AWSUltraMarines

[![Team](https://img.shields.io/badge/Team-AWSUltraMarines-0066CC)](https://github.com)
[![AWS](https://img.shields.io/badge/AWS-Infrastructure-FF9900?logo=amazon-aws)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?logo=terraform)](https://www.terraform.io/)

---

## Repository Navigation Guide

This repository contains individual team member work across separate branches. Each branch represents one member's implementation of the Armageddon project labs.

---

## Team Members & Branch Locations

| Member | Branch Name | Branch Link | Labs Included |
|--------|-------------|-------------|---------------|
| Daequan Britt | `daequan_britt` | [View Branch](../../tree/daequan_britt) | Lab 1a |
| James Scales | `james_scales` | [View Branch](../../tree/james_scales) | Lab 1a |
| Walid Ahmed | `Walid_Ahmed` | [View Branch](../../tree/Walid_Ahmed) | Lab 1a, Lab 1b |
| Willie Bright | `Willie_Bright` | [View Branch](../../tree/Willie_Bright) | Lab 1a, Lab 1b |

---

## Branch Checkout Commands

```bash
# View all branches
git branch -a

# Checkout individual member branches
git checkout daequan_britt
git checkout james_scales
git checkout Walid_Ahmed
git checkout Willie_Bright

# Return to main
git checkout main
```

---

## Branch Contents

### Daequan Britt Branch

**Location:** `daequan_britt`

**Directory Structure:**
```
daequan_britt/
├── README.md
├── 1a-tf/
│   └── README.md
└── 1a-clickops/
    ├── README.md
    ├── 1a_laba.md
    └── 1a-explanation.md
```

**Approach:** Dual implementation (Terraform + ClickOps)

**Labs Covered:** Lab 1a

---

### James Scales Branch

**Location:** `james_scales`

**Directory Structure:**
```
james_scales/
├── README.md
└── armageddon-1a/
    └── readme.md
```

**Approach:** Terraform

**Labs Covered:** Lab 1a

---

### Walid Ahmed Branch

**Location:** `Walid_Ahmed`

**Directory Structure:**
```
Walid_Ahmed/
├── README.md
├── 1a/
│   ├── README.md
│   ├── RUNBOOK.md
│   ├── SECURITY.md
│   ├── 0-backend.tf
│   ├── 0-versions.tf
│   ├── 0.1-locals.tf
│   ├── 0.1-variables.tf
│   ├── 0.2-iam.tf
│   ├── 0.3-secrets.tf
│   ├── 1-providers.tf
│   ├── 2-network.tf
│   ├── 3-security_groups.tf
│   ├── 4-ec2.tf
│   ├── 5-rds.tf
│   ├── 6-outputs.tf
│   ├── templates/user_data.sh.tftpl
│   └── evidence/ (8 screenshots)
└── 1b/
    ├── README.md
    ├── RUNBOOK.md
    ├── SECURITY.md
    ├── 0-backend.tf
    ├── 0-versions.tf
    ├── 0.1-locals.tf
    ├── 0.1-variables.tf
    ├── 0.2-iam.tf
    ├── 0.3-secrets.tf
    ├── 1-providers.tf
    ├── 2-network.tf
    ├── 3-security_groups.tf
    ├── 4-ec2.tf
    ├── 5-rds.tf
    ├── 6-cloudwatch.tf
    ├── 7-outputs.tf
    ├── templates/user_data.sh.tftpl
    └── evidence/ (11 screenshots)
```

**Approach:** Terraform Infrastructure-as-Code

**Documentation Files:**
- Root README.md (444 lines)
- 1a/README.md (663 lines)
- 1a/RUNBOOK.md (911 lines)
- 1a/SECURITY.md (337 lines)
- 1b/README.md (1275 lines)
- 1b/RUNBOOK.md (1787 lines)
- 1b/SECURITY.md (518 lines)

**Evidence:** 19 total screenshots (8 for Lab 1a, 11 for Lab 1b)

---

### Willie Bright Branch

**Location:** `Willie_Bright`

**Files:**
```
Willie_Bright/
├── README.md
├── Lab1a_Delieverable.md
└── Readme1B.md
```

**Approach:** AWS Console (ClickOps)

**Labs Covered:** Lab 1a, Lab 1b

---

## Common Technologies Across Branches

**AWS Services:**
- VPC
- EC2
- RDS (MySQL)
- Secrets Manager
- Parameter Store (Lab 1b)
- CloudWatch (Lab 1b)
- SNS (Lab 1b)
- IAM
- Security Groups

**Infrastructure Tools:**
- Terraform >= 1.5.0 (where applicable)
- AWS Provider ~> 5.0 (where applicable)
- AWS Console (ClickOps implementations)

**Application:**
- Flask (Python)
- Amazon Linux 2023
- MySQL database

---

## File Location Quick Reference

| Content Type | Walid Ahmed | Willie Bright | Daequan Britt | James Scales |
|--------------|-------------|---------------|---------------|--------------|
| **Lab 1a README** | `1a/README.md` | `README.md` | `1a-tf/README.md` or `1a-clickops/README.md` | `armageddon-1a/readme.md` |
| **Lab 1b README** | `1b/README.md` | `Readme1B.md` | - | - |
| **Terraform Files** | `1a/*.tf`, `1b/*.tf` | - | `1a-tf/` | `armageddon-1a/` |
| **Evidence/Screenshots** | `1a/evidence/`, `1b/evidence/` | (see member docs) | (see member docs) | (see member docs) |
| **Runbooks** | `1a/RUNBOOK.md`, `1b/RUNBOOK.md` | - | - | - |
| **Security Docs** | `1a/SECURITY.md`, `1b/SECURITY.md` | - | - | - |

---

## Project Components (All Branches)

Each branch demonstrates deployment of the following core architecture:

**Network Layer:**
- VPC with CIDR block
- Public subnets (EC2)
- Private subnets (RDS)
- Internet Gateway
- Route tables

**Compute Layer:**
- EC2 instance running Flask application
- Application accessible via HTTP

**Database Layer:**
- RDS MySQL instance
- Private subnet placement (no public access)
- Security group-to-security group references

**Security:**
- AWS Secrets Manager for database credentials
- IAM roles and instance profiles
- Security group configurations

**Monitoring (Lab 1b only):**
- CloudWatch Logs
- CloudWatch Metrics
- CloudWatch Alarms
- SNS notifications

---
