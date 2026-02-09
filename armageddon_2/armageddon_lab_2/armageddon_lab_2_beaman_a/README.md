# Armageddon Lab 2B Be a Man — CloudFront & Origin Driven Caching

---

## Flask Endpoints

The EC2 instance runs a Flask app (deployed via `user_data.sh` as a systemd service on port 80) with six endpoints:

| Endpoint | Method | Purpose | Cache-Control Header |
|---|---|---|---|
| `/` | GET | Home page with usage instructions | — |
| `/init` | GET | Creates the `labdb` database and `notes` table | — |
| `/add?note=<text>` | POST/GET | Inserts a note into the database | — |
| `/list` | GET | Lists all notes from the database | — |
| `/api/public-feed` | GET | Returns JSON (message + timestamp) | `public, s-maxage=30, max-age=0` |
| `/api/user-feed` | GET | Returns user-specific JSON data | `private, no-store` |

The two `/api/*` endpoints are the key players for demonstrating origin-driven caching. The app fetches RDS credentials from Secrets Manager and logs to CloudWatch via the `watchtower` library.

---

## Origin-Driven Caching

Origin-driven caching means the **origin (Flask app) tells CloudFront how to cache**, rather than CloudFront imposing its own rules. The mechanism is straightforward: Flask sets `Cache-Control` headers on each response, and CloudFront uses the AWS-managed `UseOriginCacheControlHeaders` policy to read and obey whatever the origin sends.

### The Two Contrasting Behaviors

**`/api/public-feed`** — `Cache-Control: public, s-maxage=30, max-age=0`

| Directive | What It Does |
|---|---|
| `s-maxage=30` | Tells CloudFront (the shared/CDN cache) to cache for 30 seconds |
| `max-age=0` | Tells the browser NOT to cache locally |

CloudFront serves cached copies for 30s, reducing origin load, while browsers always validate freshness.

**`/api/user-feed`** — `Cache-Control: private, no-store`

| Directive | What It Does |
|---|---|
| `private` | Tells CloudFront this is user-specific — do NOT cache at the edge |
| `no-store` | Tells browsers not to cache either |

Every request goes all the way back to the origin — appropriate for personalized data.

---

## CloudFront Cache Architecture

CloudFront uses path-based cache behaviors to apply different policies per route:

| Path Pattern | Cache Policy | Origin Request Policy | Behavior |
|---|---|---|---|
| `/static/*` | `cache_static01` (1-day default, 1-year max) | `orp_static01` (minimal forwarding) | Aggressive edge caching + response header adds `public, max-age=86400, immutable` |
| `/api/public-feed` | AWS `UseOriginCacheControlHeaders` | `orp_all_viewer_except_host01` | Origin-driven — Flask's `s-maxage=30` controls edge TTL |
| `/api/*` | `cache_api_disabled01` (0 TTL) | `orp_api01` (forward all) | No caching for other API routes |
| Default (`*`) | `cache_api_disabled01` (0 TTL) | `orp_api01` (forward all) | No caching |

---

## Origin Protection (Origin Cloaking)

The ALB is never directly accessible from the internet. Three layers enforce this:

| Layer | Mechanism |
|---|---|
| **ALB Security Group** | Ingress restricted to the `com.amazonaws.global.cloudfront.origin-facing` managed prefix list (CloudFront IPs only) |
| **Custom Origin Header** | CloudFront injects `X-Jasongeddon-Growl` (a random 32-char secret) on every request to the ALB |
| **ALB Listener Rules** | HTTPS listener returns 403 by default; only requests carrying the correct header (priority 10) are forwarded to the target group |

Even if someone discovers the ALB's DNS name, they cannot bypass CloudFront.

---

## Why Origin-Driven Caching Matters

- **Developer-controlled caching** — each endpoint declares its own cacheability in the application code, not in infrastructure config. This is self-documenting and lives alongside the business logic.
- **Granular per-endpoint control** — instead of one blanket CloudFront TTL, each route independently decides its behavior through headers.
- **Reduced origin load without sacrificing freshness** — `s-maxage=30` on `/api/public-feed` means one origin hit serves potentially thousands of edge requests within a 30-second window, while `max-age=0` ensures browsers still revalidate.
- **Simpler infrastructure management** — adding a new cacheable endpoint only requires setting the right headers in Flask, not updating Terraform.
- **Separation of concerns** — caching decisions stay where domain knowledge lives (the application), while CloudFront remains a generic, policy-driven edge layer.
