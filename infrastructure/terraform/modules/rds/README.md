# RDS Module

This module creates a PostgreSQL RDS instance with security groups and subnet groups.

## Features

- PostgreSQL RDS instance with customizable version
- Configurable instance class (t3.micro for dev, r6g.large for prod)
- Multi-AZ support for high availability
- Automated backups with configurable retention
- Security group allowing ECS access
- Subnet group in private subnets
- Performance insights and enhanced monitoring
- Storage encryption at rest

## Usage

```hcl
module "rds" {
  source = "./modules/rds"
  
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  environment               = "production"
  project_name              = "contractorlens"
  instance_class            = "db.r6g.large"
  allocated_storage         = 100
  multi_az                  = true
  backup_retention_period   = 30
  database_name             = "contractorlens"
  database_username         = "contractorlens"
  database_password         = var.db_password
}
```

## Outputs

- `database_endpoint` - RDS connection endpoint
- `database_port` - RDS port (5432)
- `database_name` - Database name
- `database_instance_class` - RDS instance class
- `db_security_group_id` - Security group ID for database access
- `performance_insights_enabled` - Whether performance insights are enabled