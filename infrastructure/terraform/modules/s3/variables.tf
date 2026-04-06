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

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS configuration"
  type        = list(string)
  default     = ["https://*.contractorlens.app", "http://localhost:3000"]
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution for S3 bucket policy"
  type        = string
}