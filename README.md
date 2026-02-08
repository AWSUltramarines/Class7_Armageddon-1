# Armageddon — Complete AWS Architecture Challenge

**Three labs. One stack. Foundation → Edge Security → Multi-Region Compliance.**

---

## The Mission

Armageddon demanded progressive construction of a production-grade AWS architecture across three labs — each building on the last, each raising the complexity ceiling:

- **Lab 1** built the foundation (VPC, EC2, RDS, IAM, Secrets, CloudWatch), then converted every manual resource into Terraform IaC with seven bonus rounds adding private compute, ALB, TLS, WAF, Route53, and incident response runbooks.
- **Lab 2** locked the front door — CloudFront replaced the ALB as the sole public entry point, with two-layer origin cloaking, behavior-specific cache policies, origin-driven caching, and invalidation discipline.
- **Lab 3** extended the architecture across regions — a Transit Gateway hub-spoke corridor connected Tokyo (data authority) to São Paulo (stateless compute) under Japan's APPI data privacy law, with automated audit evidence scripts proving PHI never left Japan.

**Naming Convention:** Helga

**AWS Account:** 919113286081

**Timeline:** January – February 2026

**Domain:** williebright.com / app.williebright.com

---

## Architecture Evolution

| Lab | Focus | Region(s) | Key Addition |
| --- | --- | --- | --- |
| **1A** | Foundation (ClickOps) | us-east-2 | VPC, EC2, RDS, Secrets Manager, SG-to-SG |
| **1B** | Operations + Incident Response | us-east-2 | SSM Parameters, CloudWatch Logs/Alarms, SNS, live sabotage exercise |
| **1C** | Terraform IaC + 7 Bonus Rounds | us-east-2 | Full IaC, private EC2, ALB + TLS 1.3, WAF, Route53, multi-destination logging, runbooks |
| **2A** | Origin Cloaking | us-east-1 | CloudFront, SG prefix list lock, secret header validation, CLOUDFRONT-scope WAF |
| **2B** | Cache Correctness | us-east-1 | Cache policies (static aggressive / API zero-TTL), origin-driven caching, invalidation discipline |
| **3A** | Cross-Region Transit Gateway | ap-northeast-1 + sa-east-1 | TGW hub-spoke, peering corridor, APPI data residency, CIDR-based cross-VPC security |
| **3B** | Audit Evidence Pack | ap-northeast-1 + sa-east-1 | 5 Python scripts proving compliance, CloudTrail analysis, auditor narrative |

---

## Final Architecture Flow

```
Internet → Route53 (williebright.com)
         → CloudFront (helga_cf_distlab2a + WAF, 3 rules)
         → ALB (SG = CF prefix list only + X-Helga-Origin-Verify or 403)
         → Target Group → Private EC2 (Flask app)
         → RDS MySQL (Tokyo ONLY — APPI compliant)
                ↑
         São Paulo EC2 → liberdade_tgwlab3 → TGW Peering → shinjuku_tgw01 → Tokyo VPC → RDS
```

---

## Lab 1: EC2 → RDS Integration + Terraform IaC

**Region:** us-east-2 (Ohio) · **Timeline:** January 2026

**Lab 1A** deployed the foundation manually — VPC (`helga-vpc01`, 10.241.0.0/16), public EC2 running a Flask notes app, private RDS MySQL, Secrets Manager for credentials, and SG-to-SG security references.

**Lab 1B** layered operations — SSM Parameter Store for config, CloudWatch Logs with ERROR filtering, Alarms, SNS notifications, and a **live sabotage exercise** where the group lead poisoned credentials three ways (typo injection, prefix injection, username poison). Detection through logs and recovery using stored config proved the operations stack under pressure.

**Lab 1C** converted everything to Terraform and executed **seven bonus rounds** (A→G): private EC2 with 6 VPC Endpoints, internet-facing ALB with TLS 1.3 + ACM, WAF with AWS Managed Rules, Route53 DNS with apex domain, multi-destination WAF logging (CloudWatch/S3/Firehose as variable-driven toggles), Logs Insights query packs, and a Bedrock Auto-IR pipeline template.

**Key Challenges:** Subnet CIDR conflicts from leftover ClickOps resources, AMI architecture mismatches, Secrets Manager 30-day deletion windows, user data runs-once behavior, ENI cleanup races, state drift from partial applies requiring full destroy-and-rebuild.

### Detailed Records

- README.md — Lab 1 full execution record (all three phases)
- 1C_README.md — Terraform IaC + Bonus A–G details + Lucidchart instructions
- Lab_1B_README.md — Operations, sabotage exercise, recovery procedures
- Lab 1 Docs — Working files and Terraform code

---

## Lab 2: CloudFront Origin Cloaking + Cache Correctness

**Region:** us-east-1 · **Timeline:** January – February 2026

**Lab 2A** deployed two-layer origin cloaking:

