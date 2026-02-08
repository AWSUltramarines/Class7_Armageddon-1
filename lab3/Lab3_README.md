# Lab 3: Cross-Region Transit Gateway  Execution Record

**What was actually deployed across ap-northeast-1 (Tokyo) and sa-east-1 (São Paulo)**

---

## What We Built

Extended the Lab 2 Helga stack into a **cross-region APPI-compliant medical architecture**. Tokyo kept its role as the data authority (all PHI in RDS), and São Paulo got a brand-new stateless compute extension  Lab 2's pattern minus the database. The two regions connect through a Transit Gateway peering corridor so São Paulo EC2 instances can reach Tokyo RDS over the AWS backbone without ever touching the public internet.

The deployment required **two separate Terraform state files** (one per region) and a strict 5-phase dependency chain because each phase's outputs feed the next phase's inputs. TGW peering has a state machine (`pendingAcceptance` → `available`) that forces this sequencing  you cannot skip ahead.

### Deployed Architecture

```
Internet → CloudFront (chewbacca-growls.com + WAF)
         → São Paulo EC2/ASG (liberdade_vpclab3, 10.214.0.0/16, stateless)
         → liberdade_tgwlab3 (São Paulo TGW Spoke, tgw-0b6ee1c6f442d1804)
         → TGW Peering (tgw-attach-0e85595d1d9755e4b)
         → shinjuku_tgw01 (Tokyo TGW Hub, tgw-0fa67d205d21bfa7f)
         → helga_vpclab2a (10.241.0.0/16)
         → helga_rds_sg01 allows 10.214.0.0/16 on 3306
         → Tokyo RDS (helga-rdslab3, PHI stored here ONLY)
```

---

## Key Resources Deployed

| Resource | Identifier |
| --- | --- |
| **Tokyo VPC** | `helga_vpclab2a`  `vpc-0748475663d384e4e` (10.241.0.0/16) |
| **Tokyo TGW (Hub)** | `shinjuku_tgw01`  `tgw-0fa67d205d21bfa7f` |
| **Tokyo TGW Attachment** | `shinjuku-attach-tokyo-vpclab3`  `tgw-attach-0df53ae538c5eee9f` |
| **Tokyo RDS** | `helga-rdslab3` - `helga-rdslab3.cv8u2kmkqq0y.ap-northeast-1.rds.amazonaws.com:3306` |
| **São Paulo VPC** | `liberdade_vpclab3`  `vpc-0cfbddcac1adec6b3` (10.214.0.0/16) |
| **São Paulo TGW (Spoke)** | `liberdade_tgwlab3`  `tgw-0b6ee1c6f442d1804` |
| **TGW Peering** | `shinjuku_to_liberdade_peer01`  `tgw-attach-0e85595d1d9755e4b` (state: available) |
| **AWS Account** | `xxxxxxxxxxxx` |

---

## Actual CIDRs Deployed

| Region | Resource | CIDR |
| --- | --- | --- |
| **Tokyo** | VPC | `10.241.0.0/16` |
| Tokyo | Public Subnets | `10.241.1.0/24`, `10.241.2.0/24`, `10.241.3.0/24` |
| Tokyo | Private Subnets | `10.241.101.0/24`, `10.241.102.0/24`, `10.241.103.0/24` |
| **São Paulo** | VPC | `10.214.0.0/16` |
| São Paulo | Public Subnets | `10.214.1.0/24`, `10.214.2.0/24` |
| São Paulo | Private Subnets | `10.214.101.0/24`, `10.214.102.0/24` |

---

## How the Deployment Actually Worked (5-Phase Chain)

TGW peering enforces a strict dependency chain. Each phase produces outputs the next phase needs. You cannot parallelize this.

```
Phase 1: Tokyo Foundation
  → shinjuku_tgw01 created, attached to helga_vpclab2a private subnets
  → Captured tgw-0fa67d205d21bfa7f

Phase 2: São Paulo Deployment
  → liberdade_vpclab3 created (10.214.0.0/16, NO RDS)
  → liberdade_tgwlab3 created, attached to liberdade private subnets
  → Captured tgw-0b6ee1c6f442d1804

Phase 3: Tokyo Completion
  → shinjuku_to_liberdade_peer01 peering request created (state: pendingAcceptance)
  → helga_private_rt01: 10.214.0.0/16 → shinjuku_tgw01
  → helga_rds_sg01: ingress from 10.214.0.0/16 on port 3306

Phase 4: São Paulo Finalization
  → liberdade_accept_peer01 accepted peering (state: available)
  → liberdade_private_rtlab3: 10.241.0.0/16 → liberdade_tgwlab3

Phase 5: Verification & Audit
  → RDS exists only in ap-northeast-1 (confirmed)
  → TGW peering available (confirmed)
  → São Paulo EC2 → Tokyo RDS on 3306 (confirmed)
  → Audit evidence pack assembled
```

