# ContractorLens Production Infrastructure - AWS Terraform Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state management (uncomment in production)
  # backend "s3" {
  #   bucket = "contractorlens-terraform-state"
  #   key    = "production/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "ContractorLens"
      ManagedBy   = "Terraform"
      CostCenter  = "Production"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}


# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name                 = var.project_name
  environment                  = var.environment
  db_instance_class            = var.db_instance_class
  db_allocated_storage         = var.db_allocated_storage
  db_max_allocated_storage     = var.db_max_allocated_storage
  backup_retention_period      = var.backup_retention_period
  multi_az                     = var.multi_az
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval
  deletion_protection          = var.deletion_protection
  db_name                      = var.db_name
  db_username                  = var.db_username
  db_password                  = var.db_password
  db_subnet_group_name         = module.vpc.db_subnet_group_name
  rds_security_group_id        = module.vpc.rds_security_group_id
  parameter_group_family       = "postgres15"

  depends_on = [module.vpc]
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.alb_security_group_id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-app-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-app-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.project_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${var.ecr_repository_url}:latest"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "DB_HOST"
          value = module.rds.db_endpoint
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        }
      ]
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = module.rds.secrets_manager_arn
        },
        {
          name      = "FIREBASE_PROJECT_ID"
          valueFrom = aws_ssm_parameter.firebase_project_id.arn
        },
        {
          name      = "FIREBASE_PRIVATE_KEY"
          valueFrom = aws_ssm_parameter.firebase_private_key.arn
        },
        {
          name      = "FIREBASE_CLIENT_EMAIL"
          valueFrom = aws_ssm_parameter.firebase_client_email.arn
        },
        {
          name      = "GEMINI_API_KEY"
          valueFrom = aws_ssm_parameter.gemini_api_key.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      essential = true
    }
  ])

  tags = {
    Name = "${var.project_name}-task-definition"
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = var.project_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [module.vpc.app_security_group_id]
    subnets          = module.vpc.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "backend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.app]

  tags = {
    Name = "${var.project_name}-service"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.ecs_max_capacity
  min_capacity       = var.ecs_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${var.project_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Parameter Store for secrets (except DB password which is in Secrets Manager)
resource "aws_ssm_parameter" "firebase_project_id" {
  name  = "/${var.project_name}/firebase/project_id"
  type  = "SecureString"
  value = var.firebase_project_id

  tags = {
    Name = "${var.project_name}-firebase-project-id"
  }
}

resource "aws_ssm_parameter" "firebase_private_key" {
  name  = "/${var.project_name}/firebase/private_key"
  type  = "SecureString"
  value = var.firebase_private_key

  tags = {
    Name = "${var.project_name}-firebase-private-key"
  }
}

resource "aws_ssm_parameter" "firebase_client_email" {
  name  = "/${var.project_name}/firebase/client_email"
  type  = "SecureString"
  value = var.firebase_client_email

  tags = {
    Name = "${var.project_name}-firebase-client-email"
  }
}

resource "aws_ssm_parameter" "gemini_api_key" {
  name  = "/${var.project_name}/gemini/api_key"
  type  = "SecureString"
  value = var.gemini_api_key

  tags = {
    Name = "${var.project_name}-gemini-api-key"
  }
}