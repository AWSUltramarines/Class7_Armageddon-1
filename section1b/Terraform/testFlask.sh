#!/bin/bash

# Get EC2 public IP from Terraform
echo "Getting EC2 public IP..."
EC2_IP=$(terraform output -raw web_public_ip 2>/dev/null)

if [ -z "$EC2_IP" ]; then
    echo "⚠️  Could not get IP from Terraform output"
    echo "Please enter your EC2 public IP:"
    read EC2_IP
fi

echo "Using EC2 IP: $EC2_IP"
echo ""

BASE_URL="http://$EC2_IP"

echo "========================================="
echo "Flask App Testing Script"
echo "========================================="
echo ""

# Test 1: Home page
echo "Test 1: Home Page"
echo "-----------------------------------"
echo "URL: $BASE_URL/"
curl -s "$BASE_URL/" && echo ""
echo ""

# Test 2: Initialize database
echo "Test 2: Initialize Database"
echo "-----------------------------------"
echo "URL: $BASE_URL/init"
curl -s "$BASE_URL/init" && echo ""
echo ""

# Test 3: Add first note
echo "Test 3: Add First Note"
echo "-----------------------------------"
echo "URL: $BASE_URL/add?note=First test note from script"
curl -s "$BASE_URL/add?note=First%20test%20note%20from%20script" && echo ""
echo ""

# Test 4: Add second note
echo "Test 4: Add Second Note"
echo "-----------------------------------"
echo "URL: $BASE_URL/add?note=Second test note"
curl -s "$BASE_URL/add?note=Second%20test%20note" && echo ""
echo ""

# Test 5: List all notes
echo "Test 5: List All Notes"
echo "-----------------------------------"
echo "URL: $BASE_URL/list"
curl -s "$BASE_URL/list" && echo ""
echo ""

echo "========================================="
echo "Testing Complete!"
echo "========================================="
echo ""
echo "You can also test in your browser:"
echo "  Home:     $BASE_URL/"
echo "  Init:     $BASE_URL/init"
echo "  Add Note: $BASE_URL/add?note=Your%20note%20here"
echo "  List:     $BASE_URL/list"