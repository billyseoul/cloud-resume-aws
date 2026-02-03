output "organization_id" {
  description = "The ID of the organization"
  value       = data.aws_organizations_organization.main.id
}

output "prod_ou_id" {
  description = "The ID of the PROD organizational unit"
  value       = aws_organizations_organizational_unit.prod.id
}

output "test_ou_id" {
  description = "The ID of the TEST organizational unit"
  value       = aws_organizations_organizational_unit.test.id
}

output "prod_account_id" {
  description = "The ID of the production account"
  value       = aws_organizations_account.prod.id
}

output "test_account_id" {
  description = "The ID of the test account"
  value       = aws_organizations_account.test.id
}
