data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Zip the lambda
data "archive_file" "rds_ip_check_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/rds_ip_check.py"
  output_path = "${path.module}/lambda/rds_ip_check.zip"
}

resource "aws_iam_role" "rds_ip_check_lambda_role" {
  name = "lab-rds-ip-check-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "rds_ip_check_lambda_policy" {
  name = "lab-rds-ip-check-lambda-policy"
  role = aws_iam_role.rds_ip_check_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "WriteLogs",
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "*"
      },
      {
        Sid: "ReadWriteSSMParam",
        Effect: "Allow",
        Action: [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ],
        Resource: "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/resolved_ip"
      },
      {
        Sid: "PublishToSNS",
        Effect: "Allow",
        Action: ["sns:Publish"],
        Resource: aws_sns_topic.ops_alerts.arn
      }
    ]
  })
}

resource "aws_lambda_function" "rds_ip_check" {
  function_name = "lab-rds-ip-check"
  role          = aws_iam_role.rds_ip_check_lambda_role.arn
  handler       = "rds_ip_check.handler"
  runtime       = "python3.11"

 filename         = data.archive_file.rds_ip_check_zip.output_path
  source_code_hash = data.archive_file.rds_ip_check_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN   = aws_sns_topic.ops_alerts.arn
      DB_ENDPOINT     = var.db_endpoint
      SSM_PARAM_NAME  = "/lab/db/resolved_ip"
    }
  }
}

# Schedule it
resource "aws_cloudwatch_event_rule" "rds_ip_check_schedule" {
  name                = "lab-rds-ip-check-schedule"
  schedule_expression = "rate(${var.rds_ip_check_rate_minutes} minutes)"
}

resource "aws_cloudwatch_event_target" "rds_ip_check_target" {
  rule      = aws_cloudwatch_event_rule.rds_ip_check_schedule.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.rds_ip_check.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_ip_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_ip_check_schedule.arn
}
 