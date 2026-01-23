**Lab 1C-Bonus-F**, is about **Observability and Incident Response** . You are moving from building the "Security Cameras" (WAF logging) to actually using the "Control Room" (CloudWatch Logs Insights) to investigate attacks and failures.

### 🕵️ Lab 1C-Bonus-F: Logs Insights Query Pack

* **🔍 The Search Engine**: CloudWatch Logs Insights is a powerful tool that allows you to run SQL-like queries against your logs to find patterns.

* **🌉 WAF vs. App Logs**: This pack covers the **WAF logs** (external pressure/attacks) and the **App logs** (internal backend failures like RDS connection issues).

* **📍 Log Location**: Insights only works on data stored in CloudWatch. Since your ALB access logs are in S3, they are not covered by this specific tool.

* **🎭 The "Detective" Workflow**: You will use these queries to answer a critical question during an incident: *"Is this an external attack or did our backend just break?"*.

---

### 📝 Step-by-Step To-Do List

Follow these steps to complete the final part of your Lab 1 assignment:

1. **Identify Your Log Groups**: Confirm your specific log group names. In this deployment, they are:

    * **WAF Log Group**: `aws-waf-logs-armage-webacl`.

    * **App Log Group**: `/aws/ec2/lab-rds-app`.

2. **Open Logs Insights**: Navigate to the **CloudWatch Console** -> **Logs** -> **Logs Insights**.

3. **Select Log Groups**: In the dropdown, select the WAF and App log groups identified above.

4. **Set the Time Range**: Ensure the time range is set to the **Last 15 minutes** (or the specific window of your "incident").

5. **Run WAF Queries (Section A)**: Copy and run the queries for "Top Actions," "Top Client IPs," and "Blocked Requests" to see who is hitting your site.

6. **Run App Queries (Section B)**: Use the "Count errors over time" and "DB failures" queries to check the health of your Flask and RDS connection.

7. **Complete the Runbook Section (Section C)**: Document your findings in an "Incident Runbook" format, following the 4-step Enterprise correlation workflow (Attack vs. Backend Failure).

8. **Verify Recovery**: Run a final `curl` to `https://app.daequanbritt.com/list` and check the B1 query to ensure errors have returned to baseline.

---

### 🚀 Pro-Tip for your Report

When you run query **A5** (*"Which WAF rule is doing the blocking?"*), take a screenshot . If you see `AWSManagedRulesCommonRuleSet`, it proves your firewall is actively defending `daequanbritt.com` against real-world scanners.
