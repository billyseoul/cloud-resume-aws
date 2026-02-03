# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api

resource "aws_api_gateway_rest_api" "visitor_counter_api" {
  name        = "visitor-counter-api"
  description = "API for visitor counter"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway Resource
resource "aws_api_gateway_resource" "count" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_counter_api.root_resource_id
  path_part   = "counter"
}

# GET Method
resource "aws_api_gateway_method" "get_count" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id   = aws_api_gateway_resource.count.id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id             = aws_api_gateway_resource.count.id
  http_method             = aws_api_gateway_method.get_count.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visitor_function.invoke_arn
  content_handling        = "CONVERT_TO_TEXT"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  # No statement_id = Terraform will generate the random UUID automatically
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_counter_api.execution_arn}/*/GET/counter"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "prod" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter_api.id
  stage_name    = "prod"
}

# CORS Configuration for OPTIONS method
resource "aws_api_gateway_method" "options_count" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id   = aws_api_gateway_resource.count.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.count.id
  http_method = aws_api_gateway_method.options_count.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.count.id
  http_method = aws_api_gateway_method.options_count.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.count.id
  http_method = aws_api_gateway_method.options_count.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Method Response for GET (CORS headers)
resource "aws_api_gateway_method_response" "get_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.count.id
  http_method = aws_api_gateway_method.get_count.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}
