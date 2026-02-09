variable "existing_lambda_name" {
  type        = string
  description = "Name of the pre-existing Lambda function"
  default     = "visit-counter-function"
}

variable "lambda_s3_bucket" {
  type        = string
  description = "S3 bucket that holds the Lambda deployment package"
}

variable "lambda_s3_key" {
  type        = string
  description = "S3 object key for the Lambda deployment package"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alerts"
}

variable "visitor_threshold" {
  type        = string
  description = "Visitor count threshold for alerts"
  default     = "100"
}