---

## What Changed from Lab 2

| Component | Lab 2 |
| --- | --- |
| **Regions** | Single region (ap-northeast-1) |
| **Terraform state** | One state file |
| **Networking** | Single VPC |
| **RDS access** | Local VPC only |
| **Route tables** | Default routes only |
| **Providers** | `aws`  • `aws.us_east_1` |
| **CloudFront / WAF / ALB** | Deployed |

---

## Lab 2 Resources That Lab 3 Connects To

| Lab 2 Resource | Terraform Reference | How Lab 3 Uses It |
| --- | --- | --- |
| Tokyo VPC | `aws_vpc.helga_vpclab2a` | TGW attachment target (`shinjuku-attach-tokyo-vpclab3`) |
| Private Subnets | `aws_subnet.helga_private_subnets[0,1]` | TGW attachment subnet IDs |
| Private Route Table | `aws_route_table.helga_private_rt01` | Added route: `10.214.0.0/16 → shinjuku_tgw01` |
| RDS Security Group | `aws_security_group.helga_rds_sg01` | Added ingress: `10.214.0.0/16` on port 3306 |
| RDS Instance | `aws_db_instance.helga_rds01` | Endpoint exported for São Paulo app config |
| CloudFront | `aws_cloudfront_distribution.helga_cf_distlab2a` | No changes  still fronts the architecture |
| WAF | `aws_wafv2_web_acl.helga_cf_waflab2a` | No changes  still attached to CloudFront |

---

## File Map (Actual Terraform Files)

### Tokyo (Modified + New)

| File | Action |
| --- | --- |
| `02-providers.tf` | MODIFIED |
| `03-variables.tf` | MODIFIED |
| `04-3a-tokyo-tgw.tf` | **NEW** |
| `04-3b-tokyo-routes.tf` | **NEW** |
| `04-3c-rds-sg-update.tf` | **NEW** |
| `05-outputs.tf` | MODIFIED |

### São Paulo (All New)

| File | What It Does |
| --- | --- |
| `01-version.tf` | Terraform version + AWS provider constraint |
| `02-providers.tf` | `aws` provider for `sa-east-1` |
| `03-variables.tf` | São Paulo CIDRs + cross-region refs (`tokyo_tgw_id`, `tokyo_rds_endpoint`) |
| `04-main.tf` | `liberdade_vpclab3`, subnets, IGW, NAT, route tables  **NO RDS** |
| `04-P-main-saopaulo-tgw.tf` | `liberdade_tgwlab3` (spoke) + VPC attachment + peering accepter |
| `sao-paulo-routes.tf` | `aws_route` in `liberdade_private_rtlab3`: `10.241.0.0/16 → liberdade_tgwlab3` |
| `05-outputs.tf` | `saopaulo_tgw_id`, `saopaulo_vpc_cidr`, subnet IDs |

---

## Key Challenges Solved

### 1. TGW Is Regional  Hub-Spoke Model Required

**Problem:** First mental model: attach São Paulo VPC directly to Tokyo TGW. This doesn't work.

**Root Cause:** Transit Gateways are regional resources. You cannot attach a VPC in one region to a TGW in another region.

**Solution:** Hub-spoke pattern:

- **Tokyo (Hub):** `shinjuku_tgw01`  manages routing between Tokyo VPC and peering
- **São Paulo (Spoke):** `liberdade_tgwlab3`  connects São Paulo VPC to the hub
- **Peering:** `shinjuku_to_liberdade_peer01`  corridor between the two TGWs

```hcl
# Tokyo creates the peering request
resource "aws_ec2_transit_gateway_peering_attachment" "shinjuku_to_liberdade_peer01" {
  peer_region             = "sa-east-1"
  peer_transit_gateway_id = var.saopaulo_tgw_id
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

# São Paulo accepts the peering
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer01" {
  provider                      = aws.saopaulo
  transit_gateway_attachment_id = var.tokyo_peering_attachment_id
}
```

**Lesson:** Cross-region TGW requires hub-spoke with peering. Direct VPC attachment only works within the same region.

---

### 2. Stale TGW IDs Broke Peering (State Drift)

**Problem:** São Paulo TGW was destroyed and recreated during development, changing its ID from `tgw-0e39a7e3adf1662e8` to `tgw-0b6ee1c6f442d1804`. Tokyo's `terraform.tfvars` still had the old ID.

