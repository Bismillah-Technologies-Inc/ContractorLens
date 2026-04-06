# ContractorLens Infrastructure Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "nat_gateway_ip" {
  description = "Elastic IP address of NAT Gateway"
  value       = aws_eip.nat.public_ip
}

# Security Groups
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}

# IAM Roles
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

# Parameter Store ARNs (for reference)
output "parameter_store_arns" {
  description = "ARNs of Parameter Store secrets"
  value = {
    db_password           = aws_ssm_parameter.db_password.arn
    firebase_project_id   = aws_ssm_parameter.firebase_project_id.arn
    firebase_private_key  = aws_ssm_parameter.firebase_private_key.arn
    firebase_client_email = aws_ssm_parameter.firebase_client_email.arn
    gemini_api_key       = aws_ssm_parameter.gemini_api_key.arn
  }
  sensitive = true
}

# Application URLs
output "application_url" {
  description = "Application URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "health_check_url" {
  description = "Health check URL"
  value       = "http://${aws_lb.main.dns_name}/health"
}

output "api_base_url" {
  description = "API base URL"
  value       = "http://${aws_lb.main.dns_name}/api/v1"
}

# Monitoring
output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}"
}

# S3 Bucket Outputs
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

output "cloudfront_logs_bucket_name" {
  description = "Name of the CloudFront logs bucket"
  value       = aws_s3_bucket.cloudfront_logs.id
}

# CloudFront Outputs
output "frontend_distribution_domain_name" {
  description = "Domain name of the frontend CloudFront distribution"
  value       = module.cloudfront.frontend_distribution_domain_name
}

output "assets_distribution_domain_name" {
  description = "Domain name of the assets CloudFront distribution"
  value       = module.cloudfront.assets_distribution_domain_name
}

output "frontend_distribution_id" {
  description = "ID of the frontend CloudFront distribution"
  value       = module.cloudfront.frontend_distribution_id
}

output "assets_distribution_id" {
  description = "ID of the assets CloudFront distribution"
  value       = module.cloudfront.assets_distribution_id
}

output "assets_origin_access_identity_path" {
  description = "Path of the origin access identity for assets bucket"
  value       = module.cloudfront.assets_origin_access_identity_path
}

output "frontend_website_url" {
  description = "Frontend website URL"
  value       = "https://${module.cloudfront.frontend_distribution_domain_name}"
}

output "assets_cdn_url" {
  description = "Assets CDN URL"
  value       = "https://${module.cloudfront.assets_distribution_domain_name}"
}