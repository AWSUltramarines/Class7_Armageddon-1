## Auditor Narrative

This multi-region architecture ensures full compliance with Japan's Act on Protection of Personal Information (APPI) through strict data residency enforcement. The RDS database (helga-rdslab3) exists exclusively in Tokyo (ap-northeast-1), ensuring all personal information of Japanese residents remains within Japanese jurisdiction at all times. São Paulo (sa-east-1) serves purely as a compute spoke with no persistent data storage—it can query the Tokyo database via Transit Gateway peering, but the data itself never physically leaves Japan.

The database cannot be placed overseas because APPI Article 28 requires explicit prior consent from data subjects before transferring their personal information to a foreign country. Without that consent, hosting Japanese resident data outside Japan is a direct regulatory violation. By keeping the RDS anchored in Tokyo, we eliminate any risk of unauthorized cross-border data transfer.

Network controls reinforce this design. Transit Gateway peering creates a verified, auditable corridor between regions. Security groups restrict database access to known CIDRs. WAF and CloudFront provide edge protection and traffic filtering. CloudTrail logs all infrastructure changes with 90-day history, ensuring every modification is attributable and auditable.