**Error Message:**

```
Error: EC2 Transit Gateway Peering Attachment create: unexpected state 'failed'
Message: "Failed to create peering attachment. This may be a result of
incorrect Transit Gateway ID and Account ID combination"
```

**Root Cause:** Hard-coded TGW ID in tfvars didn't update when São Paulo infrastructure was rebuilt.

**Fix (Short-term):** Manually updated `saopaulo_tgw_id` in Tokyo's `terraform.tfvars`.

**Fix (Long-term):** Switched to data source lookup by tag:

```hcl
data "aws_ec2_transit_gateway" "saopaulo_tgw" {
  provider = aws.saopaulo
  filter {
    name   = "tag:Name"
    values = ["liberdade_tgwlab3"]
  }
}
```

**Lesson:** Use data source lookups with tags instead of hard-coded IDs for cross-state references. Tags are stable across destroy/recreate cycles.

---

### 3. tfvars Only Accepts Literals (Terraform Syntax Limitation)

**Problem:** Attempted to put `data.aws_ec2_transit_gateway.tokyo_tgw.id` directly in `terraform.tfvars`.

**Error:** Terraform treats data source references as literal strings in tfvars.

**Root Cause:** `terraform.tfvars` files only accept **literal values**  no expressions, no data sources, no variable references.

**Fix:** Three options:

1. Remove variable from tfvars entirely, set default in `variables.tf`
2. Pass via `-var` flag: `terraform apply -var="tokyo_tgw_id=$(terraform output -raw tokyo_tgw_id)"`
3. Use data source directly in resource blocks (no variable needed)

Chose option 3:

```hcl
# In saopaulo/04-P-main-saopaulo-tgw.tf
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer01" {
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.tokyo_peer.id
}
```

**Lesson:** tfvars is for literals only. For cross-state references, use data sources or shell scripting to pass outputs as variables.

---

### 4. Whitespace in tfvars = Malformed ID

**Problem:** After updating São Paulo TGW ID in Tokyo's tfvars, got `InvalidTransitGatewayID.Malformed` error.

**Root Cause:** A **leading space** before `tgw-0b6ee1c6f442d1804` in the tfvars file:

```hcl
# What broke (invisible space before tgw-)
saopaulo_tgw_id = " tgw-0b6ee1c6f442d1804"
```

**Detection:** Invisible in most editors. Found by copying the value to a hex editor.

**Fix:** Removed whitespace.

**Prevention:** Added validation to `variables.tf`:

```hcl
variable "saopaulo_tgw_id" {
  type = string
  validation {
    condition     = can(regex("^tgw-[a-f0-9]{17}$", var.saopaulo_tgw_id))
    error_message = "TGW ID must match pattern 'tgw-' followed by 17 hex characters."
  }
}
```

**Lesson:** AWS resource IDs have strict formats. Add validation rules to catch whitespace and typos early.

---

### 5. SG References Don't Work Cross-VPC (Network Boundary)

**Problem:** Tried to reference São Paulo EC2 security group in Tokyo RDS security group ingress rule:

```hcl
# This doesn't work
source_security_group_id = data.aws_security_group.saopaulo_ec2_sg.id
```

**Error:** Security group not found or cross-VPC reference not allowed.

**Root Cause:** Security group references only work **within the same VPC**. Cross-VPC requires CIDR-based rules.

**Fix:** Used CIDR block:

```hcl
# This is what works for cross-region/cross-VPC
resource "aws_security_group_rule" "helga_rds_from_saopaulo" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["10.214.0.0/16"]  # São Paulo VPC CIDR
  security_group_id = aws_security_group.helga_rds_sg01.id
}
```

**Lesson:** SG-to-SG references work only within the same VPC. For cross-VPC, cross-region, or VPN scenarios, use CIDR blocks.

---

### 6. Peering State Machine Enforces Strict Ordering

**Problem:** Tried to configure routes before peering reached `available` state. Routes had no effect.

**Root Cause:** TGW peering has a state machine:

```
initial → pendingAcceptance → available → deleting → deleted
                  ↓
                failed
```

Routes don't work until `available`. Cannot skip states.

**Solution:** 5-phase deployment with explicit dependencies:

**Phase 1 (Tokyo):** Create TGW + VPC attachment

**Phase 2 (São Paulo):** Create TGW + VPC attachment  

**Phase 3 (Tokyo):** Create peering request (reaches `pendingAcceptance`)

**Phase 4 (São Paulo):** Accept peering (moves to `available`)  

**Phase 5 (Both):** Add routes once peering is `available`

