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
| Daequan Britt | `daequan_britt` | [View Branch](../../tree/daequan_britt) | Lab 1a, Lab 1b, Lab 1c |
| Don Mann | `Don_Mann` | [View Branch](../../tree/Don_Mann) | Lab 1a |
| Jamal Waring | `jamalwaring` | [View Branch](../../tree/jamalwaring) | Lab 1a |
| James Scales | `james_scales` | [View Branch](../../tree/james_scales) | Lab 1a, Lab 1b |
| Jason Cramer | `Jason_Cramer` | [View Branch](../../tree/Jason_Cramer) | Lab 1a |
| Jason Lee | `Jason_Lee` | [View Branch](../../tree/Jason_Lee) | Lab 1a |
| Joey Africanstar | `Joey_africanstar` | [View Branch](../../tree/Joey_africanstar) | Lab 1a |
| Kaiju Hyuga | `Kaiju_Hyuga` | [View Branch](../../tree/Kaiju_Hyuga) | Lab 1a |
| Okey Okafor | `Okey_Okafor` | [View Branch](../../tree/Okey_Okafor) | Lab 1a |
| Walid Ahmed | `Walid_Ahmed` | [View Branch](../../tree/Walid_Ahmed) | Lab 1a, Lab 1b |
| Willie Bright | `Willie_Bright` | [View Branch](../../tree/Willie_Bright) | Lab 1a, Lab 1b |

---

## Branch Checkout Commands

```bash
# View all branches
git branch -a

# Checkout individual member branches
git checkout daequan_britt
git checkout Don_Mann
git checkout jamalwaring
git checkout james_scales
git checkout Jason_Cramer
git checkout Jason_Lee
git checkout Joey_africanstar
git checkout Kaiju_Hyuga
git checkout Okey_Okafor
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
│   ├── README.md
│   └── *.tf files
├── 1a-clickops/
│   ├── README.md
│   ├── screenshots/
│   └── documentation
├── 1bc-a-tf/
│   ├── README.md
│   ├── *.tf files
│   ├── proof-1b/ (screenshots)
│   └── proof-1c/ (screenshots)
├── 1c-b-tf/
│   ├── README.md
│   ├── *.tf files (includes ALB, Dashboard, WAF)
│   ├── proof-1b/
│   ├── proof-1c-a/
│   └── proof-1c-b/
└── 1c-c-tf/
    ├── README.md
    ├── *.tf files (includes Route 53)
    ├── proof-1b/
    ├── proof-1c-a/
    ├── proof-1c-b/
    └── proof-1c-c/
```

**Approach:** Terraform + ClickOps

**Labs Covered:** Lab 1a, Lab 1b, Lab 1c

---

### Don Mann Branch

**Location:** `Don_Mann`

**Directory Structure:**
```
Don_Mann/
├── README.md
├── Short and then answers.txt
├── screenshot_inbound_rule.png
└── screenshot_output.png
```

**Approach:** AWS Console (ClickOps)

**Labs Covered:** Lab 1a

---

### Jamal Waring Branch

**Location:** `jamalwaring`

**Directory Structure:**
```
jamalwaring/
└── section1c/
    ├── 00-auth.tf
    ├── 01-IAM.tf
    ├── 02-vpc.tf
    └── 03-subnets.tf
```

**Approach:** Terraform

**Labs Covered:** Lab 1a

---

### James Scales Branch

**Location:** `james_scales`

**Directory Structure:**
```
james_scales/
├── README.md
└── armageddon-1a/
    ├── readme.md
    ├── 00.auth.tf
    ├── 01.vpc.tf
    ├── 02.subnets.tf
    ├── 03.gateway.tf
    ├── 04.route.tf
    ├── 05.sg.tf
    ├── 06.instance.tf
    ├── 07.iam.tf
    ├── 08.rds.tf
    ├── 09.secrets.tf
    ├── 10.cloudwatch.tf
    ├── 11.sns.tf
    ├── variables.tf
    ├── locals.tf
    ├── data.tf
    ├── output.tf
    ├── userdata.sh
    └── evidence/ (13 screenshots)
```

**Approach:** Terraform

**Labs Covered:** Lab 1a, Lab 1b

---

### Jason Cramer Branch

**Location:** `Jason_Cramer`

**Directory Structure:**
```
Jason_Cramer/
├── README.md
├── armageddon_lab_1a/
│   ├── 0-auth.tf
│   ├── 1-vpc.tf
│   ├── 2-subnets.tf
│   ├── 3-IGW.tf
│   ├── 4-NAT.tf
│   ├── 5-route.tf
│   ├── 6-SG.tf
│   ├── 7-EC2.tf
│   ├── 9-RDS.tf
│   ├── 10-IAM.tf
│   ├── 11-secret.tf
│   ├── A-output.tf
│   └── user_data.sh
└── armageddon_deliverables_1a/
    ├── short_anwers.txt
    ├── screenshot_rds_inbound_rule_ec2.png
    └── screenshot_list_output.png
```

