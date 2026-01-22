# IAM policy document for EC2 assume role. 
# This a "Trust" policy 
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"    # A label for this statement (Statement ID)
    effect  = "Allow"            # We are allowing an action
    actions = ["sts:AssumeRole"] # The action is "Assuming a Role" (putting on the identity)

    principals {
      type        = "Service"             # We are trusting an AWS Service...
      identifiers = ["ec2.amazonaws.com"] # ...specifically the EC2 service.
    }
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2" {
  name        = "ec2-role"
  description = "IAM role for EC2 instances to access Secrets Manager"

  # This links back to block #1. It applies the "Trust Policy" we just wrote.
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "ec2-role"
  }
}

# ================================================================ #

# IAM policy **DOCUMENT** for Secrets Manager access - least privilege
data "aws_iam_policy_document" "secrets_access" {
  statement {
    sid    = "GetDBSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue" # The specific permission to READ a secret
    ]
    # CRITICAL: This restricts access to ONLY the specific DB credential secret.
    # It cannot read other secrets in your account.
    resources = [ "arn:aws:secretsmanager:us-east-1:171158266582:secret:lab/rds/mysql*"]
  }
}




# IAM **POLICY** for Secrets Manager access
resource "aws_iam_policy" "secrets_access" {
  name        = "secrets-access"
  description = "Allow EC2 to read database credentials from Secrets Manager"
  policy      = data.aws_iam_policy_document.secrets_access.json

  tags = {
    Name = "secrets-access"
  }
}

# ================================================================ #

# Attach secrets access policy to EC2 role
resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.ec2.name             # The Role from block #2
  policy_arn = aws_iam_policy.secrets_access.arn # The Policy from block #4
}

# Instance profile to attach role to EC2
resource "aws_iam_instance_profile" "ec2_role_profile" {
  name = "ec2-role-profile"
  role = aws_iam_role.ec2.name # Wraps the role from block #2

  tags = {
    Name = "ec2-profile"
  
  }
}


