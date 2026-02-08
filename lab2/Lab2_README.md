# Lab 2: CloudFront Origin Cloaking + Cache Correctness

**Helga Stack — Edge Security & CDN Implementation (us-east-1)**

---

## What I Built

Transformed the Lab 1C public ALB architecture into a production-grade edge deployment with CloudFront as the only public ingress point. The ALB still exists as internet-facing (CloudFront requires this) but is **fully cloaked** behind two security layers. Then configured CloudFront caching behaviors to prevent data leakage while maximizing cache hit ratios.

**Lab 2A:** Origin cloaking (SG prefix list + secret header)  

**Lab 2B:** Cache correctness (cache policies, origin request policies)  

**Honors A:** Origin-driven caching (`s-maxage` control)  

**Honors B:** CloudFront invalidation discipline

**Region:** us-east-1  

**Timeline:** Lab 2A + 2B completed together, Honors A + B followed immediately after

---

## Actual Resources Deployed

| Resource | Identifier / Value |
| --- | --- |
| **CloudFront Distribution** | `<Redacted>` (later: `<Redacted>`) |
| **WAF Web ACL** | `9c64a0cf-6d67-4bbe-82b7-c61c05b2d726` (CLOUDFRONT scope) |
| **ALB (cloaked)** | `helga-alblab2a-505583442.us-east-1.elb.amazonaws.com` |
| **Target Group** | `helga-tglab2a` (port 80) |
| **Route53 Zone** | `<Redacted>` (williebright.com) |
| **VPC** | `vpc-0c3514d78a9b8a4e0` |
| **EC2** | `i-0a597c3793884caaf` (private subnet) |
| **RDS** | `helga-rdslab2a.cg9aygqkqa8i.us-east-1.rds.amazonaws.com` |

### Architecture Flow

```
Internet → Route53 (williebright.com)
         → CloudFront (E1TVVCTL7Q4QCW)
         → WAF (helga_cf_waflab2a, 3 rules)
         → ALB (SG = CF prefix list only + secret header required)
         → Target Group (helga_tglab2a:80)
         → EC2 (private subnet)
         → RDS (private subnets)
```

---

## Key Challenges Solved

### 1. Origin Cloaking — Two-Layer Security Model

**Problem:** ALB is internet-facing (CloudFront origin requirement) but needs to block direct access.

**Solution — Layer 1 (Network):** ALB Security Group allows **only HTTPS 443 from CloudFront managed prefix list** (`com.amazonaws.global.cloudfront.origin-facing`).

```hcl
ingress {
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  description     = "HTTPS from CloudFront origin-facing IPs only"
}
```

**Solution — Layer 2 (Application):** ALB HTTPS listener default action = **403 Forbidden**. Only requests with the secret header `X-Helga-Origin-Verify` get forwarded to the target group.

```hcl
# Default action = block
default_action {
  type = "fixed-response"
  fixed_response {
    content_type = "text/plain"
    message_body = "Direct access forbidden"
    status_code  = "403"
  }
}

# Priority 1 rule = forward only if header matches
condition {
  http_header {
    http_header_name = "X-Helga-Origin-Verify"
    values           = [var.cloudfront_origin_secret]  # sensitive
  }
}
```

**Lesson:** Prefix lists provide network-level blocking, but application-level validation (secret header) adds defense in depth against misconfigured CloudFront distributions or compromised AWS accounts.

---

### 2. Two ACM Certificates Required (Regional + Global)

**Problem:** CloudFront and ALB both need valid TLS certificates, but CloudFront requires certs in `us-east-1` while ALB uses regional certs.

**Root Cause:** CloudFront is a global service. All CloudFront TLS certificates must be in `us-east-1` regardless of origin location.

**Fix:** Created two separate ACM certificates:

- **CloudFront cert** (`helga_cf_certlab2a`): `us-east-1`, provider = `aws.us_east_1`
- **ALB cert** (`helga_alb_certlab2a`): Same region as ALB

Both cover `williebright.com` and `app.williebright.com`, both use DNS validation.

**Lesson:** Always check provider aliases when deploying global services with Terraform.

---

### 3. WAF Scope Change (REGIONAL → CLOUDFRONT)

**Problem:** Lab 1C WAF was REGIONAL (attached to ALB). CloudFront requires CLOUDFRONT-scoped WAF.

**Error:** Tried to attach REGIONAL WAF to CloudFront → `InvalidParameterException: WAF scope mismatch`

**Fix:** Created new WAF Web ACL with `scope = "CLOUDFRONT"` and `provider = aws.us_east_1` (CloudFront WAFs must be in us-east-1).

```hcl
resource "aws_wafv2_web_acl" "helga_cf_waflab2a" {
  provider = aws.us_east_1
  name     = "helga-cf-waflab2a"
  scope    = "CLOUDFRONT"
  # ...
}
```

