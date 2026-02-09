output "sns_topic_arn" {
  description = "ARN of the CloudWatch alarms SNS topic"
  value       = aws_sns_topic.cloud_watch_alarms.arn
}
