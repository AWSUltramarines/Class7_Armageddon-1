# Armageddon Lab_1a (click ops)
**Lab Summary**
* Build a classic AWS cloud application architecture
* Use an **Amazon EC2 instance** as the compute layer
* Use an **Amazon RDS database** as the managed relational database
* Configure **secure EC2-to-RDS connectivity** using **VPC networking + Security Groups**
* Store/manage database credentials using **AWS Secrets Manager**
* Deploy a simple app that **writes to and reads from the database**

# Lab Diagram
<img width="1352" height="716" alt="image" src="https://github.com/user-attachments/assets/0e1edc5b-41fe-4f8f-ab39-0566e394dd8c" />

# Student Deliverables:
Screenshot of: RDS SG inbound rule using source = sg-ec2-lab EC2 role attached /list output showing at least 3 notes

# ScreenShots
**EC2-Instance:ec2-lab-application**
<img width="1262" height="504" alt="image" src="https://github.com/user-attachments/assets/bc10642d-1ec6-48c8-b173-801b4bf2a0b0" />

**Database Instance: lab-mysql**
<img width="1273" height="547" alt="image" src="https://github.com/user-attachments/assets/7c767cd7-5272-45a5-a489-df81acda4b8b" />

**Public Side Security Group:SG-Pub-01**
<img width="1272" height="429" alt="image" src="https://github.com/user-attachments/assets/3f6fb89a-aeec-4812-bb08-351716f65254" />

**Private Side Security Group:SG-PVT-01**
<img width="1269" height="397" alt="image" src="https://github.com/user-attachments/assets/19852db7-620b-4f39-9877-a23cf3c9f194" />

**EC2 TCP port 80 access**

<img width="830" height="116" alt="image" src="https://github.com/user-attachments/assets/f060f590-10a9-42af-a936-3b7151894fdb" />

**EC2 Website note test**

<img width="778" height="118" alt="image" src="https://github.com/user-attachments/assets/455528ea-2236-418e-b443-1628b0d698c8" />

**Database Init test**

<img width="812" height="82" alt="image" src="https://github.com/user-attachments/assets/b6cc7340-5cc3-4b1d-abe5-ef7bbbde28d2" />

**Verify SSH Access to EC2/ secretsmanager**
<img width="1905" height="839" alt="image" src="https://github.com/user-attachments/assets/ef4f0ed5-72be-4a73-afc4-16c15aa84d43" />




**Short answers:**

A) Why is DB inbound source restricted to the EC2 security group? 

`It prevents the database from being reachable by any other device that doesn't need access. It is best practice to protect your database (Tea app!)`

B) What port does MySQL use? `TCP Port 3306`

C) Why is Secrets Manager better than storing creds in code/user-data?

`Secrets Manager prevents credentials from being exposed from your systems and replaces them with secure, controlled, auditable secret retrieval at runtime.`

Evidence for Audits / Labs (Recommended Output)



