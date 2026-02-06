# Lab 3A Deployment Guide - 5 Stage Process

## Architecture Overview
- **Tokyo (ap-northeast-1)**: Primary region with RDS database (data authority)
  - Project name: `akihabara`
- **São Paulo (sa-east-1)**: Secondary region, compute-only (connects to Tokyo RDS via TGW)
  - Project name: `liberdade`

## Key Learnings from Deployment

### Route Types Required
1. **VPC Route Table** → tells VPC "send traffic to TGW"
2. **TGW Route Table** → tells TGW "forward traffic via peering attachment"
   - Both are required! Missing TGW routes = timeout

### Common Issues Fixed
- Special characters in AWS descriptions (use "Sao Paulo" not "São Paulo")
- CloudFront CNAME conflicts (only one region can own domain aliases)
- ACM certificate validation conflicts (each region has unique tokens)
- Flask app region defaults (must match deployment region)

---

## Stage 1: Deploy Tokyo Base Infrastructure

**Purpose**: Create Tokyo's VPC, EC2, RDS, ALB, CloudFront, and Transit Gateway.

**Directory**: `work/tokyo/`

**Prerequisites**:
- Ensure `1a_user_data_tf.sh` has correct region default: `ap-northeast-1`

**Commands**:
```bash
cd work/tokyo/
terraform init
terraform apply
```

**Outputs to capture**:
```bash
terraform output tokyo_tgw_id
terraform output tokyo_rds_endpoint
terraform output tokyo_vpc_cidr
```

**Note**: TGW peering will fail without São Paulo TGW ID - this is expected.

---

## Stage 2: Deploy São Paulo Base Infrastructure

**Purpose**: Create São Paulo's VPC, EC2, ALB, and Transit Gateway (NO RDS).

**Directory**: `work/saopaulo/`

**Prerequisites**:
1. Comment out the peering accepter in `03-network.tf` (lines 215-222)
2. Comment out the TGW route to Tokyo in `03-network.tf` (the `aws_ec2_transit_gateway_route` resource)
3. Add to `saopaulo/terraform.tfvars`:
   ```hcl
   tokyo_rds_endpoint = "<value-from-stage-1>"
   ```

