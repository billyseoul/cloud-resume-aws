##############
# S3 Creation
##############

resource "aws_s3_bucket" "static_website" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
