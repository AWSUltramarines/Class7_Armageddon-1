# Class 10 – Lab 3A: Global Transit Gateway (Tokyo ↔ São Paulo)

## Goal Statements

### Concise:

Connect an application in São Paulo (`sa-east-1`) to a centralized RDS database in Tokyo (`ap-northeast-1`) using Transit Gateway (TGW) Peering.

### Infrastructure‑Focused:

Establish a high-performance, multi-region backbone using AWS Transit Gateway. You will deploy two TGWs—one in Tokyo and one in São Paulo—and interconnect them via TGW Peering. The São Paulo region will host a full application stack (ALB, ASG, CloudFront) but will rely on the Tokyo RDS instance for data persistence, simulating a centralized database architecture with cross-region application nodes.

---

---

### Infrastructure Change

* **Multi-Regional TGW:** Deploy regional TGWs in `ap-northeast-1` and `sa-east-1`.
* **TGW Peering:** Establish a cross-region peering attachment to bridge the AWS backbone.
* **Regional Specialization:** * **Tokyo:** Maintains the RDS instance and centralized database security groups.
* **São Paulo:** Deploys application tiers but **removes** local RDS and database-related resources (Alarms/Subnet Groups).


* **Inter-Region Routing:** Update VPC Route Tables in both regions to direct cross-VPC traffic through the local TGW.

## File Structure & Naming Conventions

To distinguish between regions, we use a specific naming theme:

* **Tokyo (`ap-northeast-1`):** Train Stations (Prefix: `shinjuku-`).
* **São Paulo (`sa-east-1`):** Japanese District (Prefix: `liberdade-`).

| File | Region | Purpose |
| --- | --- | --- |
| `00.provider.tf` | Global | Multi-region provider blocks for `ap-northeast-1` and `sa-east-1`. |
| `tokyo_tgw.tf` | Tokyo | Tokyo TGW creation and peering request. |
| `sao_paulo_tgw.tf` | SP | São Paulo TGW, VPC attachment, and peering acceptance. |
| `tokyo_routes.tf` | Tokyo | Route: São Paulo CIDR → Tokyo TGW. |
| `sao_paulo_routes.tf` | SP | Route: Tokyo CIDR → São Paulo TGW. |
| `tokyo_rds_sg.tf` | Tokyo | Updates RDS SG to allow 3306 from São Paulo VPC CIDR. |

---

## 🏗️ The Networking Path

São Paulo EC2 instances connect to Tokyo RDS as if it were a local subnet, traversing the AWS backbone:

1. **SP EC2** initiates a request to the Tokyo RDS Private IP.
2. **SP VPC Route Table** identifies the Tokyo CIDR and targets the **São Paulo TGW**.
3. **TGW Peering** carries the packet to the **Tokyo TGW**.
4. **Tokyo TGW** delivers the packet to the **Tokyo VPC Attachment**.
5. **Tokyo RDS Security Group** permits inbound traffic on port 3306 from the **São Paulo VPC CIDR**.

---

## 🛠️ Key Implementation Details

### 1. The Peering Handshake

Transit Gateway is a **regional** resource. You cannot attach a São Paulo VPC directly to a Tokyo TGW. You must:

* Create TGWs in both regions.
* Initiate a **TGW Peering Attachment** from Tokyo.
* **Accept** the Peering Attachment in São Paulo.

### 2. Security Group Reality Check

Security Group referencing (referencing an SG ID) does **not** work across regions via TGW.

* **Action:** You must allow the **CIDR block** of the São Paulo application subnets in the Tokyo RDS Security Group rules.

### 3. DNS Resolution

Ensure `enableDnsSupport` and `enableDnsHostnames` are true in both VPCs so the RDS endpoint continues to resolve to its private IP across the TGW link.

### 4. Terraform Workflow

#### Phase 1:
+ cd /saopaulo
+ terraform init
+ terraform plan
+ terraform apply

take note of tgw id

---

#### Phase 2:
+ cd /tokyo
+ fill in tgw id from phase 1 in tfvars file
+ terraform init
+ terraform plan
+ terraform apply

take note of tgw id
take note of rds endpoint

---

#### Phase 3:

+ cd /saopaulo
+ fill in tgw id from phase 2 in tfvars file
+ fill in rds endpoint from phase 2 in tfvars file
+ terraform plan
+ terraform apply

---


## ✅ Lab 3A Architecture Verification

Verification done via lab3a_verification.sh. Coded via AI.

Execute the following script to prove your global infrastructure is correctly wired:

```bash
echo "========== LAB 3A ARCHITECTURE VERIFICATION =========="
# Verify VPCs
aws ec2 describe-vpcs --region ap-northeast-1 --filters "Name=cidr-block,Values=10.241.0.0/16" --query "Vpcs[0].VpcId" --output text
aws ec2 describe-vpcs --region sa-east-1 --filters "Name=cidr-block,Values=10.214.0.0/16" --query "Vpcs[0].VpcId" --output text

# Verify TGWs and Peering
aws ec2 describe-transit-gateways --region ap-northeast-1 --query "TransitGateways[0].Options.AmazonSideAsn" # Expected: 64512
aws ec2 describe-transit-gateways --region sa-east-1 --query "TransitGateways[0].Options.AmazonSideAsn"    # Expected: 64513
aws ec2 describe-transit-gateway-peering-attachments --region ap-northeast-1 --query "TransitGatewayPeeringAttachments[0].State" # Expected: available

# Verify RDS Locality (Tokyo = Yes, SP = Empty)
aws rds describe-db-instances --region ap-northeast-1 --query "DBInstances[0].DBInstanceIdentifier"
aws rds describe-db-instances --region sa-east-1 --query "DBInstances[].DBInstanceIdentifier" # Should be []
echo "========== VERIFICATION COMPLETE =========="

```