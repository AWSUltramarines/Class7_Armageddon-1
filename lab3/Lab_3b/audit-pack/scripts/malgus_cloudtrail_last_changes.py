#!/usr/bin/env python3
import boto3, json
from datetime import datetime, timedelta, timezone

# Reason why Darth Malgus would be pleased with this script.
# Malgus demands accountability: "Who touched my infrastructure? When? Show me."
# Reason why this script is relevant to your career.
# CloudTrail forensics is foundational for incident response, compliance audits, and security investigations.
# How you would talk about this script at an interview.
# "I built a CloudTrail evidence collector that pulls recent security-relevant events like SG changes and TGW modifications."

TARGET_EVENTS = [
    "AuthorizeSecurityGroupIngress",
    "RevokeSecurityGroupIngress",
    "CreateTransitGateway",
    "CreateTransitGatewayPeeringAttachment",
    "AcceptTransitGatewayPeeringAttachment",
    "CreateRoute",
    "DeleteRoute",
    "ModifyDBInstance",
    "CreateDBInstance",
]

def lookup_events(region, event_names, hours_back=72):
    ct = boto3.client("cloudtrail", region_name=region)
    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(hours=hours_back)
    
    all_events = []
    for event_name in event_names:
        try:
            resp = ct.lookup_events(
                LookupAttributes=[
                    {"AttributeKey": "EventName", "AttributeValue": event_name}
                ],
                StartTime=start_time,
                EndTime=end_time,
                MaxResults=10
            )
            for e in resp.get("Events", []):
                all_events.append({
                    "region": region,
                    "event_name": e.get("EventName"),
                    "event_time": str(e.get("EventTime")),
                    "username": e.get("Username"),
                    "event_id": e.get("EventId"),
                    "resources": [r.get("ResourceName") for r in e.get("Resources", [])]
                })
        except Exception as ex:
            all_events.append({"region": region, "event_name": event_name, "error": str(ex)})
    
    return all_events

def main():
    tokyo_events = lookup_events("ap-northeast-1", TARGET_EVENTS)
    sp_events = lookup_events("sa-east-1", TARGET_EVENTS)
    
    evidence = {
        "generated_at": str(datetime.now(timezone.utc)),
        "hours_lookback": 72,
        "tokyo_events": tokyo_events,
        "saopaulo_events": sp_events,
        "total_events": len(tokyo_events) + len(sp_events)
    }
    print(json.dumps(evidence, indent=2, default=str))

if __name__ == "__main__":
    main()