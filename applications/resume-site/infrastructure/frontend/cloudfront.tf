# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution

# Origin Access Control - allows CloudFront to access private S3
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "resume-s3-oac"
  description                       = "OAC for static resume website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for resume website"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Conditional aliases (only if domain_name is provided)
  aliases = var.domain_name != "" ? [var.domain_name, "www.${var.domain_name}"] : []

  origin {
    domain_name              = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.static_website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.static_website.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations = [
        "US",
        "CA",
        "GB",
        "JP",
        "KR",
      ]
    }
  }

  # Conditional certificate (custom cert if provided, otherwise CloudFront default)
  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_arn != "" ? [1] : []
    content {
      acm_certificate_arn      = var.acm_certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.3_2025"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_arn == "" ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = {
    Name        = "Resume Website Distribution"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket Policy
data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.static_website.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.static_website.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}
