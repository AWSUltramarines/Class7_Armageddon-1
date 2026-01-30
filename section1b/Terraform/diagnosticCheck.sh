#!/bin/bash

echo "========================================="
echo "AWS Resource Diagnostic Check"
echo "========================================="
echo ""

echo "1. Checking DB Subnet Groups..."
echo "-----------------------------------"
aws rds describe-db-subnet-groups \
  --query 'DBSubnetGroups[*].[DBSubnetGroupName,VpcId,SubnetGroupStatus]' \
  --output table

echo ""
echo "2. Checking RDS Instances..."
echo "-----------------------------------"
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,DBSubnetGroup.DBSubnetGroupName]' \
  --output table

echo ""
echo "3. Checking Secrets Manager..."
echo "-----------------------------------"
aws secretsmanager list-secrets \
  --query 'SecretList[*].[Name,DeletionDate]' \
  --output table

echo ""
echo "4. Checking Terraform State..."
echo "-----------------------------------"
if [ -f "terraform.tfstate" ]; then
    echo "Terraform state file exists"
    echo "Resources in state:"
    terraform state list | grep -E "(subnet_group|db_instance|secret)" || echo "No DB-related resources in state"
else
    echo "⚠️  No terraform.tfstate file found!"
fi

echo ""
echo "========================================="
echo "Diagnostic Complete"
echo "========================================="