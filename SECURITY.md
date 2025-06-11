# Security Guide - Preventing Secret Commits

## Overview
This document provides guidelines to prevent accidentally committing secrets and sensitive information to the git repository.

## Files to Never Commit
- `.env` files containing actual secrets
- `*.key`, `*.pem`, `*.pfx`, `*.p12` files
- Configuration files with real API keys, passwords, or connection strings
- Azure subscription IDs, tenant IDs, or client secrets
- Database connection strings with credentials

## Safe Practices

### 1. Use Environment Variables
Always use environment variables for sensitive configuration:
```properties
# ✅ GOOD - application.properties
azure.openai.endpoint=${AZURE_OPENAI_ENDPOINT}
azure.openai.api-key=${AZURE_OPENAI_API_KEY}

# ❌ BAD - Never do this
azure.openai.api-key=sk-12345abcd...
```

### 2. Use .env.example Files
- Create `.env.example` with placeholder values
- Keep actual `.env` files in `.gitignore`
- Document required environment variables

### 3. Git Pre-commit Checks
Consider adding a pre-commit hook to scan for secrets:

```bash
# Install pre-commit
pip install pre-commit

# Add to .pre-commit-config.yaml
repos:
- repo: https://github.com/Yelp/detect-secrets
  rev: v1.4.0
  hooks:
  - id: detect-secrets
```

### 4. Azure Secrets Management
- Use Azure Key Vault for production secrets
- Use Azure Managed Identity when possible
- Never hardcode Azure credentials

### 5. GitHub Repository Settings
- Enable secret scanning in repository settings
- Set up dependabot alerts
- Use GitHub Secrets for CI/CD variables

## If You Accidentally Commit Secrets

### 1. Immediate Actions
- Change/revoke the compromised secrets immediately
- Create new secrets in Azure/service provider
- Update local environment with new secrets

### 2. Clean Repository (as done here)
- Remove git history: `Remove-Item -Recurse -Force .git`
- Initialize new repository: `git init`
- Verify .gitignore excludes sensitive files
- Create fresh initial commit

### 3. Alternative: BFG Repo Cleaner
For specific file removal (more complex):
```bash
# Download BFG Repo Cleaner
# Remove specific files from history
java -jar bfg.jar --delete-files .env
git reflog expire --expire=now --all && git gc --prune=now --aggressive
```

## Verification Checklist
- [ ] `.env` is in `.gitignore`
- [ ] No API keys in committed files
- [ ] `.env.example` contains only placeholders
- [ ] Application uses environment variables
- [ ] Azure resources use managed identity when possible
- [ ] GitHub secrets configured for CI/CD

## Current Repository Status
✅ Clean repository created with no secrets
✅ Proper .gitignore configuration
✅ Environment variables properly configured
✅ Managed identity setup for production
✅ Secure CI/CD pipeline configuration

## Resources
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Azure Key Vault Best Practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Detect Secrets Tool](https://github.com/Yelp/detect-secrets)
- [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
