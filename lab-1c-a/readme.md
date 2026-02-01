# Class 7 – Armageddon Lab 1c-a

## Goal Statements

### Concise:
Deploy a fully private EC2 instance running the Notes application, accessible only through SSM Session Manager, with secure connectivity to a private RDS MySQL database.
### Infrastructure‑Focused:
Build a private, NAT‑less architecture where EC2 runs in isolated subnets, communicates with AWS control‑plane services through VPC Interface Endpoints, retrieves secrets with least‑privilege IAM, and connects to RDS over internal VPC networking.

VPC Endpoints → EC2 (Private) w/ Web “Notes” App → RDS MySQL (Private)

# File Structure
|-- 00.auth.tf
|-- 01.vpc.tf
|-- 02.subnets.tf
|-- 03.vpcendpoint.tf
|-- 04.route.tf
|-- 05.sg.tf
|-- 06.instance.tf
|-- 07.iam.tf
|-- 08.ssm.tf
|-- 09.rds.tf
|-- 10.cloudwatch.tf
|-- 11.sns.tf
|-- 12.secrets.tf
|-- data.tf
|-- locals.tf
|-- output.tf
|-- readme.md
|-- userdata.sh
`-- variables.tf

### Overview
This lab evolves the previous EC2 → RDS architecture by moving the compute layer fully into private subnets and eliminating the need for public IPs, SSH access, or NAT gateways. Instead, the environment uses AWS Systems Manager Session Manager for instance access and VPC Interface Endpoints to allow private subnets to communicate with AWS control‑plane services.

All infrastructure is provisioned using Terraform, including networking, endpoints, IAM, Secrets Manager, and the EC2 instance running the Notes application.

Objectives
- Deploy a private EC2 instance with no public IP
- Access the instance exclusively through SSM Session Manager
- Remove NAT dependency by using VPC Interface Endpoints for:
    - SSM
    - EC2Messages
    - SSMMessages
    - CloudWatch Logs
    - Secrets Manager
    - KMS (optional but realistic)
- Add an S3 Gateway Endpoint to support common private‑environment workflows
- Tighten IAM permissions:
    - secretsmanager:GetSecretValue only for the specific secret
    - ssm:GetParameter / ssm:GetParameters only for the required parameter path
- Maintain secure EC2 → RDS connectivity inside private subnets


Terraform‑Managed Resources
- Networking
    - VPC, private subnets, route tables
    - No IGW or NAT required for EC2
    - S3 Gateway Endpoint
    - Interface Endpoints for SSM, EC2Messages, SSMMessages, CloudWatch Logs, Secrets Manager, KMS
- Compute
    - Private EC2 instance (no public IP)
    - SSM agent access via VPC endpoints
- Database
    - RDS MySQL instance in private subnets
- Security
    - Security groups for EC2 and RDS
    - IAM role with least‑privilege access to Secrets Manager + SSM Parameter Store
- Secrets
    - Secrets Manager secret containing DB credentials


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
