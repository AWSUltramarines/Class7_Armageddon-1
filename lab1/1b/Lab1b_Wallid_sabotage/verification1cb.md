ALB exists and is active
   
      aws elbv2 describe-load-balancers \
        --names helga-alb01 \
        --query "LoadBalancers[0].State.Code"

3) HTTPS listener exists on 443
   
      aws elbv2 describe-listeners \
        --load-balancer-arn <ALB_ARN> \
        --query "Listeners[].Port"

arn:aws:elasticloadbalancing:us-east-2:919113286081:listener/app/helga-alb01/fbd9d21c9b3e51b5/fe4eace123d566fb



aws elbv2 describe-listeners \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:919113286081:loadbalancer/app/helga-alb01/fbd9d21c9b3e51b5 \
  --query "Listeners[].Port"

4) Target is healthy
   
      aws elbv2 describe-target-health \
        --target-group-arn <TG_ARN>

      aws elbv2 describe-target-health \
        --target-group-arn arn:aws:elasticloadbalancing:us-east-2:919113286081:targetgroup/helga-tg01/83c2c9874f0da82b


5) WAF attached
   
      aws wafv2 get-web-acl-for-resource \
        --resource-arn <ALB_ARN>

      aws wafv2 get-web-acl-for-resource \
        --resource-arn arn:aws:elasticloadbalancing:us-east-2:919113286081:loadbalancer/app/helga-alb01/fbd9d21c9b3e51b5


7) Alarm created (ALB 5xx)
   
      aws cloudwatch describe-alarms \
        --alarm-name-prefix helga-alb-5xx

9) Dashboard exists
    
      aws cloudwatch list-dashboards \
        --dashboard-name-prefix helga