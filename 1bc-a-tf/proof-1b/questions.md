A. Why might Parameter Store still exist alongside Secrets Manager?

* Parameter Store is best suited for configuration values and non-rotating data.
    * Here we want to hold things like the endpoint's name "/lab/db/endpoint" or the secret's name "/lab/rds/mysql".
* Secrets Manager is best suited for credentials and rotating data.
    * Here we want to hold things like passwords "password123" or usernames "admin".

B. What breaks first during secret rotation?

* The application's existing connection or cached credentials breaks first.

C. Why should alarms be based on symptoms instead of causes?

* Because a single symptom can stem from multiple different causes. We have multiple different ways to break our application but we only need one alarm to realize that the application is broken. We then diagnose the core issue and solve it. 

* If we only focused on causes not only would we have much more to set up but we would then leave more blindspots in our monitoring setup.

D. How does this lab reduce mean time to recovery (MTTR)?

* It eliminates redeployment delays by externalizing database credentials with secrets manager and endpoints. The application can recover from configuration changes simply by reading the new values. This would shorten the recovery window compared to a system that requires a new server.

* It reduces the time to identify symptoms through centralized logging with cloudwatch and automated alarms. An engineer will be alerted when connectivity fails instead of waiting for a manual report or a search through the logs

E. What would you automate next?

* The secrets make the most sense to have automatically rotating.