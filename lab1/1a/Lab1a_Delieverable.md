Student Deliverables:
1) Screenshot of:
  RDS SG inbound rule using source = sg-ec2-lab
  EC2 role attached
  /list output showing at least 3 notes

2) Short answers:
  A) Why is DB inbound source restricted to the EC2 security group?
  The answer in my own words would be: Because we don't want anybody getting access to this database, and by it only being accessed by the EC2, that will be the only thing that can write into it. Otherwise, other people will be able to put stuff into our database or even launch attacks, and it will leave the database vulnerable. 
  
  B) What port does MySQL use?
  The Port is 3306.
  C) Why is Secrets Manager better than storing creds in code/user-data?
  In my own words, I would say the Secrets Manager is better because it is natively in AWS. Another unique benefit of using the Secrets Manager is that you don't have to worry about risking the credentials on your actual device and it's inside of your account, and you don't have to go fiddle around with passwords. So the risk of loss is lowered. And then with it also being within AWS, it has a feature where you could even rotate the keys automatically. That way you don't have to worry about remembering to change the password every single time. 