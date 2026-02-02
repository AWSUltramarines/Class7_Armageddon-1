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
| Daequan Britt | `daequan_britt` | [View Branch](../../tree/daequan_britt) | Lab 1a, Lab 1b, Lab 1c, Lab 2a, Lab 2b |
| Don Mann | `Don_Mann` | [View Branch](../../tree/Don_Mann) | Lab 1a |
| Jamal Waring | `jamalwaring` | [View Branch](../../tree/jamalwaring) | Lab 1a, Lab 1b, Lab 1c |
| James Scales | `james_scales` | [View Branch](../../tree/james_scales) | Lab 1a, Lab 1b, Lab 1c, Lab 2a |
| Jason Cramer | `Jason_Cramer` | [View Branch](../../tree/Jason_Cramer) | Lab 1a, Lab 1b |
| Jason Lee | `Jason_Lee` | [View Branch](../../tree/Jason_Lee) | Lab 1a, Lab 1b, Lab 1c |
| Joey Africanstar | `Joey_africanstar` | [View Branch](../../tree/Joey_africanstar) | Lab 1a |
| Kaiju Hyuga | `Kaiju_Hyuga` | [View Branch](../../tree/Kaiju_Hyuga) | Lab 1a, Lab 1b |
| Okey Okafor | `Okey_Okafor` | [View Branch](../../tree/Okey_Okafor) | Lab 1a |
| Walid Ahmed | `Walid_Ahmed` | [View Branch](../../tree/Walid_Ahmed) | Lab 1a, Lab 1b |
| Willie Bright | `Willie_Bright` | [View Branch](../../tree/Willie_Bright) | Lab 1, Lab 2, Lab 3 |

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
├── 1a-tf/, 1a-clickops/          (Lab 1a)
├── 1bc-a-tf/                      (Lab 1b + 1c)
├── 1c-b-tf/, 1c-c-tf/, 1c-d-tf/  (Lab 1c variants)
├── 1c-e-tf/, 1c-f-tf/            (Lab 1c variants)
├── 2a/                            (Lab 2a - CloudFront, ACM)
├── 2b/                            (Lab 2b - ElastiCache)
├── 2b-ma/                         (Lab 2b Multi-AZ)
└── 2b-mb/                         (Lab 2b Multi-AZ variant)
```

**Approach:** Terraform + ClickOps

**Labs Covered:** Lab 1a, Lab 1b, Lab 1c, Lab 2a, Lab 2b

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
├── README.md
├── section1a/
│   ├── Terraform/ (*.tf files)
│   ├── json/ (AWS CLI configs)
│   └── assets/ (screenshots)
├── section1b/
│   └── Terraform/ (*.tf files + CloudWatch)
└── section1c/
    ├── TerraformA/
    └── TerraformB/
```

**Approach:** Terraform

**Labs Covered:** Lab 1a, Lab 1b, Lab 1c

---

### James Scales Branch

**Location:** `james_scales`

**Directory Structure:**
```
james_scales/
├── README.md
├── lab-1a/, lab-1b/, lab-1c/
├── lab-1c-a/, lab-1c-b/, lab-1c-c/
├── lab-1c-d/, lab-1c-e/, lab-1c-f/
└── lab-2a/
```

**Approach:** Terraform

**Labs Covered:** Lab 1a, Lab 1b, Lab 1c, Lab 2a

---

### Jason Cramer Branch

**Location:** `Jason_Cramer`

**Directory Structure:**
```
Jason_Cramer/
├── README.md
├── armageddon_lab_1a/
├── armageddon_deliverables_1a/
├── armageddon_lab_1b/
└── armageddon_deliverables_1b/
```

**Approach:** Terraform

**Labs Covered:** Lab 1a, Lab 1b

---

### Jason Lee Branch

**Location:** `Jason_Lee`

**Directory Structure:**
```
Jason_Lee/
├── README.md
├── Lab_1a_Terraform/
├── Lab_1b/ (includes Lambda, SNS, SSM)
└── Lab_1c/ (includes CloudWatch agent)
```

**Approach:** Terraform

**Labs Covered:** Lab 1a, Lab 1b, Lab 1c

---

### Joey Africanstar Branch

**Location:** `Joey_africanstar`

**Directory Structure:**
```
Joey_africanstar/
├── README.rtf
├── Armageddon Part 1 step by step.rtf
├── armageddon Lab 1A terraform/
├── debug_db.py
├── Student Deliverables.rtfd/
└── (screenshots)
```

**Approach:** Terraform + ClickOps

**Labs Covered:** Lab 1a

---

### Kaiju Hyuga Branch

**Location:** `Kaiju_Hyuga`

**Directory Structure:**
```
Kaiju_Hyuga/
├── 1a/
│   ├── Armag1.2/lab1a/ (Terraform)
│   ├── lab1a/ (screenshots + answers)
│   └── Armag1a_json/
└── lab1b/ (Terraform with SNS)
```

**Approach:** Terraform + JSON configurations

**Labs Covered:** Lab 1a, Lab 1b

---

### Okey Okafor Branch

**Location:** `Okey_Okafor`

**Directory Structure:**
```
Okey_Okafor/
├── README.md
├── 1a/ (ClickOps documentation)
└── *.tf files (Terraform in root)
```

**Approach:** Terraform + ClickOps

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
├── lab1/
│   ├── 1a/ (Terraform + deliverables)
│   └── 1b/ (Terraform + deliverables)
├── lab2/
└── lab3/
```

**Approach:** Terraform

**Labs Covered:** Lab 1, Lab 2, Lab 3

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
- CloudFront (Lab 2a)
- ACM (Lab 2a)
- ElastiCache (Lab 2b)

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
| **Lab 1a README** | `1a/README.md` | `lab1/1a/` | `1a-tf/README.md` | `README.md` | - | `armageddon-1a/readme.md` | `armageddon_deliverables_1a/` | `README.md` | `*.rtf` files | `1a/1a_short_answers.txt` | `1a/1a.md` |
| **Lab 1b README** | `1b/README.md` | `lab1/1b/` | `1bc-a-tf/README.md` | - | - | (in `armageddon-1a/`) | - | - | - | - | - |
| **Lab 1c README** | - | - | `1c-b-tf/README.md`, `1c-c-tf/README.md` | - | - | - | - | - | - | - | - |
| **Terraform Files** | `1a/*.tf`, `1b/*.tf` | `lab1/1a/*.tf`, `lab1/1b/*.tf` | `1a-tf/`, `1bc-a-tf/`, `1c-b-tf/`, `1c-c-tf/` | - | `section1c/` | `armageddon-1a/` | `armageddon_lab_1a/` | - | - | `1a/Armageddon_1/` | - |
| **Evidence/Screenshots** | `1a/evidence/`, `1b/evidence/` | `lab1/1a/`, `lab1/1b/` | `proof-*` folders | (in branch root) | - | `armageddon-1a/evidence/` | `armageddon_deliverables_1a/` | (in README.md) | `Student Deliverables.rtfd/` | `1a/` |
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
