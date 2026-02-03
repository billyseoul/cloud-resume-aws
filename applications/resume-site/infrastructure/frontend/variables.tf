variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "domain_name" {
  description = "My primary domain name"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for my custom domain"
  type        = string
  default     = ""
}
