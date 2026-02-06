# Lab 3A: Cross-Region Architecture with Transit Gateway

A multi-region AWS infrastructure demonstrating APPI-compliant data residency with Transit Gateway peering.

## Architecture Overview

```
                            ┌─────────────────────────────────────┐
                            │         Global Entry Point          │
                            │   CloudFront + WAF (Tokyo-owned)    │
                            │   app.daequanbritt.com              │
                            └─────────────────┬───────────────────┘
                                              │
                 ┌────────────────────────────┴─────────────────────────────┐
                 │                                                          │
    ┌────────────▼─────────────┐                           ┌────────────────▼────────────┐
    │   TOKYO (ap-northeast-1) │                           │   SÃO PAULO (sa-east-1)     │
    │   Project: akihabara     │                           │   Project: liberdade        │
    │   VPC: 10.14.0.0/16      │                           │   VPC: 10.15.0.0/16         │
    ├──────────────────────────┤                           ├─────────────────────────────┤
    │ • ALB (HTTPS)            │                           │ • ALB (HTTP)                │
    │ • EC2 (Flask App)        │                           │ • EC2 (Flask App)           │
    │ • RDS MySQL (Data Auth)  │◄──── TGW Peering ────────►│ • No Database (Compute Only)│
    │ • Transit Gateway        │                           │ • Transit Gateway           │
    │ • CloudFront + Certs     │                           │                             │
    └──────────────────────────┘                           └─────────────────────────────┘
```

## Key Features

- **Data Residency Compliance**: All PHI/sensitive data remains in Tokyo (APPI compliance)
- **Cross-Region Connectivity**: Transit Gateway peering enables São Paulo to access Tokyo's RDS
- **Global Entry Point**: Single CloudFront distribution with WAF protection
- **Secure ALB Access**: Custom header validation prevents direct ALB access

## Directory Structure

```
3A/
├── tokyo/                      # Primary region (data authority)
│   ├── 00-auth.tf              # Providers and backend
│   ├── 01-IAM.tf               # IAM roles and policies
│   ├── 02-secrets.tf           # Secrets Manager and SSM parameters
│   ├── 03-network.tf           # VPC, subnets, TGW, TGW routes
│   ├── 04-sg.tf                # Security groups (incl. São Paulo CIDR)
│   ├── 05-main.tf              # EC2 and RDS instances
│   ├── 06-logging.tf           # CloudWatch and S3 logging
│   ├── 07-alb-dns.tf           # ALB, HTTPS listener, Route53 records
│   ├── 08-dashboard.tf         # CloudWatch dashboard
│   ├── 09-waf.tf               # WAF rules (ALB + CloudFront)
│   ├── 10-cloudfront.tf        # CloudFront distribution
│   ├── 11-cert.tf              # ACM certificates (us-east-1)
│   ├── 12-cache.tf             # CloudFront cache policies
│   ├── 98-outputs.tf           # Terraform outputs
│   ├── 99-variables.tf         # Variable definitions
│   ├── terraform.tfvars        # Variable values
│   └── 1a_user_data_tf.sh      # EC2 bootstrap script
│
├── saopaulo/                   # Secondary region (compute only)
│   ├── 00-auth.tf              # Providers and backend
│   ├── 01-IAM.tf               # IAM roles and policies
│   ├── 02-secrets.tf           # SSM parameters (Tokyo RDS endpoint)
│   ├── 03-network.tf           # VPC, subnets, TGW, peering accepter
│   ├── 04-sg.tf                # Security groups
│   ├── 05-main.tf              # EC2 instance (no RDS)
│   ├── 06-logging.tf           # CloudWatch and S3 logging
│   ├── 07-alb-dns.tf           # ALB, HTTP listener (no certs)
│   ├── 08-dashboard.tf         # CloudWatch dashboard
│   ├── 09-waf.tf               # WAF rules (ALB only, no CloudFront)
│   ├── 10-cloudfront.tf        # [REMOVED - uses Tokyo's]
│   ├── 11-cert.tf              # [REMOVED - uses Tokyo's]
│   ├── 12-cache.tf             # [REMOVED - uses Tokyo's]
│   ├── 98-outputs.tf           # Terraform outputs
│   ├── 99-variables.tf         # Variable definitions
│   ├── terraform.tfvars        # Variable values
│   └── 1a_user_data_tf.sh      # EC2 bootstrap script
│
├── apply-instructions.md       # 5-stage deployment guide
└── README.md                   # This file
```

