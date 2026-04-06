# ContractorLens Infrastructure

This directory contains Terraform configurations for deploying the ContractorLens application to AWS.

## Directory Structure

```
infrastructure/
├── terraform/
│   ├── main.tf                # Root module configuration
│   ├── variables.tf           # Input variables
│   ├── outputs.tf            # Output values
│   ├── providers.tf          # Provider versions
│   ├── environments/
│   │   ├── dev/
│   │   │   └── terraform.tfvars
│   │   └── prod/
│   │       └── terraform.tfvars
│   └── modules/
│       ├── vpc/              # VPC networking
│       ├── rds/              # PostgreSQL database
│       ├── ecs/              # Application hosting
│       ├── s3/               # Object storage
│       └── cloudfront/       # CDN distribution
└── README.md
```

## Prerequisites

1. **AWS Account**: Configured with appropriate IAM permissions
2. **Terraform**: Version 1.5.0 or higher
3. **AWS CLI**: Configured with credentials
4. **git**: For version control

## Environment Configuration

The infrastructure supports two environments:

- **dev**: Development environment with smaller instance sizes, single AZ, 7-day backups
- **prod**: Production environment with larger instance sizes, multi-AZ, 30-day backups

## Getting Started

### 1. Initialize Terraform

```bash
cd infrastructure/terraform
terraform init
```

### 2. Configure Environment Variables

Copy the example configuration file for your environment:

```bash
# For development
cp terraform.tfvars.example environments/dev/terraform.tfvars

# For production  
cp terraform.tfvars.example environments/prod/terraform.tfvars
```

Edit the `.tfvars` file with your specific configuration values.

### 3. Plan Deployment

```bash
# For development environment
terraform plan -var-file=environments/dev/terraform.tfvars

# For production environment
terraform plan -var-file=environments/prod/terraform.tfvars
```

### 4. Apply Configuration

```bash
# For development environment
terraform apply -var-file=environments/dev/terraform.tfvars

# For production environment
terraform apply -var-file=environments/prod/terraform.tfvars
```

### 5. View Outputs

```bash
terraform output
```

## Modules

### VPC Module (`modules/vpc/`)
- VPC with CIDR block
- Public and private subnets across 2 AZs
- Internet Gateway + NAT Gateway
- Route tables for public/private subnets
- Security groups for RDS, ECS, ALB
- VPC endpoints for S3, ECR, etc.

### RDS Module (`modules/rds/`)
- PostgreSQL RDS with instance sizing per environment
- Multi-AZ for production only
- Automated backups (7 days dev, 30 days prod)
- Storage encrypted at rest
- Parameter group with PostgreSQL 15 settings

### ECS Module (`modules/ecs/`)
- ECS Fargate cluster for backend API
- Task definition for Node.js application
- Application Load Balancer with HTTPS support
- Auto-scaling based on CPU utilization
- IAM roles for ECS task execution

### S3 Module (`modules/s3/`)
- Scan images bucket (versioned with lifecycle to Glacier)
- PDF exports bucket (versioned with retention)
- Frontend assets bucket (static website hosting)

### CloudFront Module (`modules/cloudfront/`)
- Frontend CDN for client/admin portals
- Assets CDN for private content with OAI/OAC
- HTTPS with ACM certificates
- Caching policies optimized for static assets

## Tagging Strategy

All resources are automatically tagged with:
- `Environment`: dev/prod
- `Project`: contractorlens
- `ManagedBy`: Terraform

## State Management

Terraform state is stored in S3 with DynamoDB locking:
- Separate state bucket per environment
- State locking to prevent concurrent modifications
- State encryption enabled

## Cost Estimation

Use AWS Cost Explorer to estimate monthly costs:
- Development: ~$150-200/month
- Production: ~$400-600/month

## Destroying Infrastructure

To destroy the infrastructure (use with caution):

```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```

## Troubleshooting

### Common Issues

1. **IAM Permissions**: Ensure IAM user has necessary permissions for Terraform
2. **Resource Limits**: Check AWS account service limits (EC2, RDS, ELB)
3. **State Lock**: Remove lock from DynamoDB table if apply is stuck

### Monitoring

- CloudWatch metrics and alarms are configured for critical resources
- Container Insights enabled for ECS
- RDS Enhanced Monitoring enabled

## Security Best Practices

1. **Secrets Management**: Use AWS Secrets Manager or Parameter Store
2. **Network Security**: All resources placed in private subnets where possible
3. **Encryption**: Enable encryption at rest and in transit
4. **Access Control**: Implement least privilege IAM policies

## Updates and Maintenance

1. **Updates**: Use `terraform plan` to review changes before applying
2. **Drift Detection**: Regularly run `terraform refresh` and `terraform plan`
3. **Backup**: Regularly back up Terraform state files