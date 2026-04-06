# ContractorLens Infrastructure Outputs - VPC Module Outputs
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
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "database_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "database_name" {
  description = "RDS database name"
  value       = module.rds.db_name
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
  value       = module.vpc.nat_gateway_ip
}

# Security Groups
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
  value       = module.vpc.rds_security_group_id
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

# Secrets Manager and Parameter Store ARNs (for reference)
output "secrets_manager_arns" {
  description = "ARNs of Secrets Manager and Parameter Store secrets"
  value = {
    db_credentials        = module.rds.secrets_manager_arn
    firebase_project_id   = aws_ssm_parameter.firebase_project_id.arn
    firebase_private_key  = aws_ssm_parameter.firebase_private_key.arn
    firebase_client_email = aws_ssm_parameter.firebase_client_email.arn
    gemini_api_key        = aws_ssm_parameter.gemini_api_key.arn
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