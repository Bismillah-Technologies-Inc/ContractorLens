# ContractorLens Production Environment Configuration
# Use with: terraform apply -var-file=environments/prod/terraform.tfvars

# Environment Configuration
environment = "prod"
project_name = "contractorlens"

# AWS Configuration  
aws_region = "us-west-2"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
enable_nat_gateway = true

# RDS Configuration
db_instance_class = "db.t3.medium"
db_allocated_storage = 100
db_max_allocated_storage = 1000
db_name = "contractorlens"
db_username = "contractorlens"
db_password = "your_secure_production_db_password_here"
db_backup_retention_period = 30
db_multi_az = true

# ECS Configuration
ecs_cpu = 1024
ecs_memory = 2048
ecs_desired_count = 2
ecs_min_capacity = 2
ecs_max_capacity = 10
ecr_repository_url = "123456789012.dkr.ecr.us-west-2.amazonaws.com/contractorlens"

# Firebase Configuration (required for production)
firebase_project_id = "your-prod-firebase-project-id"
firebase_private_key = "-----BEGIN PRIVATE KEY-----\nyour_production_firebase_private_key_here\n-----END PRIVATE KEY-----"
firebase_client_email = "firebase-adminsdk-xxx@your-prod-project.iam.gserviceaccount.com"

# Gemini Configuration (required for production)
gemini_api_key = "your_production_gemini_api_key_here"

# Domain Configuration
domain_name = "contractorlens.com"
certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"

# Security Configuration
enable_deletion_protection = true

# Monitoring
enable_container_insights = true
log_retention_days = 30