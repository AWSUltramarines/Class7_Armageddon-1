data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-secrets-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "secrets_access_policy" {
  name = "ec2-secrets-manager-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSpecificSecret",
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        #   "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:lab/rds/mysql*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-iam-profile"
  role = aws_iam_role.ec2_role.name
}