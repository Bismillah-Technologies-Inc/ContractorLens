# RDS Module Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial storage allocation for RDS (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage allocation for RDS (GB)"
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Database backup retention period in days"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable RDS Performance Insights"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
  default     = 0 # 0 = disabled
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "contractorlens"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "contractorlens_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_subnet_group_name" {
  description = "Name of the database subnet group"
  type        = string
}

variable "rds_security_group_id" {
  description = "Security group ID for RDS access"
  type        = string
}

variable "parameter_group_family" {
  description = "PostgreSQL parameter group family"
  type        = string
  default     = "postgres15"
}