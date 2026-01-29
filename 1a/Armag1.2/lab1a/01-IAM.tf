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
  name        = "labec2role"
  description = "IAM role for EC2 instances to access Secrets Manager"

  # This links back to block #1. It applies the "Trust Policy" we just wrote.
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "labec2role"
  }
}

# ================================================================ #

# IAM ROLE **POLICY** for Secrets Manager access
resource "aws_iam_role_policy" "secrets_access" {
  name        = "readsecretinlinepolicy"
  role        = aws_iam_role.ec2.id
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSpecificSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:us-east-1:568118412737:secret:lab/rds/mysql*"
      }
    ]
  })
}

# ================================================================ #

#  Instance profile to attach role to EC2
resource "aws_iam_instance_profile" "ec2" {
  name = "labec2role"    
  role = aws_iam_role.ec2.name
}