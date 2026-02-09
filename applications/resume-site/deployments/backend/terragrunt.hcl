include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infrastructure/backend"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("locals.hcl"))
}

dependency "monitoring" {
  config_path = "../monitoring"

  mock_outputs = {
    sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:mock-topic"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan", "destroy"]
}






inputs = {
  existing_lambda_name = "visit-counter-function"
  lambda_s3_bucket     = local.common_vars.locals.lambda_artifacts_bucket
  lambda_s3_key        = "lambda_function.zip"
  sns_topic_arn = dependency.monitoring.outputs.sns_topic_arn
  visitor_threshold = "100"
}
