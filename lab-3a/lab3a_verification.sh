#!/bin/bash

###############################################################################
# Lab 3A Verification Script
# This script verifies the Tokyo-São Paulo TGW peering architecture
###############################################################################

set -e

echo "========================================="
echo "Lab 3A Infrastructure Verification"
echo "========================================="
echo ""

###############################################################################
# 1. VPC Verification
###############################################################################
echo "1. VPC VERIFICATION"
echo "-------------------"

echo "Tokyo VPC - confirm CIDR 10.241.0.0/16"
aws ec2 describe-vpcs --region ap-northeast-1 \
  --filters "Name=cidr-block,Values=10.241.0.0/16" \
  --query "Vpcs[].{VpcId:VpcId, CIDR:CidrBlock, State:State}" --output table

echo ""
echo "São Paulo VPC - confirm CIDR 10.214.0.0/16"
aws ec2 describe-vpcs --region sa-east-1 \
  --filters "Name=cidr-block,Values=10.214.0.0/16" \
  --query "Vpcs[].{VpcId:VpcId, CIDR:CidrBlock, State:State}" --output table

echo ""

###############################################################################
# 2. Transit Gateway Verification
###############################################################################
echo "2. TRANSIT GATEWAY VERIFICATION"
echo "--------------------------------"

echo "Tokyo TGW - confirm ASN 64512"
aws ec2 describe-transit-gateways --region ap-northeast-1 \
  --query "TransitGateways[].{Id:TransitGatewayId, ASN:Options.AmazonSideAsn, State:State, Name:Tags[?Key=='Name']|[0].Value}" --output table

echo ""
echo "São Paulo TGW - confirm ASN 64513"
aws ec2 describe-transit-gateways --region sa-east-1 \
  --query "TransitGateways[].{Id:TransitGatewayId, ASN:Options.AmazonSideAsn, State:State, Name:Tags[?Key=='Name']|[0].Value}" --output table

echo ""

###############################################################################
# 3. TGW VPC Attachments
###############################################################################
echo "3. TGW VPC ATTACHMENTS"
echo "----------------------"

echo "Tokyo TGW attached to Tokyo VPC"
aws ec2 describe-transit-gateway-vpc-attachments --region ap-northeast-1 \
  --query "TransitGatewayVpcAttachments[].{AttachmentId:TransitGatewayAttachmentId, TGW:TransitGatewayId, VPC:VpcId, State:State, Name:Tags[?Key=='Name']|[0].Value}" --output table

echo ""
echo "São Paulo TGW attached to São Paulo VPC"
aws ec2 describe-transit-gateway-vpc-attachments --region sa-east-1 \
  --query "TransitGatewayVpcAttachments[].{AttachmentId:TransitGatewayAttachmentId, TGW:TransitGatewayId, VPC:VpcId, State:State, Name:Tags[?Key=='Name']|[0].Value}" --output table

echo ""

###############################################################################
# 4. TGW Peering Attachment (the cross-region link)
###############################################################################
echo "4. TGW PEERING ATTACHMENT"
echo "-------------------------"

echo "Tokyo side (Creator) - should show 'available'"
aws ec2 describe-transit-gateway-peering-attachments --region ap-northeast-1 \
  --query "TransitGatewayPeeringAttachments[].{Id:TransitGatewayAttachmentId, State:State, RequesterTGW:RequesterTgwInfo.TransitGatewayId, AccepterTGW:AccepterTgwInfo.TransitGatewayId, RequesterRegion:RequesterTgwInfo.Region, AccepterRegion:AccepterTgwInfo.Region}" --output table

echo ""
echo "São Paulo side (Accepter) - should also show 'available'"
aws ec2 describe-transit-gateway-peering-attachments --region sa-east-1 \
  --query "TransitGatewayPeeringAttachments[].{Id:TransitGatewayAttachmentId, State:State, RequesterTGW:RequesterTgwInfo.TransitGatewayId, AccepterTGW:AccepterTgwInfo.TransitGatewayId}" --output table

echo ""

###############################################################################
# 5. TGW Route Tables (cross-region routes)
###############################################################################
echo "5. TGW ROUTE TABLES"
echo "-------------------"

