# 1. Verify Peering is Active

#### Check status in Tokyo:
```bash
aws ec2 describe-transit-gateway-peering-attachments \
  --region ap-northeast-1 \
  --filters "Name=transit-gateway-id,Values=tgw-0dc41479dfabcd940" \
  --query 'TransitGatewayPeeringAttachments[0].State' \
  --output text
```

Expected output: **`available`**

#### Check status in São Paulo:
```bash
aws ec2 describe-transit-gateway-peering-attachments \
  --region sa-east-1 \
  --filters "Name=transit-gateway-id,Values=tgw-0a3c7c6d1092d5d98" \
  --query 'TransitGatewayPeeringAttachments[0].State' \
  --output text
```

Expected output: **`available`**

---

Quick verification commands (so they can prove it)
From São Paulo EC2 (SSM session)

# 2. Test network reachability to Tokyo RDS:
First SSM into the instance then test with this command:

```
nc -vz <tokyo-rds-endpoint> 3306
```

```
nc -vz akihabara-dev-mysql.cvgusgs2mgvn.ap-northeast-1.rds.amazonaws.com 3306
```

nc was not installed. I ran this command:
```
sudo dnf install nc -y
```

# 3. App-level verification:
  submit record in São Paulo = /dd?note=saopaulo
```

```
  confirm it appears when calling the Tokyo region (same data, one DB) = /list


# 4. Confirm routes (AWS CLI)
For each region, verify route tables include the cross-region CIDR to TGW:

    aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<VPC_ID>" --query "RouteTables[].Routes[]"

ap-northeast-1
```
aws ec2 describe-route-tables \
--filters "Name=vpc-id,Values=vpc-078e9306504c5c59e" \
--query "RouteTables[].Routes[]" \
--region ap-northeast-1
```

sa-east-1
```
aws ec2 describe-route-tables \
--filters "Name=vpc-id,Values=vpc-0cf6bc7b26988288d" \
--query "RouteTables[].Routes[]" \
--region sa-east-1
```