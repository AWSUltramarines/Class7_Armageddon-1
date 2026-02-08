# Lab 1B Execution Record — Operations, Secrets & Incident Response

**Helga Stack: Observability & Recovery (us-east-2)**

---

## What I Built

Extended the Lab 1A EC2 → RDS application with operational resilience:

- Dual secret storage (Parameter Store + Secrets Manager)
- Centralized logging via CloudWatch with ERROR filtering
- Automated alerting via CloudWatch Alarms
- SNS email notifications
- **Live sabotage exercise** — real attacks from the group lead requiring detection and recovery

This wasn't about building new infrastructure — it was about making existing infrastructure **observable, monitorable, and recoverable**.

**Region:** us-east-2 (Ohio)  

**Account:** <Account ID>  

**Timeline:** Building on Lab 1A foundation

---

## Actual Resources Deployed

### Base Infrastructure (from Lab 1A)

| Resource | Actual Value |
| --- | --- |
| **AWS Account ID** | `<Account ID>` |
| **Region** | `us-east-2` |
| **RDS Instance** | `helga-rds01` |
| **RDS Endpoint** | `helga-rds01.chkce02amfxr.us-east-2.rds.amazonaws.com` |
| **DB Name / Port** | `labdb` / `3306` |
| **EC2 Instance** | `i-0b2ddc7d88b6b7bed` |
| **EC2 Role** | `helga-ec2-role01` |
| **EC2 SG** | `sg-012119988bf5e29f1` |
| **RDS SG** | `sg-01f5bc3e6b016dbb2` |
| **App** | Flask at `/opt/rdsapp/app.py`, systemd service `rdsapp` |
| **Secret ID** | `lab/rds/mysql` |
| **Log Group** | `/aws/ec2/lab-rds-app` |
| **Log File** | `/var/log/rdsapp/app.log` |
| **Alarm** | `lab-db-connection-failure-alarm` |

### Configuration Storage

| Resource | Value | Purpose |
| --- | --- | --- |
| **SSM Parameters** | `/lab/db/endpoint`, `/lab/db/port`, `/lab/db/name` | Configuration values (endpoints, ports) |
| **Secrets Manager** | `lab/rds/mysql` | Credentials (username, password, host, port) |

### Observability Stack

| Resource | Value |
| --- | --- |
| **CloudWatch Log Group** | `/aws/ec2/lab-rds-app` |
| **Log File** | `/var/log/rdsapp/app.log` |
| **CloudWatch Agent** | Installed on EC2, shipping logs to CloudWatch |
| **Metric Filter** | `lab-db-error-filter` — pattern: `ERROR` → metric: `DBConnectionErrors` |
| **Alarm** | `lab-db-connection-failure-alarm` — Sum ≥ 1 per 60s |
| **SNS Topic** | Email notifications to `brightwillie21@gmail.com` |

### IAM Policies Added

| Policy Name | Purpose | Actions |
| --- | --- | --- |
| **Existing:** `AWS_EC2_Secrets_Access` | Read Secrets Manager | `secretsmanager:GetSecretValue` |
| **New:** `lab-ssm-read` (inline) | Read SSM Parameters | `ssm:GetParameter`, `ssm:GetParameters` |
| **New:** `CloudWatchAgentServerPolicy` | Ship logs to CloudWatch | `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`, etc. |

### Application Changes

| Component | Change |
| --- | --- |
| **Flask App** | Modified `get_conn()` to explicitly log `ERROR` on DB failures |
| **systemd Service** | Redirected logs from journald to `/var/log/rdsapp/app.log` |

---

## Key Challenges Solved

### 1. SSM Access Denied (IAM Troubleshooting)

**Problem:** EC2 role worked for Secrets Manager but threw `AccessDeniedException` when trying to read SSM Parameters

**Root Cause:** The lab instructions said "update the EC2 instance role policies" but **did not provide the actual IAM policy JSON**. Figuring out the correct permissions was the skill being tested.

