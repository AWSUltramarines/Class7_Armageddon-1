Student verification (CLI) for Bonus-A
1) Prove EC2 is private (no public IP)
```rb
aws ec2 describe-instances \
--instance-ids i-0495533bce4364c78 \
--query "Reservations[].Instances[].PublicIpAddress" \
--region us-east-2
```

Expected: 
  null

I got an empty list proving that the instance has no public ip.
Then I ran this command which resulted in "null:
```rb
aws ec2 describe-instances \
--instance-ids i-0495533bce4364c78 \
--region us-east-2 \
--query "Reservations[].Instances[].{State: State.Name, PublicIP: PublicIpAddress, PrivateIP: PrivateIpAddress}"
```

2) Prove VPC endpoints exist
```rb
aws ec2 describe-vpc-endpoints \
--filters "Name=vpc-id,Values=vpc-01f65a5287443134e" \
--query "VpcEndpoints[].ServiceName" \
--region us-east-2
```

Expected: list includes:
  ssm 
  ec2messages 
  ssmmessages 
  logs 
  secretsmanager
  s3

3) Prove Session Manager path works (no SSH)
```rb
aws ssm describe-instance-information \
--query "InstanceInformationList[].InstanceId" \
--region us-east-2
```

Expected: your private EC2 instance ID appears

A more specific command to see if that specific instance is recognized by SSM would be:
```rb
aws ssm describe-instance-information \
--filters "Key=InstanceIds,Values=i-0495533bce4364c78" \
--query "InstanceInformationList[].InstanceId" \
--region us-east-2
```

4) Prove the instance can read both config stores

Connect to SSM:
```rb
aws ssm start-session --target i-0495533bce4364c78 \
--region us-east-2
```

Run from SSM session:
```rb
aws ssm get-parameter \
--name /lab/db/endpoint \
--region us-east-2
```

```rb
aws secretsmanager \
get-secret-value \
--secret-id lab/rds/mysql \
--region us-east-2
```

5) Prove CloudWatch logs delivery path is available via endpoint
```rb
aws logs describe-log-streams \
--log-group-name /aws/ec2/lab-rds-app \
--region us-east-2
```