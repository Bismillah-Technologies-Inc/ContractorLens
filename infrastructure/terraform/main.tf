# ContractorLens Infrastructure - Root Module
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30.0"
    }
  }

  # S3 backend configuration for Terraform state
  backend "s3" {
    bucket         = "contractorlens-terraform-state"
    key            = "${var.environment}/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "contractorlens-terraform-locks"
    encrypt        = true
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}

# Local variables
locals {
  account_id = data.aws_caller_identity.current.account_id
  name       = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name        = local.name
  environment = var.environment
  project_name = var.project_name
  
  vpc_cidr          = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  name        = local.name
  environment = var.environment
  project_name = var.project_name
  
  db_instance_class = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  db_backup_retention_period = var.db_backup_retention_period
  db_multi_az = var.db_multi_az
  
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_security_group_id = module.vpc.db_security_group_id
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  name        = local.name
  environment = var.environment
  project_name = var.project_name
  
  ecs_cpu = var.ecs_cpu
  ecs_memory = var.ecs_memory
  ecs_desired_count = var.ecs_desired_count
  ecs_min_capacity = var.ecs_min_capacity
  ecs_max_capacity = var.ecs_max_capacity
  ecr_repository_url = var.ecr_repository_url
  
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  
  db_endpoint = module.rds.db_endpoint
  db_port = module.rds.db_port
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  alb_security_group_id = module.vpc.alb_security_group_id
  app_security_group_id = module.vpc.app_security_group_id
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  name        = local.name
  environment = var.environment
  project_name = var.project_name
  
  enable_versioning = true
}

# CloudFront Module
module "cloudfront" {
  source = "./modules/cloudfront"

  name        = local.name
  environment = var.environment
  project_name = var.project_name
  
  # S3 bucket outputs as origins
  scan_images_bucket_name = module.s3.scan_images_bucket_name
  pdf_exports_bucket_name = module.s3.pdf_exports_bucket_name
  frontend_assets_bucket_name = module.s3.frontend_assets_bucket_name
  
  scan_images_bucket_regional_domain_name = module.s3.scan_images_bucket_regional_domain_name
  pdf_exports_bucket_regional_domain_name = module.s3.pdf_exports_bucket_regional_domain_name
  frontend_assets_bucket_regional_domain_name = module.s3.frontend_assets_bucket_regional_domain_name
  
  # Domain configuration
  domain_name = var.domain_name
  certificate_arn = var.certificate_arn
  
  # Security settings
  enable_waf = false
}