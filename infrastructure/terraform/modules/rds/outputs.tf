output "db_endpoint" {
  description = "Database connection endpoint"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_parameter_group_name" {
  description = "Database parameter group name"
  value       = aws_db_instance.main.parameter_group_name
}

output "secrets_manager_arn" {
  description = "ARN of the database credentials in Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secrets_manager_version_id" {
  description = "Version ID of the database credentials in Secrets Manager"
  value       = aws_secretsmanager_secret_version.db_credentials.version_id
}

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "db_security_group_id" {
  description = "Security group ID attached to RDS"
  value       = var.rds_security_group_id
}