7.0 Connect via SSM: 
```rb
aws ssm start-session --target i-0495533bce4364c78 \
--region us-east-2
```

7.1 Verify Parameter Store Values
```rb
aws ssm get-parameters \
  --names /lab/db/endpoint /lab/db/port /lab/db/dbname \
  --with-decryption \
  --query "Parameters[].{Name:Name,Value:Value}" \
  --output table
```
Expected: Parameter names returned Correct DB endpoint and port

7.2 Verify Secrets Manager Value
```rb
aws secretsmanager get-secret-value \
--secret-id lab/rds/mysql \
--query SecretString \
--output text | jq
```
Expected: JSON output Fields: username password host port

7.3 Verify EC2 Can Read Both Systems From EC2:
```rb
aws ssm get-parameter --name /lab/db/endpoint \
--output table
```

```rb
aws secretsmanager get-secret-value --secret-id lab/rds/mysql \
--output table
```
Expected: Both commands succeed No AccessDeniedException

7.4 Verify CloudWatch Log Group Exists
```rb
aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/lab-rds-app \
  --region us-east-2 \
  --output table
```
Expected: Log group present

7.5 Verify DB Failure Logs Appear Simulate failure (examples): Stop RDS Change DB password in Secrets Manager without updating DB Block SG temporarily

Then check logs:

aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "Err" \
  --region us-east-2

aws logs get-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --log-stream-name flask-app \
  --limit 5 \
  --region us-east-2

Expected: Explicit DB connection failure messages

7.6 Verify CloudWatch Alarm
```rb
aws cloudwatch describe-alarms \
  --alarm-names lab-db-connection-failure \
  --region us-east-2 \
  --output table
```

Watch logs in real time:
```rb
while :; do clear; aws cloudwatch describe-alarms --alarm-names HighDBConnectionFailures --region us-east-2 --query 'MetricAlarms[0].StateValue'; sleep 5; done
```

Expected: Alarm present State transitions to ALARM during failure

7.7 Incident Recovery Verification After restoring correct credentials or connectivity:

curl http://<EC2_PUBLIC_IP>/list

Since I combined 1b and 1c I'll use ssm and local host
curl http://localhost/list