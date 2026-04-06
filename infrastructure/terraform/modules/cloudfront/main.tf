# CloudFront CDN Module

# CloudFront distribution for frontend assets
resource "aws_cloudfront_distribution" "frontend_assets" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # US, Canada, Europe

  origin {
    domain_name = var.frontend_assets_bucket_regional_domain_name
    origin_id   = "S3-${var.frontend_assets_bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend_oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${var.frontend_assets_bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == ""
    
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = var.certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = var.domain_name != "" ? [var.domain_name] : []

  tags = {
    Name        = "${var.name}-cf-frontend"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Origin Access Identity for frontend assets
resource "aws_cloudfront_origin_access_identity" "frontend_oai" {
  comment = "OAI for ${var.frontend_assets_bucket_name}"
}

# Bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "frontend_assets" {
  bucket = var.frontend_assets_bucket_name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend_oai.iam_arn
        }
        Action = "s3:GetObject"
        Resource = "${var.frontend_assets_bucket_name}/*"
      }
    ]
  })
}