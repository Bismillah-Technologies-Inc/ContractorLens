# State Migration Guide

This document provides guidance for migrating Terraform state between different backends or environments.

## Overview

Terraform state migration is necessary when:
1. Moving from local to remote state storage
2. Changing state backends (e.g., S3 to Terraform Cloud)
3. Splitting or merging state files
4. Re-organizing project structure

## Prerequisites

- Terraform CLI installed
- Access to both source and destination state locations
- Backup of current state before any migration

## Migration Scenarios

### 1. Migrating from Local to S3 Backend

**Current setup:** Local state file (`terraform.tfstate`)
**Target setup:** S3 backend with DynamoDB locking

**Steps:**

1. **Configure S3 bucket and DynamoDB table:**

```bash
# Create S3 bucket for state storage
aws s3api create-bucket \
  --bucket contractorlens-terraform-state \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket contractorlens-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket contractorlens-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name contractorlens-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

2. **Update Terraform configuration:**

Uncomment and configure the backend block in `versions.tf` or `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "contractorlens-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "contractorlens-terraform-locks"
    encrypt        = true
  }
}
```

3. **Initialize with migration:**

```bash
terraform init -migrate-state

# Verify state migration
terraform state list
terraform show
```

### 2. Migrating from Workspaces to Directory Structure

**Current setup:** Single configuration with workspaces
**Target setup:** Separate directories per environment

**Steps:**

1. **Backup current state:**

```bash
# For each workspace
terraform workspace select dev
terraform state pull > terraform-dev.tfstate.backup

terraform workspace select prod
terraform state pull > terraform-prod.tfstate.backup
```

2. **Re-organize directory structure:**

```
# Before
infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfstate (with workspaces)

# After
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── modules/
    └── [common modules]
```

3. **Migrate state files:**

```bash
# Initialize new directory for dev
cd infrastructure/environments/dev
terraform init

# Import dev state
terraform state push ../terraform-dev.tfstate.backup

# Verify
terraform state list
```

### 3. Splitting a Monolithic State File

**Current setup:** Single state file for all resources
**Target setup:** Separate state files per component (VPC, RDS, ECS)

**Steps:**

1. **Identify resources to move:**

```bash
terraform state list

# Example output:
aws_vpc.main
aws_subnet.public[0]
aws_subnet.public[1]
aws_db_instance.main
aws_ecs_cluster.main
```

2. **Create new Terraform configurations:**

```bash
# Create VPC module
mkdir -p modules/vpc
# Copy relevant resource definitions
```

3. **Move resources using state mv:**

```bash
# Move VPC resources to new state
terraform state mv aws_vpc.main module.vpc.aws_vpc.main
terraform state mv aws_subnet.public[0] module.vpc.aws_subnet.public[0]
terraform state mv aws_subnet.public[1] module.vpc.aws_subnet.public[1]

# Initialize new module
terraform init -reconfigure
```

### 4. Migrating Between AWS Accounts

**Current setup:** Resources in Account A
**Target setup:** Resources in Account B

**Steps:**

1. **Prepare both accounts:**

```bash
# Configure AWS profiles
aws configure --profile account-a
aws configure --profile account-b

# Update provider configuration
provider "aws" {
  alias   = "account_b"
  region  = var.aws_region
  profile = "account-b"
}
```

2. **Import resources into new account:**

```bash
# For each resource
terraform import -var-file="environments/prod/terraform.tfvars" \
  aws_vpc.main vpc-12345678

# This requires creating matching resources in the new configuration first
```

## Best Practices for State Migration

### 1. Always Create Backups

```bash
# Create timestamped backups
BACKUP_TIME=$(date +%Y%m%d%H%M%S)
terraform state pull > terraform-state-backup-${BACKUP_TIME}.json

# Store in secure location
aws s3 cp terraform-state-backup-${BACKUP_TIME}.json \
  s3://backup-bucket/terraform-state/
```

### 2. Use State Verification

```bash
# Validate state integrity
terraform state list
terraform show

