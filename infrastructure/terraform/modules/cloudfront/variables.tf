variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "frontend_bucket_domain_name" {
  description = "Domain name of the frontend S3 bucket"
  type        = string
}

variable "assets_bucket_domain_name" {
  description = "Domain name of the assets S3 bucket"
  type        = string
}

variable "logging_bucket_domain_name" {
  description = "Domain name of the S3 bucket for CloudFront logs"
  type        = string
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"
}

variable "enable_waf" {
  description = "Enable WAF web ACL for CloudFront distributions"
  type        = bool
  default     = false
}