**1C bonus C complete!**

# File tree:
Here is the file structure for this terraform deployment
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
├── 10-route53          # Hosted zone and record management
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
___

# Additional *(add this)*:
In order to make this deployment work effectively you should make a `terraform.tfvars` file. Ex:
```rb
db_username      = "engineer"
alert_email      = "jeeves@hotmail.com"
project_name     = "armage"
environment      = "dev"
```

___

# 1C bonus C instructions:

This part of the assignment elevates your infrastructure to a professional level by automating your domain management and encryption. By the end, your domain will automatically point to your secure load balancer using Terraform-managed DNS.

### 🛰️ Assignment Breakdown

* **🌌 The Nav Computer (Route 53)**: You are automating the creation of a Hosted Zone and the DNS records needed to prove you own your domain.
* **🛡️ The Hangar Bay (HTTPS Listener)**: You are updating your ALB to terminate TLS/SSL traffic on Port 443 using your ACM certificate.
* **📡 Holographic Signage (ALIAS Record)**: You are creating a specific record that points `app.daequanbritt.com` directly to your Load Balancer's DNS name.
* **🛠️ Learning Friction**: You must choose between **DNS validation** (fully automated in Terraform) or **Email validation** (requires manual clicking).
* **🚀 Real Engineering**: This setup mirrors how enterprise companies handle secure public entry for private applications.

---

### 📝 To Do

1. **Update Variables**: Append the new `manage_route53_in_terraform` and `route53_hosted_zone_id` variables to your `99-variables.tf` file.
2. **Create DNS File**: Add a new file named `bonus_b_route53.tf` to hold your Hosted Zone and ALIAS record logic.
3. **Refactor Listener**: Update your HTTPS listener in `07-alb-dns.tf` to use `aws_acm_certificate.cert.arn` and add a `depends_on` block pointing to your DNS validation resource.
4. **Append Outputs**: Add the `chewbacca_route53_zone_id` and `chewbacca_app_url_https` to your `98-outputs.tf` so you can easily find your navigation coordinates.
5. **Run Validation**: Use the AWS CLI to confirm your Hosted Zone exists, your app record is active, and your certificate status is `ISSUED`.
6. **Final Test**: Perform a `curl -I` on your HTTPS URL to confirm you receive a `200 OK` response.

---

### 📦 Deliverables

1. **The Codebase**: A complete set of `.tf` files (00 through 08 plus variables/outputs) that successfully deploy the full stack.
2. **CLI Verification Screenshots**:
* Output of `aws route53 list-resource-record-sets` showing your ALIAS record.
* Output of `aws acm describe-certificate` showing the status as `ISSUED`.


3. **Success Proof**: A screenshot or text output of the `curl -I` command showing a successful HTTPS connection to `app.daequanbritt.com`.
4. **Observability Check**: A screenshot of your CloudWatch Dashboard showing active metrics from your Load Balancer and EC2 instance.
