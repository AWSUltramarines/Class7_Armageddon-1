# Class 7 – Armageddon Lab 1c (Terraform Deployment)

## Goal Statements

### Concise:
Deploy a public-facing EC2 instance running a “Notes” web application that securely connects to a private MySQL RDS database.

### Infrastructure‑Focused:
Build a two‑tier architecture where a public EC2 instance serves the Notes web app and communicates with a private MySQL RDS database over internal VPC networking — fully provisioned using Terraform.

### Overview
This lab replaces manual AWS Console configuration with a complete Infrastructure‑as‑Code (IaC) workflow using Terraform. The Terraform configuration provisions all networking, compute, database, security, and secrets resources required to run the Notes web application.
The EC2 instance retrieves database credentials from AWS Secrets Manager using a least‑privilege IAM role. The application exposes endpoints to initialize the database, insert notes, and list stored notes.

Objectives
- Deploy a full EC2 → RDS architecture using Terraform
- Automate creation of VPC, subnets, route tables, NAT, and security groups
- Provision an RDS MySQL instance in private subnets
- Launch a public EC2 instance with User Data to bootstrap the Notes app
- Store database credentials in Secrets Manager and grant EC2 least‑privilege access
- Validate connectivity and application functionality after deployment

Terraform‑Managed Resources
- Networking:
VPC, public/private subnets, route tables, IGW, NAT Gateway, EIP
- Compute:
EC2 instance with User Data for app installation
- Database:
RDS MySQL instance in private subnets
- Security:
Security groups for EC2 and RDS
IAM role + inline policy for Secrets Manager access
- Secrets:
AWS Secrets Manager secret containing DB credentials

Deployment Flow (Terraform)
- Develop code for above resources in Terraform
- Use userdata.sh script provided in class
- Update variable values (region, CIDRs, instance types, secret names, etc.)
- Run terraform init
- Run terraform vaildate to confirm syntax and variables
- Run terraform plan to review changes
- Run terraform apply to deploy the full environment
- Retrieve the EC2 public IP from Terraform outputs
- Test the application:
- http://<public-ip>/init
- http://<public-ip>/add?note=first_note
- http://<public-ip>/list

### Troubleshooting
All previous troubleshooting steps still apply (network checks, MySQL connectivity, secret retrieval, systemd logs). These are now used after Terraform deployment instead of manual setup.
