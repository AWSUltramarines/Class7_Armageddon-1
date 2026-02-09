# Class 9 – Lab 2B: CloudFront & API Caching Correctness

## Goal Statements

### Concise:

Configure CloudFront Cache and Origin Request policies to distinguish between aggressive static asset caching and safe API delivery.

### Infrastructure‑Focused:

Extend the Lab 2 architecture by implementing granular CloudFront behaviors. This lab focuses on the separation of the **Cache Key** (Cache Policy) from **Origin Forwarding** (Origin Request Policy) to prevent production incidents like session leakage or stale data. You will implement aggressive caching for static assets while enforcing a "safe-by-default" no-cache posture for API endpoints.

---

**Request Flow:** 1. **Static Content:** CloudFront (Aggressive Cache) → S3/ALB
2. **API Content:** CloudFront (No Cache / Dynamic Forwarding) → ALB → Private EC2

---

### Infrastructure Change

* **Policy Separation:** Transition from legacy TTL settings to modern Cache and Origin Request Policies.
* **Behavioral Branching:** Default behavior set to API-safe (no cache); Ordered behavior added for `/static/*`.
* **Beron Da Saluki Criteria:** Use `Cache-Control` headers from the origin to drive expiration logic.

## File Structure

|-- 00.provider.tf
|-- ... (Existing Lab 2 Files)
|-- **lab2b_cache_correctness.tf** (New Policy Overlay)
|-- userdata.sh (Updated for API vs. Static header responses)

### Overview

Most CDN-related outages are not caused by downtime, but by **misconfiguration**. Issues like auth/session mixups or stale reads often occur because headers, cookies, or query strings were not handled correctly in the cache key. Lab 2B is where you stop "using CloudFront" and start "operating CloudFront" with production-grade correctness.

---

## Objectives

* **Cache Key Optimization:** Include minimum values to avoid cache fragmentation while ensuring correctness.
* **Avoid High-Cardinality Headers:** Learn why caching on headers like `User-Agent` is a "bad idea" that explodes variations.
* **Safe API Delivery:** Forward only what the origin needs (Auth headers, etc.) without caching the sensitive response.
* **Modern Semantics:** Prioritize `Cache-Control: max-age` over the legacy `Expires` header.

---

## Terraform‑Managed Resources

### 1. Cache Policies (`aws_cloudfront_cache_policy`)

* **Static Policy:** Aggressive settings for files that rarely change.
* **API Policy:** Caching disabled by default to prevent data leakage.

### 2. Origin Request Policies (`aws_cloudfront_origin_request_policy`)

* **API ORP:** Configured to forward headers, cookies, and query strings required by the application logic.
* **Static ORP:** Minimal forwarding to keep origin requests lean.

### 3. Distribution Behaviors

* **Default Behavior:** Patched to use the API Cache Policy and API Origin Request Policy.
* **Ordered Behavior (`/static/*`):** Targeted behavior using the Static Cache Policy and Static ORP.

---

## ✅ Verification & Correctness Tests

Students must provide evidence of correct headers to pass the Beron Da Saluki criteria.

### 1. Static Content (Cache Hit)

```bash
curl -I https://dustycloudeng.click/static/test.txt

```

**Expected Evidence:** * `X-Cache: Hit from cloudfront` (after first request).

* `Age: <number>` (indicates how long the object has been in the edge cache).

### 2. API Content (Cache Bypass/Miss)

```bash
curl -I https://dustycloudeng.click/api/user-profile

```

**Expected Evidence:**

* `X-Cache: Miss from cloudfront` (should always be a miss or bypass for dynamic API calls).
* `Cache-Control: no-store, private` (or similar origin-provided safety headers).

### 3. "Safe Caching" Evidence

Prove the origin is controlling the logic:

* Execute a request and show the `Cache-Control: public, max-age=30` header being respected by the `Age` header in subsequent CloudFront hits.
