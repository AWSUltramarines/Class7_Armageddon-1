# Class 7 – Armageddon Lab 1c-f CloudWatch Logs Insights Query Pack

## **Overview**
This lab introduces students to **CloudWatch Logs Insights** as a fast, powerful way to investigate incidents using log data from both **AWS WAF** and the **Notes application** running on EC2. The queries in this lab help students answer real operational questions such as:  
- *Is the WAF blocking traffic?*  
- *Who is hitting the application?*  
- *What paths are being scanned?*  
- *Are app errors caused by credentials, networking, or database issues?*  

This lab focuses only on logs stored in **CloudWatch Logs**.  
WAF logs appear here **only when** `waf_log_destination="cloudwatch"`.  
App logs always appear in the EC2 application log group.  
ALB access logs remain in **S3**, so they are not part of this query pack.

Run these queries during simulated incidents to quickly classify whether the issue is caused by **external pressure (WAF activity)** or **backend failure (app/RDS issues)**.

---

## **Highlights of the Queries Used in This Lab**

### **WAF Log Group**  
`aws-waf-logs-<project>-webacl01`

### **App Log Group**  
`/aws/ec2/<project>-rds-app`

### **Time Range Requirement**  
Set CloudWatch Logs Insights to **Last 15 minutes** (or match the incident window).

---

## **WAF Query Highlights**

### **A1 — Top WAF Actions (ALLOW vs BLOCK)**  
Shows what the WAF is doing right now.

### **A2 — Top Client IPs**  
Identifies who is hitting the application the most.

### **A3 — Top Requested URIs**  
Reveals what paths attackers or scanners are probing.

### **A4 — Blocked Requests Only**  
Shows which IPs and URIs are being blocked.

### **A5 — Which WAF Rule Is Blocking?**  
Breaks down blocks by rule ID and rule type.

### **A6 — Rate of Blocks Over Time**  
Helps detect spikes in malicious traffic.

### **A7 — Suspicious Scanner Patterns**  
Flags common attack paths like `/wp-login`, `/xmlrpc`, `.env`, `/admin`, etc.

### **A8 — Geo Breakdown (If Available)**  
Counts hits by country when present in the log format.

---

## **App Query Highlights**

### **B1 — Error Count Over Time**  
Shows spikes in application errors that correlate with incidents.

### **B2 — Recent Database Failures**  
Helps identify RDS connectivity or authentication issues.

### **B3 — “Creds vs Network” Classifier**  
Categorizes errors into:
- Credentials/Auth  
- Network/Route  
- Port/SG Refused  
- Other  

### **B4 — Structured JSON Field Extraction**  
For apps emitting JSON logs, extracts fields like `level`, `event`, and `reason`.

---

## **Mini Correlation Workflow (Runbook Summary)**

### **Step 1 — Confirm Timing**
Use App Query B1 to match error spikes with alarm windows.

### **Step 2 — Attack vs Backend Failure**
- Use WAF Queries A1 + A6  
- If WAF spikes → likely external scanning  
- If WAF quiet but app errors spike → backend issue

### **Step 3 — Backend Diagnosis**
- Use App Query B2 + B3  
- Identify whether the issue is:
  - Credentials drift  
  - Security group / routing failure  
  - RDS connectivity issue  

### **Step 4 — Verify Recovery**
- App errors return to normal  
- WAF blocks stabilize  
- Alarm returns to OK  
- `curl https://my-website-name.com/list` succeeds  

---
