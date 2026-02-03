include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infrastructure/frontend"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("locals.hcl"))
}

inputs = {
  bucket_name         = local.common_vars.locals.static_website_bucket
  domain_name         = local.common_vars.locals.domain_name
  acm_certificate_arn = local.common_vars.locals.acm_certificate_arn
}
