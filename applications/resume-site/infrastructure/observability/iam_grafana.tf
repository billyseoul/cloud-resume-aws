resource "aws_iam_user" "grafana" {
  name = "grafana-cloudwatch-reader"

  tags = {
    Name        = "Grafana CloudWatch Reader"
    Purpose     = "Read-only access for Grafana Cloud"
    ManagedBy   = "Terraform"
  }
}

# Attach CloudWatch read-only policy
resource "aws_iam_user_policy_attachment" "grafana_cloudwatch" {
  user       = aws_iam_user.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# Create access keys for Grafana
resource "aws_iam_access_key" "grafana" {
  user = aws_iam_user.grafana.name
}
