resource "aws_sns_topic" "cloud_watch_alarms" {
  name = "cloud-resume-alarms"

  tags = {
    Name        = "CloudWatch Alarms Topic"
    Environment = "Production"
    ManagedBy   = "Terraform"

  }
}

# Email subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.cloud_watch_alarms.arn
  protocol  = "email"
  endpoint  = data.aws_ssm_parameter.alert_email.value
}
