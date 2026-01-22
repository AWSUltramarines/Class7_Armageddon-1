## 1. Confirm WAF logging is enabled (authoritative)
```rb
aws wafv2 get-logging-configuration \
--resource-arn <WEB_ACL_ARN>
```

```rb
aws wafv2 get-logging-configuration \
--resource-arn arn:aws:wafv2:us-east-2:329599652812:regional/webacl/armage-dev-web-acl/1feb28cd-4fbf-4dd8-b67d-12ed265506a3
```

Expected: LogDestinationConfigs contains exactly one destination.

To gain arn via cli:
```rb
aws wafv2 list-web-acls \
--scope REGIONAL \
--region us-east-2 \
--query "WebACLs[?Name=='armage-dev-web-acl'].ARN" \
--output text
```

## 2. Generate traffic (hits + blocks)
```rb
  curl -I https://chewbacca-growl.com/
  curl -I https://app.chewbacca-growl.com/
```

```rb
curl -I https://daequanbritt.com/
curl -I https://app.daequanbritt.com/
```

## 3 (option 1). If CloudWatch Logs destination
```rb
aws logs describe-log-streams \
--log-group-name aws-waf-logs-<project>-webacl01 \
--order-by LastEventTime --descending
```

```rb
aws logs describe-log-streams \
--log-group-name aws-waf-logs-armage-webacl \
--order-by LastEventTime \
--descending \
--region us-east-2
```

Then pull recent events:
```rb
aws logs filter-log-events \
--log-group-name aws-waf-logs-<project>-webacl01 \
--max-items 20
```

```rb
aws logs filter-log-events \
--log-group-name aws-waf-logs-armage-webacl \
--max-items 20 \
--region us-east-2
```
## 3 (option 2). If S3 destination
  aws s3 ls s3://aws-waf-logs-<project>-<account_id>/ --recursive | head

## 3 (option 3). If Firehose destination
  aws firehose describe-delivery-stream \
  --delivery-stream-name aws-waf-logs-<project>-firehose01 \
  --query "DeliveryStreamDescription.DeliveryStreamStatus"

And confirm objects land:
  aws s3 ls s3://<firehose_dest_bucket>/waf-logs/ --recursive | head