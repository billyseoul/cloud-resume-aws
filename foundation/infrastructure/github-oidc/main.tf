resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = {
    Name        = "GitHub Actions OIDC Provider"
    ManagedBy   = "Terraform"
    Description = "Allows GitHub Actions to assume IAM roles"
  }
}