- **Layer 1 (Network):** ALB Security Group accepts only HTTPS 443 from the AWS-managed CloudFront prefix list — direct internet access times out.
- **Layer 2 (Application):** ALB HTTPS listener defaults to 403 Forbidden; only requests carrying `X-Helga-Origin-Verify` reach the target group.

WAF moved from REGIONAL scope (on ALB) to CLOUDFRONT scope with three rules: rate limiting (2000 req/5min), AWSManagedRulesCommonRuleSet, AWSManagedRulesKnownBadInputsRuleSet.

**Lab 2B** configured behavior-specific caching — static content (`/static/*`) caches aggressively (1-year max TTL), API responses pass straight through (all TTLs at zero). Migrated from legacy `forwarded_values` to modern `cache_policy_id` / `origin_request_policy_id`.

**Honors A** implemented origin-driven caching — Flask `/api/public-feed` sends `Cache-Control: public, s-maxage=30, max-age=0`, and CloudFront respects the TTL. Verified the Miss → Hit → Miss cycle.

**Honors B** established invalidation discipline — versioning-first for static assets, break-glass invalidation only for security incidents, budget awareness (1,000 free paths/month).

**Key Challenges:** Authorization header restriction in custom ORPs (switched to Managed-AllViewer), two separate ACM certificates required (CloudFront us-east-1 + ALB regional), WAF scope mismatch, RefreshHit behavior clarification.

### Detailed Records

- 2A_2B_README.md — Combined execution record (origin cloaking + cache correctness)
- README-2A.md — Origin cloaking deep dive
- README-2B.md — Cache correctness + Honors A/B
- Lab 2 Docs — Working files and Terraform code

---

## Lab 3: Cross-Region Transit Gateway + APPI Compliance

**Regions:** ap-northeast-1 (Tokyo) + sa-east-1 (São Paulo) · **Timeline:** February 2026

**Lab 3A** built a hub-spoke Transit Gateway corridor:

- **Tokyo (Hub):** `shinjuku_tgw01` — manages routing between `helga_vpclab2a` (10.241.0.0/16) and the peering corridor. All PHI stays in Tokyo RDS.
- **São Paulo (Spoke):** `liberdade_tgwlab3` — connects `liberdade_vpclab3` (10.214.0.0/16) with stateless compute only. **Zero databases. Zero local caching.**
- **Peering:** `shinjuku_to_liberdade_peer01` — connects the two TGWs over the AWS backbone.

The deployment required two separate Terraform state files and a strict **5-phase dependency chain** because TGW peering enforces a state machine (`pendingAcceptance` → `available`).

**Lab 3B** produced an audit evidence pack — five Python scripts (`malgus_*.py`) proving data residency, edge security, WAF posture, CloudTrail change history, and TGW corridor mapping.

**Key Challenges:** TGW regional limitation requiring hub-spoke, stale TGW IDs from destroy/recreate cycles, tfvars accepting only literals, whitespace creating malformed IDs, SG references not working cross-VPC (switched to CIDR), peering state machine enforcing strict ordering, state drift recovery via `terraform state rm` + `import`.

### Detailed Records

- lab3_README.md — Full execution record (3A + 3B)
- Lab 3 Docs — Working files, Terraform code, and scripts

---

## Skills Demonstrated (All Labs)

### Infrastructure & Networking

- Multi-AZ VPC design with public/private subnets, NAT Gateway, IGW, route tables
- VPC Endpoints for private AWS service access (SSM, Logs, Secrets Manager, S3)
- Cross-region Transit Gateway hub-spoke with peering corridor
- CIDR-based security rules for cross-VPC communication

### Security

- SG-to-SG references (intra-VPC), CIDR blocks (cross-VPC)
- Two-layer origin cloaking (SG prefix list + secret header)
- WAF at both REGIONAL and CLOUDFRONT scope with AWS Managed Rules + rate limiting
- TLS 1.3 via ACM certificates with DNS validation
- Secrets Manager + SSM Parameter Store dual storage pattern

### Edge & CDN

- CloudFront as sole public ingress with behavior-specific caching
- Cache policy design: aggressive static, zero-TTL API, origin-driven dynamic
- Origin Request Policy management (Managed-AllViewer for Authorization header)
- Response headers with security directives (X-Content-Type-Options, X-Frame-Options)
- Invalidation discipline: versioning-first, break-glass only

### Observability

- CloudWatch Logs, metric filters, symptom-based alarms, SNS notifications
- ALB access logs to S3, WAF logging to CloudWatch/S3/Firehose (variable-driven)
- Logs Insights query packs for incident triage
- CloudWatch Dashboard for ALB metrics

### Compliance & Audit

- APPI-compliant data residency (PHI in Tokyo only, São Paulo stateless)
- Automated audit evidence scripts (Python) proving compliance
- CloudTrail analysis for security-critical resource changes

### Terraform & IaC

- Full ClickOps-to-Terraform migration
- Multi-region, multi-state Terraform with cross-state variable passing
- State drift recovery via `terraform state rm` + `import`
- Variable validation with regex patterns
- Data source lookups by tag for cross-state resilience
- 5-phase deployment ordering for TGW peering state machine

