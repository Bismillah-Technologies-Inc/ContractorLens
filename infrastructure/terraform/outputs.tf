# ContractorLens Infrastructure Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# Database Outputs
output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "db_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "db_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}

# ECS Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.ecs.load_balancer_dns_name
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = module.ecs.load_balancer_arn
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.ecs_cluster_id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.ecs_service_name
}

# S3 Outputs
output "scan_images_bucket_name" {
  description = "Name of the scan images bucket"
  value       = module.s3.scan_images_bucket_name
}

output "pdf_exports_bucket_name" {
  description = "Name of the PDF exports bucket"
  value       = module.s3.pdf_exports_bucket_name
}

output "frontend_assets_bucket_name" {
  description = "Name of the frontend assets bucket"
  value       = module.s3.frontend_assets_bucket_name
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.vpc.alb_security_group_id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.vpc.app_security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.vpc.db_security_group_id
}

# Application URLs
output "application_url" {
  description = "Application URL"
  value       = "http://${module.ecs.load_balancer_dns_name}"
}

output "health_check_url" {
  description = "Health check URL"
  value       = "http://${module.ecs.load_balancer_dns_name}/health"
}

output "api_base_url" {
  description = "API base URL"
  value       = "http://${module.ecs.load_balancer_dns_name}/api/v1"
}

# Combined Information
output "environment_summary" {
  description = "Summary of the deployed environment"
  value = {
    environment        = var.environment
    project_name       = var.project_name
    aws_region         = var.aws_region
    vpc_id             = module.vpc.vpc_id
    app_url            = "http://${module.ecs.load_balancer_dns_name}"
    db_endpoint        = module.rds.db_endpoint
    scan_bucket        = module.s3.scan_images_bucket_name
    pdf_bucket         = module.s3.pdf_exports_bucket_name
    frontend_bucket    = module.s3.frontend_assets_bucket_name
    cloudfront_distro  = module.cloudfront.cloudfront_distribution_domain_name
  }
  sensitive = true
}