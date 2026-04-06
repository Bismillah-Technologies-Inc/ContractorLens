# RDS PostgreSQL Module

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.name}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.name}-db"

  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.db_backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"

  multi_az               = var.db_multi_az
  deletion_protection    = true
  
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.name}-db-final-snapshot"

  performance_insights_enabled = true
  monitoring_interval         = 60

  apply_immediately = true

  tags = {
    Name        = "${var.name}-database"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Parameter Store for database password
resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project_name}/${var.environment}/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Name        = "${var.name}-db-password"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}