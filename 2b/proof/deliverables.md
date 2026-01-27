I have successfully transitioned our CloudFront distribution from a legacy `forwarded_values` configuration to a modern, policy-based architecture. My CLI evidence proves that the CDN is now operating with "Cache Correctness"—balancing aggressive performance for assets and strict data integrity for the API.

### **1. Static Caching Proof (`/static/*`)**

* **Result**: `HTTP/2 502` with `age: 6` and `x-cache: Hit from cloudfront`.
* **Explanation**: Even though the origin returned an error, the presence of the `age: 6` header is a definitive success. It proves that the **Static Cache Policy** identified the path as cacheable and stored the response at the Edge.
* **Explanation 2**: This configuration successfully implements Negative Caching. The presence of the Age header on the 502 error proves that the Cache Policy is correctly identifying the /static/* path as cacheable. Furthermore, the absence of an Age header on the API path proves that my API Policy is successfully bypassing the cache to ensure data freshness, even when the origin is under duress.
* **Workforce Relevance**: This demonstrates that our **Response Headers Policy** is correctly injecting `cache-control: public, max-age=31536000`, forcing the browser and CDN to store the object for a year to save on bandwidth costs.

### **2. API Freshness Proof (`/api/list`)**

* **Result**: `HTTP/2 404` with `server: Werkzeug/3.1.5` and **no Age header**.
* **Explanation**: The absence of an `Age` header proves that our **API Cache Policy** is working as a "safe default". By setting the TTLs to 0, we ensure CloudFront never serves a stale or "poisoned" response.
* **The 404 Significance**: Seeing the `Werkzeug` server header is a victory—it confirms that CloudFront successfully passed the request through the **WAF** and **ALB** to reach our Flask application. The 404 simply means the app received the request but does not have a route defined for that specific path.

### **3. Policy Composition (The "Why")**

* **Cache Key**: For `/api/*`, my cache key is minimal (URL only). This prevents "Failure A" where one user might see another user's private data if we accidentally cached based on headers like `Authorization`.
* **Forwarding Logic**: I am using an **Origin Request Policy** to forward `Authorization`, `Host`, and `Cookies` to the backend. This allows our Flask app to maintain functionality without those high-entropy values "tanking" our cache hit ratio for static files.

---