**Fix:** Created inline policy `lab-ssm-read`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadLabParameters",
      "Effect": "Allow",
      "Action": ["ssm:GetParameter", "ssm:GetParameters"],
      "Resource": "arn:aws:ssm:us-east-2:<Account ID>:parameter/lab/db/*"
    }
  ]
}
```

**Troubleshooting Checklist Executed:**

- ✅ Trust relationship: `ec2.amazonaws.com` confirmed as trusted entity
- ✅ Exact ARN match: Secret ARN verified character-by-character against policy Resource
- ✅ KMS check: Using default `aws/secretsmanager` key — no extra `kms:Decrypt` needed
- ✅ VPC endpoint check: No Secrets Manager VPC endpoint exists — not a factor

**Lesson:** The gap between "what the instructions say" and "what you actually have to do" is the skill being tested in real-world cloud work.

---

### 2. Log Redirection (systemd vs CloudWatch)

**Problem:** Flask app runs as systemd service `rdsapp`. Logs went to **journald** by default — not a file. CloudWatch Agent reads files more easily.

**Fix:** Redirected systemd output to file:

```bash
# Added to /etc/systemd/system/rdsapp.service [Service] section
StandardOutput=append:/var/log/rdsapp/app.log
StandardError=append:/var/log/rdsapp/app.log

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart rdsapp
```

**Verification:** `sudo tail -f /var/log/rdsapp/app.log` showed Flask startup messages

---

### 3. ERROR Logging (Application Code Modification)

**Problem:** Flask app didn't explicitly log the word `ERROR` on DB connection failures. Without this, CloudWatch metric filter wouldn't trigger the alarm.

**Fix:** Modified `get_conn()` in `/opt/rdsapp/app.py

```python
def get_conn():
    try:
        c = get_db_creds()
        host = c["host"]
        user = c["username"]
        password = c["password"]
        port = int(c.get("port", 3306))
        db = c.get("dbname", "labdb")
        return pymysql.connect(host=host, user=user, password=password,
                               port=port, database=db, autocommit=True)
    except Exception as e:
        print(f"ERROR: Database connection failed - {e}")
        raise
```

**Result:** Now when DB connections fail, `ERROR: Database connection failed` appears in logs — exactly what CloudWatch filters on.

---

### 4. CloudWatch IAM (Permission Scope Mismatch)

**Problem:** Added `CloudWatchAgentServerPolicy` but agent still couldn't describe log groups

**Root Cause:** `DescribeLogStreams` (operates at stream level) and `DescribeLogGroups` (operates at group level) are two different permissions requiring different resource scopes.

**Lesson:** Had to add `log-group:*` resource for `DescribeLogGroups` to work.

---

### 5. Git Bash Path Conversion (Windows CLI Issue)

**Problem:** Git Bash on Windows converts paths starting with `/` to Windows paths (e.g., `/lab/db/endpoint` → `C:/Program Files/Git/lab/db/endpoint`)

**Fix:** Prefixed all commands with `MSYS_NO_PATHCONV=1`:

```bash
MSYS_NO_PATHCONV=1 aws ssm put-parameter \
  --name /lab/db/endpoint \
  --value "helga-rds01.chkce02amfxr.us-east-2.rds.amazonaws.com" \
  --type SecureString --overwrite --region us-east-2
```

**Lesson:** Platform-specific quirks matter when scripting AWS CLI operations.

---

## Live Sabotage Exercise

Instead of the scripted incident simulation in the lab guide, the group lead was given least-privilege IAM credentials and performed **live sabotage attacks** against the running infrastructure.

### Attacks Executed

| Attack | Target | Poisoned Value | Correct Value | Error Seen |
| --- | --- | --- | --- | --- |
| **Typo Attack** | SSM `/lab/db/endpoint` | `he1ga-rds01...` (numeral `1`) | `helga-rds01...` (letter `l`) | `Unknown MySQL server host` |
| **Prefix Injection** | SSM `/lab/db/name` | `t_labdb` | `labdb` | `Unknown database 't_labdb'` |
| **Username Poison** | Secrets Manager `username` | `adm1n` (numeral `1`) | `admin` (letter `i`) | `Access denied for user 'adm1n'` |

**Detection method:** CloudWatch Logs showed exact error messages. Cross-referencing SSM/Secrets Manager values against actual RDS configuration revealed the character substitutions.

**Key lesson:** Visually similar character substitution (`1`/`l`, `1`/`i`, `0`/`O`) is a classic attack vector. Always verify values programmatically, not visually.

### Recovery Commands Executed

