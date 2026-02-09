# iam.tf - IAM role and policies for EC2 instance
#
# Lab 1c:
# - SSM Managed Instance Core for Session Manager
# - S3 deps bucket read access (airgap mode)
# - Secrets Manager, Parameter Store, CloudWatch (least privilege)

# IAM policy document for EC2 assume role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2" {
  name               = "${local.name_prefix}-ec2-role"
  description        = "IAM role for EC2 instances with SSM Session Manager and AWS service access"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-role"
  })
}

# -----------------------------------------------------------------------------
# SSM Managed Instance Core Policy (for Session Manager)
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------------------------
# S3 Dependencies Bucket Read Policy (for offline artifact retrieval)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "s3_deps_read" {
  statement {
    sid    = "ListDepsBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.deps.arn]
  }

  statement {
    sid    = "GetDepsObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = ["${aws_s3_bucket.deps.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_deps_read" {
  name        = "${local.name_prefix}-s3-deps-read"
  description = "Allow EC2 to read from dependencies S3 bucket"
  policy      = data.aws_iam_policy_document.s3_deps_read.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-s3-deps-read"
  })
}

resource "aws_iam_role_policy_attachment" "s3_deps_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3_deps_read.arn
}

# -----------------------------------------------------------------------------
# Secrets Manager Access - Least Privilege
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "secrets_access" {
  statement {
    sid    = "GetDBSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [aws_secretsmanager_secret.db_credentials.arn]
  }
}

resource "aws_iam_policy" "secrets_access" {
  name        = "${local.name_prefix}-secrets-access"
  description = "Allow EC2 to read database credentials from Secrets Manager"
  policy      = data.aws_iam_policy_document.secrets_access.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secrets-access"
  })
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# -----------------------------------------------------------------------------
# SSM Parameter Store Access
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ssm_params_access" {
  statement {
    sid    = "GetDBParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      aws_ssm_parameter.db_endpoint.arn,
      aws_ssm_parameter.db_port.arn,
      aws_ssm_parameter.db_name.arn
    ]
  }
}

resource "aws_iam_policy" "ssm_params_access" {
  name        = "${local.name_prefix}-ssm-params-access"
  description = "Allow EC2 to read database parameters from SSM Parameter Store"
  policy      = data.aws_iam_policy_document.ssm_params_access.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ssm-params-access"
  })
}

resource "aws_iam_role_policy_attachment" "ssm_params_access" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ssm_params_access.arn
}

# -----------------------------------------------------------------------------
# CloudWatch Logs Access
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "cloudwatch_logs_access" {
  statement {
    sid    = "WriteLogsToGroup"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "${aws_cloudwatch_log_group.app_logs.arn}",
      "${aws_cloudwatch_log_group.app_logs.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_logs_access" {
  name        = "${local.name_prefix}-cloudwatch-logs-access"
  description = "Allow EC2 to write logs to CloudWatch Logs"
  policy      = data.aws_iam_policy_document.cloudwatch_logs_access.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudwatch-logs-access"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_access" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.cloudwatch_logs_access.arn
}

# -----------------------------------------------------------------------------
# CloudWatch Metrics Access
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "cloudwatch_metrics_access" {
  statement {
    sid    = "PutCustomMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["Lab/RDSApp"]
    }
  }
}

resource "aws_iam_policy" "cloudwatch_metrics_access" {
  name        = "${local.name_prefix}-cloudwatch-metrics-access"
  description = "Allow EC2 to publish custom metrics to CloudWatch"
  policy      = data.aws_iam_policy_document.cloudwatch_metrics_access.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudwatch-metrics-access"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_metrics_access" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.cloudwatch_metrics_access.arn
}

# -----------------------------------------------------------------------------
# CloudWatch Agent Server Policy (for CW agent metrics/logs)
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# -----------------------------------------------------------------------------
# Instance Profile
# -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-profile"
  })
}
