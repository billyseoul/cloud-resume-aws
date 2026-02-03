# Production ou email from SSM paramter store
data "aws_ssm_parameter" "prod_email" {
  name = "/org/prod/email"
}

# Test ou email from SSM paramter store
data "aws_ssm_parameter" "test_email" {
  name = "/org/test/email"
}

# Pull exisiting AWS Organization
data "aws_organizations_organization" "main" {}
