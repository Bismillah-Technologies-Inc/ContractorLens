# Production Environment Configuration
environment = "prod"
project_name = "contractorlens"
aws_region = "us-west-2"

# Network Configuration
vpc_cidr = "10.0.0.0/16"

# Database Configuration
db_instance_class = "db.r6g.large"
db_allocated_storage = 100
db_max_allocated_storage = 1000
db_name = "contractorlens"
db_username = "contractorlens"
db_password = "" # Set via TF_VAR_db_password environment variable or AWS Secrets Manager

# ECS Configuration
instance_sizes = {
  rds = "db.r6g.large"
  ecs_cpu = 512
  ecs_memory = 1024
}
ecs_cpu = 512
ecs_memory = 1024
ecs_desired_count = 2
min_ecs_tasks = 2
max_ecs_tasks = 10
ecr_repository_url = "" # Set to your ECR repository URL

# Auto Scaling
ecs_min_capacity = 2
ecs_max_capacity = 10

# Backup and HA
backup_retention_days = 30
multi_az = true
backup_retention_period = 30
backup_window = "03:00-04:00"
maintenance_window = "Sun:04:00-Sun:05:00"

# Security
enable_deletion_protection = true

# Secrets (should be set via environment variables or AWS Secrets Manager)
# firebase_project_id = ""
# firebase_private_key = ""
# firebase_client_email = ""
# gemini_api_key = ""

# Monitoring
enable_container_insights = true
log_retention_days = 30

# Cost Optimization
enable_spot_instances = false
schedule_scaling = true

# Domain
domain_name = "contractorlens.com"
certificate_arn = "" # Set after creating certificate