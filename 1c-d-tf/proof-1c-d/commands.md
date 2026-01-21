Student verification (CLI) — DNS + Logs
1) Verify apex record exists
```  
aws route53 list-resource-record-sets \
--hosted-zone-id <ZONE_ID> \
--query "ResourceRecordSets[?Name=='chewbacca-growl.com.']"
```

```rb
aws route53 list-resource-record-sets \
--hosted-zone-id Z05570601UFWMMRS92DVT \
--query "ResourceRecordSets[?Name=='daequanbritt.com.']"
```

```rb
aws route53 list-resource-record-sets \
--hosted-zone-id $(terraform output -raw route53_zone_id) \
--query "ResourceRecordSets[?Name=='daequanbritt.com.']"
```
___

2) Verify ALB logging is enabled
```rb
aws elbv2 describe-load-balancers \
--names chewbacca-alb01 \
--query "LoadBalancers[0].LoadBalancerArn"
```

```rb
aws elbv2 describe-load-balancers \
--names armage-dev-alb \
--query "LoadBalancers[0].LoadBalancerArn" \
--output text
```

Then:
```rb
aws elbv2 describe-load-balancer-attributes \
--load-balancer-arn <ALB_ARN>
```

```rb
aws elbv2 describe-load-balancer-attributes \
--load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:329599652812:loadbalancer/app/armage-dev-alb/2d695f8889a6bdf9
```

```rb
aws elbv2 describe-load-balancer-attributes \
--load-balancer-arn $(terraform output -raw alb_arn)
```

  Expected attributes include:
  access_logs.s3.enabled = true
  access_logs.s3.bucket = your bucket
  access_logs.s3.prefix = your prefix

3) Generate some traffic
```rb
  curl -I https://chewbacca-growl.com
  curl -I https://app.chewbacca-growl.com
```

```rb
curl -I https://daequanbritt.com
curl -I https://app.daequanbritt.com
```

4) Verify logs arrived in S3 (may take a few minutes)
```rb
aws s3 ls s3://<BUCKET_NAME>/<PREFIX>/AWSLogs/<ACCOUNT_ID>/elasticloadbalancing/ --recursive | head
```

```rb
aws s3 ls s3://armage-dev-alb-access-logs-app/alb-access-logs/AWSLogs/329599652812/elasticloadbalancing/ --recursive || head -5
```

```rb
aws s3 ls s3://$(terraform output -raw alb_logs_bucket_name)/alb-access-logs/AWSLogs/$(aws sts get-caller-identity --query Account --output text)/elasticloadbalancing/ --recursive | head
```