# Incident Runbook: Secrets Manager Credential Drift

**Description:** Application cannot authenticate with RDS due to invalid secret value.

### Step 1 — Confirm the Signal

* **Alarm Triggered**: The CloudWatch Alarm `lab-db-connection-failure`.


* **Impact**: Users visiting `https://app.daequanbritt.com/test-db` report a **500 Internal Server Error**.
* **Log Check**: Open CloudWatch Logs for `/aws/ec2/lab-rds-app` and look for the specific filter pattern: `"Database connection failed"`.



### Step 2 — Run Insights Triage 

Execute the following query in **CloudWatch Logs Insights** to confirm it is an authentication issue rather than a networking issue :

```sql
fields @timestamp, @message 
| filter @message like /DB|mysql|timeout|refused|Access denied|could not connect/ 
| sort @timestamp desc 
| limit 50

```

* **Analysis**: If hits appear for **"Access denied"**, the network path is open, but the password/username is rejected.


### Step 3 — Identify Root Cause 

* **Suspected Issue**: Manual modification of the secret `lab/rds/mysql` or an incorrect rotation.


* **Action**: Compare the current value in **Secrets Manager** with the expected value in your **Terraform State**.
* **Verification Command**:
```bash
terraform output -raw db_password

```


### Step 4 — Recovery & Resolution 

1. **Restore Secret**: Use the AWS CLI to push the "Known Good" password from your Terraform outputs back into Secrets Manager.


```bash
aws secretsmanager update-secret \
  --secret-id lab/rds/mysql \
  --secret-string "{\"username\":\"devsecopsengineer\",\"password\":\"$(terraform output -raw db_password)\",\"host\":\"$(terraform output -raw db_endpoint)\",\"port\":3306,\"dbname\":\"labdb\"}" \
  --region us-east-2

```


2. **Verify Connectivity**: Run a curl to the test endpoint:
```bash
curl -I https://app.daequanbritt.com/test-db

```


* **Expected Result**: `HTTP/2 200 OK` and a response of **"Database Connected!"**.


3. **Close Incident**: Confirm the CloudWatch Alarm returns to `OK` and logs show "Database connection successful".

---