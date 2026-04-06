# ContractorLens Development Environment Configuration
# Use with: terraform apply -var-file=environments/dev/terraform.tfvars

# Environment Configuration
environment = "dev"
project_name = "contractorlens"

# AWS Configuration  
aws_region = "us-west-2"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
enable_nat_gateway = true

# RDS Configuration
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_max_allocated_storage = 100
db_name = "contractorlens"
db_username = "contractorlens"
db_password = "your_secure_db_password_here"
db_backup_retention_period = 7
db_multi_az = false

# ECS Configuration
ecs_cpu = 256
ecs_memory = 512
ecs_desired_count = 1
ecs_min_capacity = 1
ecs_max_capacity = 2
ecr_repository_url = "123456789012.dkr.ecr.us-west-2.amazonaws.com/contractorlens"

# Firebase Configuration (required for development)
firebase_project_id = "your-dev-firebase-project-id"
firebase_private_key = "-----BEGIN PRIVATE KEY-----\nyour_firebase_private_key_here\n-----END PRIVATE KEY-----"
firebase_client_email = "firebase-adminsdk-xxx@your-dev-project.iam.gserviceaccount.com"

# Gemini Configuration (required for development)
gemini_api_key = "your_gemini_api_key_here"

# Domain Configuration (optional for dev)
domain_name = ""
certificate_arn = ""

# Security Configuration
enable_deletion_protection = false

# Monitoring
enable_container_insights = true
log_retention_days = 7