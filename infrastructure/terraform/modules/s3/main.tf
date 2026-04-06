# S3 Module for ContractorLens

# Scan images bucket
resource "aws_s3_bucket" "scan_images" {
  bucket = "${var.name}-scan-images"

  tags = {
    Name        = "${var.name}-scan-images"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "scan-images"
  }
}

# Enable versioning for scan images bucket
resource "aws_s3_bucket_versioning" "scan_images" {
  count = var.enable_versioning ? 1 : 0
  
  bucket = aws_s3_bucket.scan_images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for scan images bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "scan_images" {
  bucket = aws_s3_bucket.scan_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# PDF exports bucket
resource "aws_s3_bucket" "pdf_exports" {
  bucket = "${var.name}-pdf-exports"

  tags = {
    Name        = "${var.name}-pdf-exports"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "pdf-exports"
  }
}

# Enable versioning for PDF exports bucket
resource "aws_s3_bucket_versioning" "pdf_exports" {
  count = var.enable_versioning ? 1 : 0
  
  bucket = aws_s3_bucket.pdf_exports.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for PDF exports bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Frontend assets bucket
resource "aws_s3_bucket" "frontend_assets" {
  bucket = "${var.name}-frontend-assets"

  tags = {
    Name        = "${var.name}-frontend-assets"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Purpose     = "frontend-assets"
  }
}

# Enable versioning for frontend assets bucket
resource "aws_s3_bucket_versioning" "frontend_assets" {
  count = var.enable_versioning ? 1 : 0
  
  bucket = aws_s3_bucket.frontend_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for frontend assets bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_assets" {
  bucket = aws_s3_bucket.frontend_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access block to restrict public access
resource "aws_s3_bucket_public_access_block" "scan_images" {
  bucket = aws_s3_bucket.scan_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "pdf_exports" {
  bucket = aws_s3_bucket.pdf_exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "frontend_assets" {
  bucket = aws_s3_bucket.frontend_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}