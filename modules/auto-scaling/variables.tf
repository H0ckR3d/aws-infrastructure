variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "shiny_target_group_arn" {
  description = "Shiny target group ARN"
  type        = string
}

variable "rstudio_target_group_arn" {
  description = "RStudio target group ARN"
  type        = string
}

variable "shiny_instance_type" {
  description = "EC2 instance type for Shiny servers"
  type        = string
}

variable "rstudio_instance_type" {
  description = "EC2 instance type for RStudio servers"
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_capacity" {
  description = "Maximum number of instances"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

variable "efs_file_system_id" {
  description = "EFS file system ID"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for data access"
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