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
| [Step 2: Check CloudWatch Logs](#step-2-check-cloudwatch-logs-for-db-connection-errors) | Identify error patterns in logs |
| [Step 3: Verify Parameter Store](#step-3-verify-parameter-store-values) | Validate SSM parameter values |
| [Step 4: Verify Secrets Manager](#step-4-verify-secrets-manager-credentials) | Check credential consistency |
| [Step 5: Check RDS Status](#step-5-check-rds-instance-status) | Verify database availability |
| [Step 6a: Credential Drift Recovery](#scenario-6a-credential-drift) | Fix password mismatch |
| [Step 6b: Network Isolation Recovery](#scenario-6b-network-isolation) | Restore security group rules |
| [Step 6c: Database Unavailable Recovery](#scenario-6c-database-unavailable) | Start stopped RDS instance |
| [Step 7: Verify Application](#step-7-verify-application-endpoints) | Test all API endpoints |
| [Step 8: Confirm Alarm OK](#step-8-confirm-alarm-returns-to-ok) | Validate monitoring recovery |
| [Step 9: Post-Incident Documentation](#step-9-post-incident-documentation) | Record incident details |


