# Run these commands before #2

### Get Sao Paulo instance ID
```
aws ec2 describe-instances --region sa-east-1 \
  --filters "Name=tag:Name,Values=liberdade-*-web" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text
```

### SSM into it
```
aws ssm start-session --target <instance-id> --region sa-east-1
```

```
aws ssm start-session --target i-04bd8e7fb9d8bc9d9 --region sa-east-1
```

### Install nc
```
sudo dnf install nc -y
```

### Test from inside
```
nc -vz <tokyo-rds-endpoint> 3306
```