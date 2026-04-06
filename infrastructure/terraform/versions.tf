terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    
    # Optional providers for future use
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
    
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0, < 4.0.0"
    }
    
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0, < 3.0.0"
    }
  }
  
  # Backend configuration (uncomment and configure for remote state)
  # backend "s3" {
  #   bucket         = "contractorlens-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "contractorlens-terraform-locks"
  #   encrypt        = true
  # }
}

# Provider configurations
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      CostCenter    = var.environment == "prod" ? "Production" : "Development"
      Terraform     = "true"
      LastModified  = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
    }
  }
}

# Additional providers can be added here for multi-region or account configurations
# provider "aws" {
#   alias  = "us-east-1"
#   region = "us-east-1"
# }