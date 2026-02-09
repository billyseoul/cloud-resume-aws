# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function.html

resource "aws_lambda_function" "visitor_function" {
  function_name = "visit-counter-function"
  role          = aws_iam_role.visit_count.arn

  runtime = "python3.14"
  handler = "lambda_function.lambda_handler"

  s3_bucket = var.lambda_s3_bucket
  s3_key    = var.lambda_s3_key

  environment {
  variables = {
    SNS_TOPIC_ARN = var.sns_topic_arn
    VISITOR_THRESHOLD   = var.visitor_threshold
  }
}
}

