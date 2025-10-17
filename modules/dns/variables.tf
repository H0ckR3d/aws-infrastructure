variable "domain_name" {
  description = "The domain name"
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

variable "shiny_alb_dns_name" {
  description = "Shiny ALB DNS name"
  type        = string
}

variable "shiny_alb_zone_id" {
  description = "Shiny ALB zone ID"
  type        = string
}

variable "rstudio_alb_dns_name" {
  description = "RStudio ALB DNS name"
  type        = string
}

variable "rstudio_alb_zone_id" {
  description = "RStudio ALB zone ID"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}