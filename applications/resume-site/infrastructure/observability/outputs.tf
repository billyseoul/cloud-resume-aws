output "grafana_access_key_id" {
  description = "Access key ID for Grafana"
  value       = aws_iam_access_key.grafana.id
}

output "grafana_secret_access_key" {
  description = "Secret access key for Grafana"
  value       = aws_iam_access_key.grafana.secret
  sensitive   = true
}

output "iam_user_arn" {
  description = "ARN of the Grafana IAM user"
  value       = aws_iam_user.grafana.arn
}