echo "Tokyo TGW routes - should show 10.214.0.0/16 → peering attachment"
TOKYO_TGW_ID=$(aws ec2 describe-transit-gateways --region ap-northeast-1 --query "TransitGateways[0].TransitGatewayId" --output text)
TOKYO_TGW_RT=$(aws ec2 describe-transit-gateway-route-tables --region ap-northeast-1 --filters "Name=transit-gateway-id,Values=$TOKYO_TGW_ID" --query "TransitGatewayRouteTables[0].TransitGatewayRouteTableId" --output text)
aws ec2 search-transit-gateway-routes --region ap-northeast-1 \
  --transit-gateway-route-table-id "$TOKYO_TGW_RT" \
  --filters "Name=type,Values=static" \
  --query "Routes[].{CIDR:DestinationCidrBlock, State:State, AttachmentId:TransitGatewayAttachments[0].TransitGatewayAttachmentId, ResourceType:TransitGatewayAttachments[0].ResourceType}" --output table

echo ""
echo "São Paulo TGW routes - should show 10.241.0.0/16 → peering attachment"
SP_TGW_ID=$(aws ec2 describe-transit-gateways --region sa-east-1 --query "TransitGateways[0].TransitGatewayId" --output text)
SP_TGW_RT=$(aws ec2 describe-transit-gateway-route-tables --region sa-east-1 --filters "Name=transit-gateway-id,Values=$SP_TGW_ID" --query "TransitGatewayRouteTables[0].TransitGatewayRouteTableId" --output text)
aws ec2 search-transit-gateway-routes --region sa-east-1 \
  --transit-gateway-route-table-id "$SP_TGW_RT" \
  --filters "Name=type,Values=static" \
  --query "Routes[].{CIDR:DestinationCidrBlock, State:State, AttachmentId:TransitGatewayAttachments[0].TransitGatewayAttachmentId, ResourceType:TransitGatewayAttachments[0].ResourceType}" --output table

echo ""

###############################################################################
# 6. VPC Route Tables (private subnets route cross-region CIDR to TGW)
###############################################################################
echo "6. VPC ROUTE TABLES"
echo "-------------------"

echo "Tokyo private route tables - should have 10.214.0.0/16 → TGW"
TOKYO_VPC=$(aws ec2 describe-vpcs --region ap-northeast-1 --filters "Name=cidr-block,Values=10.241.0.0/16" --query "Vpcs[0].VpcId" --output text)
aws ec2 describe-route-tables --region ap-northeast-1 \
  --filters "Name=vpc-id,Values=$TOKYO_VPC" \
  --query "RouteTables[].{RTId:RouteTableId, Name:Tags[?Key=='Name']|[0].Value, Routes:Routes[?DestinationCidrBlock=='10.214.0.0/16'].{Dest:DestinationCidrBlock,TGW:TransitGatewayId,State:State}}" --output table

echo ""
echo "São Paulo private route tables - should have 10.241.0.0/16 → TGW"
SP_VPC=$(aws ec2 describe-vpcs --region sa-east-1 --filters "Name=cidr-block,Values=10.214.0.0/16" --query "Vpcs[0].VpcId" --output text)
aws ec2 describe-route-tables --region sa-east-1 \
  --filters "Name=vpc-id,Values=$SP_VPC" \
  --query "RouteTables[].{RTId:RouteTableId, Name:Tags[?Key=='Name']|[0].Value, Routes:Routes[?DestinationCidrBlock=='10.241.0.0/16'].{Dest:DestinationCidrBlock,TGW:TransitGatewayId,State:State}}" --output table

echo ""

###############################################################################
# 7. RDS Verification (Tokyo Only - APPI Compliance)
###############################################################################
echo "7. RDS VERIFICATION"
echo "-------------------"

echo "Confirm RDS exists ONLY in Tokyo"
aws rds describe-db-instances --region ap-northeast-1 \
  --query "DBInstances[].{Identifier:DBInstanceIdentifier, Engine:Engine, Status:DBInstanceStatus, AZ:AvailabilityZone, Endpoint:Endpoint.Address, Port:Endpoint.Port, Encrypted:StorageEncrypted}" --output table

echo ""
echo "Confirm NO RDS in São Paulo (should return empty)"
aws rds describe-db-instances --region sa-east-1 \
  --query "DBInstances[].{Identifier:DBInstanceIdentifier}" --output table

echo ""

###############################################################################
# 8. Security Group Rules - Cross-Region MySQL (Port 3306)
###############################################################################
echo "8. SECURITY GROUP RULES"
echo "-----------------------"

