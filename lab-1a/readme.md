# Class 7 Armageddon

### EC2 Web App → RDS (MySQL) “Notes” App Goal

Goal: </br>
Deploy a simple web app on an EC2 instance that can: Insert a note into RDS MySQL List notes from the database

Requirements:
+ RDS MySQL instance in a private subnet
+ EC2 instance running a Python Flask app 
+ Security groups allowing EC2 → RDS on port 3306
+   Credentials stored in AWS Secrets Manager

</br>
Resources Needed: </br>
VPC, Security Groups, IGW, EIP, NAT, Route Tables, EC2, RDS, Secrets Manager, IAM

---

</br>

# Console Instructions

Lab A
1. Create custom VPC with 1 public subnet and 2 private subnets
2. Create RDS database in private subnet
    + Take note of below
        + DB Username
        + DB Password
        + DB Endpoint (Troubleshooting)
3. Create EC2 Instance in public subnet
    +   Create Keypair
    +   Upload RDSApp script into userdata (Update userdata.sh SERCETID & REGION in script)
4. Create Security Group
	+ EC2 SG
		+ Inbound: Port 80 & 22
            + 0.0.0.0/0
        + Outbound: Default
	+ RDS SG
		+ Inbound: Port 3306
		    + Link to EC2 Security Group
        + Outbound: Default
5. Create Secret
    + Give Secret Name and take note of this (VERY IMPORTANT) 
	+ Link to created RDS
	+ Insert sensitive info from RDS login (VERY IMPORTANT)
    + Take note of ARN
6. Create IAM Trust Policy
	+ IAM > Access Management > Roles > Create Role
    + Select AWS service > EC2 > Next
    + Do not add Permissions yet > Next
	+ Give Role a Name & Dscription > Create Role
    + After creating select created role then go to Permissions
    + Add Permission Policy > Create inline policy 
    + Permission policy (Visual Editor)
        + Action: GetSecretValue (Least Privilege)
        + Effect: Allow
        + Attach Secret ARN (Leave -> mysql*) 
7. Attach Trust Policy to EC2 instance
    + EC2 > Select Running EC2 > Actions > Security > Modify IAM Role
    + Attach create Trust Policy  
8. Ready to Test! Use below URLs to connect to database
	+ http://{public-ip}/init
	+ http://{public-ip}/add?note=first_note
	+ http://{public-ip}/list

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
# Having Issues?
Troubleshooting

Ensure DB Network Connection
+ SSH into instance

``` bash

cat /etc/os-release #find os release

# Linux Commands
# Ensures EC2 can connect to RDS endpoint via network
sudo yum install -y nc
nc -vz <rds-endpoint> 3306

```

Ensure DB mysql connection

``` bash
# Ensures EC2 can connect to mysql
sudo dnf install -y mariadb105
mysql -h <rds-endpoint> -u <username> -p

```
Ensure Secret Retrieval

``` bash
# If denied check creds match
aws secretsmanager get-secret-value --secret-id <SECRET NAME>

```

Check systemctl & app logs
``` bash
# Check app logs
sudo systemctl list-units --type=service

sudo journalctl -u rdsapp -n 50


# Follow logs in real time 
# Attempt init in browser
sudo journalctl -u rdsapp.service -f

```
## Other things to look for

+ Make sure there are no spaces in the ARN json policy (GAVE ME TROUBLE!!!)
+ Ensure SECRETID & REGION are updated in userdata.sh. If not updated recreate instance and use updated script.
+ If you have to update the script file it is best to just spin up a new instance because of caching

MORE ON THIS
```bash
# check current secret value
sudo cat /etc/systemd/system/rdsapp.service
sudo systemctl show rdsapp | grep SECRET
echo $SECRET_ID

# If you need to update environment variable
export SECRET_ID="classarm7/rds/mysql"
