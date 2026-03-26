Armageddon Lab 3B



Auditor Narrative



**Deliverable B — One paragraph “auditor narrative”**

**“この設計が APPI 的に安全で、なぜ DB を海外に置けないか”を 8〜12 行で説明。**



The Japanese Legislation titled the "Act on the Protection of Personal Information" was enacted in 2003, with three amendments between 2015 and 2022. This is Japan's main protection law to regulate how personal data of Japanese citizens is used and collected both domestically and internationally. APPI applies to both Japanese and foreign companies, and defines personal data to includes names, birthdays, biometric data, medical history, criminal records and more. 



Cross border transfers are scrutinized particularly closely. Our Infrastructure configuration aligns well and is safe from  the APPI perspective because while data is accessible in Sao Paulo,  our database remains in Japan, and also is not publicly accessible. This important under our lab, because while data technically can be placed overseas,  patient data would subject to transfer requirements including patient consent, recipient country meeting or exceeding Japan's Personal Information Protection Commission (PPC) standards, and also the recipient country having an equivalent protection system. Brazil is not white listed country for cross border data transfer, and would create significant challenges as Brazil does not meet the PPC standards, and consent would be required from every patient with data. Our configuration also has non APPI specific security controls in place, including Database encryption, active Secrets Manager, CloudFront with HTTPS, active logging, and network resources in both regions limited to private access. 