```bash
# Fix 1: Correct SSM endpoint typo
MSYS_NO_PATHCONV=1 aws ssm put-parameter \
  --name /lab/db/endpoint \
  --value "helga-rds01.chkce02amfxr.us-east-2.rds.amazonaws.com" \
  --type SecureString --overwrite --region us-east-2

# Fix 2: Correct SSM db name
MSYS_NO_PATHCONV=1 aws ssm put-parameter \
  --name /lab/db/name \
  --value "labdb" \
  --type String --overwrite --region us-east-2

# Fix 3: Correct Secrets Manager username
MSYS_NO_PATHCONV=1 aws secretsmanager update-secret \
  --secret-id lab/rds/mysql \
  --secret-string '{"username":"admin","password":"<REDACTED>","host":"helga-rds01.chkce02amfxr.us-east-2.rds.amazonaws.com","port":"3306"}' \
  --region us-east-2
```

Group lead access keys: **DEACTIVATED** after exercise completed.

### Windows Git Bash Issue Encountered

Git Bash on Windows converts paths starting with `/` to Windows paths (e.g., `/lab/db/endpoint` → `C:/Program Files/Git/lab/db/endpoint`). Fixed by prefixing all commands with `MSYS_NO_PATHCONV=1`.

---

## Verification — 5-Check Script (All Passed)

Wrote a bash verification script that programmatically checks all stored values match actual RDS:

```bash
# Checks performed:
# 1. RDS status = "available"                    ✅
# 2. SSM /lab/db/endpoint matches RDS endpoint   ✅
# 3. Secrets Manager host matches RDS endpoint   ✅
# 4. SSM /lab/db/port = 3306                     ✅
# 5. SSM /lab/db/name = labdb                    ✅
# Result: 5/5 passed after fixes applied
```

---

## Verification Commands

### SSM Parameters

```bash
aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption
```

### Secrets Manager

```bash
aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
```

### CloudWatch Log Group

```bash
aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/lab-rds-app
```

### Filter Logs for Errors

```bash
aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"
```

### CloudWatch Alarm Status

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix lab-db-connection
```

### RDS Endpoint (for cross-reference)

```bash
aws rds describe-db-instances \
  --db-instance-identifier lab-mysql \
  --query "DBInstances[].Endpoint.Address"
