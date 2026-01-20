# Student Deliverables

## 1.Screenshot of: RDS SG inbound rule using source = sg-ec2-lab EC2 role attached /list output showing at least 3 notes

[ec2-rds-1](./assets/ec2-rds-1.png)
[Main App page](./assets/lab-ec2-app_main.png)
[/list of notes entries (clickOps)](./assets/lab-ec2-app_list_view.png)
[/list of notes entries (Terraform)](./assets/ec2_lab_list.png)

## 2.Short answers

A) Why is DB inbound source restricted to the EC2 security group?  
This allows access only to EC2 through SG to SG pattern

B) What port does MySQL use?
MySQL uses port 3306 for ingress/egress access

C) Why is Secrets Manager better than storing creds in code/user-data?
The Secrets Manager allows better password management for a number of factors. It is a safe place to save the password that allows access to mulitple sources, allows rotation of passwords and removes hardcoding in insecure locations.

## 3.Evidence for Audits / Labs (Recommended Output)

aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0 > [sg.json](./json/sg.json)

aws rds describe-db-instances --db-instance-identifier mydb01 > [rds.json](./json/rds.json)

aws secretsmanager describe-secret --secret-id my-db-secret > [secret.json](./json/secret.json)

aws ec2 describe-instances --instance-ids i-0123456789abcdef0 > [instance.json](./json/instance.json)

aws iam list-attached-role-policies --role-name MyEC2Role > [role-policies.json](./json/role-policies.json)

## Then Answer

Why each rule exists?
ec2-lab-sg - gives egress/ingress access to Ec2 (lab-ec2-app)
ec2-rds-1 - gives egress/ingress access to RDS (lab-mysql)
armageddon-ec2-db-role - role-policy grants access to Ec2 (lab-ec2-app) to secrets manager which gives password to access RDS (lab-mysql)

What would break if removed?
If removed Ec2 will be denied access to secrets manager

Why broader access is forbidden?
Broader access is forbidden by default because of the "Principle of Least Privilege"

Why this role exists?
This role gives the Ec2 access to the secrets manager key "lab/rds/mysql"

Why it can read this secret? Why it cannot read others?
The Ec2 can read this secret because the after the role 'armageddon-ec2-db-role' gains access, that along with an attached inline policy that connects to secret 'lab/rds/mysql' specifically, which restricts access to that key rather than all secretss in the secrets manager.
