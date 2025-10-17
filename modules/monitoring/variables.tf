variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "shiny_alb_arn" {
  description = "Shiny ALB ARN"
  type        = string
}

variable "rstudio_alb_arn" {
  description = "RStudio ALB ARN"
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