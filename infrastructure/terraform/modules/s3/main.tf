# S3 Buckets Module for ContractorLens
# Contains buckets for scan images, PDF exports, and frontend assets

# Scan Images Bucket
resource "aws_s3_bucket" "scan_images" {
  bucket = "${var.project_name}-scan-images-${var.environment}"
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-scan-images"
    Type = "Storage"
  })
}

resource "aws_s3_bucket_versioning" "scan_images" {
  bucket = aws_s3_bucket.scan_images.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scan_images" {
  bucket = aws_s3_bucket.scan_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "scan_images" {
  bucket = aws_s3_bucket.scan_images.id

  rule {
    id = "transition-to-glacier"
    status = "Enabled"
    
    filter {
      prefix = "scans/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class = "GLACIER"
    }
    
    expiration {
      days = 730
    }
  }
}

resource "aws_s3_bucket_public_access_block" "scan_images" {
  bucket = aws_s3_bucket.scan_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "scan_images" {
  bucket = aws_s3_bucket.scan_images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag", "x-amz-server-side-encryption", "x-amz-request-id"]
    max_age_seconds = 3000
  }
}

# PDF Exports Bucket
resource "aws_s3_bucket" "pdf_exports" {
  bucket = "${var.project_name}-pdf-exports-${var.environment}"
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-pdf-exports"
    Type = "Storage"
  })
}

resource "aws_s3_bucket_versioning" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id

  rule {
    id = "delete-after-1-year"
    status = "Enabled"
    
    filter {
      prefix = "exports/"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Frontend Assets Bucket (Static Website Hosting)
resource "aws_s3_bucket" "frontend_assets" {
  bucket = "${var.project_name}-frontend-${var.environment}"
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-frontend"
    Type = "Website"
  })
}

resource "aws_s3_bucket_public_access_block" "frontend_assets" {
  bucket = aws_s3_bucket.frontend_assets.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend_assets" {
  bucket = aws_s3_bucket.frontend_assets.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "admin/"
    }
    redirect {
      replace_key_prefix_with = "admin.html"
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_assets_cloudfront" {
  bucket = aws_s3_bucket.frontend_assets.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CloudFrontReadAccess"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

# IAM Policy for ECS Task to access S3 buckets
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-s3-access-${var.environment}"
  description = "Policy for ECS tasks to access S3 buckets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ScanImagesAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.scan_images.arn,
          "${aws_s3_bucket.scan_images.arn}/*"
        ]
      },
      {
        Sid    = "PDFExportsAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.pdf_exports.arn,
          "${aws_s3_bucket.pdf_exports.arn}/*"
        ]
      }
    ]
  })
}

# S3 Bucket Inventory Configuration
resource "aws_s3_bucket_inventory" "scan_images_inventory" {
  bucket = aws_s3_bucket.scan_images.id
  name   = "AllObjects"

  included_object_versions = "All"

  schedule {
    frequency = "Weekly"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.scan_images.arn
      prefix     = "inventory/"
    }
  }
}