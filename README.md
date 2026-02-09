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
│       │   ├── dns/             # ACM certificate + Route53
│       │   ├── monitoring/      # SNS topics for alerts
│       │   └── observability/   # Grafana IAM setup
│       ├── deployments/
│       │   ├── backend/
│       │   ├── frontend/
│       │   ├── dns/
│       │   ├── monitoring/
│       │   └── observability/
│       ├── src/
│       │   ├── frontend/        # HTML/CSS/JS files
│       │   └── lambda/          # Lambda function code
│       │       └── visitor_counter/
│       └── tests/               # pytest integration tests
├── scripts/
│   └── update_godaddy_dns.py    # GoDaddy DNS automation
├── .github/
│   └── workflows/
│       ├── foundation.yml       # Deploy foundation infrastructure
│       ├── infrastructure.yml   # Deploy application infrastructure
│       ├── frontend.yml         # Deploy frontend assets
│       └── lambda.yml           # Deploy Lambda functions
├── root.hcl                     # Root Terragrunt config
├── locals.hcl                   # SSM parameter fetching
├── Makefile                     # Deployment commands
├── requirements.txt             # Python dependencies
└── mise.toml                    # Development environment config
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

# Monitoring alert email
aws ssm put-parameter --name "/cloud-resume/email" --value "alerts@example.com" --type "String"

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

# 3. Deploy monitoring (SNS topic for alerts)
make deploy-monitoring

# 4. Deploy backend
make deploy-backend

# Store API URL in SSM
API_URL=$(cd applications/resume-site/deployments/backend && terragrunt output -raw api_gateway_url)
aws ssm put-parameter --name "/cloud-resume/api_gateway_url" --value "${API_URL}" --type "String" --overwrite

# 5. Deploy frontend
make deploy-frontend

# 6. Deploy observability (Grafana IAM user)
make deploy-observability

# 7. Run integration tests
make test
```

**Or deploy everything:** `make deploy-all`

---

## Monitoring & Observability Setup

### SNS Email Alerts
The monitoring module creates an SNS topic that sends email notifications when CloudWatch alarms are triggered (e.g., high Lambda error rates or API Gateway 5xx errors).

**Confirm email subscription:**
After deploying monitoring, check your email for an AWS SNS confirmation message and click the confirmation link.

### Grafana Cloud Integration
The observability module creates an IAM user with CloudWatch read-only access for Grafana Cloud integration.

**Setup Grafana:**
```bash
# Get Grafana credentials
cd applications/resume-site/deployments/observability
export GRAFANA_ACCESS_KEY=$(terragrunt output -raw grafana_access_key_id)
export GRAFANA_SECRET_KEY=$(terragrunt output -raw grafana_secret_access_key)

# Add to Grafana Cloud:
# 1. Log into Grafana Cloud
# 2. Add AWS CloudWatch data source
# 3. Use the credentials above
# 4. Set default region to us-east-1
```

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
make fmt                  # Format Terraform code
make deploy-org           # Deploy AWS Organizations
make deploy-foundation    # Deploy GitHub OIDC
make deploy-monitoring    # Deploy SNS monitoring
make deploy-backend       # Deploy backend
make deploy-frontend      # Deploy frontend
make deploy-observability # Deploy Grafana IAM
make deploy-all           # Deploy everything in order
make test                 # Run pytest tests
make clean                # Remove cache files
```

---

## Architecture

### Layer 1: AWS Organizations
- **Management Account** - Root account with billing and organizational controls
- **Production OU + Account** - Isolated production environment
- **Test OU + Account** - Isolated testing/development environment

### Layer 2: Foundation Infrastructure
- **GitHub OIDC Identity Provider** - Passwordless authentication for GitHub Actions
- **IAM Role for GitHub Actions** - Scoped permissions for CI/CD deployments
- **Terraform State Management** - S3 backend with DynamoDB locking (auto-created by Terragrunt)

### Layer 3: Application Backend
- **Lambda Function** - Python 3.14 runtime for visitor counter logic
- **API Gateway REST API** - HTTP endpoint for frontend integration
- **DynamoDB Table** - Persistent visitor counter storage with on-demand billing
- **IAM Policies** - Least-privilege access for Lambda execution

### Layer 4: Application Frontend
- **S3 Bucket** - Static website hosting (private bucket)
- **CloudFront Distribution** - Global CDN with HTTPS, caching, and compression
- **Origin Access Control (OAC)** - Secure S3 access (replaces legacy OAI)