```

---

## Skills Demonstrated

- **Dual Secret Storage Pattern** — Parameter Store for config, Secrets Manager for credentials
- **IAM Troubleshooting** — Diagnosed missing permissions, scoped policies correctly, understood resource-level permission differences
- **Observability Engineering** — Centralized logging, metric filters, symptom-based alarms
- **Incident Response** — Detection via logs, diagnosis via stored config, recovery without redeploy
- **Application Instrumentation** — Modified Flask code to log errors explicitly
- **systemd Management** — Redirected service logs to files for CloudWatch ingestion
- **Real-World Attack Detection** — Character substitution attacks, log correlation, value verification
- **CLI Proficiency** — AWS CLI for diagnostics, updates, and recovery
- **Platform Awareness** — Handled Windows Git Bash path conversion quirks

---

## Interview Talk Track

> "In Lab 1B, I took the working EC2-to-RDS application from Lab 1A and made it production-ready by adding observability and incident response capabilities. I implemented dual secret storage using Parameter Store for configuration and Secrets Manager for credentials, then set up CloudWatch Logs with metric filters and alarms. The real test came when the group lead performed live sabotage — three character substitution attacks on endpoints, database names, and usernames. I detected all three through CloudWatch error logs, diagnosed the exact character changes by cross-referencing stored values against actual resources, and recovered the system using AWS CLI commands without any redeploy. The biggest lessons were that IAM permissions require exact resource scopes, symptom-based alarms catch more failure modes than cause-based alarms, and tooling matters — I had to work around Git Bash path conversion issues on Windows."
> 

---

## Reflection Questions (Lab Deliverables)

### A Why might Parameter Store still exist alongside Secrets Manager?

My top of mind thought would be because the secrets manager just stores the password to access the thing, and the parameter store holds the finer details of the individual infrastructure that you're building. You may change out the parameters of something like your RDS information (as in the resource number could change). And if it did change, you will want to have that track so that you know what infrastructure you're working on as you're scaling up.

**Additional context to strengthen this answer:**

- **Cost:** Parameter Store standard parameters are **free**. Secrets Manager charges ~$0.40/secret/month. For non-sensitive config, Parameter Store saves money.
- **Rotation:** Secrets Manager has **built-in automatic rotation** with Lambda integration. Parameter Store doesn't.
- **History:** Parameter Store existed first (2016); Secrets Manager came later (2018) specifically for credentials. Many orgs already had Parameter Store in place.
- **Access Patterns:** Parameter Store is optimized for high-throughput reads of config values; Secrets Manager is optimized for secure credential storage with audit trails.

**Bottom Line:** Use both intentionally — Parameter Store for config, Secrets Manager for credentials.

---

### B What breaks first during secret rotation?

My best guess to this question is that the passwords themselves break, and that it won't rotate properly. You’ll have to go in and reconfigure the passwords. That's what I think first.

**What actually breaks (technical precision):**

The **application layer** breaks first — not the passwords themselves. Here's the sequence:

1. Secrets Manager rotates the password (updates the secret)
2. A Lambda function updates the password **on the database side**
3. But your **application still has the OLD password cached in memory**
4. App tries to connect → "Access denied" → Outage

**What Breaks First:** The **application** — because it's holding stale credentials while the DB and Secrets Manager have already moved on.

**The Fix:** Applications must re-fetch credentials on connection failure (or use short TTL caching). This is why in the recovery exercise, restarting the app was necessary — it needed to pick up the new credentials.

---

### C Why should alarms be based on symptoms instead of causes?

Alarms are based on symptoms - things that are happening. It allows us to be more reactive to the infrastructure because it's similar. I would think of it like a doctor. A cause is something you would need to diagnose; it's a diagnosis, and you can't go off of a cause based on the thing because that doesn't get to the root of the problem. You have to have an understanding of what is happening (the symptoms) and then the programmer can analyze that data and identify the cause and prescribe the right remedy. There is a difference in medicine - the remedy could be healing or a poison. Basing alarms on a cause removes that ability to pick the right remedy we need and we may put in a poison instead.

**Technical precision to add:**

- **Symptom-based alarm:** "DB connections are failing" → Catches **ANY** cause (SG change, credential issue, DB down, network partition, DNS failure, etc.)
- **Cause-based alarm:** "Security Group was modified" → Only catches **ONE** specific cause, misses everything else

**Why Symptoms Win:**

1. You can't predict every failure mode
2. A single symptom alarm catches multiple root causes
3. Detection comes first, diagnosis comes second
4. Users don't care **WHY** it's broken — they care that it **IS** broken

**Lab 1B Example:** The alarm fired on `ERROR` logs (a symptom). It would have fired whether the cause was SG blocking, RDS stopped, or bad credentials. This is why it's more resilient.

---

### D How does this lab reduce mean time to recovery (MTTR)?

And the way this lab reduces mean time to recovery. It gives you a comprehensive understanding and puts you through a scenario where you can experiment with failures within the system. Then you have to solve and figure out that issue without having to redeploy the infrastructure because redeploying it takes a long time and also costs money. Whereas you fixing it within keeps the system going and your updating it.

**Full breakdown of how each component reduces MTTR:**

MTTR = **Detection** + **Diagnosis** + **Recovery**. This lab optimized all three:

| Component | How It Reduces MTTR |  |
| --- | --- | --- |
| **CloudWatch Alarm** | Faster **detection** — you know immediately, not after user complaints |  |
| **CloudWatch Logs** | Faster **diagnosis** — error messages tell you what's wrong |  |
| **Parameter Store** | Faster **recovery** — known-good config is pre-stored, no guessing |  |
| **Secrets Manager** | Faster **recovery** — correct credentials are retrievable instantly |  |
| **This Lab Documentation** | Faster **response** — documented runbook means no improvisation |  |

---

### E What would you automate next?

Right now, I had put all of this and did it in ClickOps and in the cloud shell, but I would instead make a Terraform configuration out of this so that I can instantly deploy the infrastructure every single time. Then, anytime I needed to make changes, I would only have to adjust the code instead of having to do ClickOps.

**Additional automation targets worth mentioning:**

- **Auto-remediation:** Lambda triggered by the CloudWatch Alarm that automatically restores the SG rule (self-healing infrastructure)
- **Automated secret rotation:** Secrets Manager can rotate credentials on a schedule with zero human intervention
- **CI/CD pipeline:** Auto-deploy app changes with rollback on failure
- **Systems Manager Automation:** Runbooks that execute recovery steps automatically

---