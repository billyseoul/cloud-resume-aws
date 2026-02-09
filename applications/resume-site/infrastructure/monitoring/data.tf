data "aws_ssm_parameter" "alert_email" {
  name = "/cloud-resume/email"
}
