output "frontend_distribution_id" {
  description = "ID of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "frontend_distribution_arn" {
  description = "ARN of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "frontend_distribution_domain_name" {
  description = "Domain name of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "assets_distribution_id" {
  description = "ID of the assets CloudFront distribution"
  value       = aws_cloudfront_distribution.assets.id
}

output "assets_distribution_arn" {
  description = "ARN of the assets CloudFront distribution"
  value       = aws_cloudfront_distribution.assets.arn
}

output "assets_distribution_domain_name" {
  description = "Domain name of the assets CloudFront distribution"
  value       = aws_cloudfront_distribution.assets.domain_name
}

output "assets_origin_access_identity_iam_arn" {
  description = "IAM ARN of the origin access identity for assets bucket"
  value       = aws_cloudfront_origin_access_identity.assets.iam_arn
}

output "assets_origin_access_identity_path" {
  description = "Path of the origin access identity for assets bucket"
  value       = aws_cloudfront_origin_access_identity.assets.cloudfront_access_identity_path
}

output "frontend_waf_web_acl_arn" {
  description = "ARN of the WAF web ACL for frontend distribution"
  value       = var.enable_waf ? aws_wafv2_web_acl.frontend[0].arn : null
}