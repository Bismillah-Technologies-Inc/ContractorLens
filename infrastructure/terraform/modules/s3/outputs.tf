output "scan_images_bucket_name" {
  description = "Name of the scan images bucket"
  value       = aws_s3_bucket.scan_images.id
}

output "scan_images_bucket_arn" {
  description = "ARN of the scan images bucket"
  value       = aws_s3_bucket.scan_images.arn
}

output "scan_images_bucket_domain_name" {
  description = "Regional domain name of the scan images bucket"
  value       = aws_s3_bucket.scan_images.bucket_regional_domain_name
}

output "pdf_exports_bucket_name" {
  description = "Name of the PDF exports bucket"
  value       = aws_s3_bucket.pdf_exports.id
}

output "pdf_exports_bucket_arn" {
  description = "ARN of the PDF exports bucket"
  value       = aws_s3_bucket.pdf_exports.arn
}

output "pdf_exports_bucket_domain_name" {
  description = "Regional domain name of the PDF exports bucket"
  value       = aws_s3_bucket.pdf_exports.bucket_regional_domain_name
}

output "frontend_assets_bucket_name" {
  description = "Name of the frontend assets bucket"
  value       = aws_s3_bucket.frontend_assets.id
}

output "frontend_assets_bucket_arn" {
  description = "ARN of the frontend assets bucket"
  value       = aws_s3_bucket.frontend_assets.arn
}

output "frontend_assets_website_endpoint" {
  description = "Website endpoint for frontend assets bucket"
  value       = aws_s3_bucket_website_configuration.frontend_assets.website_endpoint
}

output "s3_access_policy_arn" {
  description = "ARN of the S3 access policy for ECS tasks"
  value       = aws_iam_policy.s3_access.arn
}