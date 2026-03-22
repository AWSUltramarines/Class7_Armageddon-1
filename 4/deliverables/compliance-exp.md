Two pre-shared keys were generated using openssl. This produced random hex strings with no special characters that would be rejected by AWS.
The pre-shared keys were stored in GCP Secret manager before any VPN infrastructure was deployed. 
On the AWS side the pre shared keys were passed in as terraform variables sourced from environment variables at apply time and never written into the tfvars file or committed to version control.
On the GCP side the pre shared keys were read directly from secret manager at terraform apply time so they never appeared in terraform state.
The two sides coordinated by referencing the same pre shared key values.
The secret names were shared verbally and the AWS team retrieved the values from secret manager rather than some other insecure method such as slack message.
If the key were to be intercepted an attacker can decrypt all vpn traffic including api calls to tokyo rds containing patient data.
Keeping pre shared keys out of chats, emails, and repositories is a compliance requirement.
Additionally IAM limited secret retrieval to authorized service accounts only.

___

No patient data is stored in GCP because the New York branch runs stateless compute only. The GCP VMs process requests in memory and reads from Tokyo RDS over the VPN corridor, but write nothing to disk. 
There is no local database, cache or logs that could contain the PHI.
This satisfies Japanese privacy law (APPI) (Act on the Protection of Personal Information).
The authoritative data store remains exclusively in AWS Tokyo (ap-northeast-1) at all times.
The GCP Iowa environment holds no medical records at rest.
The MIG instances mount no persistent disks beyond the operating system.
The startup script does not log query results.
The RDS test script writes a timestamp row to Tokyo instead of a local data store.
Cloud is a capability, and this deployment makes use of the capabilities of GCP whithout having multi-storage although it is multi-cloud.
Just having two clouds does not duplicate permissions to replicate regulated data.
The architecture was designed so that GCP is a corridor for computing not holding data.
All PHI remains in Japan regardless of which cloud serves the application layer