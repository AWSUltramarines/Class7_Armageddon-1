#!/usr/bin/env python3
import boto3, json
from datetime import datetime, timedelta, timezone

# Reason why Darth Malgus would be pleased with this script.
# Malgus does not tolerate invisible shields: "Prove the WAF is working. Show me blocks."
# Reason why this script is relevant to your career.
# WAF metrics are critical for security posture reporting and incident triage.
# How you would talk about this script at an interview.
# "I built a WAF evidence collector that queries CloudWatch metrics to prove Allow/Block rates for audit compliance."

def get_waf_acls():
    """List WAFv2 Web ACLs (CloudFront scope requires us-east-1)"""
    waf = boto3.client("wafv2", region_name="us-east-1")
    acls = []
    try:
        resp = waf.list_web_acls(Scope="CLOUDFRONT")
        for acl in resp.get("WebACLs", []):
            acls.append({
                "name": acl.get("Name"),
                "id": acl.get("Id"),
                "arn": acl.get("ARN")
            })
    except Exception as ex:
        acls.append({"error": str(ex)})
    return acls

def get_waf_metrics(web_acl_name, rule_name="ALL", hours_back=24):
    """Get WAF Allow/Block counts from CloudWatch metrics"""
    cw = boto3.client("cloudwatch", region_name="us-east-1")
    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(hours=hours_back)
    
    metrics = {}
    for action in ["AllowedRequests", "BlockedRequests"]:
        try:
            resp = cw.get_metric_statistics(
                Namespace="AWS/WAFV2",
                MetricName=action,
                Dimensions=[
                    {"Name": "WebACL", "Value": web_acl_name},
                    {"Name": "Rule", "Value": rule_name},
                    {"Name": "Region", "Value": "us-east-1"}
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=3600,
                Statistics=["Sum"]
            )
            total = sum(dp.get("Sum", 0) for dp in resp.get("Datapoints", []))
            metrics[action] = int(total)
        except Exception as ex:
            metrics[action] = f"error: {ex}"
    
    return metrics

def main():
    acls = get_waf_acls()
    
    evidence = {
        "generated_at": str(datetime.now(timezone.utc)),
        "web_acls": acls,
        "metrics": {}
    }
    
    # Try to get metrics for each ACL found
    for acl in acls:
        if "name" in acl:
            evidence["metrics"][acl["name"]] = get_waf_metrics(acl["name"])
    
    print(json.dumps(evidence, indent=2, default=str))

if __name__ == "__main__":
    main()