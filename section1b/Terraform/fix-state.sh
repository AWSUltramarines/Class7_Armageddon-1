#!/bin/bash

echo "========================================="
echo "Terraform State Fix Script"
echo "========================================="
echo ""
echo "This script will help you fix the state mismatch issue."
echo ""

# Function to check if resource exists in AWS
check_subnet_group() {
    aws rds describe-db-subnet-groups \
      --db-subnet-group-name armageddon-db-mysql-subnet \
      2>/dev/null
    return $?
}

# Function to check if resource exists in Terraform state
check_state() {
    terraform state list | grep -q "aws_db_subnet_group.db_mysql_subnet"
    return $?
}

echo "Checking current state..."
echo ""

if check_subnet_group; then
    echo "✅ Subnet group EXISTS in AWS"
    AWS_EXISTS=true
else
    echo "❌ Subnet group DOES NOT exist in AWS"
    AWS_EXISTS=false
fi

if check_state; then
    echo "✅ Subnet group EXISTS in Terraform state"
    STATE_EXISTS=true
else
    echo "❌ Subnet group DOES NOT exist in Terraform state"
    STATE_EXISTS=false
fi

echo ""
echo "========================================="
echo "Recommended Solution:"
echo "========================================="

if [ "$AWS_EXISTS" = true ] && [ "$STATE_EXISTS" = false ]; then
    echo ""
    echo "SOLUTION: Import the existing resource into Terraform state"
    echo ""
    echo "Run this command:"
    echo "  terraform import aws_db_subnet_group.db_mysql_subnet armageddon-db-mysql-subnet"
    echo ""
    echo "Then run:"
    echo "  terraform apply"
    
elif [ "$AWS_EXISTS" = false ] && [ "$STATE_EXISTS" = false ]; then
    echo ""
    echo "SOLUTION: Clean slate - neither exists, just apply"
    echo ""
    echo "Run this command:"
    echo "  terraform apply"
    
elif [ "$AWS_EXISTS" = false ] && [ "$STATE_EXISTS" = true ]; then
    echo ""
    echo "SOLUTION: Remove from state and recreate"
    echo ""
    echo "Run these commands:"
    echo "  terraform state rm aws_db_subnet_group.db_mysql_subnet"
    echo "  terraform apply"
    
else
    echo ""
    echo "SOLUTION: State is in sync, this shouldn't happen"
    echo ""
    echo "Try running:"
    echo "  terraform refresh"
    echo "  terraform apply"
fi

echo ""
echo "========================================="