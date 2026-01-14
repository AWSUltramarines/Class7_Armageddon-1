# ☁️ Secure Two-Tier AWS Deployment with Terraform

![image](rds-secrets.png)

## 📖 Overview

This project automates the deployment of a secure, two-tier web application architecture on AWS using **Terraform**. It features a **Python Flask** application running on EC2 that communicates with an **Amazon RDS (MySQL)** database.

The core philosophy of this deployment is **"Zero Hardcoded Credentials."** The database password is generated dynamically during deployment, stored in **AWS Secrets Manager**, and retrieved by the application at runtime using IAM authentication.

## ✨ Key Features

* **🔒 AWS Secrets Manager Integration:** Database credentials are never stored in code or configuration files. The EC2 instance fetches them programmatically at runtime.
* **🛡️ Least Privilege IAM:** The EC2 instance uses a dedicated IAM Role (`ec2-role`) with specific permissions to read only the required secret.
* **🕸️ Isolated Networking:**
* **Public Subnets:** Host the web server (EC2) with Internet Gateway access.
* **Private Subnets:** Host the database (RDS), accessible only from the web server.


* **🧱 Security Groups:** Strict firewall rules ensure the Database only accepts traffic from the Web Server's security group.
* **🐍 Automated App Deployment:** A `user_data` script automatically installs Python, Flask, and dependencies, and configures the application as a systemd service.

## 🏗️ Architecture

* **VPC:** Custom VPC with public and private subnets across two Availability Zones for high availability.
* **Compute:** Amazon Linux 2023 EC2 instance with `t3.micro` tier.
* **Database:** RDS MySQL 8.0 instance (`db.t3.micro`).
* **Secrets:** Randomly generated password stored in AWS Secrets Manager.

## 📂 Project Structure

| File | Description |
| --- | --- |
| `00-auth.tf` | Terraform provider configuration (AWS, Random, TLS) and S3 backend setup. 
|
| `01-IAM.tf` | IAM Roles and Policies granting EC2 permission to access Secrets Manager. 
|
| `02-secrets.tf` | Generates a random password and stores it in AWS Secrets Manager. 
|
| `03-network.tf` | VPC, Subnets, Route Tables, and Internet Gateway configuration. 
|
| `04-sg.tf` | Security Groups for EC2 (HTTP/SSH) and RDS (MySQL access from EC2). 
|
| `05-EC2.tf` | EC2 instance definition, SSH Key generation, and User Data script injection. 
|
| `06-RDS.tf` | RDS MySQL instance configuration. 
|
| `1a_user_data_tf.sh` | Bash script that installs Flask and configures the app to run on boot. 
|
| `99-variables.tf` | Input variables for CIDRs, Database names, and Instance types. 
| `terraform.tfvars` | (Optional) Input variable values if not using default

For example your tfvars file might look like this:

```rb
ssh_allowed_cidr = "0.0.0.0/0"
db_username = "cloudengineer"
```

## 🚀 Quick Start

### Prerequisites

* [Terraform](https://www.terraform.io/downloads) (v1.x+)
* [AWS CLI](https://aws.amazon.com/cli/) installed and configured with appropriate credentials.

### Deployment Steps

1. **Clone the repository:**
```bash
git clone <repository-url>
cd <repository-directory>

```

2. **Initialize Terraform:**
```bash
terraform init

```

3. **Review the Plan:**
```bash
terraform plan

```

4. **Deploy:**
```bash
terraform apply
# Type 'yes' to confirm

```

5. **Access the Application:**
Once the deployment is complete, locate the **Public IP** of the EC2 instance in the AWS Console (or Terraform outputs if configured).
* Open your browser and navigate to: `http://<EC2-PUBLIC-IP>`


### ⚙️ Configuration (Variables)

You can customize the deployment by creating a `terraform.tfvars` file or passing variables via command line.

| Variable | Description | Default |
| --- | --- | --- |
| `ssh_allowed_cidr` | **Critical:** Set this to your IP (`x.x.x.x/32`) to enable SSH. Default is disabled. | `""` |
| `allowed_http_cidrs` | List of IPs allowed to access the web app. | `["0.0.0.0/0"]` |
| `db_username` | Username of the database to create. | `"engineer"` |

## 🧪 Testing the Application

The Flask application includes the following endpoints:

1. **Initialize DB:** `http://<IP>/init`
* *First run only.* Creates the `notes` table in the database.


2. **Add Note:** `http://<IP>/add?note=HelloTerraform`
* Writes data to the secure RDS database.


3. **List Notes:** `http://<IP>/list`
* Reads data from the database.


## 🧹 Clean Up

To avoid ongoing AWS charges, destroy the resources when you are finished:

```bash
terraform destroy
# Type 'yes' to confirm

```

---

*Project maintained by [DaeQuan B./DevOpsEngineer]*