**Lesson:** REGIONAL and CLOUDFRONT WAFs cannot be reused across scopes. Must create separate Web ACLs.

---

### 4. Authorization Header Restriction (Custom ORP Blocked)

**Problem:** Created custom Origin Request Policy (`helga_orp_api01`) that whitelisted `Authorization` header. Terraform apply failed.

**Error Message:** `InvalidArgument: The parameter HeaderBehavior is invalid`

**Root Cause:** AWS blocks `Authorization` in custom origin request policies for security reasons. CloudFront documentation doesn't make this obvious.

**Fix:** Used AWS Managed Policy `Managed-AllViewer` which forwards all viewer headers including `Authorization`.

```hcl
# What we actually used
data "aws_cloudfront_origin_request_policy" "managed_all_viewer" {
  name = "Managed-AllViewer"
}
```

**Lesson:** Always check AWS Managed Policies before creating custom ones. AWS often restricts sensitive headers in custom policies.

---

### 5. Migration from `forwarded_values` to Policy IDs

**Problem:** Lab 2A distribution used legacy `forwarded_values` block. Lab 2B required modern `cache_policy_id` / `origin_request_policy_id` pattern.

**Error:** Tried to use both → `InvalidArgument: Cannot specify both forwarded_values and cache_policy_id`

**Fix:** Deleted `forwarded_values` block entirely, migrated all caching logic to explicit policies.

**Lesson:** `forwarded_values` is deprecated. Modern CloudFront uses separate cache policies and origin request policies for better control.

---

### 6. RefreshHit vs Hit (Cache Behavior Misunderstanding)

**Problem:** Expected `X-Cache: Hit from cloudfront` but kept seeing `X-Cache: RefreshHit from cloudfront`. Thought caching was broken.

**Root Cause:** `min_ttl = 1` with aggressive revalidation. CloudFront validates cached objects via ETag/Last-Modified frequently, then serves from cache if origin returns 304 Not Modified.

**Fix:** No fix needed — `RefreshHit` **is** a valid cache hit. Bandwidth is saved, origin load is reduced. To see pure `Hit` with `Age` header increasing, set `min_ttl = 60+`.

**Lesson:** `RefreshHit` = CloudFront revalidated with origin and served cached content. This is correct behavior for short TTLs.

---

### 7. Flask Static File Location Confusion

**Problem:** Created `/static/` folder in wrong location. CloudFront returned 404 for `/static/*` paths.

**Root Cause:** Flask app lives at `/opt/rdsapp/` (service: `rdsapp`). Static files must be at `/opt/rdsapp/static/`, not `/static/` at filesystem root.

**Fix:** Created correct directory structure:

```bash
sudo mkdir -p /opt/rdsapp/static
echo "test content" | sudo tee /opt/rdsapp/static/example.txt
```

**Lesson:** Application-relative paths matter. Always verify where the web server is actually serving static files from.

---

### 8. Honors A — Origin-Driven Caching Without Data Leakage

**Problem:** Need safe caching for dynamic content where origin controls TTL, but don't want User A seeing User B's data.

**Solution:** Two separate endpoints with different `Cache-Control` headers:

**Public endpoint** (`/api/public-feed`):

```python
response.headers['Cache-Control'] = 'public, s-maxage=30, max-age=0'
```

`s-maxage` targets CDN caches only. CloudFront caches for 30 seconds.

**Private endpoint** (`/api/list`):

```python
response.headers['Cache-Control'] = 'private, no-store'
```

Prevents any caching. Every request goes to origin.

**CloudFront behavior:** Used AWS Managed `UseOriginCacheControlHeaders` cache policy.

**Verification:**

- First request: `X-Cache: Miss from cloudfront`
- Second request (within 30s): `X-Cache: Hit from cloudfront`, `Age` header present
- After 35s: `X-Cache: Miss from cloudfront` again (TTL expired)

**Lesson:** Origin-driven caching gives developers control over what gets cached and for how long. Use `s-maxage` for CDN-specific TTLs, keep `max-age=0` for browsers to prevent local caching of user-specific data.

---

### 9. Honors B — Invalidation Discipline (Break-Glass Only)

**Problem:** Deployments were triggering `/*` invalidations routinely, creating unpredictable cache behavior and wasting the free invalidation budget.

**Solution:** Established operational rules:

**Rule 1:** Never invalidate `/*` for deployments. Only use for:

- Security incident
- Corrupted content
- Legal takedown
- Catastrophic caching misconfig

**Rule 2:** Prefer versioning for static assets (`/static/app.9f3c1c7.js`). New filename = new cache key = automatic cache miss on first request.

