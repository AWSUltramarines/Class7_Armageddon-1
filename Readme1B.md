```markdown
# Lab 1B — Operations, Secrets & Incident Response

## Purpose
Lab 1A built a working system. Lab 1B teaches you to **operate, observe, break, and recover** that system. This is where most real cloud work lives — not in initial deployment, but in ongoing operations.

## What This Lab Adds
| Capability | Service | Why It Matters |
|------------|---------|----------------|
| Dual secret storage | SSM Parameter Store + Secrets Manager | Config vs. credentials separation |
| Centralized logging | CloudWatch Logs | Single pane for diagnostics |
| Automated alerting | CloudWatch Alarms | Detect failures before users do |
| Incident response | CLI + stored config | Recover without redeploying |

## Architecture (Extended from 1A)
```

┌─────────────────────────────────────────────────────────────────┐

│                        VPC: Helga                               │

│  ┌──────────────────┐              ┌──────────────────────┐     │

│  │   Public Subnet  │              │   Private Subnet     │     │

│  │   ┌──────────┐   │              │   ┌────────────┐     │     │

│  │   │   EC2    │───┼──────────────┼──▶│    RDS     │     │     │

│  │   │  Flask   │   │    :3306     │   │  lab-mysql │     │     │

│  │   └────┬─────┘   │              │   └────────────┘     │     │

│  └────────┼─────────┘              └──────────────────────┘     │

└───────────┼─────────────────────────────────────────────────────┘

│

▼

┌─────────────────────────────────────────────────────┐

│               AWS Management Services               │

│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │

│  │  Parameter  │  │   Secrets   │  │ CloudWatch  │  │

│  │    Store    │  │   Manager   │  │    Logs     │  │

