# Development Environment Configuration
environment = "dev"
project_name = "contractorlens"
aws_region = "us-west-2"

# Network Configuration
vpc_cidr = "10.0.0.0/16"

# Database Configuration
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_max_allocated_storage = 100
db_name = "contractorlens"
db_username = "contractorlens"
db_password = "" # Set via TF_VAR_db_password environment variable or AWS Secrets Manager

# ECS Configuration
instance_sizes = {
  rds = "db.t3.micro"
  ecs_cpu = 256
  ecs_memory = 512
}
ecs_cpu = 256
ecs_memory = 512
ecs_desired_count = 1
min_ecs_tasks = 1
max_ecs_tasks = 3
ecr_repository_url = "" # Set to your ECR repository URL

# Auto Scaling
ecs_min_capacity = 1
ecs_max_capacity = 3

# Backup and HA
backup_retention_days = 7
multi_az = false
backup_retention_period = 7
backup_window = "02:00-03:00"
maintenance_window = "Sun:02:00-Sun:03:00"

# Security
enable_deletion_protection = false

# Secrets (should be set via environment variables or AWS Secrets Manager)
# firebase_project_id = ""
# firebase_private_key = ""
# firebase_client_email = ""
# gemini_api_key = ""

# Monitoring
enable_container_insights = true
log_retention_days = 7

# Cost Optimization
enable_spot_instances = false
schedule_scaling = false

# Domain
domain_name = "dev.contractorlens.com"
certificate_arn = "" # Set after creating certificate