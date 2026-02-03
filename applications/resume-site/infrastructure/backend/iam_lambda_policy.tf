# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

resource "aws_iam_role" "visit_count" {
  name_prefix = "visit-counter-function-role-"
  path        = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# DynamoDB permissions for Lambda
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "visitor-counter-dynamodb-access"
  role = aws_iam_role.visit_count.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:UpdateItem"
      ]
      Resource = aws_dynamodb_table.visitor_counter.arn
    }]
  })
}

# CloudWatch Logs permissions for Lambda
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.visit_count.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
