# Makefile for Cloud Resume Challenge
.PHONY: fmt test deploy-org deploy-foundation deploy-backend deploy-frontend deploy-all clean

fmt:
	find . -name "*.tf" -type f -exec terraform fmt {} \;

test:
	export AWS_PROFILE=cloudadmin && cd applications/resume-site && pytest tests/ -v

deploy-org:
	cd foundation/deployments/organization && terragrunt apply

deploy-foundation:
	cd foundation/deployments/github-oidc && terragrunt apply

deploy-backend:
	cd applications/resume-site/deployments/backend && terragrunt apply

deploy-frontend:
	cd applications/resume-site/deployments/frontend && terragrunt apply

deploy-all: deploy-org deploy-foundation deploy-backend deploy-frontend

clean:
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
