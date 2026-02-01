# Class 7 Armageddon Lab 1b

## RDS Connectivity Failure Lab
### Overview
This lab simulates a real‑world incident where an application running on a public EC2 instance loses connectivity to a private RDS MySQL database due to a misconfigured security group. The environment uses least‑privilege IAM access to Secrets Manager and Parameter Store, and relies on CloudWatch + SNS for alerting. During the chaos injection, the monitoring pipeline failed to detect the outage, requiring manual investigation to identify the root cause.
