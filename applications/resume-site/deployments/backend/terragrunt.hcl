include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infrastructure/backend"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("locals.hcl"))
}


inputs = {
  existing_lambda_name = "visit-counter-function"
  lambda_s3_bucket     = local.common_vars.locals.lambda_artifacts_bucket
  lambda_s3_key        = "lambda_function.zip"
}
