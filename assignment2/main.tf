
resource "aws_iam_role" "lambda_role" {
  name = "ami-cleanup-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ami_cleanup_policy" {
  name = "ami-cleanup-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeImages",
          "ec2:DeregisterImage",
          "ec2:DescribeSnapshots",
          "ec2:DeleteSnapshot"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ami_cleanup_policy.arn
}

resource "aws_lambda_function" "ami_cleanup" {
  filename         = "ami_cleanup.zip" # zip containing ami_cleanup_lambda.py
  function_name    = "ami-cleanup"
  handler          = "ami_cleanup_lambda.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("ami_cleanup.zip")
  environment {
    variables = {
      DRY_RUN         = "true"
      DELETE_SNAPSHOTS= "false"
      RETAIN          = "2"
      TAG_KEY         = "CreatedBy"
      TAG_VALUE       = "AMILifecycle"
    }
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "ami-cleanup-daily"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "target" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.ami_cleanup.arn
}

resource "aws_lambda_permission" "allow_event" {
  statement_id  = "AllowEventToCallLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ami_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
	
