# Class 9 – Lab 2B: CloudFront & API Caching Correctness (Be A Man)

## Goal Statements

### Concise:

Configure CloudFront behaviors to distinguish between aggressive static caching and safe, origin-controlled API delivery.

### Infrastructure‑Focused:

Extend the Lab 2 architecture by implementing granular CloudFront policies that separate the **Cache Key** (Cache Policy) from **Origin Forwarding** (Origin Request Policy). This lab introduces the **Beron Da Saluki** criteria: implementing "safe caching" for public GET endpoints where the origin (EC2) dictates expiration logic via `Cache-Control` headers rather than manual CloudFront overrides.

---

**Request Flow:** 1. **Static Content:** CloudFront (Aggressive Cache) → ALB → Private EC2
2. **API Content:** CloudFront (Safe-by-default / Origin-Controlled) → ALB → Private EC2

---

### Infrastructure Change

* **Policy Separation:** Transition from legacy TTL settings to modern Cache and Origin Request Policies.
* **Behavioral Branching:** Default behavior set to API-safe (caching disabled); Ordered behavior added for `/static/*`.
* **Origin-Controlled Caching:** Shift to using `Cache-Control` headers (e.g., `public, max-age=30`) supplied directly by the origin application.

## File Structure

|-- 00.provider.tf
|-- ... (Existing Lab 2 Files)
|-- **lab2b_cache_correctness.tf** (Cache & Origin Request Policy Overlay)
|-- userdata.sh (Updated to serve specific `Cache-Control` headers)

### Overview

Most CDN-related outages stem from misconfigured caching, such as session leakage or stale reads after writes. Lab 2B focuses on operating CloudFront correctly by ensuring the **cache key** includes only the minimum required values to avoid cache fragmentation, while ensuring all necessary values are forwarded to avoid serving the wrong response to the wrong user.

---

## Objectives

* **Cache Key Composition:** Understand how to build a cache key that prevents "cache poisoning" and data mixups.
* **Safe API Defaults:** Implement a default-deny caching posture for API endpoints to protect sensitive data.
* **Beron Da Saluki Criteria:**
* Implement "safe caching" for a public GET endpoint using `Cache-Control` from the origin.
* Demonstrate correct behavior using response headers and evidence.
* Show an understanding of why `Cache-Control` (origin-side) is preferred over `Expires`.



---

## Terraform‑Managed Resources

### 1. Cache Policies (`aws_cloudfront_cache_policy`)

* **Static Policy:** Aggressive caching for high performance.
* **API Policy:** Safe default where caching is disabled to prevent accidental exposure of private data.

### 2. Origin Request Policies (`aws_cloudfront_origin_request_policy`)

* **API ORP:** Forwards headers, cookies, and query strings that the origin needs for processing (e.g., Authorization).
* **Static ORP:** Minimal forwarding to maximize the cache hit ratio.

---

## ✅ Verification & Beron Da Saluki Evidence

Students must prove correctness using the following header-based evidence:

### 1. Verification of "Safe Caching"

**Command:**

```bash
curl -I https://dustycloudeng.click/api/public-endpoint

```

**Required Evidence:**

* `Cache-Control: public, max-age=30` (Sent by the origin).
* `X-Cache: Hit from cloudfront` (On subsequent requests).
* `Age: <value>` (Proving the duration the object has lived in the Edge cache).

### 2. Verification of API Safety

**Command:**

```bash
curl -I https://chewbacca-growl.com/api/user-data

```

**Required Evidence:**

* `X-Cache: Miss from cloudfront` or `Bypass` (Ensuring sensitive data is never cached by mistake).