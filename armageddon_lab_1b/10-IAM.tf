data "aws_caller_identity" "current" {}

# Assume role policy - allows EC2 service to assume this role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# EC2 permissions policy - Secrets Manager, SSM, CloudWatch Logs
data "aws_iam_policy_document" "ec2_permissions" {
  statement {
    sid     = "ReadSpecificSecret"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:lab/rds/mysql*"
    ]
  }

  statement {
    sid    = "ReadSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/lab/rds/mysql",
      "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/lab/rds/mysql/*"
    ]
  }

  statement {
    sid    = "WriteCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:FilterLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DescribeCloudWatchAlarms"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DescribeRDSInstances"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances"
    ]
    resources = ["*"]
  }
}

# IAM Role
resource "aws_iam_role" "ec2_role" {
  name               = "ec2-secrets-access-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Attach permissions policy to role
resource "aws_iam_role_policy" "secrets_access_policy" {
  name   = "ec2-secrets-manager-policy"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.ec2_permissions.json
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-iam-profile"
  role = aws_iam_role.ec2_role.name
}
