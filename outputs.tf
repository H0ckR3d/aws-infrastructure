# Network Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.networking.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.networking.nat_gateway_ids
}

# Load Balancer Outputs
output "shiny_alb_dns_name" {
  description = "Shiny Application Load Balancer DNS name"
  value       = module.load_balancers.shiny_alb_dns_name
}

output "rstudio_alb_dns_name" {
  description = "RStudio Application Load Balancer DNS name"
  value       = module.load_balancers.rstudio_alb_dns_name
}

output "shiny_alb_zone_id" {
  description = "Shiny Application Load Balancer Zone ID"
  value       = module.load_balancers.shiny_alb_zone_id
}

output "rstudio_alb_zone_id" {
  description = "RStudio Application Load Balancer Zone ID"
  value       = module.load_balancers.rstudio_alb_zone_id
}

# Storage Outputs
output "s3_bucket_names" {
  description = "S3 bucket names"
  value       = module.storage.s3_bucket_names
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = module.storage.efs_file_system_id
}

output "efs_file_system_dns_name" {
  description = "EFS file system DNS name"
  value       = module.storage.efs_file_system_dns_name
}

# Security Outputs
output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = var.enable_waf ? module.security.waf_web_acl_id : null
}

output "guardduty_detector_id" {
  description = "GuardDuty Detector ID"
  value       = var.enable_guardduty ? module.security.guardduty_detector_id : null
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

# Transfer Family Outputs
output "sftp_server_id" {
  description = "Transfer Family SFTP server ID"
  value       = module.transfer.sftp_server_id
}

output "sftp_endpoint" {
  description = "Transfer Family SFTP endpoint"
  value       = module.transfer.sftp_endpoint
}

# DNS Outputs
output "shiny_fqdn" {
  description = "Shiny application FQDN"
  value       = "${var.shiny_subdomain}.${var.domain_name}"
}

output "rstudio_fqdn" {
  description = "RStudio application FQDN"
  value       = "${var.rstudio_subdomain}.${var.domain_name}"
}