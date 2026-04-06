# S3 bucket for PDF storage + scan images
resource "aws_s3_bucket" "contractorlens_assets" {
  bucket = "contractorlens-assets-${var.environment}"
}

resource "aws_s3_bucket_versioning" "contractorlens_assets" {
  bucket = aws_s3_bucket.contractorlens_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "contractorlens_assets" {
  bucket = aws_s3_bucket.contractorlens_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "contractorlens_assets" {
  bucket                  = aws_s3_bucket.contractorlens_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM policy for ECS task to access S3
resource "aws_iam_policy" "ecs_s3_policy" {
  name = "contractorlens-ecs-s3-${var.environment}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:GetObjectUrl"]
        Resource = "${aws_s3_bucket.contractorlens_assets.arn}/*"
      },
      {
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = aws_s3_bucket.contractorlens_assets.arn
      }
    ]
  })
}
