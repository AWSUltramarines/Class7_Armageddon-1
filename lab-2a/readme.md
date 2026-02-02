# Class 7 – Armageddon Lab 2a

## **Goal Statements**

### **Concise**  
Convert the existing public‑ALB architecture into a **CloudFront‑only public entry point**, where CloudFront is the *only* service exposed to the internet and the ALB is fully cloaked behind AWS‑managed origin protections.

### **Infrastructure‑Focused**  
Implement a production‑grade origin‑protection pattern used by large organizations:

- **CloudFront is the only public ingress**  
- ALB remains *internet‑facing* (required for CloudFront) but is **shielded** so direct access is impossible  
- ALB Security Group allows inbound **only** from the AWS‑managed prefix list:  
  `com.amazonaws.global.cloudfront.origin-facing`  
- ALB listener requires a **secret custom header** that only CloudFront injects  
- WAF moves from ALB to **CloudFront scope** (`scope = "CLOUDFRONT"`)  
- Both `chewbacca-growl.com` and `app.chewbacca-growl.com` become **ALIAS → CloudFront**  
- CloudFront forwards traffic to the ALB using HTTPS + custom header  
- ALB forwards to private EC2 targets (no public IPs)  

This lab teaches students how to build a **zero‑trust edge**, where the origin is never directly reachable.

---

## **Architecture Flow**

**Route53 (Apex + app) → CloudFront Distribution + WAF (CLOUDFRONT) → ALB (origin‑cloaked) → Private EC2 → Private RDS**

### **Origin Cloaking Components**

1. **CloudFront is the only public endpoint**  
   No one can reach the ALB directly.

2. **ALB Security Group allows inbound only from CloudFront origin‑facing prefix list**  
   This blocks all direct traffic from the internet.

3. **ALB listener requires a custom header**  
   CloudFront adds:  
   `X-Origin-Secret: <random-value>`  
   Direct clients cannot guess or send this header.

4. **WAF moves to CloudFront**  
   - Scope = `CLOUDFRONT`  
   - Protects the entire edge  
   - Logs at the CloudFront layer  

5. **Route53 aliases now point to CloudFront**  
   - `dustycloudeng.com → CloudFront`  
   - `app.dustycloudeng.com → CloudFront`  

6. **CloudFront → ALB → EC2 → RDS**  
   The entire backend remains private and unreachable from the internet.

---

## **Why This Matters**

This lab introduces students to a real enterprise pattern known as **origin cloaking** or **origin protection**.  
It ensures:

- No one can hit your ALB directly  
- No one can bypass CloudFront caching, WAF, or rate limiting  
- No one can scan your ALB or EC2 instances  
- All traffic is inspected at the edge  
- Only CloudFront can reach your ALB 