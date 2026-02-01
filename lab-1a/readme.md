# Class 7 Armageddon Lab 1a Deployment

## Goal Statements
### Concise:
Deploy a public-facing EC2 instance running a “Notes” web application that securely connects to a private MySQL RDS database.

### Infrastructure‑Focused:
Build a two‑tier architecture where a public EC2 instance serves the Notes web app and communicates with a private MySQL RDS database over internal VPC networking.

EC2 (Public) w/ Web “Notes” App → RDS MySQL (Private)

---

### Overview

This lab provisions a simple Notes web application running on an EC2 instance. The application supports:
- Inserting notes into an RDS MySQL database
- Listing notes stored in the database

The EC2 instance retrieves database credentials from AWS Secrets Manager and connects to the RDS instance over port 3306 using security group rules.

---


### Requirements:
- RDS MySQL instance deployed in a private subnet
- EC2 instance running a Python Flask application
- Security groups allowing EC2 → RDS traffic on port 3306
- Database credentials stored in AWS Secrets Manager
- IAM role granting EC2 permission to read the secret


### AWS Resources Used
- Networking: VPC, Subnets, Route Tables, IGW, NAT Gateway
- Compute: EC2
- Database: RDS (MySQL)
- Security: Security Groups, IAM Role + Inline Policy
- Secrets: AWS Secrets Manager
- Other: EIP (for NAT), User Data script for app bootstrap

---

</br>

## Console Instructions
Lab A – Manual Deployment Steps
1. Create the VPC
    - Custom VPC
    - 1 public subnet
    - 2 private subnets
2. Create the RDS MySQL Instance
    - Deploy into a private subnet
    - Record the following:
        - DB Username
        - DB Password
        - DB Endpoint (critical for troubleshooting)
3. Launch the EC2 Instance
    - Place in the public subnet
    - Create a key pair
    - Add the userdata.sh script to User Data
        - Update SECRETID and REGION before launching
4. Configure Security Groups
    - EC2 Security Group
        - Inbound:
            - Port 80 → 0.0.0.0/0
            - Port 22 → 0.0.0.0/0
        - Outbound: Default
    RDS Security Group
        - Inbound:
        - Port 3306
        - Source: EC2 Security Group
        - Outbound: Default
5. Create the Secret in Secrets Manager
    - Assign a clear Secret Name (save this!)
    - Link the secret to the RDS instance
    - Insert DB username, password, host, and port
    - Record the Secret ARN
6. Create the IAM Role (Trust Policy)
    - IAM → Roles → Create Role
    - Select: AWS Service → EC2
    - Skip permissions for now
    - Name the role and create it
    - Add an inline policy:
        - Action: secretsmanager:GetSecretValue
        - Resource: Secret ARN
        - Principle of least privilege
7. Attach the IAM Role to the EC2 Instance
    - EC2 → Select instance
    - Actions → Security → Modify IAM Role
    - Attach the role created above
8. Test the Application
    - Use the EC2 public IP:
        - Initialize DB: http://<public-ip>/init
        - Add a note: http://<public-ip>/add?note=first_note
        - List notes: http://<public-ip>/list

---
</br>

# Policy Reference

``` json
Trust Policy
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```


``` json
Permissions Policy
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "ReadSpecificSecret",
			"Effect": "Allow",
			"Action": "secretsmanager:GetSecretValue",
			"Resource": "arn:aws:secretsmanager:<REGION>:<ACCOUNT ID>:secret:<SECRET NAME>"
		}
	]
}
```

</br>

---
## Troubleshooting Guide

### 1. Verify Network Connectivity to RDS

``` bash
# SSH into instance
cat /etc/os-release #find os release

# Linux Commands
# Ensures EC2 can connect to RDS endpoint via network
sudo yum install -y nc
nc -vz <rds-endpoint> 3306
```

### 2. Verify MySQL Connectivity

``` bash
# Install mysql
sudo dnf install -y mariadb105
mysql -h <rds-endpoint> -u <username> -p
```
### 3. Verify Secret Retrieval

``` bash
# If denied check creds match
aws secretsmanager get-secret-value --secret-id <SECRET NAME>
```

### 4. Check Systemd & App Logs
``` bash
# Check app logs
sudo systemctl list-units --type=service

sudo journalctl -u rdsapp -n 50

# Follow logs in real time 
# Attempt init in browser
sudo journalctl -u rdsapp.service -f
```
## Additional things to check

- Ensure no spaces exist in the ARN inside the IAM policy
 (GAVE ME TROUBLE!!!)
- Confirm SECRETID and REGION are correct in
 userdata.sh.
- If User Data changes, recreate the instance (User Data is only applied at launch)


### Inspect current environment variables
```bash
# check current secret value
sudo cat /etc/systemd/system/rdsapp.service
sudo systemctl show rdsapp | grep SECRET
echo $SECRET_ID
```
### Update SECRET_ID manually (temporary)
``` bash
# If you need to update environment variable
export SECRET_ID= <SECRET_NAME>
```
