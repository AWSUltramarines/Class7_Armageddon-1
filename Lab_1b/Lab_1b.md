# Armegadden_Lab_1b (Operations & Incident Response)
**Summary**
In Lab 1b, you will operate, observe, break, and recover the system. You will extend your EC2 → RDS application to include: 
- Dual Secret Storage - Parameter Store for operational metadata
- Centralized Logging - CloudWatch Logs with real-time log shipping
- Proactive Monitoring - Metric filters detecting DB connection failures
- Automated Alerting - CloudWatch Alarms with SNS notifications
- Incident Response - Recovery Procedures |  After action report

This lab simulates what happens after deployment, which is where most real cloud work lives.


## Troubleshooting Checklist and General troubleshooting
| First Steps | Description |
|-------------|-------------|
| [Step 1: Check Alarm State](#step-1-check-alarm-state) | Verify CloudWatch alarm status |
| [Step 2: Check CloudWatch Logs] | Identify error patterns in logs |
| [Step 3: Verify Parameter Store](#step-3-verify-parameter-store-values) | Validate SSM parameter values |
| [Step 4: Verify Secrets Manager](#step-4-verify-secrets-manager-credentials) | Check credential consistency |
| [Step 5: Check RDS Status](#step-5-check-rds-instance-status) | Verify database availability |
| [Step 6a: Credential Drift Recovery](#scenario-6a-credential-drift) | Fix password mismatch |
| [Step 6b: Network Isolation Recovery](#scenario-6b-network-isolation) | Restore security group rules |
| [Step 6c: Database Unavailable Recovery](#scenario-6c-database-unavailable) | Start stopped RDS instance |
| [Step 7: Verify Application](#step-7-verify-application-endpoints) | Test all API endpoints |
| [Step 8: Confirm Alarm OK](#step-8-confirm-alarm-returns-to-ok) | Validate monitoring recovery |
| [Step 9: Post-Incident Documentation](#step-9-post-incident-documentation) | Record incident details |

### After Action Report
Incident Title: Network & Computing Systems Outage
Date of Incident: [Insert Date]
Prepared By: Jason Lee
Systems Affected: Network Infrastructure, Application Servers, Database Services
Duration: [Start Time – End Time]

1. Incident Summary

On [date/time], a network and computing systems outage impacted user access to critical applications and backend services.
Users experienced intermittent connectivity issues and service unavailability.

The outage was detected through user reports and system monitoring alerts.

Services were restored after identifying and resolving the root cause.

2. Impact

Application access disruptions

Database connectivity failures

Reduced productivity for affected users

Increased support requests

No data loss was identified.

3. Root Cause

The outage was caused by:
[Example — choose one or customize]

Misconfigured security group/firewall rule blocking service traffic

Network routing failure between compute and database subnets

Expired credentials or access permissions

Resource exhaustion (CPU, memory, or disk)

This prevented正常 communication between core systems.

4. Detection & Response

Detection Methods:

User-reported errors

Monitoring alerts (logs/metrics)

Response Actions Taken:

Verified system health and connectivity

Reviewed logs and network access controls

Identified misconfiguration/failure point

Implemented corrective fix

Validated service restoration

5. Resolution

Service was restored by:

Correcting network/security configuration

Restoring access permissions

Restarting affected services (if applicable)

Verifying application and database connectivity

All systems returned to normal operation.

6. Lessons Learned

Monitoring alerts were effective but could trigger sooner

Configuration changes should include validation checks

Clearer documentation would speed troubleshooting

7. Preventive Actions

Implement automated configuration validation

Improve monitoring thresholds and alerts

Update network and system documentation

Conduct periodic recovery drills
