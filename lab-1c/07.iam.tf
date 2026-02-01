# ###########################################
# Trust Policy for EC2 to Assume Role
###########################################
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "compute2secrets_role" {
  name               = "${local.name_prefix}-compute2secrets-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# ##############################################################################
# Permission Policy for EC2 to Access Secrets Manager and SSM Parameter Store
##############################################################################
data "aws_iam_policy_document" "compute2secrets_access" {
  # Secrets Manager: Scoped to specific ARN
  statement {
    sid       = "GetDBSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${data.aws_region.region.name}:${data.aws_caller_identity.self.account_id}:secret:${var.secret_name}*"]
  }

  # SSM Parameter Store: Scoped to specific Path
  statement {
    sid       = "GetParamAccess"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.self.account_id}:parameter/lab/db/*"]
  }

  # KMS: Decryption (Required if Secrets Manager uses Customer Managed Keys)
  statement {
    sid     = "KMSDecrypt"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    # Ideally scope this to the specific KMS Key ARN
    resources = ["*"]
  }

  # CloudWatch Logs: Allow pushing logs
  statement {
    sid    = "AllowLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}
resource "aws_iam_policy" "compute2secrets_access_policy" {
  name        = "${local.name_prefix}-secrets-access"
  description = "Least privilege access for Private EC2"
  policy      = data.aws_iam_policy_document.compute2secrets_access.json
}

resource "aws_iam_role_policy_attachment" "compute2secrets_secrets_attach" {
  role       = aws_iam_role.compute2secrets_role.name
  policy_arn = aws_iam_policy.compute2secrets_access_policy.arn
}

resource "aws_iam_instance_profile" "compute2secrets_instance_profile" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.compute2secrets_role.name
}

#################### Additional Amazon Permission Attachments #####################
### AWS Systems Manager
### Allows EC2 to communicate with SSM for Session Manager and Patch Manager
resource "aws_iam_role_policy_attachment" "compute2secrets_ssm_attach" {
  role       = aws_iam_role.compute2secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
### AWS CLoud Watch Agent
### Allows EC2 to push metrics and logs to Cloud Watch
resource "aws_iam_role_policy_attachment" "compute2secrets_cw_attach" {
  role       = aws_iam_role.compute2secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}