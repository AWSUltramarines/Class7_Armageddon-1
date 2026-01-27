Honors Verification (students must prove origin-driven caching)
1) Prove CloudFront is honoring origin Cache-Control
A) First request should be MISS

    curl -i https://chewbacca-growl.com/api/public-feed | sed -n '1,20p'

Check headers:
    Cache-Control: public, s-maxage=30, max-age=0 (from origin)
    x-cache: Miss from cloudfront (or similar)
    Age: likely absent or 0

x-cache meanings are documented by AWS

B) Second request within 30 seconds should be HIT

    curl -i https://chewbacca-growl.com/api/public-feed | sed -n '1,20p'

Expected:
    x-cache: Hit from cloudfront 
    Age: increases on subsequent hits (cache indicator)
    Body should remain identical until TTL expires

C) After 35 seconds, it should MISS again

    sleep 35
    curl -i https://chewbacca-growl.com/api/public-feed | sed -n '1,20p'

Expected:
    x-cache becomes Miss or RefreshHit
    Body updates

2) Prove “no-store” never caches (safety proof)

    curl -i https://chewbacca-growl.com/api/list | sed -n '1,30p'
    curl -i https://chewbacca-growl.com/api/list | sed -n '1,30p'

Expected:
    Cache-Control: private, no-store
    No meaningful cache hit behavior (Age not growing / no Hit)
    Each request should reflect origin state
If a student gets a cache HIT here, it’s a fail (potential data leak).

Honors “Make them sweat” incident challenge
  Failure Injection: “Origin forgot Cache-Control”
      Remove Cache-Control from /api/public-feed
      With the managed origin-driven policy, CloudFront should default to not caching 
      Students must observe:
        no Hit from cloudfront
        increased origin load
      Fix: restore proper Cache-Control
  
  Failure Injection: “Cache fragmentation”
      Forward User-Agent / all headers into cache key (bad)
      Hit ratio tanks
      Fix: whitelist headers; CloudFront warns about forwarding unnecessary headers hurting hit ratio

Student submission checklist (Honors)
Students submit:
1) Terraform diff showing:
    use of UseOriginCacheControlHeaders managed cache policy 

2) curl -i evidence showing:
    Cache-Control present
    x-cache transitions (Miss → Hit → Miss) 

3) One paragraph answering:
    Why origin-driven caching is safer for APIs
    When you would still disable caching entirely