# CloudFront OAC for private S3 access
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "contractorlens-s3-oac-${var.environment}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "assets" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "ContractorLens Assets CDN (${var.environment})"
  default_root_object = "index.html"
  price_class         = var.environment == "prod" ? "PriceClass_100" : "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.contractorlens_assets.bucket_regional_domain_name
    origin_id                = "S3-contractorlens-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-contractorlens-assets"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized managed policy
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# S3 bucket policy to allow CloudFront OAC
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.contractorlens_assets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.contractorlens_assets.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.assets.arn
        }
      }
    }]
  })
}
