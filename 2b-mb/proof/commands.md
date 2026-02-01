1. Prove caching is in place. Run this twice:
```
curl -I https://daequanbritt.com/static/example.txt | sed -n '1,30p'
```

Expected:
    Age increases on second request (cached)
    x-cache shows Hit from cloudfront (or similar)

Run this once to see version:
```
curl https://daequanbritt.com/static/example.txt | sed -n '1,30p'
```

2. Deploy change (simulate)
Students must update index.html content at origin (or change static file).

Run this to see version hasn't changed:
```
curl https://daequanbritt.com/static/example.txt | sed -n '1,30p'
```

3. Invalidate:
```
aws cloudfront list-distributions --query "DistributionList.Items[*].{Id:Id,Comment:Comment}" --output table
```

```
aws cloudfront create-invalidation --distribution-id EIMZ0RF4643MZ --paths "/static/example.txt"
```

After invalidation: prove cache refresh
Run invalidation for /static/index.html, then:

```
curl -I https://daequanbritt.com/static/example.txt | sed -n '1,30p'
```

Expected:
    x-cache is Miss or RefreshHit depending on TTL/conditional validation
    CloudFront standard logs define Hit, Miss, RefreshHit.

Run this to see version has changed:
```
curl https://daequanbritt.com/static/example.txt | sed -n '1,30p'
```