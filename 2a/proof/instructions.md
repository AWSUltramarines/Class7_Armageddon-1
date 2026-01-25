Congrats on completing Lab 1! You are now moving into **Lab 2A: Origin Cloaking**, where we transition from a regional secure entry point to a global, "cloaked" architecture . The goal is to make your website, `daequanbritt.com`, reachable **only** through AWS CloudFront.

### 🛡️ Lab 2A: Origin Cloaking + CloudFront Ingress

* **🕵️ The "Cloak"**: Your Application Load Balancer (ALB) remains "public" in name only; it will be configured to reject any request that doesn't come directly from CloudFront .


* **🌍 Global Edge**: WAF protection moves from the regional ALB to the CloudFront Edge (Global scope), stopping threats further away from your infrastructure .


* **🔑 Dual-Layer Defense**: You will implement two security layers: a **Prefix List** (IP-based) and a **Secret Custom Header** (token-based) .


* **📍 Domain Transition**: DNS records for `daequanbritt.com` and `app.daequanbritt.com` will point to the CloudFront Distribution instead of the ALB .


* **❄️ The `us-east-1` Rule**: CloudFront certificates **must** reside in the N. Virginia `us-east-1` region . You will need a second Terraform provider for this region.

---

### 📝 To-Do List for Completion

Follow these steps in order to reconfigure your `armage` environment:

1. **Configure Multi-Region Providers**: Add a second `aws` provider to your `00-auth.tf` aliased for `us-east-1` to handle the CloudFront ACM certificate .


2. **Migrate WAF to Global Scope**: Create a new WAF Web ACL in your `09-waf.tf` (or a new `lab2_waf.tf`) with `scope = "CLOUDFRONT"` .


3. **Implement Security Group Cloaking**: Modify `04-sg.tf` to replace the ALB's open ingress (0.0.0.0/0) with a rule that only allows the `com.amazonaws.global.cloudfront.origin-facing` prefix list .


4. **Add Secret Header Validation**:
* Generate a secret string (using `random_password`).
* In `07-alb-dns.tf`, add an `aws_lb_listener_rule` to your HTTPS listener that only forwards traffic if the header `X-Custom-Header` matches your secret; otherwise, return a **403 Fixed Response** .




5. **Deploy CloudFront Distribution**: Create the distribution (e.g., `lab2_cloudfront_alb.tf`) pointing to your ALB DNS as the origin, ensuring it passes the secret header and uses your `us-east-1` certificate .


6. **Update Route 53 Records**: Modify `06-logging.tf` or `07-alb-dns.tf` so the A-records for `daequanbritt.com` point to the **CloudFront Domain Name**, not the ALB .


7. **Verification**: Execute the CLI commands below to prove the ALB is "hidden" and CloudFront is the only entry point .

---

### 🚀 Verification CLI

| Test | Command | Expected Result |
| --- | --- | --- |
| **ALB Cloaking** | `curl -I https://<YOUR_ALB_DNS>` | <br>**403 Forbidden** (Direct access blocked) |
| **CloudFront Entry** | `curl -I https://daequanbritt.com` | **200 OK** (Access through the edge) |
| **WAF Scope** | `aws wafv2 get-web-acl --scope CLOUDFRONT...` | Web ACL exists at Global scope |
| **DNS Resolution** | `dig daequanbritt.com A +short` | Resolves to CloudFront Anycast IPs |

___

### 🛠️ Why you can't use only us-east-2

* CloudFront Global Rule: AWS requires that any ACM certificate associated with a CloudFront distribution be located in the `us-east-1` region.


* Regional Limitation: If you create the certificate in `us-east-2`, it simply won't show up in the dropdown menu or API options when you try to attach it to your CloudFront distribution.

* Infrastructure remains in Ohio: This does not mean you have to move your servers. Your ALB and EC2 stay in `us-east-2`. Only the Certificate and the WAF (which becomes global) will be managed via the N. Virginia/Global endpoints in `us-east-1`.