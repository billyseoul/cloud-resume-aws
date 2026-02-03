locals {
  account_id = run_cmd(
    "--terragrunt-quiet",
    "aws", "ssm", "get-parameter",
    "--name", "/cloud-resume/account_id",
    "--query", "Parameter.Value",
    "--output", "text"
  )

  region = run_cmd(
    "--terragrunt-quiet",
    "aws", "ssm", "get-parameter",
    "--name", "/cloud-resume/region",
    "--query", "Parameter.Value",
    "--output", "text"
  )

  terraform_state_bucket = run_cmd(
    "--terragrunt-quiet",
    "aws", "ssm", "get-parameter",
    "--name", "/cloud-resume/terraform_state_bucket",
    "--query", "Parameter.Value",
    "--output", "text"
  )

  lambda_artifacts_bucket = run_cmd(
    "--terragrunt-quiet",
    "aws", "ssm", "get-parameter",
    "--name", "/cloud-resume/lambda_artifacts_bucket",
    "--query", "Parameter.Value",
    "--output", "text"
  )

  static_website_bucket = run_cmd(
    "--terragrunt-quiet",
    "aws", "ssm", "get-parameter",
    "--name", "/cloud-resume/static_website_bucket",
    "--query", "Parameter.Value",
    "--output", "text"
  )

  domain_name = run_cmd(
    "--terragrunt-quiet",
    "aws", "ssm", "get-parameter",
    "--name", "/cloud-resume/domain_name",
    "--query", "Parameter.Value",
    "--output", "text"
  )

  acm_certificate_arn = run_cmd(
    "--terragrunt-quiet",
    "aws", "ssm", "get-parameter",
    "--name", "/cloud-resume/acm_certificate_arn",
    "--query", "Parameter.Value",
    "--output", "text"
  )
}
