This guide focuses on the technical precision required for caching correctness.

### 🛡️ Lab 2B: CloudFront + API Caching Correctness

In this lab, you will move from "using" CloudFront to "operating" it like a Sith Lord—ensuring static content is cheap and fast while dynamic API content remains secure and fresh.

---

### 📝 Step-by-Step Implementation Guide

1. **Define Two Cache Policies (`12-cache-policies.tf`)** 🧠
* **Static (Aggressive)**: Configure for high performance. Minimize the **Cache Key** by excluding headers and cookies to avoid "Cache Fragmentation" (Failure C).
* **API (Disabled)**: Create a "safe default" where `min_ttl`, `default_ttl`, and `max_ttl` are all **0**. This prevents "User A seeing User B's data" (Failure A).


2. **Define Two Origin Request Policies (ORP)** 📡
* **Static (Minimal)**: Forward only what is necessary (usually just the `Host` header).
* **API (Comprehensive)**: Forward `Authorization`, `Cookies`, and `Query Strings` so the ALB/Flask app can identify the user. **Note**: These are forwarded but *not* part of the cache key.


3. **The "Be A Man" Challenge: Response Headers Policy** 💪
* Create a `aws_cloudfront_response_headers_policy` to inject security headers and explicit `Cache-Control: public, max-age=31536000` for static content.


4. **Patch the CloudFront Distribution (`10-cloudfront.tf`)** 🛠️
* **Default Behavior (`/api/*` logic)**: Use the API policies. This ensures that any path not explicitly defined is treated as dynamic and uncacheable.
* **Ordered Behavior (`/static/*`)**: Create a new behavior block. Attach your Static Cache Policy, Static ORP, and your new Response Headers Policy.

---

### 📦 Expected Deliverables

#### **Deliverable A: Terraform Submission** 🏗️

Submit the HCL code creating the 2 Cache Policies, 2 ORPs, 2 Behaviors, and the Response Headers Policy.

#### **Deliverable B: Correctness Proof (CLI)** 💻

Run the following tests and provide the output:

* **Static Caching**: Run `curl -I` twice on `/static/example.txt`. Verify the `Age` header increases and your custom `Cache-Control` appears.
* **API Freshness**: Run `curl -I` twice on `/api/list`. Verify `Age` is absent or `0`, proving it's hitting the origin every time.
* **Cache Key Sanity**: Run `/static/example.txt?v=1` and `?v=2`. Both should be a `Hit` from the same cache object.

#### **Deliverable C: The Technical Explanation** ✍️

Write a short explanation answering:

1. "What is my cache key for `/api/*` and why?" (Hint: It should be minimal to prevent poisoning).
2. "What am I forwarding to origin and why?" (Hint: Forwarding `Authorization` is required for your Flask app to work).

#### **Deliverable D: The Haiku** ✍️

Submit a Haiku describing Chewbacca's perfection in Japanese (漢字のみ).

---

### ⚠️ Incident Watch (Failure Injections)

During your deployment, watch out for these Sith-level configuration errors:

* **Failure A**: If you enable API caching but exclude the `Authorization` header from the cache key, User A will see User B's private data.
* **Failure B**: "Forwarding all headers" often results in random 403s because the ALB receives headers it doesn't recognize or CloudFront tries to cache high-entropy values.
* **Failure C**: Including too many cookies in your static cache key will "tank" your hit ratio, as every user will generate a unique (and unnecessary) cache entry.
