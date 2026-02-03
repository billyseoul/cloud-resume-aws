# Cloud Resume – AWS Multi-Account Infrastructure
website: https://thefullstacker.com

---

## Repository Structure
```
.
├── foundation/
│   ├── infrastructure/
│   │   ├── organization/        # AWS Organizations + Prod/Test accounts
│   │   └── github-oidc/         # GitHub OIDC for CI/CD
│   └── deployments/
│       ├── organization/
│       └── github-oidc/
├── applications/
│   └── resume-site/
│       ├── infrastructure/
│       │   ├── backend/         # Lambda + API Gateway + DynamoDB
│       │   ├── frontend/        # S3 + CloudFront
│       │   └── dns/             # ACM certificate (optional)
│       ├── deployments/
│       │   ├── backend/
│       │   ├── frontend/
│       │   └── dns/
│       └── tests/               # pytest integration tests
├── scripts/
│   └── update-godaddy-dns.py   # GoDaddy DNS automation
├── root.hcl                    # Root Terragrunt config
├── locals.hcl                  # SSM parameter fetching
└── Makefile                    # Deployment commands
```

---

## Prerequisites

- AWS CLI installed and configured
- AWS Organizations enabled in management account
- Two unique email addresses for Prod/Test AWS accounts
- Terraform + Terragrunt installed
- Python 3.x with pip

---

## Deployment

### Step 1: Bootstrap SSM Parameters
```bash
# Manual AWS CLI
aws ssm put-parameter --name "/org/prod/email" --value "prod@example.com" --type "String"
aws ssm put-parameter --name "/org/test/email" --value "test@example.com" --type "String"

# Create Lambda artifacts bucket and upload function
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://lambda-artifacts-${AWS_ACCOUNT_ID}
cd applications/resume-site/src/lambda
zip function.zip lambda_function.py
aws s3 cp function.zip s3://lambda-artifacts-${AWS_ACCOUNT_ID}/visit-counter/
cd ~/repos/cloud-resume

# Store bucket names in SSM
aws ssm put-parameter --name "/cloud-resume/lambda_artifacts_bucket" --value "lambda-artifacts-${AWS_ACCOUNT_ID}" --type "String"
aws ssm put-parameter --name "/cloud-resume/static_website_bucket" --value "static-website-${AWS_ACCOUNT_ID}" --type "String"
```

### Step 2: Deploy Infrastructure

**Terragrunt will automatically create the state backend (S3 + DynamoDB) on first run.**
```bash
# 1. Deploy AWS Organizations (creates Prod + Test accounts)
make deploy-org

# 2. Deploy GitHub OIDC (for CI/CD)
make deploy-foundation

# 3. Deploy backend
make deploy-backend

# Store API URL in SSM
API_URL=$(cd applications/resume-site/deployments/backend && terragrunt output -raw api_gateway_url)
aws ssm put-parameter --name "/cloud-resume/api_gateway_url" --value "${API_URL}" --type "String" --overwrite

# 4. Deploy frontend
make deploy-frontend

# 5. Run integration tests
make test
```

**Or deploy everything:** `make deploy-all`

---

## DNS Setup (GoDaddy)

Using GoDaddy DNS instead of Route53 to save costs.
```bash
export GODADDY_API_KEY="your_key"
export GODADDY_API_SECRET="your_secret"
export GODADDY_DOMAIN="yourdomain.com"
export CLOUDFRONT_DOMAIN=$(cd applications/resume-site/deployments/frontend && terragrunt output -raw cloudfront_domain_name)

python3 scripts/update-godaddy-dns.py
```

**Get API keys:** https://developer.godaddy.com/keys

---

## Testing
```bash
export AWS_PROFILE=your-profile
pip install -r requirements.txt
pytest applications/resume-site/tests/ -v
```

---

## Makefile Commands
```bash
make fmt              # Format Terraform code
make deploy-org       # Deploy AWS Organizations
make deploy-foundation # Deploy GitHub OIDC
make deploy-backend   # Deploy backend
make deploy-frontend  # Deploy frontend
make deploy-all       # Deploy everything in order
make test             # Run pytest tests
make clean            # Remove cache files
```

---

## Architecture

### Layer 1: AWS Organizations
- Management Account
- Production OU + Account
- Test OU + Account

### Layer 2: Foundation
- GitHub OIDC Identity Provider
- IAM Role for GitHub Actions
- Terraform state management (auto-created by Terragrunt)

### Layer 3: Backend
- Lambda function (Python 3.14)
- API Gateway REST API
- DynamoDB table (visitor counter)
- IAM policies

### Layer 4: Frontend
- S3 bucket (static website)
- CloudFront distribution
- Origin Access Control (OAC)

### Layer 5: DNS (Optional)
- ACM certificate
- GoDaddy CNAME records → CloudFront

---

## Security Features

- **Multi-account isolation** - Prod/Test in separate AWS accounts
- **GitHub OIDC** - No static credentials, 1-hour session tokens
- **Least privilege IAM** - Service-scoped permissions
- **CloudFront OAC** - S3 bucket not publicly accessible
- **SSM Parameter Store** - Encrypted configuration storage

---

## Cost Estimate

**~$1-5/month** (mostly within AWS Free Tier)

---

## Tech Stack

**Infrastructure:** Terraform, Terragrunt, Ansible, Python
**Cloud:** AWS Lambda, API Gateway, DynamoDB, S3, CloudFront, Organizations
**CI/CD:** GitHub Actions, GitHub OIDC
**Testing:** pytest, requests, boto3
**DNS:** GoDaddy API

---

## Author

**Billy Campbell** – Cloud Engineer
Website: [thefullstacker.com](https://thefullstacker.com)
