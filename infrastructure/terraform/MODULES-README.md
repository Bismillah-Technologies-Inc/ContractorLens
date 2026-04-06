# S3 and CloudFront Modules for ContractorLens

## Overview
Terraform modules for managing S3 buckets and CloudFront distributions for the ContractorLens application.

## S3 Module (`/modules/s3/`)

### Features
- **Scan Images Bucket**: Versioned, encrypted storage with lifecycle rules (transition to Glacier after 90 days)
- **PDF Exports Bucket**: Versioned, encrypted storage with automatic deletion after 1 year
- **Frontend Assets Bucket**: Static website hosting for client portal and admin dashboard
- **Security**: Block public access, CORS configuration, encryption at rest
- **IAM Policy**: Dedicated policy for ECS task access to S3 resources
- **Inventory Configuration**: Weekly S3 inventory reports

### Usage
```hcl
module "s3" {
  source = "./modules/s3"
  
  project_name  = var.project_name
  environment   = var.environment
  common_tags   = var.common_tags
  cors_allowed_origins = var.cors_allowed_origins
  cloudfront_distribution_arn = module.cloudfront.frontend_distribution_arn
}
```

## CloudFront Module (`/modules/cloudfront/`)

### Features
- **Frontend CDN**: Distribution for client portal/admin dashboard with static hosting
- **Assets CDN**: Private distribution for scan images and PDFs with Origin Access Identity
- **Optimization**: Caching policies for different content types (images, PDFs, static assets)
- **Security**: HTTPS with modern TLS, optional WAF integration
- **Monitoring**: Logging to S3 with configurable prefixes
- **Error Handling**: Custom error responses (404, 503)

### Usage
```hcl
module "cloudfront" {
  source = "./modules/cloudfront"
  
  project_name  = var.project_name
  environment   = var.environment
  common_tags   = var.common_tags
  frontend_bucket_domain_name = module.s3.frontend_assets_website_endpoint
  assets_bucket_domain_name   = module.s3.scan_images_bucket_domain_name
  logging_bucket_domain_name  = aws_s3_bucket.cloudfront_logs.bucket_regional_domain_name
  price_class                 = var.price_class
  enable_waf                  = var.enable_waf
}
```

## Integration

### ECS Task Access
The S3 module creates an IAM policy (`s3_access_policy_arn`) that grants ECS tasks:
- Read/write access to scan images bucket
- Read/write access to PDF exports bucket
- List bucket permissions

### CloudFront Origin Access
S3 bucket policies are configured to allow CloudFront distributions:
- Frontend bucket: Allows CloudFront read access for static website
- Scan images bucket: Private access via Origin Access Identity
- PDF exports bucket: Private access via Origin Access Identity

### Environment Variables
ECS tasks receive these S3/CloudFront details:
- `S3_SCAN_IMAGES_BUCKET`: Name of scan images bucket
- `S3_PDF_EXPORTS_BUCKET`: Name of PDF exports bucket
- `CLOUDFRONT_ASSETS_URL`: Assets CDN domain name
- `CLOUDFRONT_FRONTEND_URL`: Frontend CDN domain name

## Configuration

### Required Variables
```hcl
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}
```

### Security Settings
- **Versioning**: Enabled on all buckets for data protection
- **Encryption**: AES256 server-side encryption on all buckets
- **Public Access**: Blocked on data buckets, selectively allowed on frontend
- **CORS**: Configurable origins for iOS app uploads
- **WAF**: Optional AWS Managed Rules for production

### Lifecycle Management
- Scan images: Transition to Glacier after 90 days
- PDF exports: Automatic deletion after 365 days
- CloudFront logs: 30-day retention in S3

## Outputs

### S3 Module
- `scan_images_bucket_name` - Name of scan images bucket
- `pdf_exports_bucket_name` - Name of PDF exports bucket
- `frontend_assets_bucket_name` - Name of frontend assets bucket
- `s3_access_policy_arn` - IAM policy ARN for ECS task access

### CloudFront Module
- `frontend_distribution_domain_name` - Frontend CDN URL
- `assets_distribution_domain_name` - Assets CDN URL
- `assets_origin_access_identity_path` - OAI path for private access
- `frontend_waf_web_acl_arn` - WAF ACL ARN (if enabled)