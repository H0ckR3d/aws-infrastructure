# General Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "analytics-platform"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "devops-team"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "example.com"
}

variable "shiny_subdomain" {
  description = "Subdomain for Shiny applications"
  type        = string
  default     = "shiny"
}

variable "rstudio_subdomain" {
  description = "Subdomain for RStudio"
  type        = string
  default     = "rstudio"
}

# Compute Configuration
variable "shiny_instance_type" {
  description = "EC2 instance type for Shiny servers"
  type        = string
  default     = "t3.medium"
}

variable "rstudio_instance_type" {
  description = "EC2 instance type for RStudio servers"
  type        = string
  default     = "t3.large"
}

variable "min_capacity" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 10
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

# Security Configuration
variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty"
  type        = bool
  default     = true
}

variable "enable_shield_advanced" {
  description = "Enable AWS Shield Advanced"
  type        = bool
  default     = false
}

# Storage Configuration
variable "efs_performance_mode" {
  description = "EFS performance mode"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "EFS throughput mode"
  type        = string
  default     = "provisioned"
}

variable "efs_provisioned_throughput" {
  description = "EFS provisioned throughput in MiB/s"
  type        = number
  default     = 500
}

# Transfer Family Configuration
variable "sftp_users" {
  description = "List of SFTP users"
  type = list(object({
    username   = string
    public_key = string
    home_dir   = string
  }))
  default = []
}

# Development Testing Configuration
variable "enable_debug_logging" {
  description = "Enable debug logging for development environment"
  type        = bool
  default     = true
}