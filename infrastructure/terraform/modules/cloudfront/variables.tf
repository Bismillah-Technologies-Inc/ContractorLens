# CloudFront Module Variables
variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "scan_images_bucket_name" {
  description = "Scan images S3 bucket name"
  type        = string
}

variable "pdf_exports_bucket_name" {
  description = "PDF exports S3 bucket name"
  type        = string
}

variable "frontend_assets_bucket_name" {
  description = "Frontend assets S3 bucket name"
  type        = string
}

variable "scan_images_bucket_regional_domain_name" {
  description = "Scan images bucket regional domain name"
  type        = string
}

variable "pdf_exports_bucket_regional_domain_name" {
  description = "PDF exports bucket regional domain name"
  type        = string
}

variable "frontend_assets_bucket_regional_domain_name" {
  description = "Frontend assets bucket regional domain name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Enable WAF for CloudFront distributions"
  type        = bool
  default     = false
}