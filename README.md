
# Lab 1A — EC2 → RDS Notes App (ClickOps Foundation)

## Purpose
Deploy a simple web application on EC2 that connects to a private RDS MySQL instance using AWS Secrets Manager for credential storage. This lab establishes the foundational architecture that Labs 1B and 1C build upon.

## Architecture
```

┌─────────────────────────────────────────────────────────┐

│                    VPC: Helga (10.212.0.0/16)           │

│  ┌──────────────────┐       ┌──────────────────────┐    │

│  │  Public Subnet   │       │   Private Subnet     │    │

│  │  (us-east-2a)    │       │   (us-east-2a/2b)    │    │

│  │                  │       │                      │    │

│  │   ┌──────────┐   │       │    ┌────────────┐    │    │

│  │   │   EC2    │───┼───────┼───▶│  RDS MySQL │    │    │

│  │   │  Flask   │   │ :3306 │    │  lab-mysql │    │    │

│  │   └──────────┘   │       │    └────────────┘    │    │

│  └──────────────────┘       └──────────────────────┘    │

└─────────────────────────────────────────────────────────┘

│

│ :80 HTTP

▼

[Internet Gateway]

│

[User Browser]

```

## Components
| Resource | Name/ID | Purpose |
|----------|---------|---------|
| VPC | Helga | 10.212.0.0/16 |
| EC2 | lab-ec2-app | Flask app host (Amazon Linux 2023) |
| RDS | lab-mysql | MySQL database (private, no public access) |
| Secret | lab/rds/mysql | DB credentials (Secrets Manager) |
| IAM Role | RDS-lab-Access | EC2 role with Secrets Manager read |
| SG (EC2) | sg-ec2-lab | Inbound HTTP 80, SSH 22 |
| SG (RDS) | sg-rds-lab | Inbound MySQL 3306 from sg-ec2-lab |

## Key Security Pattern
RDS Security Group allows inbound **only from the EC2 Security Group** — not from 0.0.0.0/0. This is the industry-standard pattern for app-to-database connectivity.

## Application Endpoints
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Home page |
| `/init` | GET | Initialize database + create notes table |
| `/add?note=<text>` | GET/POST | Insert a new note |
| `/list` | GET | List all notes |

## Verification Commands
```

# Confirm EC2 can read the secret

aws secretsmanager get-secret-value --secret-id lab/rds/mysql --region us-east-2

# Confirm app is running

curl http://<EC2_PUBLIC_IP>/list

```

## Deliverables
1. Screenshot: RDS SG inbound rule using source = sg-ec2-lab
2. Screenshot: EC2 role attached
3. Screenshot: `/list` output showing at least 3 notes
4. Short answers:
   - A) Why is DB inbound source restricted to the EC2 security group?
   - B) What port does MySQL use?
   - C) Why is Secrets Manager better than storing creds in code/user-data?

## Files in This Directory
- `user_[data.sh](http://data.sh)` — EC2 bootstrap script (Flask app + systemd service)
- `inline_policy.json` — IAM policy for Secrets Manager access
- `evidence/` — Screenshots proving completion
