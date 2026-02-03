include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infrastructure/github-oidc"
}

inputs = {
  github_org      = "billyseoul"
  github_repo     = "cloud-resume-aws"
  allowed_branch  = "main"
}
