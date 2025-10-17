variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}

variable "shiny_subdomain" {
  description = "Subdomain for Shiny applications"
  type        = string
}

variable "rstudio_subdomain" {
  description = "Subdomain for RStudio"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}