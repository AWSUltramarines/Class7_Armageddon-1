# Class 9 – Lab 2B-Honors: Origin-Driven Caching (Be A Man A)

## Goal Statements

### Concise:

Implement origin-driven caching for dynamic APIs, using `Cache-Control` headers from the EC2 application to dictate CloudFront edge behavior.

### Infrastructure‑Focused:

Extend the Lab 2 architecture by implementing **Origin-Driven Caching**, where CloudFront dynamically adjusts TTLs based on the application's response. You will configure managed cache policies to respect `s-maxage` for public endpoints while strictly enforcing `no-store` for private data, proving correctness through `x-cache` transitions and `Age` header tracking.

---

**Request Flow:** 1. **Public API:** CloudFront (Respects `s-maxage`) → ALB → EC2 (Dynamic Response)
2. **Private API:** CloudFront (Bypass/No-Store) → ALB → EC2 (Sensitive Data)

---

### Infrastructure Change

* **Behavioral Matrix:** Specific CloudFront behaviors for `/api/public-feed` (Origin-driven) and `/api/*` (Safe default/Disabled).
* **Managed Policies:** Integration of AWS Managed Cache Policies via Terraform data sources.
* **Application Logic:** Update EC2 endpoints to serve specific `Cache-Control` directives.

## File Structure

|-- 00.provider.tf
|-- ... (Existing Lab 2 Files)
|-- **lab2b_honors_origin_driven.tf** (Honors Overlay: Managed Policy Data Sources & Behaviors)
|-- **userdata.sh** (Updated to serve `/api/public-feed` and `/api/list` logic)

---

## 🛠️ Application Setup (EC2)

Students must implement two distinct endpoints to test caching logic:

1. **Public Endpoint (`/api/public-feed`):**
* **Header:** `Cache-Control: public, s-maxage=30, max-age=0`
* **Payload:** Must return a dynamic value (e.g., `server_time_utc`) to prove the difference between a CloudFront hit and an origin refresh.


2. **Private Endpoint (`/api/list`):**
* **Header:** `Cache-Control: private, no-store`
* **Goal:** Prevent user data mixups and stale reads.



---

## 🏗️ Terraform: Honors Overlay

Instead of manual TTLs, use **Data Sources** to reference AWS Managed Policies:

* **Managed Cache Policy:** Use `Managed-CachingOptimized` or specific origin-driven policies.
* **Logic:** Patch the CloudFront distribution to apply the `UseOriginCacheControlHeaders` policy only to the public API behavior.

---

## ✅ Honors Verification (Beron Da Saluki Criteria)

Students must prove origin-driven caching via CLI evidence:

### 1. Prove Origin-Driven TTL

* **Step A (Initial Request):** Observe `x-cache: Miss from cloudfront`.
* **Step B (Within 30s):** Observe `x-cache: Hit from cloudfront` and an increasing `Age` header. The body must remain identical.
* **Step C (After 35s):** Observe `x-cache: Miss` or `RefreshHit` as the TTL expires and the body updates.

### 2. Safety Proof (No-Store)

Repeated requests to `/api/list` must **never** result in a cache `HIT`.

* **Success:** Each request shows `Miss` and reflects the current origin state.
* **Fail:** Receiving a `HIT` here indicates a potential data leak (Cache Poisoning).

---

## ⚡ Honors "Make Them Sweat" Challenges

* **Incident 1: Missing Headers:** If you remove `Cache-Control` from the origin, does CloudFront default to a safe "no-cache" state?
* **Incident 2: Cache Fragmentation:** What happens to the hit ratio if you accidentally include high-cardinality headers like `User-Agent` in the cache key?

---

## 📥 Submission Checklist

1. **Terraform Diff:** Show use of `UseOriginCacheControlHeaders` managed policy.
2. **Curl Evidence:** Provide logs showing the `Miss` → `Hit` → `Miss` transition.
3. **Reflection:** One paragraph explaining why origin-driven caching is safer for APIs than static TTLs.