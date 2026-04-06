# S3 Module

This module creates S3 buckets for different application purposes.

## Features

- **Scan Images Bucket**: For room scan image uploads from iOS app
- **PDF Exports Bucket**: For generated estimate PDF storage
- **Frontend Assets Bucket**: For client portal and admin dashboard static files
- Versioning enabled for all buckets
- Server-side encryption (AES256)
- Lifecycle rules for cost optimization
- CORS configuration for web and mobile access
- Bucket policies and access controls
- Block public access enabled by default

## Usage

```hcl
module "s3" {
  source = "./modules/s3"
  
  environment               = "production"
  project_name              = "contractorlens"
  enable_scan_images_bucket = true
  enable_pdf_exports_bucket = true
  enable_frontend_assets    = true
  enable_versioning         = true
  enable_encryption         = true
}
```

## Outputs

- `scan_images_bucket_name` - Name of the scan images bucket
- `pdf_exports_bucket_name` - Name of the PDF exports bucket
- `frontend_assets_bucket_name` - Name of the frontend assets bucket
- `bucket_arns` - ARNs of all created buckets
- `bucket_domain_names` - Domain names of all buckets