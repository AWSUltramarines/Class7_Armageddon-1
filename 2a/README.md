### Lab 2A complete!

---

# 🛡️ Cloud Architecture: Lab 2A

### *Origin Cloaking & Global Ingress for daequanbritt.com*

## 🌐 Overview

This project demonstrates an enterprise-grade secure entry pattern. By moving the **WAF** to the global edge and "cloaking" the **Application Load Balancer**, we ensure that only legitimate, encrypted traffic passing through **AWS CloudFront** can reach the private infrastructure.

---

## 🏗️ Architecture Stack

* **🌍 CDN**: CloudFront Distribution with Global Edge Caching.


* **🛡️ WAFv2**: Multi-layer protection (Regional for ALB + Global for CloudFront).


* **⚖️ ALB**: Internet-facing Load Balancer (Cloaked via Prefix Lists & Custom Headers).


* **💻 EC2**: Private Flask Application running on Amazon Linux 2023.


* **🗄️ RDS**: Private MySQL instance secured by Secrets Manager.


* **🔑 Secrets**: Automated credential rotation and origin-header verification.


---

## 🔒 Security Features

* **🕵️ Origin Cloaking**: The ALB Security Group is restricted to the **CloudFront Origin-Facing Prefix List**, blocking direct public access.


* **🔑 Secret Header**: The ALB only forwards requests containing a 32-character `X-Custom-Header` injected by CloudFront.


* **📜 Dual-Region SSL**:
* **us-east-1**: ACM Certificate for CloudFront Edge.

* **us-east-2**: ACM Certificate for the ALB Origin and SNI support.

* **🛡️ Least Privilege IAM**: EC2 instances use scoped policies for Secrets Manager and SSM Parameter Store.

---

## 📈 Observability & Monitoring

* **📊 CloudWatch Dashboard**: Real-time visual metrics for CPU, ALB Request counts, and Latency.

* **🚨 Incident Response**:
  * **DB Failure Alarm**: Triggers when logs detect "Database connection failed".

  * **ALB 5xx Alarm**: Notifies via SNS if the backend returns server errors.

  * **📧 SNS Alerts**: Automated email notifications sent to `daequanbritt@gmail.com`.

---

## 🚀 Deployment & Verification

### **Prerequisites**

* Terraform v1.5+.

* AWS CLI configured with appropriate permissions.
* Domain `daequanbritt.com` registered in Route 53.

### **Verification Commands**

1A. **Verify ALB Cloaking**:
```bash
curl -I https://<ALB_DNS_NAME>
# Expected: 403 Forbidden (Missing Secret Header)
```

1B. **Confirm App Health**:
```bash
curl -I https://daequanbritt.com
curl -I https://app.daequanbritt.com
# Expected: 200 OK
```

2. **WAF moved to Cloudfront**
```bash
aws wafv2 list-web-acls \
--scope CLOUDFRONT \
--region us-east-1
```

3. **Check Global DNS**:
```bash
dig daequanbritt.com A +short
dig app.daequanbritt.com A +short
# Expected: CloudFront Anycast IPs
```

---

## 📁 File Structure

* `00-auth.tf`: Provider and Backend configurations.


* `04-sg.tf`: Cloaked Security Group rules.


* `07-alb-dns.tf`: Load Balancer and Route 53 logic.


* `10-cloudfront.tf`: Global CDN configuration.


* `1a_user_data_tf.sh`: Flask application bootstrap script.

```bash
.
├── 00-auth.tf          # Multi-Region Providers (Ohio & N. Virginia) & S3 Backend 
├── 01-IAM.tf           # EC2 Role with scoped Secrets/SSM & CloudWatch permissions
├── 02-secrets.tf       # DB Credentials & Global Origin-Header secret generation
├── 03-network.tf       # VPC, Multi-AZ Subnets, NAT GW, & PrivateLink Endpoints
├── 04-sg.tf            # ALB Cloaking via CloudFront Prefix List & SG-to-SG rules 
├── 05-main.tf          # Private EC2 Web Server & RDS MySQL Instance (Isolated)
├── 06-logging.tf       # SNS, Metric Filters, & S3 Bucket for ALB Access Logs
├── 07-alb-dns.tf       # ALB Listeners, Header-Check Rules, & Regional SSL Certs 
├── 08-dashboard.tf     # CloudWatch Dashboard for CPU, Latency, & 5xx Monitoring
├── 09-waf.tf           # Regional WAF (ALB) & New Global WAF (CloudFront) 
├── 10-cloudfront.tf    # CDN Distribution with Custom Origin Header & Host Forwarding
├── 11-cert.tf          # N. Virginia (us-east-1) ACM Certificate for Global Edge
├── 1a_user_data_tf.sh  # Flask App script with CloudWatch logging & RDS logic
├── 98-outputs.tf       # Global App URLs, ALB DNS, and Resource ARNs
├── 99-variables.tf     # Variable definitions for Project, Domain, & WAF settings
└── terraform.tfvars    # Environment values & Alert Email configurations
```
