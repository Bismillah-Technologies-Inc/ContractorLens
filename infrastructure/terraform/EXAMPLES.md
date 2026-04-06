# Example: Modular Infrastructure

This example shows how to use the modularized infrastructure components with environment-specific configurations.

## Directory Structure

```
infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf              # Dev-specific main configuration
│   │   └── terraform.tfvars     # Dev variables (sensitive values excluded)
│   └── prod/
│       ├── main.tf              # Prod-specific main configuration
│       └── terraform.tfvars     # Prod variables (sensitive values excluded)
├── modules/
│   ├── vpc/                     # VPC networking module
│   ├── rds/                     # RDS database module
│   ├── ecs/                     # ECS container module
│   ├── s3/                      # S3 storage module
│   └── cloudfront/              # CloudFront CDN module
└── shared/                      # Shared configurations
    ├── variables.tf             # Common variable definitions
    └── outputs.tf               # Common output definitions
```

## Example: Development Environment (`environments/dev/main.tf`)

```hcl
# Development Environment - Lower cost, single AZ

module "vpc" {
  source = "../../modules/vpc"
  
  vpc_cidr        = "10.0.0.0/16"
  environment     = "dev"
  project_name    = "contractorlens"
  az_count        = 2
  enable_nat_gateway = true
}

module "rds" {
  source = "../../modules/rds"
  
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  environment               = "dev"
  project_name              = "contractorlens"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  max_allocated_storage     = 100
  multi_az                  = false
  backup_retention_period   = 7
  database_name             = "contractorlens"
  database_username         = "contractorlens"
  database_password         = var.db_password
  
  security_group_rules = {
    allow_ecs = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Allow ECS tasks to access RDS"
    }
  }
}

module "s3" {
  source = "../../modules/s3"
  
  environment               = "dev"
  project_name              = "contractorlens"
  enable_scan_images_bucket = true
  enable_pdf_exports_bucket = true
  enable_frontend_assets    = false  # Use CloudFront in production only
  enable_versioning         = false  # Disable to save costs in dev
  enable_encryption         = true
}

module "ecs" {
  source = "../../modules/ecs"
  
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids        = module.vpc.private_subnet_ids
  database_endpoint         = module.rds.database_endpoint
  database_name             = module.rds.database_name
  database_username         = module.rds.database_username
  scan_images_bucket_name   = module.s3.scan_images_bucket_name
  pdf_exports_bucket_name   = module.s3.pdf_exports_bucket_name
  
  environment               = "dev"
  project_name              = "contractorlens"
  ecs_cpu                   = 256
  ecs_memory                = 512
  ecr_repository_url        = var.ecr_repository_url
  min_capacity              = 1
  max_capacity              = 3
  desired_count             = 1
  
  container_port            = 3000
  container_image           = "${var.ecr_repository_url}:latest"
  
  health_check_path         = "/health"
  health_check_matcher      = "200"
  
  autoscaling_metrics = {
    cpu_utilization    = 70
    memory_utilization = 80
  }
}

# CloudFront is typically not used in dev (higher cost)
# module "cloudfront" {
#   source = "../../modules/cloudfront"
#   ...
# }
```

## Example: Production Environment (`environments/prod/main.tf`)

