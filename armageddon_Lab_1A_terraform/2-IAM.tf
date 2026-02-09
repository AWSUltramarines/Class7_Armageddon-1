
# 1. Create the Role
resource "aws_iam_role" "flask_role" {
  name = "flask_app_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
 
 "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetHostedZone",
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "arn:aws:route53:::hostedzone/Z011619411G3BJBS8ER7U"
        }
    ]
 
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" } # Change to ecs-tasks.amazonaws.com if using ECS
    }]
  })
}

# Attach the standard SSM policy to your existing role
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.flask_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 2. Create the Policy to allow reading the secret
resource "aws_iam_role_policy" "flask_app_database_access" {
  name = "FlaskSecretAccess"
  role = aws_iam_role.flask_role.name

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

resource "aws_iam_role_policy" "flask_app_secrets" {
  name = "FlaskSecretAccess"
  role = aws_iam_role.flask_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = [aws_secretsmanager_secret.db_cradentials.arn]
      },
      {
        Action   = ["kms:Decrypt"]
        Effect   = "Allow"
        Resource = [aws_kms_key.secrets_key.arn] # If using a CMK
      },
      {
        Action   = ["ssm:GetParameter*", "ssm:GetParametersByPath"]
        Effect   = "Allow"
        Resource = ["arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/myapp/*"]
      }
    ]
  })
}

# 3. Create the Instance Profile (The bridge to EC2)
resource "aws_iam_instance_profile" "flask_profile" {
  name = "flask_app_instance_profile"
  role = aws_iam_role.flask_role.name
}

