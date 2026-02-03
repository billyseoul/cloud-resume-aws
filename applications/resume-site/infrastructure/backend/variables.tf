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