**What's already removed** (from earlier fixes):
- CloudFront distribution (using Tokyo's)
- ACM certificates (using Tokyo's domain)
- HTTPS listener (using HTTP only)

**Commands**:
```bash
cd work/saopaulo/
terraform init
terraform apply
```

**Outputs to capture**:
```bash
terraform output saopaulo_tgw_id
```

---

## Stage 3: Update Tokyo with São Paulo TGW ID

**Purpose**: Create TGW peering request and routes.

**Directory**: `work/tokyo/`

**Prerequisites**:
Add to `tokyo/terraform.tfvars`:
```hcl
saopaulo_tgw_id   = "<value-from-stage-2>"
saopaulo_vpc_cidr = "10.15.0.0/16"
```

**Commands**:
```bash
cd work/tokyo/
terraform apply
```

**Get peering attachment ID for Stage 4**:
```bash
aws ec2 describe-transit-gateway-peering-attachments \
  --region ap-northeast-1 \
  --query "TransitGatewayPeeringAttachments[].{ID:TransitGatewayAttachmentId,State:State}" \
  --output table
```

---

## Stage 4: São Paulo Accepts Peering + TGW Routes

**Purpose**: Accept peering and create TGW route table entries.

**Directory**: `work/saopaulo/`

**Prerequisites**:
1. Uncomment the peering accepter in `03-network.tf` (lines 215-222)
2. Uncomment the TGW route resource (`aws_ec2_transit_gateway_route`)
3. Add to `saopaulo/terraform.tfvars`:
   ```hcl
   tokyo_peering_attachment_id = "<peering-attachment-id-from-stage-3>"
   ```

**Commands**:
```bash
cd work/saopaulo/
terraform apply
```

**Then re-apply Tokyo** to create its TGW route:
```bash
cd work/tokyo/
terraform apply
```

---

## Stage 5: Verify Cross-Region Connectivity

### Check Peering Status
```bash
aws ec2 describe-transit-gateway-peering-attachments \
  --region ap-northeast-1 \
  --query "TransitGatewayPeeringAttachments[].State"
# Expected: "available"
```

### Check VPC Route Tables
```bash
# Tokyo → São Paulo
aws ec2 describe-route-tables \
  --region ap-northeast-1 \
  --filters "Name=tag:Name,Values=akihabara-*-private-rt" \
  --query "RouteTables[].Routes[?DestinationCidrBlock=='10.15.0.0/16']"

# São Paulo → Tokyo
aws ec2 describe-route-tables \
  --region sa-east-1 \
  --filters "Name=tag:Name,Values=liberdade-*-private-rt" \
  --query "RouteTables[].Routes[?DestinationCidrBlock=='10.14.0.0/16']"
```

### Check TGW Route Tables (CRITICAL!)
```bash
# Tokyo TGW routes
aws ec2 search-transit-gateway-routes \
  --region ap-northeast-1 \
  --transit-gateway-route-table-id <tokyo-tgw-rtb-id> \
  --filters "Name=state,Values=active" \
  --query "Routes[].{CIDR:DestinationCidrBlock,Type:Type}"

# São Paulo TGW routes
aws ec2 search-transit-gateway-routes \
  --region sa-east-1 \
  --transit-gateway-route-table-id <saopaulo-tgw-rtb-id> \
  --filters "Name=state,Values=active" \
  --query "Routes[].{CIDR:DestinationCidrBlock,Type:Type}"
```

### Test from São Paulo EC2
```bash
# Get instance ID
aws ec2 describe-instances --region sa-east-1 \
  --filters "Name=tag:Name,Values=liberdade-*-web" \
  --query "Reservations[].Instances[].InstanceId" --output text

# SSM in
aws ssm start-session --target <instance-id> --region sa-east-1

# Test RDS connectivity
nc -vz <tokyo-rds-endpoint> 3306
# Expected: Connection succeeded!
```

### App-Level Verification
1. Go to `https://app.daequanbritt.com/init` to initialize database
2. Add a note via `https://app.daequanbritt.com/add?note=test`
3. List notes via `https://app.daequanbritt.com/list`

---

## Quick Reference: All Variables

### Tokyo `terraform.tfvars`:
```h
project_name      = "akihabara"
environment       = "dev"
region            = "ap-northeast-1"
azs               = ["ap-northeast-1a", "ap-northeast-1c"]
saopaulo_tgw_id   = "tgw-xxxxxxxxx"
saopaulo_vpc_cidr = "10.15.0.0/16"
```

### São Paulo `terraform.tfvars`:
```hcl
project_name                = "liberdade"
environment                 = "dev"
region                      = "sa-east-1"
azs                         = ["sa-east-1a", "sa-east-1c"]
tokyo_rds_endpoint          = "xxx.rds.amazonaws.com"
tokyo_vpc_cidr              = "10.14.0.0/16"
tokyo_peering_attachment_id = "tgw-attach-xxxxxxxxx"
```

---

## Troubleshooting

### nc timeout from São Paulo EC2
1. Check TGW peering is "available" (not pendingAcceptance)
2. Check **TGW route tables** have routes (not just VPC route tables!)
3. Check RDS security group allows 10.15.0.0/16

### Flask app "ParameterNotFound" error
- Check `1a_user_data_tf.sh` has correct region default
- Recreate EC2: `terraform taint aws_instance.web && terraform apply`

### ACM certificate validation stuck
- Check domain email is verified (Route53 → Registered domains)
- Check nameservers point to Route53

### CloudFront CNAME conflict
- Only Tokyo should have CloudFront with domain aliases
- São Paulo uses HTTP-only ALB (accessed via Tokyo CloudFront)
