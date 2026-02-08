# Auditor Narrative — APPI Compliance Statement

This architecture enforces data residency by storing all Protected Health Information (PHI) in a single RDS MySQL instance located exclusively in Tokyo (ap-northeast-1), with no database replicas or storage resources in any other AWS region.

Under Japan's Act on the Protection of Personal Information (APPI), personal data of Japanese citizens must remain within Japanese jurisdiction unless explicit consent or an adequacy determination exists — this design eliminates that risk entirely by confining PHI to Tokyo.

Sao Paulo (sa-east-1) operates as a compute-only region: its EC2 instances process requests and communicate with Tokyo's database over a private Transit Gateway peering corridor, never storing PHI locally.

All user traffic enters through a single CloudFront distribution protected by AWS WAF, which inspects every request for common web attacks before forwarding it to the origin — direct access to the ALB is blocked via a custom header validation mechanism.

A multi-region CloudTrail trail records all management-plane activity across both regions to a versioned S3 bucket, providing an immutable record of who changed security groups, WAF rules, TGW routes, or CloudFront configurations.

VPC Flow Logs capture network metadata in both regions, proving that cross-region traffic flows exclusively through the Transit Gateway and not over the public internet.

WAF logs in CloudWatch record every Allow and Block decision, enabling security teams to detect and investigate anomalous traffic patterns.

CloudFront standard logs in S3 document every viewer request, including cache behavior (Hit/Miss/RefreshHit), providing evidence that the edge layer is functioning as designed.

All log buckets have S3 versioning enabled, ensuring that audit evidence cannot be silently deleted or tampered with — a requirement for regulatory confidence.

In summary, this design proves that PHI never leaves Japan, all access is mediated through secured edge infrastructure, and every change and access event is logged in a tamper-resistant manner suitable for regulatory audit.
