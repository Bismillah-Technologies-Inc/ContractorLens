# CloudFront Module

This module creates CloudFront distributions for content delivery.

## Features

- **Frontend Distribution**: For client portal and admin dashboard
- **Assets Distribution**: For static assets and CDN
- Custom domain configuration with ACM certificates
- WAF integration for security
- Geographic restrictions
- Origin access control (OAC/OAI)
- Cache policies and behaviors
- Logging enabled to S3 bucket
- Price class optimized (US, Canada, Europe)

## Usage

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"
  
  environment               = "production"
  project_name              = "contractorlens"
  domain_name               = "contractorlens.com"
  certificate_arn           = var.certificate_arn
  frontend_s3_bucket_name   = module.s3.frontend_assets_bucket_name
  assets_s3_bucket_name     = module.s3.static_assets_bucket_name
  enable_waf                = true
  price_class               = "PriceClass_100" # US, Canada, Europe
}
```

## Outputs

- `frontend_distribution_id` - CloudFront distribution ID for frontend
- `assets_distribution_id` - CloudFront distribution ID for assets
- `frontend_distribution_domain` - Domain name for frontend distribution
- `assets_distribution_domain` - Domain name for assets distribution
- `cloudfront_distribution_urls` - Map of all distribution URLs