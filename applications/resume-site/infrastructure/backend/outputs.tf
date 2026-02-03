output "lambda_name" {
  value = var.existing_lambda_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.visitor_counter.name
}

output "api_gateway_url" {
  value       = "${aws_api_gateway_stage.prod.invoke_url}/counter"
  description = "API Gateway endpoint URL for visitor counter"
}
