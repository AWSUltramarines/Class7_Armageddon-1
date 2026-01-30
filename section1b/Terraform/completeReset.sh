#!/bin/bash

echo "========================================="
echo "Complete Reset & Clean Start"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will delete ALL related resources!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1: Deleting all RDS instances..."
echo "-----------------------------------"
INSTANCES=$(aws rds describe-db-instances \
  --query 'DBInstances[*].DBInstanceIdentifier' \
  --output text)

if [ -n "$INSTANCES" ]; then
    for instance in $INSTANCES; do
        echo "Deleting RDS instance: $instance"
        aws rds delete-db-instance \
          --db-instance-identifier "$instance" \
          --skip-final-snapshot 2>&1 || true
    done
    
    echo ""
    echo "⏳ Waiting for RDS instances to be deleted..."
    for instance in $INSTANCES; do
        echo "   Waiting for $instance..."
        aws rds wait db-instance-deleted \
          --db-instance-identifier "$instance" 2>&1 || true
    done
    echo "✅ All RDS instances deleted"
else
    echo "No RDS instances found"
fi

echo ""
echo "Step 2: Deleting DB subnet groups..."
echo "-----------------------------------"
SUBNET_GROUPS=$(aws rds describe-db-subnet-groups \
  --query 'DBSubnetGroups[*].DBSubnetGroupName' \
  --output text)

if [ -n "$SUBNET_GROUPS" ]; then
    for group in $SUBNET_GROUPS; do
        echo "Deleting subnet group: $group"
        aws rds delete-db-subnet-group \
          --db-subnet-group-name "$group" 2>&1 || true
    done
    echo "✅ All subnet groups deleted"
else
    echo "No subnet groups found"
fi

echo ""
echo "Step 3: Force deleting secrets..."
echo "-----------------------------------"
SECRETS=$(aws secretsmanager list-secrets \
  --query 'SecretList[?contains(Name, `lab/rds`) || contains(Name, `rds!`)].Name' \
  --output text)

if [ -n "$SECRETS" ]; then
    for secret in $SECRETS; do
        echo "Force deleting secret: $secret"
        aws secretsmanager delete-secret \
          --secret-id "$secret" \
          --force-delete-without-recovery 2>&1 || true
    done
    echo "✅ All secrets deleted"
else
    echo "No secrets found"
fi

echo ""
echo "Step 4: Cleaning Terraform state..."
echo "-----------------------------------"
if [ -f "terraform.tfstate" ]; then
    # Remove DB-related resources from state
    terraform state rm aws_db_instance.rds-lab-mysql 2>/dev/null || true
    terraform state rm aws_db_subnet_group.db_mysql_subnet 2>/dev/null || true
    terraform state rm aws_secretsmanager_secret.app_db_secret 2>/dev/null || true
    terraform state rm aws_secretsmanager_secret_version.app_db_secret_version 2>/dev/null || true
    terraform state rm data.aws_secretsmanager_secret.rds_master_secret 2>/dev/null || true
    terraform state rm data.aws_secretsmanager_secret_version.rds_master_secret_version 2>/dev/null || true
    echo "✅ Terraform state cleaned"
else
    echo "No terraform.tfstate file found"
fi

echo ""
echo "========================================="
echo "Reset Complete!"
echo "========================================="
echo ""
echo "Now you can run a fresh deployment:"
echo "  terraform apply"
echo ""