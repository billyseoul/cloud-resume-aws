include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../infrastructure/organization"
}

inputs = {
  prod_account_name = "Production"
  test_account_name = "Test"
}
