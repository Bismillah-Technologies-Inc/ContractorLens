# S3 Module Outputs
output "scan_images_bucket_name" {
  description = "Name of the scan images bucket"
  value       = aws_s3_bucket.scan_images.id
}

output "pdf_exports_bucket_name" {
  description = "Name of the PDF exports bucket"
  value       = aws_s3_bucket.pdf_exports.id
}

output "frontend_assets_bucket_name" {
  description = "Name of the frontend assets bucket"
  value       = aws_s3_bucket.frontend_assets.id
}

output "scan_images_bucket_regional_domain_name" {
  description = "Regional domain name of the scan images bucket"
  value       = aws_s3_bucket.scan_images.bucket_regional_domain_name
}

output "pdf_exports_bucket_regional_domain_name" {
  description = "Regional domain name of the PDF exports bucket"
  value       = aws_s3_bucket.pdf_exports.bucket_regional_domain_name
}

output "frontend_assets_bucket_regional_domain_name" {
  description = "Regional domain name of the frontend assets bucket"
  value       = aws_s3_bucket.frontend_assets.bucket_regional_domain_name
}