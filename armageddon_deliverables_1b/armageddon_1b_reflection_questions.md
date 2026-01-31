Armageddon 1B Reflection Questions

A) Why might Parameter Store still exist alongside Secrets Manager?

SSM Parameter Store and Secrets Manager are useful for different things which allow them to pair together nicely. Parameter store is useful for retrieving static values from your configuration, while Secrets manager is more secure, allows retrieval of more sensitive data, and supports rotation. Also, parameter store is free, while Secrets manager charges by use. So it is good to have both together to retrieve data of different risk levels, as well as to manage cost. 

B) What breaks first during secret rotation?

When Secrets Manager creates a new secret during rotation, what breaks first is the applications access to the db as authentication will fail. 

C) Why should alarms be based on symptoms instead of causes?

The symptoms indicate the actual impact is, while the cause does not. 

D) How does this lab reduce mean time to recovery (MTTR)?

This lab reduces mean time to recovery because it take a proactive approach. There are notifications set up to alert of failure, logs to  state the issue, and parameter store/secrets manager to help with recovery. With out certain components of this labs configuration, recovery would take much longer.


E) What would you automate next?

I'd add health checks to proactively check detect connectivity issue. You may be able to catch the failure before the alarm is triggered. 
