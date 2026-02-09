#############################
### Data Sources
#############################
data "aws_caller_identity" "self" {}

data "aws_region" "region" {}
########################################
# Data Source for Trust Policy
########################################
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
# attach policy to role
resource "aws_iam_role" "compute2secrets_role" {
  name               = "${var.name_prefix}-compute2secrets-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
################################################################
# Data Source for DBSecret, ParamAccess, KMS, & Logging Policy
################################################################
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
####################### Create Policy from Data Source
resource "aws_iam_policy" "compute2secrets_access_policy" {
  name        = "${var.name_prefix}-secrets-access"
  description = "Least privilege access for Private EC2"
  policy      = data.aws_iam_policy_document.compute2secrets_access.json
}
####################### Attach Policy to Role
resource "aws_iam_role_policy_attachment" "compute2secrets_secrets_attach" {
  role       = aws_iam_role.compute2secrets_role.name
  policy_arn = aws_iam_policy.compute2secrets_access_policy.arn
}
####################### Attach Role to Profile
resource "aws_iam_instance_profile" "compute2secrets_instance_profile" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.compute2secrets_role.name
}
####################### Additional Attachments to Role
resource "aws_iam_role_policy_attachment" "compute2secrets_ssm_attach" {
  role       = aws_iam_role.compute2secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "compute2secrets_cw_attach" {
  role       = aws_iam_role.compute2secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}