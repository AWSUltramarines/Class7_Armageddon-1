Lab 1C-Bonus-D adds critical audit and incident response capabilities to your stack. By enabling the **Zone Apex** and **Access Logs**, you are ensuring your root domain (`daequanbritt.com`) works just as well as your subdomains (`app.daequanbritt.com`) and that every request is logged for security audits.

# 🛰️ Assignment Breakdown: Bonus-D

* **🌍 The Front Gate (Zone Apex)**: You are creating an ALIAS record for the "naked" domain (`daequanbritt.com`) so it points directly to your Load Balancer, just like your `app` subdomain.
* **📜 Flight Logs (ALB Access Logs)**: You are configuring the ALB to send detailed logs of every request to an S3 bucket. This is "incident response fuel" used to track client IPs, latency, and 5xx errors.
* **🛡️ Audit Trail**: This setup mirrors how production environments maintain compliance and perform real-time triage during outages.

---

## 🛠️ To-Do: Updating Your Infrastructure

Follow these numbered steps to update your code. Remember to use your `daequan` naming convention instead of the one in the instructions.

1. **Update Variables**: Open **`99-variables.tf`** and append the `enable_alb_access_logs` and `alb_access_logs_prefix` variables.
2. **Create Logging File**: Add a new file named **`bonus_d_logging.tf`**. This file must contain the S3 bucket for logs and the specific **Bucket Policy** that allows the AWS Load Balancing service to write to it.
3. **Patch the ALB**: You must edit **`07-alb-dns.tf`**. Inside the `resource "aws_lb" "main"` block, add the `access_logs` nested block.
* *Note: Terraform cannot append nested blocks; you must edit the resource directly*.


4. **Update Outputs**: Append the `apex_url_https` and `alb_logs_bucket_name` to your **`98-outputs.tf`**.
5. **Apply and Verify**: Run `terraform apply`, then use the CLI commands to confirm the apex record exists and the ALB is successfully pushing logs to S3.

---

## 📦 Deliverables

1. **Updated Code**: Your `07-alb-dns.tf` and the new `bonus_d_logging.tf`.
2. **DNS Proof**: CLI output from `aws route53 list-resource-record-sets` showing the record for the naked domain `daequanbritt.com.`.
3. **Logging Proof**:
* CLI output from `aws elbv2 describe-load-balancer-attributes` showing `access_logs.s3.enabled = true`.
* A list of files in your S3 bucket using `aws s3 ls` to show logs have started arriving.


4. **Connectivity Proof**: A successful `curl -I https://daequanbritt.com` showing a `200 OK` or `301 Redirect`.
___

# Instruction Origins

Ready to Suffer? —here’s the next realism bump for Lab 1C-Bonus-D:
  1) Zone apex (chewbacca-growl.com) ALIAS → ALB
  2) ALB access logs → S3 bucket (with the required bucket policy)
  3) A couple of verification commands students can run to prove it’s working

Add this as bonus_b_logging_route53_apex.tf (or append to your existing Route53/logging file).

Add variables (append to variables.tf)
variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}

Add file: bonus_b_logging_route53_apex.tf (go to Folder)

Patch reminder (students must modify the existing ALB resource)
Terraform can’t “append” nested blocks, so they must edit:
In bonus_b.tf, inside resource "aws_lb" "chewbacca_alb01" { ... } add:

  # Explanation: Chewbacca keeps flight logs—ALB access logs go to S3 for audits and incident response.
  access_logs {
    bucket  = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].bucket
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

Outputs (append to outputs.tf)

# Explanation: The apex URL is the front gate—humans type this when they forget subdomains.
output "chewbacca_apex_url_https" {
  value = "https://${var.domain_name}"
}

# Explanation: Log bucket name is where the footprints live—useful when hunting 5xx or WAF blocks.
output "chewbacca_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.chewbacca_alb_logs_bucket01[0].bucket : null
}

Student verification (CLI) — DNS + Logs
1) Verify apex record exists
  aws route53 list-resource-record-sets \
    --hosted-zone-id <ZONE_ID> \
    --query "ResourceRecordSets[?Name=='chewbacca-growl.com.']"

2) Verify ALB logging is enabled
  aws elbv2 describe-load-balancers \
    --names chewbacca-alb01 \
    --query "LoadBalancers[0].LoadBalancerArn"

Then:
  aws elbv2 describe-load-balancer-attributes \
  --load-balancer-arn <ALB_ARN>

  Expected attributes include:
  access_logs.s3.enabled = true
  access_logs.s3.bucket = your bucket
  access_logs.s3.prefix = your prefix

3) Generate some traffic
  curl -I https://chewbacca-growl.com
  curl -I https://app.chewbacca-growl.com

4) Verify logs arrived in S3 (may take a few minutes)
  aws s3 ls s3://<BUCKET_NAME>/<PREFIX>/AWSLogs/<ACCOUNT_ID>/elasticloadbalancing/ --recursive | head


Why this matters to YOU (career-critical point)
This is incident response fuel:
  Access logs tell you:
    client IPs
    paths
    response codes
    target behavior
    latency

Combined with WAF logs/metrics and ALB 5xx alarms, you can do real triage:
  “Is it attackers, misroutes, or downstream failure?”

