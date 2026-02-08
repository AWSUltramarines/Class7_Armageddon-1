# Architecture Summary — APPI-Compliant Multi-Region Design

## Overview

This architecture serves a medical application that must comply with Japan's Act on the Protection of Personal Information (APPI). Protected Health Information (PHI) is stored exclusively in Tokyo (`ap-northeast-1`), while compute resources in Sao Paulo (`sa-east-1`) handle application logic without local data storage. All traffic enters through a global CloudFront distribution fronted by AWS WAF, ensuring edge security and access control before requests reach the origin.

## Data Residency (Tokyo Only)

- **RDS MySQL** (`akihabara-dev-mysql`) runs in `ap-northeast-1c` — this is the only database in the architecture
- **No RDS instance exists in Sao Paulo** or any other region
- Database credentials are stored in AWS Secrets Manager and SSM Parameter Store within the Tokyo region
- This guarantees that PHI never leaves Japanese jurisdiction

## Edge Security (CloudFront + WAF)

- **CloudFront Distribution** (`EQQRUTNIGIKPP`) serves as the single global entry point for all user traffic
- **Global WAF** (`akihabara-cf-waf`, scope: CLOUDFRONT, us-east-1) inspects all requests at the edge before they reach the origin
- **Regional WAF** (`akihabara-dev-web-acl`, scope: REGIONAL, ap-northeast-1) protects the ALB with AWS Managed Rules (Common Rule Set for SQLi, XSS)
- **Direct ALB access is blocked** — the ALB validates a custom origin header that only CloudFront knows, rejecting any request that bypasses the CDN
- CloudFront standard logs are written to S3 (`akihabara-dev-cloudfront-standard-logs`) for audit evidence

## Network Corridor (Transit Gateway Peering)

- **Tokyo TGW** (`tgw-0dc41479dfabcd940`) acts as the hub
- **Sao Paulo TGW** (`tgw-0a3c7c6d1092d5d98`) acts as the spoke
- Inter-region peering connects the two TGWs, with static routes directing cross-region CIDR traffic through the TGW attachment
- Tokyo VPC CIDR: `10.10.0.0/16`, Sao Paulo VPC CIDR: `10.15.0.0/16`
- Sao Paulo compute instances communicate with Tokyo's RDS exclusively through this TGW corridor — there is no public internet path between regions

## Logging & Audit Trail

| Log Source | Destination | Coverage |
|---|---|---|
| **CloudTrail** | S3 (`akihabara-dev-cloudtrail-audit-logs`) | Multi-region trail capturing management events from all regions |
| **VPC Flow Logs** | CloudWatch Logs | Enabled in both Tokyo and Sao Paulo VPCs |
| **WAF Logs** | CloudWatch Logs (`aws-waf-logs-akihabara-webacl`) | Allow/Block decisions on all ALB-bound requests |
| **CloudFront Standard Logs** | S3 (`akihabara-dev-cloudfront-standard-logs`) | Viewer request details including cache Hit/Miss/RefreshHit |
| **ALB Access Logs** | S3 | Request-level access logs for the application load balancer |

## Retention & Immutability

- **S3 versioning is enabled** on CloudTrail, CloudFront, and ALB log buckets — objects cannot be permanently deleted without removing all versions
- **CloudTrail Event History** provides a 90-day immutable record of management events by default
- CloudWatch Logs retention policies are configured on all log groups
- This posture ensures audit logs cannot be silently tampered with or destroyed
