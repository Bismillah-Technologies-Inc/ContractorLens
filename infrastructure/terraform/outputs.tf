# ==============================================================================
# ContractorLens Infrastructure Outputs
# ==============================================================================

# VPC and Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = try(aws_vpc.main.id, "")
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = try(aws_subnet.public[*].id, [])
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = try(aws_subnet.private[*].id, [])
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = try(data.aws_availability_zones.available.names, [])
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = try(aws_internet_gateway.main.id, "")
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = try(aws_nat_gateway.main.id, "")
}

output "nat_gateway_ip" {
  description = "Elastic IP address of NAT Gateway"
  value       = try(aws_eip.nat.public_ip, "")
}

# Database Outputs (RDS PostgreSQL)
output "database_endpoint" {
  description = "RDS instance endpoint (connect string)"
  value       = try(aws_db_instance.main.address, "")
  sensitive   = true
}

output "database_host" {
  description = "RDS instance hostname"
  value       = try(aws_db_instance.main.address, "")
}

output "database_port" {
  description = "RDS instance port"
  value       = try(aws_db_instance.main.port, "")
}

output "database_name" {
  description = "RDS database name"
  value       = try(aws_db_instance.main.db_name, "")
}

output "database_engine" {
  description = "RDS database engine"
  value       = try(aws_db_instance.main.engine, "")
}

output "database_engine_version" {
  description = "RDS database engine version"
  value       = try(aws_db_instance.main.engine_version, "")
}

output "database_instance_class" {
  description = "RDS instance class"
  value       = try(aws_db_instance.main.instance_class, "")
}

output "db_subnet_group_name" {
  description = "RDS DB subnet group name"
  value       = try(aws_db_subnet_group.main.name, "")
}

# Load Balancer Outputs (ALB)
output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer (ALB DNS name)"
  value       = try(aws_lb.main.dns_name, "")
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = try(aws_lb.main.zone_id, "")
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = try(aws_lb.main.arn, "")
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = try(aws_lb_target_group.app.arn, "")
}

output "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = try(aws_lb_listener.app.arn, "")
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = try(aws_ecs_cluster.main.id, "")
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = try(aws_ecs_cluster.main.arn, "")
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = try(aws_ecs_cluster.main.name, "")
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = try(aws_ecs_service.app.name, "")
}

output "ecs_service_arn" {
  description = "ARN of the ECS service"
  value       = try(aws_ecs_service.app.id, "")
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = try(aws_ecs_task_definition.app.arn, "")
}

output "ecs_task_definition_family" {
  description = "Family name of the ECS task definition"
  value       = try(aws_ecs_task_definition.app.family, "")
}

output "ecs_task_cpu" {
  description = "CPU allocation for ECS task"
  value       = try(aws_ecs_task_definition.app.cpu, "")
}

output "ecs_task_memory" {
  description = "Memory allocation for ECS task"
  value       = try(aws_ecs_task_definition.app.memory, "")
}

# ECR Outputs (configured separately - placeholder note)
output "ecr_repository_url" {
  description = "ECR repository URL for container images"
  value       = var.ecr_repository_url
}

# Container Insights and Logging
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.app.name, "")
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.app.arn, "")
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = try(aws_security_group.alb.id, "")
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = try(aws_security_group.app.id, "")
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = try(aws_security_group.db.id, "")
}

# IAM Role Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = try(aws_iam_role.ecs_task_execution_role.arn, "")
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = try(aws_iam_role.ecs_task_role.arn, "")
}

output "rds_enhanced_monitoring_role_arn" {
  description = "ARN of the RDS enhanced monitoring IAM role"
  value       = try(aws_iam_role.rds_enhanced_monitoring.arn, "")
}

# Parameter Store ARNs (for secret management)
output "parameter_store_arns" {
  description = "ARNs of Parameter Store secrets"
  value = {
    db_password           = try(aws_ssm_parameter.db_password.arn, "")
    firebase_project_id   = try(aws_ssm_parameter.firebase_project_id.arn, "")
    firebase_private_key  = try(aws_ssm_parameter.firebase_private_key.arn, "")
    firebase_client_email = try(aws_ssm_parameter.firebase_client_email.arn, "")
    gemini_api_key       = try(aws_ssm_parameter.gemini_api_key.arn, "")
  }
  sensitive = true
}

# Application URLs
output "application_url" {
  description = "Application HTTP URL"
  value       = "http://${try(aws_lb.main.dns_name, "dns-not-available")}"
}

output "health_check_url" {
  description = "Health check URL"
  value       = "http://${try(aws_lb.main.dns_name, "dns-not-available")}/health"
}

output "api_base_url" {
  description = "API base URL"
  value       = "http://${try(aws_lb.main.dns_name, "dns-not-available")}/api/v1"
}

# Monitoring Outputs
output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}"
}

# Auto Scaling Outputs
output "ecs_autoscaling_target_resource_id" {
  description = "Auto scaling target resource ID"
  value       = try(aws_appautoscaling_target.ecs_target.resource_id, "")
}

output "ecs_min_capacity" {
  description = "Minimum ECS task capacity"
  value       = var.ecs_min_capacity
}

output "ecs_max_capacity" {
  description = "Maximum ECS task capacity"
  value       = var.ecs_max_capacity
}

# Backup Configuration Outputs
output "backup_retention_period" {
  description = "Database backup retention period (days)"
  value       = var.backup_retention_period
}

output "multi_az_enabled" {
  description = "Multi-AZ deployment enabled"
  value       = try(aws_db_instance.main.multi_az, false)
}

# Cost Tagging Outputs
output "resource_tags" {
  description = "Common tags applied to all resources"
  value = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "Terraform"
    CostCenter    = var.environment == "prod" ? "Production" : "Development"
  }
}

# S3 Bucket Outputs (placeholder - for future S3 modules)
output "s3_bucket_names" {
  description = "S3 bucket names for different purposes"
  value = {
    scan_images    = "${var.project_name}-scan-images-${var.environment}"
    pdf_exports    = "${var.project_name}-pdf-exports-${var.environment}"
    frontend_assets = "${var.project_name}-frontend-assets-${var.environment}"
  }
}

# CloudFront Outputs (placeholder - for future CloudFront modules)
output "cloudfront_distribution_urls" {
  description = "CloudFront distribution URLs"
  value = {
    frontend = "https://cdn.${var.domain_name}"
    assets   = "https://assets.${var.domain_name}"
  }
}

# AWS Account Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = try(data.aws_caller_identity.current.account_id, "")
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

# Deployment Information
output "deployment_summary" {
  description = "Summary of deployment outputs"
  value = {
    environment          = var.environment
    project_name         = var.project_name
    load_balancer_dns    = try(aws_lb.main.dns_name, "")
    database_host        = try(aws_db_instance.main.address, "")
    ecs_cluster_name     = try(aws_ecs_cluster.main.name, "")
    vpc_id               = try(aws_vpc.main.id, "")
    deployment_timestamp = timestamp()
  }
}