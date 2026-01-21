# Class7_Armageddon-1

Within these folders you will find each part of Armageddon.

### 1A via Terraform and ClickOps
![image](rds-secrets.png)
___

**1C bonus C complete!**

# File tree:
Here is the current file structure for this terraform deployment
```
.
├── 00-auth.tf          # Provider & S3 Remote State Backend
├── 01-IAM.tf           # Roles, policies & instance profiles
├── 02-secrets.tf       # Secrets Manager & SSM Parameter Store
├── 03-network.tf       # VPC, Subnets, NAT GW, & Endpoints 
├── 04-sg.tf            # ALB, EC2, and RDS Security Group rules
├── 05-main.tf          # Private EC2 Web Server & RDS MySQL Instance
├── 06-logging.tf       # SNS Topic & CloudWatch Log Metric Filters
├── 07-alb-dns.tf       # Load Balancer & SSL Certificate
├── 08-dashboard.tf     # Visual App Health Dashboard & 5xx Alarm
├── 09-waf.tf           # Cross-site scripting (XSS) & SQL injection protection
├── 1a_user_data_tf.sh  # App initialization script with logging
├── 98-outputs.tf       # Dynamic verification URLs and ARNs
├── 99-variables.tf     # Project and naming variable definitions
└── terraform.tfvars    # Environment-specific values (armage-dev)
```
___

Additionally there is the evidence file paths:
```
.
├── proof-1b            # The evidence for 1b including commands used
|   └── questions       # Answers to questions for 1b
├── proof-1c-a          # The evidence for 1c bonus A including commands
├── proof-1c-b          # The evidence for 1c bonus B including commands
└── proof-1c-c          # The evidence for 1c bonus C including commands. See the file 'A-GRADEME.md' for a 1 page document
```
