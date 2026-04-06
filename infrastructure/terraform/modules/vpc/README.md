# VPC Module

This module creates a VPC with public and private subnets across multiple availability zones.

## Features

- VPC with customizable CIDR block
- Public subnets with Internet Gateway routing
- Private subnets with NAT Gateway routing
- Route tables for public and private subnets
- Availability zone distribution
- Basic tagging

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr        = "10.0.0.0/16"
  environment     = "production"
  project_name    = "contractorlens"
  az_count        = 2
}
```

## Outputs

- `vpc_id` - ID of the created VPC
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `nat_gateway_ip` - Elastic IP of the NAT Gateway
- `internet_gateway_id` - ID of the Internet Gateway