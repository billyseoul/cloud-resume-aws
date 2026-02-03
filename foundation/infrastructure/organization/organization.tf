resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = data.aws_organizations_organization.main.roots[0].id

  tags = {
    Name        = "Production OU"
    Environment = "Production"
    ManagedBy   = "Terraform"

  }
}

resource "aws_organizations_account" "prod" {
  name      = var.prod_account_name
  email     = data.aws_ssm_parameter.prod_email.value
  parent_id = aws_organizations_organizational_unit.prod.id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name        = "Prod Account"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [role_name]
  }
}

resource "aws_organizations_organizational_unit" "test" {
  name      = "Test"
  parent_id = data.aws_organizations_organization.main.roots[0].id

  tags = {
    Name        = "Test OU"
    Environment = "Test"
    ManagedBy   = "Terraform"

  }
}

resource "aws_organizations_account" "test" {
  name      = var.test_account_name
  email     = data.aws_ssm_parameter.test_email.value
  parent_id = aws_organizations_organizational_unit.test.id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name        = "Test Account"
    Environment = "Test"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [role_name]
  }
}
