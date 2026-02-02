
# 1. Create the Role
resource "aws_iam_role" "flask_role" {
  name = "flask_app_secrets_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" } # Change to ecs-tasks.amazonaws.com if using ECS
    }]
  })
}

# 2. Create the Policy to allow reading the secret
resource "aws_iam_role_policy" "password_policy" {
  name = "password_policy"
  role = aws_iam_role.flask_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSpecificSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:lab/rds/mysql*"
      },
   # SSM Parameter Store IAM Permissions   
      
      {
        Sid      = "ReadSSMParameters"
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
      }
    ]
  })
}

# 3. Create the Instance Profile (The bridge to EC2)
resource "aws_iam_instance_profile" "flask_profile" {
  name = "flask_app_instance_profile"
  role = aws_iam_role.flask_role.name
}