```hcl
# Production Environment - High availability, multi-AZ

module "vpc" {
  source = "../../modules/vpc"
  
  vpc_cidr        = "10.0.0.0/16"
  environment     = "prod"
  project_name    = "contractorlens"
  az_count        = 3  # Multi-AZ for high availability
  enable_nat_gateway = true
  enable_vpc_flow_logs = true  # Security audit trail
}

module "rds" {
  source = "../../modules/rds"
  
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  environment               = "prod"
  project_name              = "contractorlens"
  instance_class            = "db.r6g.large"
  allocated_storage         = 100
  max_allocated_storage     = 1000
  multi_az                  = true
  backup_retention_period   = 30
  database_name             = "contractorlens"
  database_username         = "contractorlens"
  database_password         = var.db_password
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  
  security_group_rules = {
    allow_ecs = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Allow ECS tasks to access RDS"
    }
  }
}

module "s3" {
  source = "../../modules/s3"
  
  environment               = "prod"
  project_name              = "contractorlens"
  enable_scan_images_bucket = true
  enable_pdf_exports_bucket = true
  enable_frontend_assets    = true
  enable_versioning         = true
  enable_encryption         = true
  enable_lifecycle_rules    = true
  
  lifecycle_rules = {
    scan_images = {
      expiration_days = 90
      transition_days = 30
      storage_class   = "STANDARD_IA"
    }
    pdf_exports = {
      expiration_days = 365
      transition_days = 90
      storage_class   = "GLACIER"
    }
  }
}

module "ecs" {
  source = "../../modules/ecs"
  
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids        = module.vpc.private_subnet_ids
  database_endpoint         = module.rds.database_endpoint
  database_name             = module.rds.database_name
  database_username         = module.rds.database_username
  scan_images_bucket_name   = module.s3.scan_images_bucket_name
  pdf_exports_bucket_name   = module.s3.pdf_exports_bucket_name
  
  environment               = "prod"
  project_name              = "contractorlens"
  ecs_cpu                   = 512
  ecs_memory                = 1024
  ecr_repository_url        = var.ecr_repository_url
  min_capacity              = 2
  max_capacity              = 10
  desired_count             = 2
  
  container_port            = 3000
  container_image           = "${var.ecr_repository_url}:latest"
  
  health_check_path         = "/health"
  health_check_matcher      = "200"
  
  enable_https              = true
  certificate_arn           = var.certificate_arn
  
  autoscaling_metrics = {
    cpu_utilization    = 70
    memory_utilization = 80
    request_count      = 1000  # RPS-based scaling
  }
  
  autoscaling_schedules = {
    business_hours = {
      min_capacity      = 4
      max_capacity      = 10
      scheduled_action  = "at(09:00)"
      end_time          = "at(18:00)"
      timezone          = "America/Los_Angeles"
    }
    off_hours = {
      min_capacity      = 2
      max_capacity      = 4
      scheduled_action  = "at(18:00)"
      end_time          = "at(09:00)"
      timezone          = "America/Los_Angeles"
    }
  }
}

module "cloudfront" {
  source = "../../modules/cloudfront"
  
  environment               = "prod"
  project_name              = "contractorlens"
  domain_name               = "contractorlens.com"
  certificate_arn           = var.certificate_arn
  frontend_s3_bucket_name   = module.s3.frontend_assets_bucket_name
  
  enable_waf                = true
  price_class               = "PriceClass_100" # US, Canada, Europe
  
  waf_rules = {
    rate_limit = {
      priority      = 1
      action        = "BLOCK"
      rate_limit    = 2000
      aggregate_key = "IP"
    }
    sql_injection = {
      priority = 2
      action   = "BLOCK"
      rule     = "AWSManagedRulesSQLiRuleSet"
    }
    common_vulnerabilities = {
      priority = 3
      action   = "BLOCK"
      rule     = "AWSManagedRulesCommonRuleSet"
    }
  }
  
  cache_behaviors = {
    default = {
      path_pattern           = "*"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingOptimized
      origin_request_policy_id = null
    }
  }
}
```

## Deployment Commands

```bash
# Initialize module dependencies
terraform init

# Plan deployment for development
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply development configuration
terraform apply -var-file="environments/dev/terraform.tfvars"

# Plan deployment for production
terraform plan -var-file="environments/prod/terraform.tfvars"

# Apply production configuration
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## Variable Files Example

### `environments/dev/terraform.tfvars`
```hcl
# Development Configuration
environment = "dev"
project_name = "contractorlens"

# AWS Region
aws_region = "us-west-2"

# Database Configuration - values should come from environment/secrets
# db_password = "set_via_TF_VAR_db_password"
# db_username = "contractorlens"

# ECS Configuration
ecs_cpu = 256
ecs_memory = 512
min_ecs_tasks = 1
max_ecs_tasks = 3

# RDS Configuration
db_instance_class = "db.t3.micro"
multi_az = false
backup_retention_days = 7

# Monitoring
enable_container_insights = true
log_retention_days = 7

# Security
enable_deletion_protection = false
```

### `environments/prod/terraform.tfvars`
```hcl
# Production Configuration
environment = "prod"
project_name = "contractorlens"

# AWS Region
aws_region = "us-west-2"

# Database Configuration - values should come from environment/secrets
# db_password = "set_via_TF_VAR_db_password"
# db_username = "contractorlens"

# ECS Configuration
ecs_cpu = 512
ecs_memory = 1024
min_ecs_tasks = 2
max_ecs_tasks = 10

# RDS Configuration
db_instance_class = "db.r6g.large"
multi_az = true
backup_retention_days = 30

# Monitoring
enable_container_insights = true
log_retention_days = 30

# Security
enable_deletion_protection = true

# Domain
domain_name = "contractorlens.com"
# certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/abcd-efgh"
```

## Module Benefits

1. **Reusability**: Same modules for dev/prod with different parameters
2. **Consistency**: Standardized patterns across environments
3. **Maintainability**: Changes in one module propagate to all environments
4. **Security**: Centralized security configurations
5. **Cost Optimization**: Environment-specific resource sizing
6. **Scalability**: Easy to add new environments (staging, QA, etc.)

## Migration from Monolithic Configuration

If migrating from the monolithic configuration in `main.tf`:

1. **Backup current state**: `terraform state pull > backup.json`
2. **Create modular structure**: Copy resources into respective modules
3. **Reference modules**: Update environment configurations to use modules
4. **Test migration**: Apply to non-production environment first
5. **Update CI/CD**: Modify deployment pipelines to use module structure