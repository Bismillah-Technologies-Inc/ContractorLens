# ECS Fargate Module Variables

# Core Configuration
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "production"
}

# Container Configuration
variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "backend"
}

variable "container_image" {
  description = "Container image registry URL"
  type        = string
}

variable "container_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

# Resource Configuration
variable "cpu" {
  description = "CPU units for the ECS task (256 for 0.25 vCPU, 512 for 0.5 vCPU)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory (MB) for the ECS task"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets for ALB"
  type        = list(string)
}

# Security Configuration
variable "enable_deletion_protection" {
  description = "Enable deletion protection for load balancer"
  type        = bool
  default     = true
}

# SSL Configuration
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}

# Environment Variables
variable "db_host" {
  description = "Database host address"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for scan images"
  type        = string
}

variable "cloudfront_url" {
  description = "CloudFront URL for asset distribution"
  type        = string
}

# Secrets Configuration
variable "db_password_secret_arn" {
  description = "ARN of the DB password secret in Secrets Manager"
  type        = string
}

variable "db_user_secret_arn" {
  description = "ARN of the DB user secret in Secrets Manager"
  type        = string
}

variable "db_host_secret_arn" {
  description = "ARN of the DB host secret in Secrets Manager (optional - uses db_host variable if not provided)"
  type        = string
  default     = ""
}

variable "db_port_secret_arn" {
  description = "ARN of the DB port secret in Secrets Manager (optional - uses db_port variable if not provided)"
  type        = string
  default     = ""
}

variable "db_name_secret_arn" {
  description = "ARN of the DB name secret in Secrets Manager (optional - uses db_name variable if not provided)"
  type        = string
  default     = ""
}

variable "stripe_secret_key_secret_arn" {
  description = "ARN of the Stripe secret key in Secrets Manager"
  type        = string
}

variable "stripe_webhook_secret_arn" {
  description = "ARN of the Stripe webhook secret in Secrets Manager"
  type        = string
}

variable "firebase_project_id_secret_arn" {
  description = "ARN of the Firebase project ID in Secrets Manager"
  type        = string
}

variable "firebase_private_key_secret_arn" {
  description = "ARN of the Firebase private key in Secrets Manager"
  type        = string
}

# IAM Resource ARNs
variable "secrets_manager_arns" {
  description = "List of Secrets Manager ARNs for task execution role"
  type        = list(string)
  default     = []
}

variable "ssm_parameter_arns" {
  description = "List of SSM Parameter ARNs for task execution role"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs for task role permissions"
  type        = list(string)
  default     = []
}

# Auto-scaling Configuration
variable "min_capacity" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 10
}

variable "cpu_utilization_target" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70.0
}

variable "memory_utilization_target" {
  description = "Target memory utilization percentage for auto-scaling"
  type        = number
  default     = 80.0
}

variable "scale_in_cooldown" {
  description = "Cooldown period for scale-in events (seconds)"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown period for scale-out events (seconds)"
  type        = number
  default     = 60
}

# Monitoring Configuration
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Additional Configuration
variable "additional_environment_variables" {
  description = "Additional environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "additional_secrets" {
  description = "Additional secrets from Secrets Manager for the container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

# AWS Region
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}