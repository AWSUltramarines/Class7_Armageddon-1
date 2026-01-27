1) Static caching proof
Run twice:
  curl -I https://chewbacca-growl.com/static/example.txt
  curl -I https://chewbacca-growl.com/static/example.txt

2X:
```
curl -I https://daequanbritt.com/static/example.txt
```

Look for:
  Cache-Control: public, max-age=... (from response headers policy)
  Age: increases on subsequent requests (cached object indicator) 

  If Age never appears/increases, caching isn’t working (or TTL is 0 / headers prevent caching).

2) API must NOT cache unsafe output
Run twice:
  curl -I https://chewbacca-growl.com/api/list
  curl -I https://chewbacca-growl.com/api/list

```rb
curl -I https://daequanbritt.com/api/list
```

Expected for “safe default” API behavior:
    Age should be absent or 0
    Responses should reflect fresh origin behavior
    If you add auth later, you must never allow one user to see another’s response

3) Cache key sanity checks (query strings)
Static should ignore query strings by default:
  curl -I "https://chewbacca-growl.com/static/example.txt?v=1"
  curl -I "https://chewbacca-growl.com/static/example.txt?v=2"

```
curl -I "https://daequanbritt.com/static/example.txt?v=1"
curl -I "https://daequanbritt.com/static/example.txt?v=2"
```

Expected:
both map to the same cached object (hit ratio stays high) because static cache policy ignores query strings (unless students intentionally change it)

4) “Stale read after write” safety test
  If your API supports writes:
    POST a new row
    Immediately GET /api/list
    Ensure the new row appears
      If it doesn’t, they accidentally cached a dynamic response.