## Deployment Stages

### Stage 1: Deploy Tokyo
```bash
cd tokyo
terraform init && terraform apply
```

### Stage 2: Deploy São Paulo
```bash
cd saopaulo
# Comment out peering accepter first
terraform init && terraform apply
```

### Stage 3: Update Tokyo with São Paulo TGW ID
```bash
# Add saopaulo_tgw_id to tokyo/terraform.tfvars
cd tokyo && terraform apply
```

### Stage 4: São Paulo Accepts Peering
```bash
# Uncomment peering accepter, add tokyo_peering_attachment_id
cd saopaulo && terraform apply
cd tokyo && terraform apply  # Create TGW route
```

### Stage 5: Verify Connectivity
```bash
# From São Paulo EC2 via SSM:
nc -vz <tokyo-rds-endpoint> 3306
```

See `apply-instructions.md` for detailed steps.

## Verification Commands

### Check TGW Peering Status
```bash
aws ec2 describe-transit-gateway-peering-attachments \
  --region ap-northeast-1 \
  --query "TransitGatewayPeeringAttachments[].State"
```

### Check VPC Routes
```bash
# Tokyo → São Paulo
aws ec2 describe-route-tables --region ap-northeast-1 \
  --filters "Name=tag:Name,Values=akihabara-*-private-rt" \
  --query "RouteTables[].Routes[?DestinationCidrBlock=='10.15.0.0/16']"

# São Paulo → Tokyo
aws ec2 describe-route-tables --region sa-east-1 \
  --filters "Name=tag:Name,Values=liberdade-*-private-rt" \
  --query "RouteTables[].Routes[?DestinationCidrBlock=='10.14.0.0/16']"
```

### Test Application
- Initialize DB: `https://app.daequanbritt.com/init`
- Add note: `https://app.daequanbritt.com/add?note=test`
- List notes: `https://app.daequanbritt.com/list`

## Key Variables

### Tokyo (`terraform.tfvars`)
```hcl
project_name      = "akihabara"
region            = "ap-northeast-1"
saopaulo_tgw_id   = "tgw-xxxxxxxxx"
saopaulo_vpc_cidr = "10.15.0.0/16"
```

### São Paulo (`terraform.tfvars`)
```hcl
project_name                = "liberdade"
region                      = "sa-east-1"
tokyo_rds_endpoint          = "xxx.rds.amazonaws.com"
tokyo_vpc_cidr              = "10.14.0.0/16"
tokyo_peering_attachment_id = "tgw-attach-xxxxxxxxx"
```

## Lessons Learned

1. **Two route types for TGW**: VPC routes AND TGW route table entries both required
2. **CloudFront aliases are global**: Only one distribution can own a domain
3. **ACM certs have unique tokens**: Can't share validation records between certificates
4. **AWS descriptions must be ASCII**: No special characters (ã, ñ, etc.)
5. **Always specify --region**: AWS CLI defaults may not be correct
6. **User_data runs once**: Must recreate EC2 to apply changes

## Troubleshooting

| Issue | Solution |
|-------|----------|
| ACM validation stuck | Check domain email verification (spam folder) |
| nc timeout to RDS | Check TGW route tables have static routes |
| ParameterNotFound | Check Flask app region matches deployment |
| CNAME conflict | Only one region should have CloudFront |
| Empty query results | Add --region flag, verify resource names |

## Resources

- [Transit Gateway Peering](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-peering.html)
- [ACM DNS Validation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html)
- [CloudFront with ALB](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/restrict-access-to-load-balancer.html)