```hcl
# Ensure routes wait for peering
resource "aws_route" "tokyo_to_saopaulo" {
  route_table_id         = aws_route_table.helga_private_rt01.id
  destination_cidr_block = "10.214.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgw01.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01
  ]
}
```

**Lesson:** TGW peering is not instant. Plan for the state machine in your deployment order. Use `depends_on` to enforce sequencing.

---

### 7. State Drift Recovery  `terraform state rm` + `import`

**Problem:** Multiple failed peering attempts left AWS state and Terraform state out of sync. Terraform kept trying to create peering that already existed (in failed state).

**Symptoms:**

- `terraform plan` showed peering needed to be created
- AWS Console showed peering attachment in `failed` state
- `terraform apply` kept failing with "attachment already exists"

**Root Cause:** Failed peering attachments in AWS cannot be deleted via API or console  AWS garbage-collects them automatically after a delay.

**Recovery:**

```bash
# Step 1: Remove stale state reference
terraform state rm 'aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01[0]'

# Step 2: Wait for AWS to garbage-collect failed attachment (or use working one)
# Check: aws ec2 describe-transit-gateway-peering-attachments

# Step 3: Import the real working attachment
terraform import 'aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01[0]' tgw-attach-0e85595d1d9755e4b

# Step 4: Verify state matches reality
terraform plan
# Should show "No changes"
```

**Same pattern for São Paulo accepter:**

```bash
terraform state rm 'aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01'
terraform import 'aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01' tgw-attach-0e85595d1d9755e4b
```

**Lesson:** When Terraform state diverges from AWS reality, `state rm` + `import` recovers without destroying working infrastructure. Always verify with `terraform plan` after import.

---

### 8. Two Separate State Files  Cross-State Variable Passing

**Problem:** Tokyo and São Paulo are in different regions. Terraform state files cannot span regions effectively.

**Solution:** Two separate Terraform directories with outputs → tfvars pattern:

**Tokyo outputs:**

```hcl
output "tokyo_tgw_id" {
  value = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

output "tokyo_rds_endpoint" {
  value = aws_db_instance.helga_rds01.endpoint
}
```

**São Paulo consumes via tfvars:**

```hcl
# saopaulo/terraform.tfvars
tokyo_tgw_id       = "tgw-0fa67d205d21bfa7f"
tokyo_rds_endpoint = "helga-rdslab3.cv8u2kmkqq0y.ap-northeast-1.rds.amazonaws.com"
```

**Automation:**

```bash
# Extract Tokyo outputs and inject into São Paulo tfvars
cd tokyo
terraform output -json > ../saopaulo/tokyo-outputs.json

cd ../saopaulo
# Parse tokyo-outputs.json and update terraform.tfvars
```

**Lesson:** Multi-region Terraform requires either:

1. Two state files + manual/scripted variable passing (chosen approach)
2. Terraform Cloud/Enterprise workspaces with data sources
3. Remote state data sources (adds S3 backend dependency)

---

### 9. APPI Data Residency  No RDS in São Paulo

**Problem:** APPI regulations require all PHI to remain in Japan. São Paulo cannot have any database storing patient records.

**Architecture Decision:** São Paulo VPC has **zero RDS instances**. All database queries flow:

```
São Paulo EC2 → liberdade_tgwlab3 → TGW peering → shinjuku_tgw01 → Tokyo VPC → Tokyo RDS
```

**Verification:**

```bash
# São Paulo: NO RDS (must return empty)
aws rds describe-db-instances --region sa-east-1 \
  --query "DBInstances[].DBInstanceIdentifier"
# Result: []

# Tokyo: RDS exists
aws rds describe-db-instances --region ap-northeast-1 \
  --query "DBInstances[].{DB:DBInstanceIdentifier,Endpoint:Endpoint.Address}"
# Result: helga-rdslab3
```

**What's NOT allowed:**

- ❌ Cross-region RDS replicas
- ❌ Aurora Global Database
- ❌ Local caching of patient records
- ❌ CloudFront caching PHI

**Lesson:** Data residency isn't just "prefer local storage"  it's a legal requirement. Architecture must make violations **impossible**, not just "against policy."

---

## Verification Commands

### Data Residency Proof

```bash
# Tokyo: RDS must exist
aws rds describe-db-instances --region ap-northeast-1 \
  --query "DBInstances[].{DB:DBInstanceIdentifier,AZ:AvailabilityZone,Endpoint:Endpoint.Address}"
# Expected: helga-rdslab3 in ap-northeast-1

# São Paulo: NO RDS (must return empty array)
aws rds describe-db-instances --region sa-east-1 \
  --query "DBInstances[].DBInstanceIdentifier"
# Expected: []
```

