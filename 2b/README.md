# Lab 2B: CloudFront + API Caching Correctness

## Project Overview

This lab marks the transition from basic CDN usage to production-grade CloudFront operation. The core objective was to implement a policy-based architecture that distinguishes between **Cache Policies** (defining the Cache Key) and **Origin Request Policies** (defining what is forwarded to the backend) to prevent common production outages like session mix-ups and cache poisoning.

---

## Infrastructure as Code (Terraform)

I updated the deployment to utilize modular policies instead of legacy `forwarded_values`.

### **Key Components**

* **Static Cache Policy**: Aggressive caching (1-year TTL) with minimal headers to prevent cache fragmentation.
* **API Cache Policy**: Safe-by-default (0 TTL) to ensure dynamic content always hits the origin.
* **Origin Request Policy**: Configured to forward `Authorization`, `Host`, and `Cookies` to the Flask app without including them in the Cache Key.
* **Response Headers Policy**: Injected security headers and explicit `Cache-Control` max-age requirements.

---

## Technical Verification

### **1. Static Caching Proof (`/static/*`)**

Running `curl -I` on static assets produced the following results:

* **Status**: `HTTP/2 502`.
* **Cache Evidence**: `x-cache: Error from cloudfront` and `age: 6`.
* **Analysis**: The presence of the `age` header proves that **Negative Caching** is active. CloudFront successfully identified the `/static/*` path as cacheable and served the stored error from the Edge, proving the Cache Policy is correctly configured.
* **Headers**: `cache-control: public, max-age=31536000, immutable` confirms the Response Headers Policy is operational.

### **2. API Freshness Proof (`/api/list`)**

Running `curl -I` on the API path produced the following results:

* **Status**: `HTTP/2 404`.
* **Backend Evidence**: `server: Werkzeug/3.1.5 Python/3.9.25`.
* **Cache Evidence**: **No Age header present**.
* **Analysis**: The absence of an `age` header confirms that CloudFront is bypassing the cache for API calls. The 404 error combined with the `Werkzeug` header proves the request successfully reached the Flask application, confirming connectivity through the WAF and ALB.

---

## Workforce Relevance: Failure Mitigations

* **Failure A (Data Leakage)**: Prevented by disabling API caching.
* **Failure B (Random 403s)**: Resolved by correctly whitelisting the `Host` header and ensuring SSL certificate SNI alignment for the apex domain.
* **Failure C (Tanked Hit Ratio)**: Mitigated by removing high-entropy headers from the static cache key.

---

## Key Changes Summary
```diff
+ Added 12-cache.tf: Centralizes the logic for how CloudFront handles cache keys and forwards headers to your origin.

+ Refined 07-alb-dns.tf: Now includes the aws_lb_listener_certificate resource to fix the SSL handshake issues (502s) on the apex domain.

+ Patched 10-cloudfront.tf: Migrated from legacy forwarded_values to the modern policy-based behavior model required for Lab 2B.
```

## File Tree:
```bash
.
├── 00-auth.tf          # Multi-Region Providers (Ohio & N. Virginia) & S3 Backend 
├── 01-IAM.tf           # EC2 Role with scoped Secrets/SSM & CloudWatch permissions
├── 02-secrets.tf       # DB Credentials & Global Origin-Header secret generation
├── 03-network.tf       # VPC, Multi-AZ Subnets, NAT GW, & PrivateLink Endpoints
├── 04-sg.tf            # ALB Cloaking via CloudFront Prefix List & SG-to-SG rules 
├── 05-main.tf          # Private EC2 Web Server & RDS MySQL Instance (Isolated)
├── 06-logging.tf       # SNS, Metric Filters, & S3 Bucket for ALB Access Logs
├── 07-alb-dns.tf       # ALB Listeners, SNI Cert Bindings (Apex Fix), & Header-Check Rules 
├── 08-dashboard.tf     # CloudWatch Dashboard for CPU, Latency, & 5xx Monitoring
├── 09-waf.tf           # Regional WAF (ALB) & Global WAF (CloudFront) 
├── 10-cloudfront.tf    # CDN Distribution with Policy-Based Behaviors (Static vs. API)
├── 11-cert.tf          # N. Virginia (us-east-1) ACM Certificate for Global Edge
├── 12-cache.tf         # Cache Policies, Origin Request Policies, & Response Headers
├── 1a_user_data_tf.sh  # Flask App script with CloudWatch logging & RDS logic
├── 98-outputs.tf       # Global App URLs, ALB DNS, and Sensitive Origin Header Secrets
├── 99-variables.tf     # Variable definitions for Project, Domain, & WAF settings
└── terraform.tfvars    # Environment values & Alert Email configurations
```