### Troubleshooting

- 20+ distinct Terraform/AWS challenges resolved across all labs
- Live sabotage exercise (credential poisoning detection + recovery)
- User data runs-once, ENI cleanup races, secret deletion windows
- Cross-region SG limitations, TGW peering state machine, tfvars syntax constraints

---

## Master Interview Talk Track

> "The Armageddon challenge pushed me through three progressively complex AWS labs over six weeks.
> 

> 
> 

> In Lab 1, I built a secure EC2-to-RDS architecture starting with manual deployment, then layered operations with dual secret storage and CloudWatch observability. After surviving a live sabotage exercise — three credential poisoning attacks that I detected and recovered using only logs and stored values — I converted the entire stack to Terraform IaC and completed seven bonus rounds. The final Lab 1 architecture delivered private compute with VPC endpoints, internet-facing ALB with TLS 1.3 and WAF, Route53 DNS, multi-destination logging, and a documented incident response runbook.
> 

> 
> 

> Lab 2 locked the front door. I replaced the public ALB with CloudFront as the sole entry point, deploying two-layer origin cloaking: the ALB security group accepts only CloudFront prefix list IPs, and the HTTPS listener defaults to 403 unless requests carry a secret header that CloudFront injects. I then configured cache correctness — aggressive caching for static content, zero-TTL pass-through for APIs, and origin-driven caching via Cache-Control headers for dynamic public feeds. The Honors tracks established invalidation discipline: versioning-first for static assets, break-glass invalidation only for security incidents.
> 

> 
> 

> Lab 3 extended the architecture across regions for APPI compliance. Tokyo holds all patient health information in RDS — no copies, no replicas, no caching outside Japan. São Paulo provides stateless compute that queries Tokyo RDS over a Transit Gateway hub-spoke corridor, never touching the public internet. The deployment demanded a strict 5-phase sequence because TGW peering enforces a state machine. I used two separate Terraform state files with cross-state variable passing, recovered from state drift using `terraform state rm` and `import`, and built five Python audit scripts proving PHI never left Japan.
> 

> 
> 

> Across all three labs, I resolved over 20 distinct challenges — from CIDR conflicts and AMI mismatches to secret deletion windows, cross-region SG limitations, and TGW peering failures. The biggest lesson: production AWS architecture demands understanding not just what resources do, but how they fail, how they sequence, and how they drift."
> 

---

## Repository Structure

```
armageddon/
├── lab1/                              # us-east-2
│   ├── 01-version.tf
│   ├── 02-providers.tf
│   ├── 03-variables.tf
│   ├── 04-main.tf                     # VPC, EC2, RDS, IAM, SSM, Secrets, CW, SNS
│   ├── 04-1cb-Main.tf                 # Bonus B: ALB, TLS, WAF, Dashboard
│   ├── 04-1cc-route53.tf              # Bonus C: Route53 + ACM DNS validation
│   ├── 04-1cd-logging-apex.tf         # Bonus D: Apex + ALB logs to S3
│   ├── 04-1ce-Main.tf                 # Bonus E: WAF logging (CW/S3/Firehose)
│   ├── 05-outputs.tf
│   ├── terraform.tfvars
│   └── user_data.sh
│
├── lab2/                              # us-east-1
│   ├── 01-version.tf
│   ├── 02-providers.tf
│   ├── 03-variables.tf
│   ├── 04-2a-Main.tf                  # ACM + Route53 → CloudFront
│   ├── 04-2ab-Main.tf                 # ALB SG lock + secret header listener
│   ├── 04-2ac-main.tf                 # CloudFront + WAF (CLOUDFRONT scope)
│   ├── 04-2ad-Main.tf                 # WAF logging
│   ├── 04-2B-cache_correctness.tf     # Cache + ORP + response headers
│   ├── lab2b_honors_origin_driven.tf  # Honors A: origin-driven caching
│   ├── 05-outputs.tf
│   └── terraform.tfvars
│
└── lab3/
    ├── tokyo/                         # ap-northeast-1
    │   ├── 04-3a-tokyo-tgw.tf         # shinjuku_tgw01 + peering request
    │   ├── 04-3b-tokyo-routes.tf      # 10.214.0.0/16 → TGW
    │   ├── 04-3c-rds-sg-update.tf     # Allow São Paulo CIDR on 3306
    │   └── terraform.tfvars
    │
    ├── saopaulo/                      # sa-east-1
    │   ├── 04-main.tf                 # liberdade_vpclab3 (NO RDS)
    │   ├── 04-P-main-saopaulo-tgw.tf  # Spoke TGW + peering accepter
    │   ├── sao-paulo-routes.tf        # 10.241.0.0/16 → TGW
    │   └── terraform.tfvars
    │
    └── scripts/
        ├── malgus_residency_proof.py
        ├── malgus_tgw_corridor_proof.py
        ├── malgus_cloudtrail_last_changes.py
        ├── malgus_waf_summary.py
        └── malgus_cloudfront_log_explainer.py
```