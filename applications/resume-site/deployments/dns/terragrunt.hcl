include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infrastructure/dns"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("locals.hcl"))
}

inputs = {
  domain_name = local.common_vars.locals.domain_name
}
