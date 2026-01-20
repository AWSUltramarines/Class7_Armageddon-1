1. ALB exists and is active
```rb
aws elbv2 describe-load-balancers \
--names armage-dev-alb \
--region us-east-2 \
--query "LoadBalancers[0].State.Code"
```

2. HTTPS listener exists on 443
```rb
aws elbv2 describe-listeners \
--load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:329599652812:loadbalancer/app/armage-dev-alb/156aeae77d1d5381 \
--region us-east-2 \
--query "Listeners[].Port"
```

A more dynamic command without pasting the actual arn, have tf generate it:
```rb
aws elbv2 describe-listeners \
  --load-balancer-arn $(terraform output -raw alb_arn) \
  --region us-east-2 \
  --query "Listeners[].Port"
```

3. Target is healthy
```rb
aws elbv2 describe-target-health \
--target-group-arn arn:aws:elasticloadbalancing:us-east-2:329599652812:targetgroup/flask-app-tg/940d922b2c9a5cd4 \
--region us-east-2
```

```rb
aws elbv2 describe-target-health \
--target-group-arn $(terraform output -raw target_group_arn) \
--region us-east-2
```

4. WAF attached
```rb
aws wafv2 get-web-acl-for-resource
--resource-arn <ALB_ARN>
```

```rb
aws wafv2 get-web-acl-for-resource \
  --resource-arn arn:aws:elasticloadbalancing:us-east-2:329599652812:loadbalancer/app/armage-dev-alb/156aeae77d1d5381 \
  --region us-east-2
```

```rb
aws wafv2 get-web-acl-for-resource \
--resource-arn $(terraform output -raw alb_arn) \
--region us-east-2
```

5. Alarm created (ALB 5xx)

```rb
aws cloudwatch describe-alarms \
--alarm-name-prefix chewbacca-alb-5xx
```

```rb
aws cloudwatch describe-alarms \
--alarm-name-prefix daequan-alb-5xx
```

6. Dashboard exists
```rb
aws cloudwatch list-dashboards \
--dashboard-name-prefix daequanbritt
```