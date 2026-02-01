# **📄 Incident Report — RDS Connectivity Failure**

## **Incident Title**
RDS Connectivity Failure Due to Misconfigured Security Group Port

## **Date of Incident**
1/19/2026 | 8:45PM

## **Reported By**
Automated Chaos Engineering Injection (no alert received)

---

# **1. Summary**
During a chaos engineering exercise, a failure was injected into an AWS environment consisting of a VPC with a public EC2 instance and a private RDS instance. The EC2 instance retrieves database credentials exclusively through AWS Secrets Manager and Parameter Store using a least‑privilege IAM role. The RDS‑backed application allows users to initialize and write to the database via `http://<public-ip>/init`.

The expected behavior is that any database connectivity issues are logged to CloudWatch and trigger an SNS alert. However, due to incomplete CloudWatch and SNS configuration, no alert was generated when the failure occurred. Manual investigation through AWS CloudShell revealed that the RDS security group was misconfigured to allow traffic on port **3307** instead of the required **3306**, causing the application to lose database connectivity.

Correcting the security group rule restored normal functionality.

---

# **2. Impact**
- Application unable to connect to the RDS database  
- `/init` and other DB‑dependent endpoints failed  
- No CloudWatch alarm or SNS alert was triggered  
- Required manual investigation to identify root cause  

No data loss occurred.

---

# **3. Detection**
The issue was **not** detected by automated monitoring due to misconfigured CloudWatch alarms and SNS notifications.

The issue was detected manually when the application became unresponsive and database operations failed.

---

# **4. Root Cause**
A misconfiguration in the **RDS security group inbound rule** allowed MySQL traffic on **port 3307** instead of the required **3306**. This prevented the EC2 instance from establishing a database connection.

---

# **5. Timeline**

| Time | Event |
|------|--------|
| T0 | Chaos engineering failure injected (unknown to operator) |
| T0 + X | Application stops connecting to RDS |
| No alert | CloudWatch/SNS misconfigured → no notification |
| Investigation begins | Operator checks Secrets Manager → values unchanged |
| Investigation continues | RDS instance checked → available and healthy |
| Investigation continues | Security groups reviewed |
| T0 + Y | Misconfigured inbound rule discovered (3307 instead of 3306) |
| Fix applied | Security group updated to allow port 3306 |
| Recovery | Application connectivity restored |


---
# ** CLI Commands Used **

``` bash
# Verify Status of RDS instance
aws rds describe-db-instances \
  --db-instance-identifier lab-rds
```

``` bash
# Verify I am able to get Secrets Value
aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
```
``` bash
# Verify Security Groups
aws ec2 describe-security-groups \
  --group-ids <RDS_SG_ID>
```


---
# **6. Resolution**
The RDS security group inbound rule was corrected:

- Removed incorrect rule: **TCP 3307**
- Added correct rule: **TCP 3306** from EC2 security group

After updating the rule, the EC2 instance successfully connected to RDS and the application resumed normal operation.

---

# **7. Lessons Learned**

### **What Went Well**
- Manual investigation through CloudShell was systematic and effective  
- IAM least‑privilege design ensured secure access to Secrets Manager and Parameter Store  
- Root cause was identified without needing to redeploy infrastructure  

### **What Didn’t Go Well**
- CloudWatch alarms and SNS notifications were not configured correctly  
- No automated alerting meant delayed detection 

---

# **8. Preventive Actions**

### **To Reduce MTTR (Mean Time to Recovery)**
- Fully configure CloudWatch metric filters, alarms, and SNS notifications  
- Add dashboards to visualize DB connection metrics  

### **To Prevent Recurrence**
- Implement infrastructure validation checks (e.g., Terraform `aws_security_group_rule` tests)  
- Add automated port validation in CI/CD pipeline  
- Use AWS Config rules to detect non‑standard MySQL ports  

---

# **9. Current Status**
✔️ Issue resolved  
✔️ Application operational  
⚠️ Monitoring improvements pending 

# **10. Fix Applied**
Cleared SNS subscriptions that were pending from previous terraform runs
Updated Cloud Watch config 
Simulated RDS failure and recieved proper alert notification