# RDS Module Main Configuration

locals {
  # Map instance class to appropriate family for parameter group
  instance_family_map = {
    "db.t3"     = "db.t3"
    "db.r5"     = "db.r5"
    "db.r6g"    = "db.r6g"
    "db.m5"     = "db.m5"
    "db.t4g"    = "db.t4g"
    "db.r6i"    = "db.r6i"
    "db.x2ie"   = "db.x2ie"
    "db.x2iedn" = "db.x2iedn"
    "db.m6i"    = "db.m6i"
  }

  instance_family = var.db_instance_class
}

# PostgreSQL Parameter Group with extensions enabled
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-postgres15-params"
  family = var.parameter_group_family

  parameter {
    name  = "shared_preload_libraries"
    value = "pgcrypto,uuid-ossp"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "statement_timeout"
    value = "30000"
  }

  parameter {
    name  = "idle_in_transaction_session_timeout"
    value = "30000"
  }

  tags = {
    Name = "${var.project_name}-postgres15-params"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"

  engine                = "postgres"
  engine_version        = "15.6"
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = var.db_subnet_group_name
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sun:04:00-Sun:05:00"

  multi_az                  = var.multi_az
  publicly_accessible       = false
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-db-final-snapshot"

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : 0
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  apply_immediately = false

  tags = {
    Name = "${var.project_name}-database"
  }
}

# RDS Enhanced Monitoring IAM Role (conditional)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Secrets Manager for database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}/database/credentials"

  description = "PostgreSQL database credentials for ${var.project_name}"

  tags = {
    Name = "${var.project_name}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
    username = aws_db_instance.main.username
    password = var.db_password
    engine   = "postgres"
  })
}