# Check for inconsistencies
terraform plan -refresh-only
```

### 3. Test in Non-Production First

1. Create a clone of production state
2. Perform migration on clone
3. Validate results
4. Apply to production

### 4. Document Migration Steps

Create a runbook with:
- Pre-migration checklist
- Step-by-step commands
- Rollback procedures
- Verification steps

## Common Issues and Solutions

### Issue 1: State Locking During Migration

```bash
# Check for existing locks
terraform state list

# If locked and safe to remove
terraform force-unlock <LOCK_ID>
```

### Issue 2: Resource Address Mismatch

```bash
# Get current resource address
terraform state show aws_vpc.main

# Compare with new configuration
# Adjust import/move commands accordingly
```

### Issue 3: Provider Configuration Mismatch

```bash
# Check provider requirements
terraform providers

# Update provider versions if needed
terraform init -upgrade
```

## Rollback Procedures

### If Migration Fails

1. **Stop further changes:**
   ```bash
   # Lock the state if possible
   ```

2. **Restore from backup:**
   ```bash
   terraform state push terraform-state-backup.json
   ```

3. **Re-configure original setup:**
   ```bash
   # Revert backend configuration
   # Re-initialize with original settings
   terraform init -reconfigure
   ```

### If Resources Are Partially Migrated

1. **Identify migrated resources:**
   ```bash
   terraform state list
   ```

2. **Move back to original state:**
   ```bash
   terraform state mv module.new.aws_vpc.main aws_vpc.main
   ```

## Automation Scripts

### Sample Migration Script

```bash
#!/bin/bash
set -e

# Configuration
BACKEND_BUCKET="contractorlens-terraform-state"
ENVIRONMENT="production"
REGION="us-west-2"

echo "Starting Terraform state migration..."

# Step 1: Backup current state
echo "Backing up current state..."
BACKUP_FILE="terraform-state-backup-$(date +%Y%m%d%H%M%S).json"
terraform state pull > ${BACKUP_FILE}

# Step 2: Configure new backend
echo "Configuring S3 backend..."
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "${BACKEND_BUCKET}"
    key            = "${ENVIRONMENT}/terraform.tfstate"
    region         = "${REGION}"
    encrypt        = true
  }
}
EOF

# Step 3: Initialize with migration
echo "Initializing with state migration..."
terraform init -migrate-state

# Step 4: Verify migration
echo "Verifying migration..."
terraform state list

echo "Migration completed successfully!"
echo "Backup saved to: ${BACKUP_FILE}"
```

## Security Considerations

1. **Encrypt state at rest:** Always enable encryption for S3 buckets
2. **Limit access:** Use IAM policies to restrict state access
3. **Audit trails:** Enable CloudTrail for state modification tracking
4. **Regular rotation:** Rotate state bucket credentials regularly

## Post-Migration Validation

After migration, verify:

1. **State integrity:**
   ```bash
   terraform validate
   terraform plan -refresh-only
   ```

2. **Resource accessibility:**
   ```bash
   # Test key resources
   aws ec2 describe-vpcs --vpc-ids $(terraform output -raw vpc_id)
   ```

3. **Application functionality:**
   - Test application connectivity
   - Verify database access
   - Check load balancer health

## Maintenance Tasks

### Regular State Maintenance

1. **State optimization:**
   ```bash
   terraform state list
   # Remove unused resources
   terraform state rm aws_instance.old_instance
   ```

2. **State cleanup:**
   ```bash
   # Compact state file
   terraform state push terraform.tfstate
   ```

3. **Backup verification:**
   ```bash
   # Verify backups are usable
   terraform state push --dry-run backup-file.json
   ```

## References

- [Terraform State Documentation](https://developer.hashicorp.com/terraform/language/state)
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- [AWS S3 State Storage](https://developer.hashicorp.com/terraform/language/settings/backends/s3)

---

*Last Updated: $(date +%Y-%m-%d)*
*Applicable to Terraform 1.5+*