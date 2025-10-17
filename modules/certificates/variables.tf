variable "domain_name" {
  description = "The domain name for certificates"
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

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}