echo "Tokyo RDS SG - should allow inbound 3306 from 10.214.0.0/16 (São Paulo)"
aws ec2 describe-security-groups --region ap-northeast-1 \
  --filters "Name=vpc-id,Values=$TOKYO_VPC" "Name=group-name,Values=*rds*" \
  --query "SecurityGroups[].{Name:GroupName, SgId:GroupId, IngressRules:IpPermissions[?FromPort==\`3306\`].{Port:FromPort, CIDR:IpRanges[].CidrIp, Desc:IpRanges[].Description}}" --output json

echo ""
echo "São Paulo EC2 SG - should allow outbound 3306 to 10.241.0.0/16 (Tokyo)"
aws ec2 describe-security-groups --region sa-east-1 \
  --filters "Name=vpc-id,Values=$SP_VPC" "Name=group-name,Values=*ec2*" \
  --query "SecurityGroups[].{Name:GroupName, SgId:GroupId, EgressRules:IpPermissionsEgress[?FromPort==\`3306\`].{Port:FromPort, CIDR:IpRanges[].CidrIp, Desc:IpRanges[].Description}}" --output json

echo ""

###############################################################################
# 9. ALB Verification
###############################################################################
echo "9. ALB VERIFICATION"
echo "-------------------"

echo "Tokyo ALB"
aws elbv2 describe-load-balancers --region ap-northeast-1 \
  --query "LoadBalancers[].{Name:LoadBalancerName, DNSName:DNSName, Scheme:Scheme, State:State.Code, Type:Type}" --output table

echo ""
echo "São Paulo ALB (if exists)"
aws elbv2 describe-load-balancers --region sa-east-1 \
  --query "LoadBalancers[].{Name:LoadBalancerName, DNSName:DNSName, Scheme:Scheme, State:State.Code, Type:Type}" --output table

echo ""

###############################################################################
# 10. WAF Verification
###############################################################################
echo "10. WAF VERIFICATION"
echo "--------------------"

echo "Regional WAF (Tokyo ALB)"
aws wafv2 list-web-acls --scope REGIONAL --region ap-northeast-1 \
  --query "WebACLs[].{Name:Name, Id:Id, ARN:ARN}" --output table

echo ""
echo "CloudFront WAF (must be us-east-1)"
aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1 \
  --query "WebACLs[].{Name:Name, Id:Id, ARN:ARN}" --output table

echo ""
echo "Verify WAF is associated to Tokyo ALB"
TOKYO_ALB_ARN=$(aws elbv2 describe-load-balancers --region ap-northeast-1 --query "LoadBalancers[0].LoadBalancerArn" --output text)
if [ ! -z "$TOKYO_ALB_ARN" ]; then
  aws wafv2 get-web-acl-for-resource --resource-arn "$TOKYO_ALB_ARN" --region ap-northeast-1 \
    --query "WebACL.{Name:Name, Id:Id}" --output table
else
  echo "No ALB found in Tokyo region"
fi

echo ""

###############################################################################
# 11. CloudFront Verification
###############################################################################
echo "11. CLOUDFRONT VERIFICATION"
echo "---------------------------"

echo "List CloudFront distributions - check origin points to Tokyo ALB"
aws cloudfront list-distributions \
  --query "DistributionList.Items[].{Id:Id, Domain:DomainName, Aliases:Aliases.Items[0], Origin:Origins.Items[0].DomainName, WAF:WebACLId, Status:Status, Enabled:Enabled}" --output table

echo ""

###############################################################################
# 12. ACM Certificate Verification
###############################################################################
echo "12. ACM CERTIFICATE VERIFICATION"
echo "---------------------------------"

echo "Tokyo regional cert (for ALB)"
aws acm list-certificates --region ap-northeast-1 \
  --query "CertificateSummaryList[].{Domain:DomainName, Status:Status, ARN:CertificateArn}" --output table

echo ""
echo "us-east-1 cert (required for CloudFront)"
aws acm list-certificates --region us-east-1 \
  --query "CertificateSummaryList[].{Domain:DomainName, Status:Status, ARN:CertificateArn}" --output table

echo ""

###############################################################################
# 13. EC2 / ASG Verification
###############################################################################
echo "13. EC2 / ASG VERIFICATION"
echo "--------------------------"