**Rule 3:** Invalidate only smallest blast radius:

- `/static/index.html` (entrypoint)
- `/static/manifest.json`
- `/static/*` (acceptable only with justification)

**Rule 4:** Budget awareness: First 1,000 paths/month free, then billed per path.

**CLI Commands Used:**

```bash
# Single path
aws cloudfront create-invalidation \
  --distribution-id <ID Name here> \
  --paths "/static/index.html"

# Track completion
aws cloudfront get-invalidation \
  --distribution-id <ID Name here> \
  --id <INVALIDATION_ID>
```

**Verification:** Proved cache before invalidation (`Age` increasing, `X-Cache: Hit`), then showed `X-Cache: Miss` after invalidation confirmed cache refresh.

**Lesson:** Invalidation is break-glass, not routine. Train teams to version static assets instead of invalidating on every deploy.

---

## Cache Policies Deployed (Lab 2B)

### Static Content — `helga-cache-static-aggressive`

```hcl
default_ttl           = 86400      # 1 day
max_ttl               = 31536000   # 1 year
min_ttl               = 1          # allows revalidation
cookie_behavior       = "none"
header_behavior       = "none"
query_string_behavior = "none"
```

**Why:** No cookies, headers, or query strings in cache key = maximum hit ratio. Static files don't vary by user.

### API — `helga-cache-api-disabled`

```hcl
default_ttl           = 0
max_ttl               = 0
min_ttl               = 0
cookie_behavior       = "none"
header_behavior       = "none"
query_string_behavior = "none"
```

**Why:** All TTLs at zero = CloudFront always goes to origin. Prevents User A seeing User B's data.

---

## Behavior Matrix (As Deployed)

| **Path Pattern** | **Cache Policy** | **Origin Request Policy** | **Response Headers** |
| --- | --- | --- | --- |
| `/static/*` | `helga-cache-static-aggressive` | `helga-orp-static` | `Cache-Control: public, max-age=31536000, immutable` |
| `/api/*` | `helga-cache-api-disabled` | `Managed-AllViewer` | — |
| `/api/public-feed` (Honors A) | `UseOriginCacheControlHeaders` | `Managed-AllViewer` | `Cache-Control: public, s-maxage=30, max-age=0` |
| `Default (*)` | `helga-cache-static-aggressive` | `helga-orp-static` | — |

---

## WAF Configuration (CLOUDFRONT Scope)

| Priority | Rule Name | Type | Action |
| --- | --- | --- | --- |
| 1 | **RateLimitRule** | Rate-based (2000 req/5min per IP) | Block |
| 2 | **AWSManagedRulesCommonRuleSet** | AWS Managed Rule Group | Use rule group actions |
| 3 | **AWSManagedRulesKnownBadInputsRuleSet** | AWS Managed Rule Group | Use rule group actions |

Default action: **Allow**. WAF logs to CloudWatch: `aws-waf-logs-helga-cf` (30-day retention).

---

## Skills Demonstrated

- **Origin Cloaking** — Two-layer security (SG prefix list + secret header validation)
- **Edge WAF** — CLOUDFRONT-scoped WAF with rate limiting and AWS Managed Rules
- **Cache Policy Design** — Separate policies for static (aggressive) vs API (no-cache)
- **Origin Request Policy** — Used AWS Managed `AllViewer` to work around `Authorization` header restriction
- **Response Headers Policy** — Added `Cache-Control: immutable` and security headers to static responses
- **CloudFront Behaviors** — Path-based routing with different caching strategies
- **ACM Multi-Cert Architecture** — CloudFront cert (us-east-1) + ALB cert (regional)
- **DNS Management** — Route53 ALIAS records pointing to CloudFront (not ALB)
- **Origin-Driven Caching** — Used `s-maxage` for CDN control while preventing browser caching of user data
- **Invalidation Discipline** — Established break-glass procedures and versioning-first approach
- **Terraform Multi-Provider** — Used `provider = aws.us_east_1` for CloudFront resources
- **Cache Verification** — Interpreted `X-Cache`, `Age`, `RefreshHit` headers correctly
- **Migration Path** — Converted legacy `forwarded_values` to modern policy IDs
- **Security Headers** — Added `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`

---

## Interview Talk Track

> "In Lab 2, I implemented CloudFront origin cloaking where the ALB became fully hidden behind two security layers. First, the ALB security group only allows HTTPS 443 from the AWS-managed CloudFront prefix list — direct internet access times out. Second, the ALB HTTPS listener default action is 403 Forbidden; it only forwards requests with a secret header that CloudFront injects. This prevents direct origin attacks even if someone discovers the ALB DNS name.
> 

> 
> 

