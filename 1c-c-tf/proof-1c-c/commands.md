Student verification (CLI)

1. Confirm hosted zone exists (if managed) 
```rb
aws route53 list-hosted-zones-by-name
--dns-name chewbacca-growl.com
--query "HostedZones[].Id"
```

```rb
aws route53 list-hosted-zones-by-name
--dns-name daequanbritt.com
--query "HostedZones[].Id"
```

2. Confirm app record exists 
```rb
aws route53 list-resource-record-sets
--hosted-zone-id <ZONE_ID>
--query "ResourceRecordSets[?Name=='app.chewbacca-growl.com.']"
```

```rb
aws route53 list-resource-record-sets \
--hosted-zone-id Z04376043T34812BLBEDG \
--query "ResourceRecordSets[?Name=='app.daequanbritt.com.']" \
--region us-east-2
```

3. Confirm certificate issued 
```rb
aws acm describe-certificate
--certificate-arn <CERT_ARN>
--query "Certificate.Status"
```

```rb
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-2:329599652812:certificate/9bc64508-6a26-4466-a996-b88bcd468cf5 \
  --region us-east-2 \
  --query "Certificate.Status"
```

```rb
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_arn) \
  --region us-east-2 \
  --query "Certificate.Status"
```

Expected: ISSUED

4. Confirm HTTPS works 
```rb
curl -I https://app.chewbacca-growl.com
```

```rb
curl -I https://app.daequanbritt.com
```

Expected: HTTP/1.1 200 (or 301 then 200 depending on your app)