│  │ /lab/db/*   │  │lab/rds/mysql│  │ /aws/ec2/   │  │

│  └─────────────┘  └─────────────┘  └──────┬──────┘  │

│                                           │         │

│                                    ┌──────▼──────┐  │

│                                    │  Metric     │  │

│                                    │  Filter     │  │

│                                    │  (ERROR)    │  │

│                                    └──────┬──────┘  │

│                                           │         │

│                                    ┌──────▼──────┐  │

│                                    │ CloudWatch  │  │

│                                    │   Alarm     │  │

│                                    └─────────────┘  │

└─────────────────────────────────────────────────────┘

```

## Stored Configuration

### Parameter Store (`/lab/db/*`)
| Parameter | Value | Type |
|-----------|-------|------|
| `/lab/db/endpoint` | [lab-mysql.chkce02amfxr.us-east-2.rds.amazonaws.com](http://lab-mysql.chkce02amfxr.us-east-2.rds.amazonaws.com) | String |
| `/lab/db/port` | 3306 | String |
| `/lab/db/name` | labdb | String |

### Secrets Manager (`lab/rds/mysql`)
```

{

"username": "admin",

"password": "",

"host": "[lab-mysql.chkce02amfxr.us-east-2.rds.amazonaws.com](http://lab-mysql.chkce02amfxr.us-east-2.rds.amazonaws.com)",

"port": 3306

}

```

## IAM Policies Added

### SSM Parameter Store Access
```

{

"Version": "2012-10-17",

"Statement": [

{

"Sid": "ReadLabParameters",

"Effect": "Allow",

"Action": ["ssm:GetParameter", "ssm:GetParameters"],

"Resource": "arn:aws:ssm:us-east-2:919113286081:parameter/lab/db/*"

}

]

}

```

### CloudWatch Logs Access
```

{

"Version": "2012-10-17",

"Statement": [

{

"Effect": "Allow",

"Action": [

"logs:CreateLogGroup",

"logs:CreateLogStream",

"logs:PutLogEvents",

"logs:DescribeLogStreams",

"logs:DescribeLogGroups"

],

"Resource": [

"arn:aws:logs:us-east-2:919113286081:log-group:/aws/ec2/lab-rds-app:*",

"arn:aws:logs:us-east-2:919113286081:log-group:*"

]

}

]

}

```

## Observability Stack

### CloudWatch Agent Config
```

{

"logs": {

"logs_collected": {

"files": {

"collect_list": [

{

"file_path": "/var/log/rdsapp/app.log",

"log_group_name": "/aws/ec2/lab-rds-app",

"log_stream_name": "{instance_id}",

"timezone": "UTC"

}

]

}

}

}

}

```

### Metric Filter
- **Name:** `lab-db-error-filter`
- **Pattern:** `ERROR`
- **Namespace:** `Lab/Application`
- **Metric:** `DBConnectionErrors`

### CloudWatch Alarm
- **Name:** `lab-db-connection-failure-alarm`
- **Metric:** `DBConnectionErrors`
- **Threshold:** >= 1 per minute
- **Action:** Transitions to ALARM state on DB failure

## Incident Simulation (Chaos Engineering)

### Method Used: Security Group Block
```

# Break connectivity

aws ec2 revoke-security-group-ingress \

--group-id sg-01f5bc3e6b016dbb2 \

--protocol tcp \

--port 3306 \

--source-group sg-012119988bf5e29f1

# Restore connectivity

aws ec2 authorize-security-group-ingress \

--group-id sg-01f5bc3e6b016dbb2 \

--protocol tcp \

--port 3306 \

--source-group sg-012119988bf5e29f1

```

### Results
- ✅ ERROR logs appeared in CloudWatch Logs
- ✅ Alarm transitioned to ALARM state
- ✅ Service recovered without redeployment
- ✅ Alarm returned to OK state after fix

## CLI Verification Commands
```

# Verify Parameter Store

aws ssm get-parameters \

--names /lab/db/endpoint /lab/db/port /lab/db/name \

--with-decryption

# Verify Secrets Manager

aws secretsmanager get-secret-value --secret-id lab/rds/mysql

# Verify Log Group

aws logs describe-log-groups --log-group-name-prefix /aws/ec2/lab-rds-app

# Check for ERROR logs

aws logs filter-log-events \

--log-group-name /aws/ec2/lab-rds-app \

--filter-pattern "ERROR"

# Verify Alarm State

aws cloudwatch describe-alarms --alarm-name-prefix lab-db-connection

```

## Reflection Questions & Answers

**A) Why might Parameter Store still exist alongside Secrets Manager?**
> Parameter Store is free for standard parameters and optimized for config values. Secrets Manager costs ~$0.40/secret/month but offers automatic rotation. Use both: Parameter Store for config, Secrets Manager for credentials.

**B) What breaks first during secret rotation?**
> The application layer — it holds stale credentials in memory while the DB and Secrets Manager have already rotated. Apps must re-fetch credentials on connection failure.

**C) Why should alarms be based on symptoms instead of causes?**
> A symptom-based alarm ("DB connections failing") catches ANY cause (SG, credentials, DNS, etc.). A cause-based alarm only catches one specific failure mode. Detection first, diagnosis second.

**D) How does this lab reduce MTTR?**
> - CloudWatch Alarm → Faster detection
> - CloudWatch Logs → Faster diagnosis
> - Parameter Store + Secrets Manager → Faster recovery (known-good config pre-stored)

**E) What would you automate next?**
> Convert this entire stack to Terraform (IaC) so it's repeatable, reviewable, and recoverable. Also: auto-remediation Lambda triggered by alarms.

## Key Lesson
> "I can operate, monitor, and recover AWS workloads using proper secret management and observability."
> 
> This is mid-level engineer capability, not entry-level.

## Files in This Directory
- `evidence/` — Screenshots proving completion
- `policies/` — IAM policy JSON files
- `cloudwatch-agent-config.json` — Agent configuration
```

1. Answer:
- A) Why might Parameter Store still exist alongside Secrets Manager?

My top of mind thought would be because the secrets manager just stores the password to access the thing, and the parameter store holds the finer details of the individual infrastructure that you're building. You may change out the parameters of something like your RDS information (as in the resource number could change). And if it did change, you will want to have that track so that you know what infrastructure you're working on as you're scaling up.

- B) What breaks first during secret rotation?

My best guess to this question is that the passwords themselves break, and that it won't rotate properly, and you have to go in and reconfigure the passwords. That's what I think first.

**Review:** You're circling the issue but the real answer is about **timing and synchronization**. Here's what actually breaks:

1. Secrets Manager rotates the password (updates the secret)
2. A Lambda function updates the password **on the database side**
3. But your **application still has the OLD password cached in memory**
4. App tries to connect → "Access denied" → Outage

**What breaks first:** The **application layer** — because it's holding stale credentials while the DB and Secrets Manager have already moved on.

**The fix:** Applications must re-fetch credentials on connection failure (or use short TTL caching). This is why you saw the "restart your app" step in Option C recovery — the app needed to pick up the new credentials.

- C) Why should alarms be based on symptoms instead of causes?

When I say this shit, alarms are based on symptoms - things that are happening. It allows us to be more reactive to the infrastructure because it's similar. I would think of it like a doctor. A cause is something you would need to diagnose; it's a diagnosis, and you can't go off of a cause based on the thing because that doesn't get to the root of the problem. You have to have an understanding of what is happening (the symptoms) and then the programmer can analyze that data and identify the cause and prescribe the right remedy. There is a difference in medicine - the remedy could be healing or a poison. Having a cause removes that ability to pick the right remedy. We need and we may put in a poison instead.

- D) How does this lab reduce mean time to recovery (MTTR)?

And the way this lab reduces mean time to recovery. It gives you a comprehensive understanding and puts you through a scenario where you can experiment with failures within the system. Then you have to solve and figure out that issue without having to redeploy the infrastructure because redeploying it takes a long time and also costs money. Whereas you fixing it within keeps the system going and your updating it.

- E) What would you automate next?

Right now, I had put all of this and did it in ClickOps and in the cloud shell, but I would instead make a Terraform configuration out of this so that I can instantly deploy the infrastructure every single time. Then, anytime I needed to make changes, I would only have to adjust the code instead of having to do ClickOps.