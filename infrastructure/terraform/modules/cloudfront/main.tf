# CloudFront Module for ContractorLens
# Contains CDN distributions for frontend and asset delivery

# Frontend CDN Distribution
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "ContractorLens Frontend CDN"
  default_root_object = "index.html"
  price_class         = var.price_class

  origin {
    domain_name = var.frontend_bucket_domain_name
    origin_id   = "S3-Frontend-${var.project_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend-${var.project_name}"

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
    compress               = true
  }

  # Assets path for client portal and admin dashboard
  ordered_cache_behavior {
    path_pattern     = "/admin/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend-${var.project_name}"

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
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  logging_config {
    include_cookies = false
    bucket          = var.logging_bucket_domain_name
    prefix          = "frontend-cdn/"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-frontend-cdn"
    Type = "CDN"
  })
}

# Assets CDN Distribution (Private with OAI/OAC)
resource "aws_cloudfront_distribution" "assets" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "ContractorLens Assets CDN - Scan images and PDFs"
  price_class     = var.price_class

  origin {
    domain_name = var.assets_bucket_domain_name
    origin_id   = "S3-Assets-${var.project_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.assets.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Assets-${var.project_name}"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  # Caching for images
  ordered_cache_behavior {
    path_pattern     = "*.jpg"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Assets-${var.project_name}"

    forwarded_values {
      query_string = false
      headers = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern     = "*.png"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Assets-${var.project_name}"

    forwarded_values {
      query_string = false
      headers = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  # Caching for PDFs
  ordered_cache_behavior {
    path_pattern     = "*.pdf"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Assets-${var.project_name}"

    forwarded_values {
      query_string = false
      headers = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }

  custom_error_response {
    error_code         = 503
    response_code      = 503
    response_page_path = "/error.html"
  }

  logging_config {
    include_cookies = false
    bucket          = var.logging_bucket_domain_name
    prefix          = "assets-cdn/"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-assets-cdn"
    Type = "CDN"
  })
}

# Origin Access Identity for private assets
resource "aws_cloudfront_origin_access_identity" "assets" {
  comment = "Access identity for ContractorLens assets bucket"
}

# WAF Web ACL for Production (optional)
resource "aws_wafv2_web_acl" "frontend" {
  count       = var.enable_waf ? 1 : 0
  name        = "${var.project_name}-frontend-webacl-${var.environment}"
  description = "Web ACL for frontend CDN"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-frontend-webacl-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-frontend-webacl-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-frontend-webacl"
    sampled_requests_enabled   = true
  }

  tags = var.common_tags
}

resource "aws_wafv2_web_acl_association" "frontend" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_cloudfront_distribution.frontend.arn
  web_acl_arn  = aws_wafv2_web_acl.frontend[0].arn
}