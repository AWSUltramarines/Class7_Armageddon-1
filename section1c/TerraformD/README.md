# Verification

[verify png first part](./verify/1c_B_verifcation.png)

PROVE EC2 HAS NO PUBLIC IP:
   aws ec2 describe-instances \
     --instance-ids i-05eff1374d532dc49 \
     --query "Reservations[].Instances[].PublicIpAddress"
   Expected: null

PROVE VPC ENDPOINTS EXIST:
   aws ec2 describe-vpc-endpoints \
     --filters "Name=vpc-id,Values=vpc-0dd5396269950ad64" \
     --query "VpcEndpoints[].ServiceName"
   Expected: ssm, ssmmessages, ec2messages, logs, secretsmanager, kms, s3

PROVE SSM SESSION MANAGER WORKS:
   aws ssm describe-instance-information \
     --query "InstanceInformationList[].InstanceId"
   Expected: i-05eff1374d532dc49 appears

1. CONNECT VIA SESSION MANAGER:
   aws ssm start-session --target i-05eff1374d532dc49

[verify png first part](./verify/1c_B_verifcation2.png)

FROM INSIDE SSM SESSION - TEST CONFIG ACCESS;
   aws ssm get-parameter --name /lab/db/endpoint --region us-east-1
   aws secretsmanager get-secret-value --secret-id chewbacca/rds/mysql --region us-east-1

PROVE CLOUDWATCH LOGS PATH:
   aws logs describe-log-streams \
     --log-group-name /aws/ec2/chewbacca-rds-app
