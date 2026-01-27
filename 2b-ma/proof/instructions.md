### 🚀 Lab 2B-Honors: Compliance Checklist

#### 1. 🐍 Update the Python Application (`1a_user_data_tf.sh`)

You must modify your Flask app to serve the two specific endpoints with the required headers.

* **Create `/api/public-feed**`:
* Include `Cache-Control: public, s-maxage=30, max-age=0`.
* Return dynamic data like a timestamp to prove when the origin was actually hit.


* **Create `/api/list` (or update existing)**:
* Explicitly add `Cache-Control: private, no-store`.
* This ensures that even if CloudFront *can* cache, it *won't* because the app said so.



#### 2. 🏗️ Patch Terraform for Origin-Driven Caching (`12-cache.tf`)

You need to stop forcing a "0 TTL" from the CloudFront side for the public feed and instead tell CloudFront to listen to the app.

* **Import Managed Policy**: Use a `data` source to grab the AWS managed `CachingOptimized` or a specific policy that respects origin headers (like `Managed-CachingOptimized`).
* **Create `lab2b_honors_origin_driven.tf**`:
* Add a new `ordered_cache_behavior` specifically for `path_pattern = "/api/public-feed"`.
* Set its `cache_policy_id` to the managed policy that respects origin `Cache-Control`.
* Keep your existing "Safe Default" (caching disabled) for the general `/api/*` pattern to catch everything else.



#### 3. 🧪 Execute the "Miss → Hit → Miss" Proof

You must provide CLI evidence of the 30-second lifecycle.

* **The Initial Miss**: Run `curl -I`. Verify `x-cache: Miss` and that the `Age` header is absent.
* **The Golden Hit**: Run `curl -I` 10 seconds later. Verify `x-cache: Hit` and that the `Age` header has increased.
* **The Expiration**: Wait 35 seconds. Run `curl -I`. Verify the `x-cache` resets to `Miss` (or `RefreshHit`) and the timestamp in the body updates.

#### 4. 🛡️ Perform the "Safety Proof" (No-Store)

Prove you aren't leaking private data.

* Run `curl -I` on `/api/list` multiple times in rapid succession.
* **The Goal**: You must see `Cache-Control: private, no-store` and **never** see an `x-cache: Hit`. If the `Age` header appears here, your configuration is leaking data.

#### 5. 💥 Incident Challenge: Failure Injection

Demonstrate you understand the "Make them sweat" scenarios.

* **Test "Origin Forgot"**: Temporarily comment out the `Cache-Control` in your Python script for the public feed. Observe that CloudFront stops caching (Correct behavior for origin-driven policies).
* **Test "Fragmentation"**: In Terraform, briefly forward all headers (like `User-Agent`) to the cache key. Observe that `curl` from a different terminal (or browser) results in a `Miss` instead of a `Hit`.

---

### 📝 Your Honors Submission Package

To be fully compliant, your final submission must include these three items:

1. **The Terraform Diff**: Specifically highlighting the use of the `data "aws_cloudfront_cache_policy"` block and the new behavior mapping for `/api/public-feed`.
2. **The CLI Evidence**: A clear sequence of `curl` outputs showing the `Age` header climbing for the public feed and staying dead for the private feed.
3. **The "Sith Lord" Paragraph**: Answering the following:
* **Why is origin-driven caching safer?** (Answer: It puts the security/freshness decision in the hands of the application developer who knows the data, rather than the infrastructure engineer who only knows the path).
* **When do you still disable caching entirely?** (Answer: For highly sensitive endpoints like `/billing` or `/user/profile` where any risk of a CDN configuration error leading to a "Hit" could result in a catastrophic data leak).