**Approach:** Terraform

**Labs Covered:** Lab 1a

---

### Jason Lee Branch

**Location:** `Jason_Lee`

**Directory Structure:**
```
Jason_Lee/
└── README.md (contains screenshots, short answers, and documentation)
```

**Approach:** AWS Console (ClickOps)

**Labs Covered:** Lab 1a

---

### Joey Africanstar Branch

**Location:** `Joey_africanstar`

**Directory Structure:**
```
Joey_africanstar/
├── README.md
├── Armageddon Part 1 Read Me.rtf
├── Armageddon Data Script.rtf
├── debug_db.py
└── Student Deliverables.rtfd/
    ├── TXT.rtf
    └── (screenshots)
```

**Approach:** AWS Console (ClickOps)

**Labs Covered:** Lab 1a

**Notes:** Documentation in RTF format with step-by-step console instructions. Includes Python debug script for testing RDS connectivity.

---

### Kaiju Hyuga Branch

**Location:** `Kaiju_Hyuga`

**Directory Structure:**
```
Kaiju_Hyuga/
└── 1a/
    ├── 1a_short_answers.txt
    ├── Armageddon_1/
    │   ├── 0-auth.tf
    │   ├── 01-rds.tf
    │   ├── ec2.tf
    │   ├── IAM.tf
    │   ├── network.tf
    │   ├── secrets.tf
    │   ├── sg.tf
    │   ├── variables.tf
    │   └── 1a_user_data.sh
    ├── Codes/
    │   ├── instance.json
    │   ├── rds.json
    │   ├── role-policies.json
    │   ├── secret.json
    │   └── sg.json
    └── Console/
        ├── App_list_output.png
        └── RDS_SG_source.png
```

**Approach:** Terraform + JSON configurations

**Labs Covered:** Lab 1a

---

### Okey Okafor Branch

**Location:** `Okey_Okafor`

**Directory Structure:**
```
Okey_Okafor/
├── README.md
└── 1a/
    ├── 1a.md
    └── (8 screenshots: 1a-1.png through 1a-8.png)
```

**Approach:** AWS Console (ClickOps)

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

**Approach:** Terraform

**Labs Covered:** Lab 1a, Lab 1b

---

### Willie Bright Branch

**Location:** `Willie_Bright`

**Directory Structure:**
```
Willie_Bright/
├── README.md
├── Lab1a_Delieverable.md
├── Readme1B.md
├── 01-version.tf
├── 02-providers.tf
├── 03-variables.tf
├── 04-1a-1c-Main.tf
├── 04-1ca-Main.tf
├── 05-outputs.tf
├── user_data.sh
└── (screenshots for 1a and 1b)
```

**Approach:** Terraform + ClickOps

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

| Content Type | Walid Ahmed | Willie Bright | Daequan Britt | Don Mann | Jamal Waring | James Scales | Jason Cramer | Jason Lee | Joey Africanstar | Kaiju Hyuga | Okey Okafor |
|--------------|-------------|---------------|---------------|----------|--------------|--------------|--------------|-----------|------------------|-------------|-------------|
| **Lab 1a README** | `1a/README.md` | `README.md` | `1a-tf/README.md` | `README.md` | - | `armageddon-1a/readme.md` | `armageddon_deliverables_1a/` | `README.md` | `*.rtf` files | `1a/1a_short_answers.txt` | `1a/1a.md` |
| **Lab 1b README** | `1b/README.md` | `Readme1B.md` | `1bc-a-tf/README.md` | - | - | (in `armageddon-1a/`) | - | - | - | - | - |
| **Lab 1c README** | - | - | `1c-b-tf/README.md`, `1c-c-tf/README.md` | - | - | - | - | - | - | - | - |
| **Terraform Files** | `1a/*.tf`, `1b/*.tf` | `*.tf` | `1a-tf/`, `1bc-a-tf/`, `1c-b-tf/`, `1c-c-tf/` | - | `section1c/` | `armageddon-1a/` | `armageddon_lab_1a/` | - | - | `1a/Armageddon_1/` | - |
| **Evidence/Screenshots** | `1a/evidence/`, `1b/evidence/` | (in branch root) | `proof-*` folders | (in branch root) | - | `armageddon-1a/evidence/` | `armageddon_deliverables_1a/` | (in README.md) | `Student Deliverables.rtfd/` | `1a/Console/` | `1a/` |
| **Runbooks** | `1a/RUNBOOK.md`, `1b/RUNBOOK.md` | - | - | - | - | - | - | - | - | - | - |
| **Security Docs** | `1a/SECURITY.md`, `1b/SECURITY.md` | - | - | - | - | - | - | - | - | - | - |

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

**Advanced Features (Lab 1c only):**
- Application Load Balancer (ALB)
- Route 53 DNS
- CloudWatch Dashboards
- AWS WAF

---
