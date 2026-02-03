##################################################################
# Allows GitHub Actions to read/write Terraform state files in S3
# and manage state locks in DynamoDB
###################################################################
resource "aws_iam_role_policy" "terraform_state" {
  name = "TerraformStateAccess"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateS3"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::terraform-state-*",
          "arn:aws:s3:::terraform-state-*/*"
        ]
      },
      {
        Sid    = "TerraformStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/terraform-locks-*"
      }
    ]
  })
}

##############################################################################
# Allows GitHub Actions to read configuration values from SSM Parameter Store
##############################################################################
resource "aws_iam_role_policy" "ssm_parameters" {
  name = "SSMParameterAccess"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/cloud-resume/*",
          "arn:aws:ssm:*:*:parameter/org/*"
        ]
      }
    ]
  })
}

###################################################################
# Allows GitHub Actions to deploy and manage my AWS infrastructure
###################################################################
resource "aws_iam_role_policy" "infrastructure_management" {
  name = "InfrastructureManagement"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaManagement"
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:ListFunctions",
          "lambda:ListVersionsByFunction",
          "lambda:GetFunctionCodeSigningConfig"
        ]
        Resource = "*"
      },
      {
        Sid    = "APIGatewayManagement"
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "apigateway:POST",
          "apigateway:PUT",
          "apigateway:PATCH",
          "apigateway:DELETE"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Management"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy"
        ]
        Resource = [
          "arn:aws:s3:::static-website-*",
          "arn:aws:s3:::static-website-*/*",
          "arn:aws:s3:::lambda-artifacts-*",
          "arn:aws:s3:::lambda-artifacts-*/*"
        ]
      },
      {
        Sid    = "CloudFrontManagement"
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:UpdateDistribution",
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListDistributions"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBManagement"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMReadOnly"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      },
      {
        Sid      = "IAMPassRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::*:role/visit-counter-function-role-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      }
    ]
  })
}


###################################################################
# Allows GitHub Actions to read AWS Organizations information
###################################################################
resource "aws_iam_role_policy" "organizations_read" {
  name = "OrganizationsRead"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OrganizationsRead"
        Effect = "Allow"
        Action = [
          "organizations:DescribeOrganization",
          "organizations:ListAccounts",
          "organizations:ListOrganizationalUnitsForParent",
          "organizations:ListRoots",
          "organizations:ListAWSServiceAccessForOrganization"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "organizations_management" {
  name = "OrganizationsManagement"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "OrganizationsRead"
        Effect = "Allow"
        Action = [
          "organizations:DescribeOrganization",
          "organizations:ListAccounts",
          "organizations:ListOrganizationalUnitsForParent",
          "organizations:ListRoots"
        ]
        Resource = "*"
      }
    ]
  })
}

#############################################################################
# IAM role that GitHub Actions assumes via OIDC
# Trust policy restricts access to only the specified GitHub repo and branch
#############################################################################
resource "aws_iam_role" "github_actions" {
  name                 = "GitHubActionsRole-${var.github_repo}"
  description          = "Role for GitHub Actions to deploy cloud-resume-aws"
  max_session_duration = 3600 # 1 hour minimum

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "GitHub Actions Role"
    ManagedBy = "Terraform"
    Project   = "cloud-resume"
  }
}