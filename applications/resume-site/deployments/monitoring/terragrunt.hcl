# /Users/billycampbell/repos/cloud-resume/applications/resume-site/deployments/monitoring/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infrastructure/monitoring"
}

