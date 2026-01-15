resource "aws_iam_role" "compute2secrets_role" {
  name = "${local.name_prefix}-compute2secrets_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "ec2AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Terraform = local.terraform_tag
  }
}

resource "aws_iam_role_policy" "compute2secrets_policy" {
  name = "compute2secrets_policy"
  role = aws_iam_role.compute2secrets_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "ReadSpecificSecret",
        "Effect" : "Allow",
        "Action" : ["secretsmanager:GetSecretValue"],
        "Resource" : "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.secret_name}*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "compute2secrets_profile" {
  name = "${local.name_prefix}_profile"
  role = aws_iam_role.compute2secrets_role.name
}