### Layer 5: DNS & TLS
- **ACM Certificate** - Free SSL/TLS certificate with DNS validation
- **GoDaddy DNS** - CNAME records pointing to CloudFront distribution
- **Custom Domain Support** - Optional domain configuration via variables

### Layer 6: Monitoring & Observability
- **SNS Topic** - Email notifications for CloudWatch alarms
- **CloudWatch Alarms** - Monitor Lambda errors, API Gateway latency, DynamoDB throttles
- **Grafana Cloud** - IAM user with read-only CloudWatch access for metrics dashboards
- **Lambda Integration** - Visitor counter function sends SNS alerts when threshold exceeded

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Organizations                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Management  │  │ Production   │  │     Test     │         │
│  │   Account    │  │   Account    │  │   Account    │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Foundation Layer                              │
│  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │  GitHub OIDC Provider│  │  Terraform State     │            │
│  │  + IAM Roles         │  │  S3 + DynamoDB       │            │
│  └──────────────────────┘  └──────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
┌───────────────────────────┐     ┌───────────────────────────┐
│   Backend (API Layer)     │     │   Frontend (Static Site)  │
│                           │     │                           │
│  ┌─────────────────────┐ │     │  ┌─────────────────────┐  │
│  │  API Gateway        │ │     │  │  S3 Bucket          │  │
│  │  (REST API)         │ │     │  │  (Private)          │  │
│  └──────────┬──────────┘ │     │  └──────────┬──────────┘  │
│             │             │     │             │             │
│  ┌──────────▼──────────┐ │     │  ┌──────────▼──────────┐  │
│  │  Lambda Function    │ │     │  │  CloudFront         │  │
│  │  (Python 3.14)      │─┼─────┼─▶│  (Global CDN + OAC) │  │
│  └──────────┬──────────┘ │     │  └──────────┬──────────┘  │
│             │             │     │             │             │
│  ┌──────────▼──────────┐ │     │  ┌──────────▼──────────┐  │
│  │  DynamoDB Table     │ │     │  │  ACM Certificate    │  │
│  │  (Visitor Counter)  │ │     │  │  (SSL/TLS)          │  │
│  └─────────────────────┘ │     │  └─────────────────────┘  │
└───────────────────────────┘     └───────────────────────────┘
            │                                   │
            └─────────────────┬─────────────────┘
                              ▼
                    ┌─────────────────────┐
                    │  GoDaddy DNS        │
                    │  (CNAME → CF)       │
                    └─────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  End User Browser   │
                    └─────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Monitoring & Observability                         │
│  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │  CloudWatch Metrics  │  │  SNS Email Alerts    │            │
│  │  + Alarms            │─▶│  (Threshold-based)   │            │
│  └──────────────────────┘  └──────────────────────┘            │
│  ┌──────────────────────┐                                      │
│  │  Grafana Cloud       │                                      │
│  │  (Metrics Dashboard) │◀─── IAM User (Read-Only)            │
│  └──────────────────────┘                                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Features

- **Multi-account isolation** - Prod/Test in separate AWS accounts
- **GitHub OIDC** - No static credentials, 1-hour session tokens
- **Least privilege IAM** - Service-scoped permissions
- **CloudFront OAC** - S3 bucket not publicly accessible
- **SSM Parameter Store** - Encrypted configuration storage
- **Private S3 Bucket** - No public access; CloudFront OAC enforces origin restrictions
- **HTTPS Enforcement** - CloudFront redirects HTTP to HTTPS
- **DynamoDB Encryption** - Server-side encryption at rest (AWS managed keys)
- **Grafana Read-Only Access** - IAM user limited to CloudWatch metrics only

---

## Cost Estimate

**~$1-5/month** (mostly within AWS Free Tier)
- AWS Organizations: Free
- CloudWatch metrics & alarms: ~$0.10/alarm (first 10 free)
- SNS notifications: $0.50/month (first 1000 free)
- Grafana Cloud: Free tier available
- Lambda/API Gateway/DynamoDB/S3/CloudFront: Free tier eligible

---

## Tech Stack

**Infrastructure:** Terraform, Terragrunt, Python
**Cloud:** AWS Lambda, API Gateway, DynamoDB, S3, CloudFront, Organizations, SNS, CloudWatch
**CI/CD:** GitHub Actions, GitHub OIDC
**Testing:** pytest, requests, boto3
**DNS:** GoDaddy API
**Monitoring:** AWS CloudWatch, Grafana Cloud

---

## Author

**Billy Campbell** – Cloud Engineer  
Website: [thefullstacker.com](https://thefullstacker.com)
