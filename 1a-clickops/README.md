Here is the **ClickOps** (manual AWS Console) version of the deployment guide. This guide replicates the exact architecture from your Terraform code but allows you to build it step-by-step using the AWS web interface.

---

# 🖱️ Manual AWS Deployment Guide (ClickOps)

This guide walks you through deploying the secure **EC2 + RDS + Secrets Manager** architecture manually.

## ✅ Prerequisites

* An active AWS Account.
* Region: **US East 2 (Ohio)** (recommended to match the guide, but any region works).
* A text editor to prepare your User Data script.

---

## 1. 🌐 Networking Setup (VPC)

*Goal: Create the isolated network for your resources.*

1. Go to **VPC Service** > **Your VPCs** > **Create VPC**.
* **Name:** `lab-vpc`
* **IPv4 CIDR:** `10.14.0.0/16`
* **Tenancy:** Default.
* Click **Create VPC**.


2. **Create Subnets** (Side menu > Subnets > Create subnet):
* Select `lab-vpc`.
* **Subnet 1 (Public):** Name `public-1`, AZ `us-east-2a`, CIDR `10.14.1.0/24`.
* **Subnet 2 (Public):** Name `public-2`, AZ `us-east-2b`, CIDR `10.14.2.0/24`.
* **Subnet 3 (Private):** Name `private-1`, AZ `us-east-2a`, CIDR `10.14.11.0/24`.
* **Subnet 4 (Private):** Name `private-2`, AZ `us-east-2b`, CIDR `10.14.12.0/24`.


3. **Create Internet Gateway** (Side menu > Internet gateways):
* Name: `lab-igw`.
* Click **Create**, then **Actions** > **Attach to VPC** > Select `lab-vpc`.


4. **Configure Route Tables**:
* **Public RT:** Go to Route Tables > Create `public-rt` > Select `lab-vpc`.
* **Routes:** Edit routes > Add route `0.0.0.0/0` targeting `Internet Gateway` (`lab-igw`).
* **Associations:** Subnet associations > Edit > Select `public-1` and `public-2`.


* **Private RT:** Create `private-rt` > Select `lab-vpc`.
* **Routes:** Leave as default (local only).
* **Associations:** Select `private-1` and `private-2`.





---

## 2. 🛡️ Security Groups

*Goal: Create the firewalls.*

1. Go to **VPC** > **Security Groups** > **Create security group**.
2. **EC2 Security Group:**
* **Name:** `ec2-sg`
* **VPC:** `lab-vpc`
* **Inbound Rules:**
* Type: **HTTP**, Source: `Anywhere-IPv4` (0.0.0.0/0).
* Type: **SSH**, Source: **My IP** (for security).


* **Outbound Rules:** Leave default (Allow all).


3. **RDS Security Group:**
* **Name:** `rds-sg`
* **VPC:** `lab-vpc`
* **Inbound Rules:**
* Type: **MySQL/Aurora**, Source: **Custom** > Select the `ec2-sg` you just created.


* **Outbound Rules:** Leave default.



---

## 3. 🗄️ Database (RDS)

*Goal: Create the database first so we have the endpoint for the Secret.*

1. Go to **RDS** > **Subnet groups** > **Create DB subnet group**.
* **Name:** `db-subnet-group`
* **VPC:** `lab-vpc`
* **Add subnets:** Select the AZs (us-east-2a/b) and choose the **Private** subnets (`10.14.11.0/24`, `10.14.12.0/24`).


2. Go to **Databases** > **Create database**.
* **Method:** Standard create.
* **Engine:** MySQL (Version 8.0.x).
* **Templates:** Free Tier.
* **Settings:**
* **DB Instance Identifier:** `mysql`
* **Master username:** `dbadmin`
* **Master password:** Create a strong password (e.g., `SuperSecret123!`). **Remember this!**


* **Instance configuration:** `db.t3.micro`.
* **Connectivity:**
* **VPC:** `lab-vpc`
* **Subnet group:** `db-subnet-group`
* **Public access:** **No**.
* **VPC security group:** Choose existing > `rds-sg` (Remove the "default" one).


* **Additional configuration** (Expand this section):
* **Initial database name:** `labdb` (Crucial! If you miss this, the app will fail).


* Click **Create database**.


3. **Wait** for the status to turn "Available". Copy the **Endpoint** URL (e.g., `mysql.cw...us-east-2.rds.amazonaws.com`).

---

## 4. 🔐 Secrets Manager

*Goal: Store the credentials so EC2 can read them.*

1. Go to **Secrets Manager** > **Store a new secret**.
2. **Secret type:** Select **"Other type of secret"** (Do NOT select "Credentials for RDS database" as we need a custom JSON format for the script).
3. **Key/value pairs:** Add the following rows exactly:
* `username` : `dbadmin`
* `password` : `SuperSecret123!` (The one you just created).
* `host` : Paste the RDS Endpoint.
* `port` : `3306`
* `dbname` : `labdb`


4. **Next**.
5. **Secret name:** `lab/rds/mysql` (Must match the script default).
6. **Next** > **Next** > **Store**.

---

## 5. 🆔 IAM Role

*Goal: Give EC2 permission to read the secret.*

1. Go to **IAM** > **Roles** > **Create role**.
2. **Trusted entity type:** AWS Service > **EC2**.
3. **Add permissions:** Click **Create policy**.
* **Service:** Secrets Manager.
* **Actions:** `GetSecretValue`.
* **Resources:** Paste the ARN of the secret you just created.
* Name the policy `SecretsAccessPolicy` and create it.
* Back in the "Create role" tab, hit Refresh, search for `SecretsAccessPolicy`, and select it.
4. **Role name:** `ec2-role`.
5. Click **Create role**.

---

## 6. 💻 Compute (EC2)

*Goal: Launch the web server.*

1. Go to **EC2** > **Instances** > **Launch instances**.
2. **Name:** `Web Server`.
3. **OS Image:** Amazon Linux 2023.
4. **Instance Type:** `t3.micro`.
5. **Key pair:** Create a new one or select an existing one (for SSH access).
6. **Network settings:**
* **VPC:** `lab-vpc`
* **Subnet:** `public-1` (Ensure "Auto-assign public IP" is **Enabled**).
* **Security groups:** Select existing > `ec2-sg`.


7. **Advanced details:**
* **IAM instance profile:** Select `ec2-role`.
* **User data:** Copy and paste the 1a_user_data.sh script.

8. Click **Launch instance**.

---

## 7. 🧪 Verification

1. Go to the **EC2 Console** and click on your instance.
2. Copy the **Public IPv4 address**.
3. Open your browser and test the connection:
* **Home:** `http://<YOUR-IP>` (Should see the "EC2 -> RDS Notes App" text).
* **Init DB:** `http://<YOUR-IP>/init` (Initializes the table).
* **Add Note:** `http://<YOUR-IP>/add?note=ClickOpsIsHardWork`
* **List Notes:** `http://<YOUR-IP>/list`