> I moved the WAF from REGIONAL scope on the ALB to CLOUDFRONT scope on the distribution, which required creating a new Web ACL in us-east-1 with three rules: rate limiting, AWS Managed Common Rule Set, and Known Bad Inputs. I also had to deploy two separate ACM certificates — CloudFront requires certs in us-east-1 even though my infrastructure is in us-east-1, so I needed one global cert and one regional cert.
> 

> 
> 

> For Lab 2B, I configured cache correctness to prevent data leakage. Static content gets aggressive caching with 1-year max TTL and query strings ignored, while API responses have all TTLs at zero so CloudFront always goes to origin. I ran into an issue where I couldn't whitelist the Authorization header in a custom origin request policy — AWS blocks that for security reasons — so I had to use the managed AllViewer policy instead.
> 

> 
> 

> The Honors A challenge was origin-driven caching using Cache-Control headers from the Flask app. I created a public feed endpoint that returns `s-maxage=30` for CDN caching but `max-age=0` for browsers, and verified the Miss → Hit → Miss cycle as the 30-second TTL expired. I also created a private endpoint with `no-store` to prove it never cached.
> 

> 
> 

> Honors B was about invalidation discipline. I established operational rules: never invalidate `/*` for deployments, prefer versioning for static assets, and only use invalidation for break-glass scenarios like security incidents. I proved correctness by showing cache headers before and after invalidation, and documented when to invalidate versus when to version.
> 

> 
> 

> The biggest lessons were understanding RefreshHit as valid caching behavior, knowing when AWS restricts custom policies, and building a culture around versioning-first instead of invalidation-heavy deployments."
> 

---

## Verification Commands

### Lab 2A — Origin Cloaking

```bash
# Direct ALB access should FAIL (SG blocks + no secret header)
curl -I https://helga-alblab2a-505583442.us-east-1.elb.amazonaws.com
# Expected: Connection timeout or 403

# CloudFront access should SUCCEED
curl -I https://app.williebright.com
# Expected: 200 OK

# Verify WAF attached
aws wafv2 get-web-acl-for-resource \
  --resource-arn arn:aws:cloudfront::<Account ID>:distribution/E1TVVCTL7Q4QCW \
  --scope CLOUDFRONT \
  --region us-east-1
```

### Lab 2B — Cache Correctness

```bash
# Static caching — should see RefreshHit or Hit
curl -I https://williebright.com/static/example.txt
# Look for: X-Cache: RefreshHit from cloudfront
# Look for: Cache-Control: public, max-age=31536000, immutable

# API no-cache — should see Miss every time
curl -I https://williebright.com/list
curl -I https://williebright.com/list
# Both should show: X-Cache: Miss from cloudfront

# Cache key sanity — query strings ignored for static
curl -I "https://williebright.com/static/example.txt?v=1"
curl -I "https://williebright.com/static/example.txt?v=2"
# Both map to same cached object
```

### Honors A — Origin-Driven Caching

```bash
# First request — Miss
curl -i https://williebright.com/api/public-feed | sed -n '1,20p'
# Look for: X-Cache: Miss from cloudfront
# Look for: Cache-Control: public, s-maxage=30, max-age=0

# Second request within 30s — Hit
curl -i https://williebright.com/api/public-feed | sed -n '1,20p'
# Look for: X-Cache: Hit from cloudfront
# Look for: Age header present

# After 35s — Miss again
sleep 35
curl -i https://williebright.com/api/public-feed | sed -n '1,20p'
# Look for: X-Cache: Miss from cloudfront (TTL expired)
```

### Honors B — Invalidation

```bash
# Create invalidation
aws cloudfront create-invalidation \
  --distribution-id <ID Name here> \
  --paths "/static/index.html"

# Track status
aws cloudfront get-invalidation \
  --distribution-id <ID Name here> \
  --id <INVALIDATION_ID>

# Verify cache cleared
curl -I https://williebright.com/static/index.html
# Should show: X-Cache: Miss from cloudfront (after invalidation completes)
```

---

## Repository Structure

```jsx
lab2/
├── 01-version.tf
├── 02-providers.tf           # Includes provider = aws.us_east_1 alias
├── 03-variables.tf           # Lab 2A + 2B variables
├── 04-2a-Main.tf             # ACM cert (us-east-1) + Route53 ALIAS
├── 04-2ab-Main.tf            # ALB SG (prefix list) + listener (secret header) + ALB cert
├── 04-2ac-main.tf            # CloudFront distribution + WAF (CLOUDFRONT scope)
├── 04-2ad-Main.tf            # WAF logging to CloudWatch
├── 04-2B-cache_correctness.tf # Cache policies + origin request policies + response headers
├── lab2b_honors_origin_driven.tf  # Honors A: UseOriginCacheControlHeaders
├── 05-outputs.tf
└── terraform.tfvars
```