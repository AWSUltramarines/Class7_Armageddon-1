# Class 7 – Armageddon Lab 1c-e

## Goal Statements

## Concise:
Enable AWS WAF logging using Terraform with support for CloudWatch Logs, S3, or Firehose as the destination.
## Infrastructure‑Focused:
Extend the existing ALB + Route53 + ACM deployment by adding configurable AWS WAF logging using aws_wafv2_web_acl_logging_configuration, supporting CloudWatch Logs, S3, or Kinesis Data Firehose as selectable destinations. Enforce AWS naming requirements, retention policies, and provide verification commands to validate log delivery.



---
Route53 Zone Apex + app Records → ACM DNS Validation → ALB with HTTPS Listener + WAF Logging (CloudWatch / S3 / Firehose) → Private EC2 (SSM‑only) via VPC Interface Endpoints → Private RDS MySQL

---

## File structure
|-- 00.provider.tf
|-- 01.main.tf
|-- 02.variables.tf
|-- 03.data.tf
|-- 04.output.tf
|-- modules
|   |-- alerts
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- autoscaling
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- compute
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- database
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- iam
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- load_balancer
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- network
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- route53
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- s3bucket
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- secrets
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   |-- vpc_endpoints
|   |   |-- main.tf
|   |   |-- output.tf
|   |   `-- variables.tf
|   `-- waf
|       |-- main.tf
|       |-- output.tf
|       `-- variables.tf
|-- readme.md
`-- userdata.sh


### Overview
This lab introduces production‑grade WAF logging into your Terraform deployment. AWS WAF now supports sending logs to one of three destinations:
- CloudWatch Logs
- S3
- Kinesis Data Firehose

Terraform provisions the selected destination and configures the Web ACL to deliver logs accordingly. The log destination name must follow AWS requirements and begin with:

```hcl
aws-waf-logs-
```

This module also includes optional toggles for sampled‑requests‑only mode and log retention settings.


---

Objectives
- Add WAF logging to the existing Web ACL using Terraform
- Support one destination per Web ACL: CloudWatch, S3, or Firehose
- Enforce AWS naming requirements for WAF log groups and S3 prefixes
- Configure CloudWatch retention policies
- Provide verification commands to confirm logs are flowing
- Append outputs to help students locate the log destination
- Maintain consistency with the existing ALB + Route53 + ACM + private EC2 architecture

---


Terraform‑Managed Resources
This lab introduces new resources and enhancements:
### WAF Logging Configuration
- aws_wafv2_web_acl_logging_configuration
- Conditional logic based on var.waf_log_destination
- Support for:
- CloudWatch Logs log group
- S3 bucket + prefix
- Kinesis Data Firehose delivery stream
### CloudWatch Logs (Optional)
- Log group named aws-waf-logs-<identifier>
- Retention policy controlled by var.waf_log_retention_days
### S3 (Optional)
- S3 bucket for WAF logs
- Required bucket policy for WAF log delivery
- Prefix must start with aws-waf-logs-
### Firehose (Optional)
- Delivery stream for WAF logs
- IAM role for Firehose → S3 or Firehose → destination
### Outputs
- Log destination ARN or name
- Helpful for verification and debugging


---

## New Updates
### 1. WAF Logging Destination Toggle
- Choose one destination:
```hcl
variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}
```

Terraform skeleton includes three blocks:
- CloudWatch Logs
- S3
- Firehose
Only one is activated based on the variable.


### 2. CloudWatch Log Retention
variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

This ensures logs don’t accumulate indefinitely.

### 3. Sampled‑Requests‑Only Toggle
```hcl
variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}
```
This prepares students for future labs involving field redaction and sampling.

### 4. New Terraform File
- CloudWatch log group
- S3 bucket + policy
- Firehose delivery stream
- WAF logging configuration
- Conditional logic for destination selection

### 5. Outputs
```hcl
output "chewbacca_waf_log_destination" {
  value = local.waf_log_destination_identifier
}
```

Explanation:
Coordinates for the WAF log destination