### TGW Peering State

```bash
# Check peering status (must be "available")
aws ec2 describe-transit-gateway-peering-attachments --region ap-northeast-1 \
  --transit-gateway-attachment-ids tgw-attach-0e85595d1d9755e4b \
  --query "TransitGatewayPeeringAttachments[0].{State:State,RequesterTGW:TransitGatewayId,AccepterTGW:AccepterTransitGatewayId}"
# Expected State: "available"
```

### Cross-Region Route Tables

```bash
# Tokyo: São Paulo CIDR should route to TGW
aws ec2 describe-route-tables --region ap-northeast-1 \
  --filters "Name=vpc-id,Values=vpc-0748475663d384e4e" \
  --query "RouteTables[*].Routes[?DestinationCidrBlock=='10.214.0.0/16']"
# Expected: Route via tgw-0fa67d205d21bfa7f

# São Paulo: Tokyo CIDR should route to TGW
aws ec2 describe-route-tables --region sa-east-1 \
  --filters "Name=vpc-id,Values=vpc-0cfbddcac1adec6b3" \
  --query "RouteTables[*].Routes[?DestinationCidrBlock=='10.241.0.0/16']"
# Expected: Route via tgw-0b6ee1c6f442d1804
```

### RDS Security Group (Tokyo)

```bash
# Tokyo RDS SG must allow São Paulo VPC CIDR on 3306
aws ec2 describe-security-groups --region ap-northeast-1 \
  --group-ids <helga_rds_sg01_id> \
  --query "SecurityGroups[0].IpPermissions[?ToPort==\`3306\`].IpRanges"
# Expected: 10.214.0.0/16 present
```

### Cross-Region Connectivity Test

```bash
# From São Paulo EC2 (via SSM Session Manager)
aws ssm start-session --target <saopaulo_ec2_instance_id> --region sa-east-1

# Once in session:
nc -vz helga-rdslab3.cv8u2kmkqq0y.ap-northeast-1.rds.amazonaws.com 3306
# Expected: Connection succeeded

# Alternative: Python test script
python3 << 'EOF'
import pymysql
try:
    conn = pymysql.connect(
        host='helga-rdslab3.cv8u2kmkqq0y.ap-northeast-1.rds.amazonaws.com',
        port=3306,
        user='admin',
        password='<password>',
        database='t_labdb',
        connect_timeout=5
    )
    print("✅ Cross-region DB connection successful")
    conn.close()
except Exception as e:
    print(f"❌ Connection failed: {e}")
EOF
```

### TGW Attachments

```bash
# Tokyo TGW attachments (should show VPC attachment + peering)
aws ec2 describe-transit-gateway-attachments --region ap-northeast-1 \
  --filters "Name=transit-gateway-id,Values=tgw-0fa67d205d21bfa7f" \
  --query "TransitGatewayAttachments[].{Type:ResourceType,ResourceId:ResourceId,State:State}"

# São Paulo TGW attachments
aws ec2 describe-transit-gateway-attachments --region sa-east-1 \
  --filters "Name=transit-gateway-id,Values=tgw-0b6ee1c6f442d1804" \
  --query "TransitGatewayAttachments[].{Type:ResourceType,ResourceId:ResourceId,State:State}"
```

---

## Verification Results

### Data Residency  Confirmed

```bash
# Tokyo: RDS exists
aws rds describe-db-instances --region ap-northeast-1 \
  --query "DBInstances[].{DB:DBInstanceIdentifier,AZ:AvailabilityZone,Endpoint:Endpoint.Address}"
# Result: helga-rdslab3 in ap-northeast-1

# São Paulo: NO RDS
aws rds describe-db-instances --region sa-east-1 \
  --query "DBInstances[].DBInstanceIdentifier"
# Result: []
```

### TGW Peering  Available

```bash
aws ec2 describe-transit-gateway-peering-attachments --region ap-northeast-1 \
  --transit-gateway-attachment-ids tgw-attach-0e85595d1d9755e4b \
  --query "TransitGatewayPeeringAttachments[0].State"
# Result: "available"
```

### Cross-Region Connectivity  Confirmed

```bash
# From São Paulo EC2 (SSM session)
nc -vz helga-rdslab3.cv8u2kmkqq0y.ap-northeast-1.rds.amazonaws.com 3306
# Result: Connection succeeded
```

### Route Tables  Cross-Region CIDRs Present

