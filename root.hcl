locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("locals.hcl"))

  # Extract for easy reference
  account_id             = local.common_vars.locals.account_id
  region                 = local.common_vars.locals.region
  terraform_state_bucket = local.common_vars.locals.terraform_state_bucket
}

# Remote state configuration
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = local.terraform_state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-locks-${local.account_id}"
  }
}

# Provider generation
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<PROVIDER
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "${local.region}"
}
PROVIDER
}
