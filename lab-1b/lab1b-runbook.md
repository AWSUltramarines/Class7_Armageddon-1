# **Incident Response Runbook — RDS Connectivity Failure**

A structured, repeatable guide for diagnosing and recovering from database connectivity failures in the AWS EC2 + RDS lab environment.

---

## **📌 Overview**

This runbook helps engineers:

- Confirm alerts  
- Investigate logs and metrics  
- Validate configuration sources  
- Check RDS, EC2, and network paths  
- Perform safe recovery  
- Validate system health  
- Document the incident  

Everything is CLI‑driven and follows on‑call best practices.

---

## **📣 1. Acknowledge the Alarm**

### **Check alarm state**
```bash
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
```

### **View alarm history (optional)**
```bash
aws cloudwatch describe-alarm-history \
  --alarm-name lab-db-connection-failure
```

---

## **🔍 2. Observe System Behavior**

### **Check application logs**
```bash
aws logs filter-log-events \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --filter-pattern "ERROR"
```

### **Check for DB‑related failures**
```bash
aws logs filter-log-events \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --filter-pattern "?database ?fail"
```

### **List log streams**
```bash
aws logs describe-log-streams \
  --log-group-name "/aws/ec2/lab-rds-app"
```

---

## **⚙️ 3. Validate Configuration Sources**

### **Parameter Store**
```bash
aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/name \
  --with-decryption
```

### **Secrets Manager**
```bash
aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
```

Compare values against expected known‑good configuration.

---

## **📊 4. Validate Monitoring & Metrics**

### **Check if metric exists**
```bash
aws cloudwatch list-metrics \
  --namespace "Lab/RDSApp" \
  --metric-name "DBConnectionFailures"
```

### **Check recent metric values**
```bash
aws cloudwatch get-metric-statistics \
  --namespace "Lab/RDSApp" \
  --metric-name "DBConnectionFailures" \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum
```

---

## **🗄️ 5. Validate RDS State**

### **Check RDS instance**
```bash
aws rds describe-db-instances \
  --db-instance-identifier lab-rds
```

### **Get RDS endpoint**
```bash
aws rds describe-db-instances \
  --db-instance-identifier lab-rds \
  --query "DBInstances[].Endpoint.Address"
```

### **Check RDS security groups**
```bash
aws rds describe-db-instances \
  --db-instance-identifier lab-rds \
  --query "DBInstances[].VpcSecurityGroups"
```

### **Describe RDS SG**
```bash
aws ec2 describe-security-groups \
  --group-ids <RDS_SG_ID>
```

---

## **🖥️ 6. Validate EC2 Instance**

### **Check EC2 state**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab-ec2" \
  --query "Reservations[].Instances[].State.Name"
```

### **Get EC2 public IP**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab-ec2" \
  --query "Reservations[].Instances[].PublicIpAddress"
```

### **Check EC2 security group**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=lab-ec2" \
  --query "Reservations[].Instances[].SecurityGroups"
```

---

## **📣 7. Validate SNS Alerts**

### **List SNS topics**
```bash
aws sns list-topics
```

### **Check subscriptions**
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn <SNS_TOPIC_ARN>
```

---

## **🌐 8. Validate Application Health**

After recovery:

```bash
curl http://<EC2_PUBLIC_IP>/list
```

Expected:

- Data returns  
- No errors  

---

## **🛠️ 9. Recovery Decision Matrix**

| Root Cause | Correct Action |
|-----------|----------------|
| **Credential Drift** | Update RDS password to match Secrets Manager **OR** update Secrets Manager to match known-good password |
| **Network Block** | Re-add EC2 SG to RDS inbound rules on port 3306 |
| **RDS Stopped** | Start RDS instance and wait for `available` |

---

## **🔁 10. Post‑Incident Validation**

### **Alarm returns to OK**
```bash
aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
```

### **Logs show no new errors**
```bash
aws logs filter-log-events \
  --log-group-name "/aws/ec2/lab-rds-app" \
  --filter-pattern "ERROR"
```

---

## **📝 11. Required Incident Report**

### **Incident Summary**
- What failed  
- How it was detected  
- Root cause  
- Time to recovery  

### **Preventive Actions**
- One improvement to reduce MTTR  
- One improvement to prevent recurrence  