# ECS Module

This module creates an ECS Fargate cluster with auto-scaling and load balancing.

## Features

- ECS Fargate cluster with container insights
- Fargate task definition with configurable CPU/memory
- Application Load Balancer with HTTP/HTTPS listeners
- Auto-scaling based on CPU utilization
- CloudWatch logging and monitoring
- IAM roles for task execution and permissions
- Security groups for ALB and application
- Integration with RDS and S3 via IAM roles

## Usage

```hcl
module "ecs" {
  source = "./modules/ecs"
  
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids        = module.vpc.private_subnet_ids
  database_endpoint         = module.rds.database_endpoint
  environment               = "production"
  project_name              = "contractorlens"
  ecs_cpu                   = 512
  ecs_memory                = 1024
  ecr_repository_url        = var.ecr_repository_url
  min_capacity              = 2
  max_capacity              = 10
  desired_count             = 2
}
```

## Outputs

- `ecs_cluster_name` - Name of the ECS cluster
- `ecs_service_name` - Name of the ECS service
- `load_balancer_dns_name` - ALB DNS name
- `load_balancer_zone_id` - ALB zone ID
- `ecs_task_execution_role_arn` - IAM role ARN for task execution
- `ecs_task_role_arn` - IAM role ARN for task permissions