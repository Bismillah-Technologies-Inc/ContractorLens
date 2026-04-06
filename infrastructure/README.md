# ContractorLens Infrastructure

This directory contains Terraform infrastructure-as-code for deploying ContractorLens on AWS.

## Overview

The infrastructure supports:
- **VPC Networking**: Multi-AZ VPC with public/private subnets, NAT Gateway, Internet Gateway
- **RDS PostgreSQL**: Managed database with automated backups and encryption
- **ECS Fargate**: Containerized backend API with auto-scaling
- **Application Load Balancer**: HTTP/HTTPS traffic routing with health checks
- **Security Groups**: Network security for ALB, ECS, and RDS
- **Parameter Store**: Secure secret management for credentials and API keys
- **CloudWatch Logging**: Centralized logging and monitoring

## Prerequisites

### 1. AWS Account Setup
- AWS Account with appropriate permissions
- IAM user with programmatic access (Access Key ID and Secret Access Key)
- AWS CLI installed and configured

### 2. Required Tools
- **Terraform 1.5+** ([Download](https://developer.hashicorp.com/terraform/downloads))
- **AWS CLI 2.0+** ([Download](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **Git** (for version control)
- **jq** (optional, for JSON parsing)

### 3. Environment Setup

```bash
# Configure AWS CLI
aws configure

# Verify AWS credentials
aws sts get-caller-identity
```

## Directory Structure

```
infrastructure/
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Input variables and defaults
│   ├── outputs.tf          # Output values for integration
│   ├── environments/
│   │   ├── dev/
│   │   │   └── terraform.tfvars    # Development configuration
│   │   └── prod/
│   │       └── terraform.tfvars    # Production configuration
│   └── .gitignore          # Terraform-specific ignores
└── README.md               # This file
```

## Environments

### Development (`dev/terraform.tfvars`)
- Lower-cost resources (t3.micro RDS, smaller ECS tasks)
- Single-AZ deployment
- Shorter backup retention (7 days)
- No deletion protection

### Production (`prod/terraform.tfvars`)
- Production-grade resources (r6g.large RDS, larger ECS tasks)
- Multi-AZ deployment for high availability
- Longer backup retention (30 days)
- Deletion protection enabled
- Enhanced monitoring and logging

## Deployment Instructions

### Step 1: Initialize Terraform

```bash
cd infrastructure/terraform

# Initialize Terraform and download providers
terraform init

# Verify configuration
terraform validate
```

### Step 2: Plan Deployment

```bash
# For development environment
terraform plan -var-file="environments/dev/terraform.tfvars"

# For production environment  
terraform plan -var-file="environments/prod/terraform.tfvars"
```

### Step 3: Apply Configuration

```bash
# Apply development configuration
terraform apply -var-file="environments/dev/terraform.tfvars"

# Apply production configuration
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### Step 4: Review Outputs

After successful deployment, Terraform will display outputs including:
- Load Balancer DNS name
- Database endpoint
- ECS cluster information
- Security group IDs
- IAM role ARNs

Save these outputs for integration with other systems.

## Configuration Management

### Required Variables

Some variables must be provided either via:
1. `.tfvars` files (recommended for sensitive values)
2. Environment variables prefixed with `TF_VAR_`
3. Interactive prompts during `terraform apply`

**Critical variables to set:**
```bash
# Database credentials (use AWS Secrets Manager for production)
export TF_VAR_db_password="your_secure_password"
export TF_VAR_firebase_project_id="your_firebase_project"
export TF_VAR_firebase_private_key="your_firebase_key"
export TF_VAR_firebase_client_email="your_firebase_email"
export TF_VAR_gemini_api_key="your_gemini_api_key"

# ECR repository URL
export TF_VAR_ecr_repository_url="123456789012.dkr.ecr.us-west-2.amazonaws.com/contractorlens-backend"
```

### Environment-Specific Configuration

Modify the `.tfvars` files in the `environments/` directory to adjust:
- Resource sizes
- Scaling parameters
- Backup settings
- Security configurations

## State Management

### Remote State Storage

For production deployments, configure remote state with S3 backend and DynamoDB locking:

```hcl
# In main.tf, uncomment the backend configuration:
terraform {
  backend "s3" {
    bucket = "contractorlens-terraform-state"
    key    = "production/terraform.tfstate"
    region = "us-west-2"
    
    # Optional: Enable state locking with DynamoDB
    dynamodb_table = "contractorlens-terraform-locks"
    encrypt        = true
  }
}
```

### State Commands

```bash
# View current state
terraform state list
terraform show

# Move resources (if needed)
# terraform state mv module.vpc.aws_vpc.main aws_vpc.main

# Remove resources from state
# terraform state rm aws_instance.example
```

## Resource Cleanup

### Destroy Infrastructure

```bash
# Destroy development environment
terraform destroy -var-file="environments/dev/terraform.tfvars"

# Destroy production environment  
terraform destroy -var-file="environments/prod/terraform.tfvars"
```

⚠️ **Warning**: The `destroy` command will permanently delete all infrastructure resources. Ensure you have backups of critical data (database, S3 objects) before destroying.

### Preservation of Critical Resources

To prevent accidental deletion:
1. **Database**: Set `skip_final_snapshot = false` to create a final RDS snapshot
2. **S3 Buckets**: Enable versioning and bucket policies to protect data
3. **IAM Roles**: Avoid deleting IAM roles that may be used by other services

## Cost Estimation

### Development Environment
- **Estimated Monthly Cost**: ~$150-200/month
- **Main Components**:
  - RDS PostgreSQL (db.t3.micro): ~$15/month
  - ECS Fargate (256 CPU / 512 MB): ~$30/month
  - ALB: ~$20/month
  - NAT Gateway: ~$35/month
  - Data transfer and monitoring: ~$50/month

### Production Environment
- **Estimated Monthly Cost**: ~$400-600/month
- **Main Components**:
  - RDS PostgreSQL (db.r6g.large): ~$250/month
  - ECS Fargate (512 CPU / 1024 MB, 2-10 tasks): ~$150-250/month
  - ALB: ~$20/month
  - NAT Gateway: ~$35/month
  - Multi-AZ: Additional ~$200/month
  - Backup storage: ~$20/month

### Cost Optimization Tips

1. **Schedule Scaling**: Enable `schedule_scaling` to reduce ECS tasks during off-hours
2. **Reserved Instances**: Consider RDS Reserved Instances for production workloads
3. **Clean Up Development**: Destroy development environments when not in use
4. **Monitor Usage**: Use AWS Cost Explorer to identify optimization opportunities

## Troubleshooting

### Common Issues

1. **"Access Denied" or Permission Errors**
   ```
   Error: AccessDenied: User: arn:aws:iam::123456789012:user/terraform 
   is not authorized to perform: ec2:DescribeVpcs
   ```
   **Solution**: Update IAM policies to include required permissions.

2. **Terraform State Locking Errors**
   ```
   Error: Error acquiring the state lock
   ```
   **Solution**: Check DynamoDB table or manually remove lock if safe:
   ```bash
   terraform force-unlock <LOCK_ID>
   ```

3. **Resource Creation Timeouts**
   ```
   Error: timeout while waiting for state to become 'available'
   ```
   **Solution**: Increase timeout values in resource configurations.

4. **Database Connection Issues**
   **Solution**: Verify:
   - Security group rules allow ECS → RDS connections (port 5432)
   - Database credentials are correct in Parameter Store
   - VPC routing allows private subnet → RDS communication

### Debug Commands

```bash
# Enable verbose logging
export TF_LOG=DEBUG
terraform apply

# Check provider versions
terraform version

# Refresh state
terraform refresh -var-file="environments/dev/terraform.tfvars"
```

## Security Best Practices

### 1. Secrets Management
- **Never commit secrets** to version control (use `.gitignore`)
- Store sensitive values in AWS Parameter Store or Secrets Manager
- Use IAM roles for ECS tasks instead of hardcoded credentials

### 2. Network Security
- Deploy RDS in private subnets
- Restrict security group ingress rules to minimum required ports
- Enable VPC Flow Logs for network traffic monitoring

### 3. IAM Least Privilege
- Create separate IAM roles for Terraform deployment vs application runtime
- Use role-based access control (RBAC) for different environments
- Regularly review and rotate IAM credentials

### 4. Compliance
- Enable RDS encryption at rest
- Use TLS/HTTPS for all external communications
- Enable CloudTrail logging for audit trails
- Regular security scanning of container images

## Maintenance and Updates

### Regular Tasks

1. **Terraform Provider Updates**
   ```bash
   terraform init -upgrade
   terraform plan -var-file="environments/dev/terraform.tfvars"
   ```

2. **Security Updates**
   - Update ECS task definitions with patched container images
   - Apply RDS minor version updates during maintenance windows
   - Rotate secrets and certificates regularly

3. **Cost Review**
   - Monthly review of AWS Cost Explorer
   - Right-size resources based on usage patterns
   - Clean up unused resources

### Backup and Recovery

1. **Database Backups**
   - Automated RDS snapshots (configurable retention)
   - Manual snapshots before major changes
   - Test restoration procedures quarterly

2. **State Backup**
   - Enable S3 versioning on Terraform state bucket
   - Regular state exports for disaster recovery:
     ```bash
     terraform state pull > terraform-state-backup.json
     ```

3. **Infrastructure Recovery**
   - Document dependencies between resources
   - Test full environment recreation procedures
   - Maintain runbooks for common recovery scenarios

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Terraform Deploy
on:
  push:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
          
      - name: Terraform Init
        run: terraform init
        
      - name: Terraform Validate
        run: terraform validate
        
      - name: Terraform Plan
        run: terraform plan -var-file="environments/prod/terraform.tfvars"
        env:
          TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
          TF_VAR_ecr_repository_url: ${{ secrets.ECR_REPOSITORY_URL }}
          
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve -var-file="environments/prod/terraform.tfvars"
        env:
          TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
          TF_VAR_ecr_repository_url: ${{ secrets.ECR_REPOSITORY_URL }}
```

## Related Documentation

- [AWS Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [ContractorLens Project Documentation](../docs/)

## Support and Contact

For infrastructure-related issues:
1. Check troubleshooting section above
2. Review Terraform and AWS documentation
3. Contact DevOps team for production emergencies

**Emergency Contacts:**
- Infrastructure Lead: [Name] - [email/phone]
- DevOps On-Call: [Rotation schedule]

---

*Last Updated: $(date +%Y-%m-%d)*
*Terraform Version: 1.5+*
*AWS Provider Version: 5.0+*