```bash
# Tokyo: São Paulo CIDR routes to TGW
aws ec2 describe-route-tables --region ap-northeast-1 \
  --filters "Name=vpc-id,Values=vpc-0748475663d384e4e"
# Confirmed: 10.214.0.0/16 → tgw-0fa67d205d21bfa7f

# São Paulo: Tokyo CIDR routes to TGW
aws ec2 describe-route-tables --region sa-east-1 \
  --filters "Name=vpc-id,Values=vpc-0cfbddcac1adec6b3"
# Confirmed: 10.241.0.0/16 → tgw-0b6ee1c6f442d1804
```

---

## Lab 3B: Audit Evidence Pack

### Deliverable Structure

```
audit-pack/
├── 00_architecture-summary.md
├── 01_data-residency-proof.txt
├── 02_edge-proof-cloudfront.txt
├── 03_waf-proof.txt
├── 04_cloudtrail-change-proof.txt
├── 05_network-corridor-proof.txt
└── evidence.json   (Malgus scripts output)
```

### Malgus Evidence Scripts

| Script | Purpose |
| --- | --- |
| `malgus_residency_proof.py` | Proves RDS exists only in ap-northeast-1 |
| `malgus_tgw_corridor_proof.py` | TGW attachments + routes in both regions |
| `malgus_cloudtrail_last_changes.py` | Who changed SG / TGW / WAF / CloudFront |
| `malgus_waf_summary.py` | WAF Allow vs Block decision counts |
| `malgus_cloudfront_log_explainer.py` | Hit/Miss/RefreshHit analysis from S3 logs |

---

## What Is NOT Allowed

❌ RDS outside Tokyo

❌ Cross-region replicas

❌ Aurora Global Database

❌ Local caching of patient records

❌ CloudFront caching PHI

❌ "Active/active" databases

If you do these, the architecture is **illegal**, not just "wrong."

---

## Naming Conventions

| Region | Theme | Prefix | Deployed Examples |
| --- | --- | --- | --- |
| Tokyo | Train stations | `shinjuku` | `shinjuku_tgw01`, `shinjuku-attach-tokyo-vpclab3`, `shinjuku_to_liberdade_peer01` |
| São Paulo | Japanese district | `liberdade` | `liberdade_tgwlab3`, `liberdade-attach-sp-vpclab3`, `liberdade_accept_peer01` |
| Lab 2 (Tokyo) | Helga | `helga` | `helga_vpclab2a`, `helga_rds_sg01`, `helga_private_rt01` |

---

## Skills Demonstrated