echo "Tokyo ASG instances"
aws autoscaling describe-auto-scaling-groups --region ap-northeast-1 \
  --query "AutoScalingGroups[].{Name:AutoScalingGroupName, Min:MinSize, Max:MaxSize, Desired:DesiredCapacity, Instances:Instances[].InstanceId}" --output table

echo ""
echo "São Paulo ASG instances (stateless compute only)"
aws autoscaling describe-auto-scaling-groups --region sa-east-1 \
  --query "AutoScalingGroups[].{Name:AutoScalingGroupName, Min:MinSize, Max:MaxSize, Desired:DesiredCapacity, Instances:Instances[].InstanceId}" --output table

echo ""

###############################################################################
# 14. SSM Connectivity Test (São Paulo EC2 → Tokyo RDS)
###############################################################################
echo "14. SSM CONNECTIVITY TEST"
echo "-------------------------"

echo "Getting São Paulo instance ID for SSM..."
SP_INSTANCE=$(aws autoscaling describe-auto-scaling-groups --region sa-east-1 \
  --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text 2>/dev/null)

if [ ! -z "$SP_INSTANCE" ] && [ "$SP_INSTANCE" != "None" ]; then
  echo "São Paulo Instance: $SP_INSTANCE"
  
  echo "Getting Tokyo RDS endpoint..."
  TOKYO_RDS=$(aws rds describe-db-instances --region ap-northeast-1 \
    --query "DBInstances[0].Endpoint.Address" --output text 2>/dev/null)
  
  if [ ! -z "$TOKYO_RDS" ] && [ "$TOKYO_RDS" != "None" ]; then
    echo "Tokyo RDS Endpoint: $TOKYO_RDS"
    echo ""
    echo "THE CRITICAL TEST - São Paulo EC2 can reach Tokyo RDS on 3306 via TGW"
    COMMAND_ID=$(aws ssm send-command --region sa-east-1 \
      --instance-ids "$SP_INSTANCE" \
      --document-name "AWS-RunShellScript" \
      --parameters "commands=[\"nc -vz $TOKYO_RDS 3306 2>&1 || echo 'FAIL: Cannot reach Tokyo RDS'\"]" \
      --query "Command.CommandId" --output text)
    
    echo "Command ID: $COMMAND_ID"
    echo "Waiting 10 seconds for command to execute..."
    sleep 10
    
    echo "Command Output:"
    aws ssm get-command-invocation --region sa-east-1 \
      --command-id "$COMMAND_ID" \
      --instance-id "$SP_INSTANCE" \
      --query "StandardOutputContent" --output text
  else
    echo "No RDS instance found in Tokyo"
  fi
else
  echo "No instances found in São Paulo ASG"
fi

echo ""

###############################################################################
# 15. Terraform State Verification
###############################################################################
echo "15. TERRAFORM STATE VERIFICATION"
echo "---------------------------------"

echo "Note: Update the S3 paths below with your actual state file locations"
echo "Checking for lab3a state files..."
echo "aws s3 ls s3://armageddon-prod-2026/path/to/lab3a-tokyo/ --region us-east-1"
echo "aws s3 ls s3://armageddon-prod-2026/path/to/lab3a-saopaulo/ --region us-east-1"

echo ""

###############################################################################
# 16. APPI Compliance Summary Check (No Data Outside Japan)
###############################################################################
echo "16. APPI COMPLIANCE SUMMARY CHECK"
echo "----------------------------------"

echo "Confirm NO RDS in any region except Tokyo"
for region in us-east-1 sa-east-1 eu-west-1; do
  echo "=== $region ==="
  aws rds describe-db-instances --region $region \
    --query "DBInstances[].DBInstanceIdentifier" --output text 2>/dev/null || echo "No RDS instances"
done

echo ""
echo "Confirm NO RDS snapshots outside Tokyo"
for region in us-east-1 sa-east-1; do
  echo "=== Snapshots in $region ==="
  aws rds describe-db-snapshots --region $region \
    --query "DBSnapshots[].DBSnapshotIdentifier" --output text 2>/dev/null || echo "No snapshots"
done

echo ""
echo "Confirm NO RDS read replicas outside Tokyo"
aws rds describe-db-instances --region ap-northeast-1 \
  --query "DBInstances[].{Id:DBInstanceIdentifier, Replicas:ReadReplicaDBInstanceIdentifiers}" --output json

echo ""
echo "========================================="
echo "Verification Complete!"
echo "========================================="