- **Data Residency Architecture**  Designed APPI-compliant system where all PHI remains in Tokyo; São Paulo has zero data storage
- **Transit Gateway Hub-Spoke**  Deployed cross-region TGW (`shinjuku_tgw01` ↔ `liberdade_tgwlab3`) with peering corridor
- **TGW Peering State Machine**  Managed `pendingAcceptance` → `available` lifecycle with proper sequencing
- **Multi-State Terraform**  Two separate state files with cross-region variable passing via outputs → tfvars
- **Cross-Region Networking**  Private connectivity over AWS backbone; no public internet transit
- **CIDR-Based Security**  Used CIDR blocks for cross-VPC SG rules (SG references don't work cross-region)
- **Route Table Management**  Added cross-region routes (`10.214.0.0/16` → TGW in Tokyo, `10.241.0.0/16` → TGW in São Paulo)
- **State Recovery**  Used `terraform state rm` + `terraform import` to recover from drift without destroying infrastructure
- **Resource Validation**  Added regex validation to variables to catch whitespace and format errors
- **5-Phase Deployment**  Enforced strict dependency ordering due to TGW peering state machine
- **Data Source Lookups**  Used tag-based TGW lookups to avoid hard-coded ID brittleness
- **Audit Evidence Automation**  Built Python scripts (`malgus_*.py`) to generate compliance proof
- **CloudTrail Analysis**  Tracked who changed TGW, SG, WAF, CloudFront configurations
- **Multi-Region Provider Management**  Used `provider = aws.saopaulo` alias pattern in Terraform
- **Compliance Documentation**  Created audit pack proving data never leaves Japan

---

## Interview Talk Track

> "In Lab 3, I built a cross-region medical architecture compliant with Japan's APPI data privacy law. The requirement was that all patient health information had to remain in Tokyo  no copies, no replicas, no caching outside Japan. São Paulo needed compute capacity but couldn't store any data locally.
> 

> 
> 

> The solution was a hub-spoke Transit Gateway architecture. Tokyo got `shinjuku_tgw01` as the hub with the RDS database in `helga_vpclab2a` (10.241.0.0/16). São Paulo got `liberdade_tgwlab3` as the spoke with stateless compute in `liberdade_vpclab3` (10.214.0.0/16)  no RDS, no databases, no storage. TGW peering connected the two regions over the AWS backbone so São Paulo EC2 instances could query Tokyo RDS without touching the public internet.
> 

> 
> 

> The deployment was strictly ordered because TGW peering has a state machine: pending Acceptance → available. You can't add routes until peering reaches available, and you can't accept until the request reaches pending Acceptance. This forced a 5-phase deployment: Phase 1 created Tokyo's TGW, Phase 2 created São Paulo's TGW, Phase 3 sent the peering request from Tokyo, Phase 4 accepted it in São Paulo, and Phase 5 added the cross-region routes once peering was available. You cannot parallelize this the state machine enforces it.
> 

> 
> 

> I used two separate Terraform state files (one per region) with outputs from Tokyo feeding variables in São Paulo via tfvars. This created challenges: I learned that tfvars only accepts literal values, not expressions or data sources. When São Paulo's TGW was rebuilt during development, the ID changed but Tokyo's tfvars still had the old ID, breaking peering. I fixed it short-term by updating the tfvars manually, then long-term by switching to data source lookups by tag so IDs could change without breaking references.
> 

> 
> 

> Another challenge was cross-region security group rules. I tried to reference São Paulo's EC2 security group in Tokyo's RDS security group ingress rule, but SG references only work within the same VPC. The fix was CIDR-based rules: Tokyo RDS allows 10.214.0.0/16 (São Paulo's entire VPC CIDR) on port 3306.
> 

> 
> 

> When multiple failed peering attempts left Terraform state out of sync with AWS, I recovered using `terraform state rm` to remove the stale reference, then `terraform import` to bring the working peering attachment back into state. Failed TGW peering attachments can't be deleted via API  AWS garbage-collects them automatically  so import was the only way to recover without destroying working infrastructure.
> 

> 
> 

> For compliance proof, I built an audit evidence pack with five Python scripts that query AWS APIs: one proves RDS exists only in Tokyo, one maps the TGW peering corridor with all attachments and routes, one shows CloudTrail history of who changed security-critical resources, one summarizes WAF allow/block decisions, and one analyzes CloudFront cache behavior from S3 access logs. This gives auditors machine-readable proof that PHI never left Japan.
> 

> 
> 

> The architecture demonstrates that data residency isn't just policy  it's enforced by making violations impossible. São Paulo has zero capability to store data. All patient information lives in Tokyo, and São Paulo compute accesses it over a controlled private corridor."
> 

---

## Lab 3B: Audit Evidence Pack (Deliverables)

Lab 3B shifts from building infrastructure to **proving compliance**. Auditors need machine-readable evidence showing PHI never left Japan.

### Deliverable A: Audit Evidence Pack

```
audit-pack/
├── 00_architecture-summary.md
├── 01_data-residency-proof.txt
├── 02_edge-proof-cloudfront.txt
├── 03_waf-proof.txt
├── 04_cloudtrail-change-proof.txt
├── 05_network-corridor-proof.txt
└── evidence.json (Malgus scripts output)
```

**What each file proves:**

| File | Evidence Type | Why It Matters |
| --- | --- | --- |
| `00_architecture-summary.md` | System design overview | Shows auditors the big picture: Tokyo = data authority, São Paulo = stateless compute |
| `01_data-residency-proof.txt` | RDS location verification | Proves no databases exist in São Paulo; all PHI stored only in Tokyo |
| `02_edge-proof-cloudfront.txt` | CloudFront logs (Hit/Miss/RefreshHit) | Proves direct ALB access is blocked; all traffic flows through CloudFront+WAF |
| `03_waf-proof.txt` | WAF decision logs (Allow vs Block) | Shows edge security is active and filtering traffic |
| `04_cloudtrail-change-proof.txt` | Who changed what (90-day history) | Tracks modifications to TGW, SG, WAF, CloudFront  answers "who touched security-critical resources?" |
| `05_network-corridor-proof.txt` | TGW attachments + routes | Maps the private corridor: São Paulo → TGW peering → Tokyo |
| `evidence.json` | Malgus scripts aggregated output | Machine-readable format for automated compliance checks |

### Deliverable B: Auditor Narrative (8-12 lines)

**Example narrative:**

> "This architecture complies with APPI by enforcing data residency: all patient health information (PHI) resides exclusively in Tokyo (ap-northeast-1) RDS. São Paulo (sa-east-1) operates as stateless compute only  no databases, no local caching. The two regions communicate via AWS Transit Gateway peering over the AWS private backbone, never traversing the public internet. CloudFront provides global access while WAF filters malicious traffic at the edge. Direct ALB access is blocked via security group prefix lists and secret header validation. CloudTrail maintains a 90-day immutable audit log of all infrastructure changes. This design makes APPI violations architecturally impossible, not just policy-enforced."
> 

### Malgus Evidence Scripts (5 Python Scripts)

| Script | What It Proves | Data Source |
| --- | --- | --- |
| `malgus_residency_proof.py` | RDS exists only in Tokyo | `aws rds describe-db-instances` (both regions) |
| `malgus_tgw_corridor_proof.py` | TGW peering + cross-region routes | `aws ec2 describe-transit-gateway-*`  • route tables |
| `malgus_cloudtrail_last_changes.py` | Who modified security resources | CloudTrail Event History (90-day default) |
| `malgus_waf_summary.py` | WAF Allow/Block decision counts | CloudWatch Logs (`aws-waf-logs-*`) |
| `malgus_cloudfront_log_explainer.py` | Cache behavior (Hit/Miss/RefreshHit) | CloudFront standard logs in S3 |

**Running the scripts:**

```bash
# Data residency proof
python3 malgus_residency_proof.py > audit-pack/01_data-residency-proof.txt

# TGW corridor proof
python3 malgus_tgw_corridor_proof.py > audit-pack/05_network-corridor-proof.txt

# CloudTrail changes (last 90 days)
python3 malgus_cloudtrail_last_changes.py > audit-pack/04_cloudtrail-change-proof.txt

# WAF summary
python3 malgus_waf_summary.py > audit-pack/03_waf-proof.txt

# CloudFront cache analysis
python3 malgus_cloudfront_log_explainer.py --latest 5 > audit-pack/02_edge-proof-cloudfront.txt
```

### Lab Assumptions (Fixed Values)

- **S3 Bucket:** `Class_Lab3`
- **CloudFront Logs Prefix:** `Chwebacca-logs/` (intentionally misspelled)
- **Domain:** `chewbacca-growls.com`
- **AWS Account ID:** `xxxxxxxxxxxx` (your actual account, not the lab assumption)

### What Good Evidence Looks Like

Auditors want 6 things:

1. **Data Residency:** RDS in Tokyo only, none elsewhere
2. **Access Trail:** Who accessed the API (CloudFront logs, not raw user IPs)
3. **Change Trail:** Who modified security configurations (CloudTrail)
4. **Network Corridor:** São Paulo → TGW → Tokyo route proof
5. **Edge Security:** CloudFront + WAF in front, direct ALB blocked
6. **Retention/Immutability:** Logs stored in S3 with versioning enabled

---

## Repository Structure (Actual)

```
lab3/
├── tokyo/
│   ├── 02-providers.tf           # Added aws.saopaulo alias
│   ├── 03-variables.tf           # Added Lab 3 vars (CIDRs, TGW IDs, enable_tgw)
│   ├── 04-3a-tokyo-tgw.tf        # shinjuku_tgw01, VPC attachment, peering request
│   ├── 04-3b-tokyo-routes.tf      # helga_private_rt01: 10.214.0.0/16 → TGW
│   ├── 04-3c-rds-sg-update.tf     # helga_rds_sg01 allows 10.214.0.0/16 on 3306
│   ├── 05-outputs.tf              # tokyo_tgw_id, tokyo_vpc_cidr_block, tokyo_rds_endpoint
│   └── terraform.tfvars           # saopaulo_tgw_id = "tgw-0b6ee1c6f442d1804"
│
├── saopaulo/
│   ├── 01-version.tf              # Terraform >= 1.5.0, AWS >= 5.0
│   ├── 02-providers.tf            # aws provider for sa-east-1
│   ├── 03-variables.tf            # São Paulo CIDRs + tokyo_tgw_id, tokyo_rds_endpoint
│   ├── 04-main.tf                 # liberdade_vpclab3, subnets, IGW, NAT (NO RDS)
│   ├── 04-P-main-saopaulo-tgw.tf  # liberdade_tgwlab3 (spoke), VPC attachment, peering accepter
│   ├── sao-paulo-routes.tf        # liberdade_private_rtlab3: 10.241.0.0/16 → TGW
│   ├── 05-outputs.tf              # saopaulo_tgw_id, saopaulo_vpc_cidr
│   └── terraform.tfvars           # tokyo_tgw_id, tokyo_rds_endpoint
│
└── scripts/
    ├── malgus_residency_proof.py
    ├── malgus_tgw_corridor_proof.py
    ├── malgus_cloudtrail_last_changes.py
    ├── malgus_waf_summary.py
    └── malgus_cloudfront_log_explainer.py
```