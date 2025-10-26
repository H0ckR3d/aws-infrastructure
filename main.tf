# Data sources for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  # Common tags for all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CreatedBy   = "dev-branch-test" # Added for branch testing
  }

  # Naming convention for consistent resource names
  name_prefix = "${var.project_name}-${var.environment}"

  # Account and region info from data sources
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Development specific configurations
  is_development = var.environment == "dev"
  debug_enabled  = var.enable_debug_logging && local.is_development
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  vpc_id                 = module.networking.vpc_id
  enable_waf             = var.enable_waf
  enable_guardduty       = var.enable_guardduty
  enable_shield_advanced = var.enable_shield_advanced

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  depends_on = [module.networking]
}

# Load Balancers Module
module "load_balancers" {
  source = "./modules/load-balancers"

  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  certificate_arn   = module.certificates.shiny_certificate_arn

  shiny_subdomain   = var.shiny_subdomain
  rstudio_subdomain = var.rstudio_subdomain
  domain_name       = var.domain_name

  waf_web_acl_arn = var.enable_waf ? module.security.waf_web_acl_arn : null

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  depends_on = [module.networking]
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  performance_mode       = var.efs_performance_mode
  throughput_mode        = var.efs_throughput_mode
  provisioned_throughput = var.efs_provisioned_throughput

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  depends_on = [module.networking]
}

# ECS Cluster Module - Container orchestration for Shiny and RStudio
module "ecs" {
  source = "./modules/ecs"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  alb_target_group_arns = [
    module.load_balancers.shiny_target_group_arn
  ]

  efs_file_system_id  = module.storage.efs_file_system_id
  efs_access_point_id = module.storage.efs_access_point_shiny_apps_id

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  depends_on = [module.networking, module.storage, module.load_balancers]
}

# Auto Scaling Groups Module
module "auto_scaling" {
  source = "./modules/auto-scaling"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  shiny_target_group_arn   = module.load_balancers.shiny_target_group_arn
  rstudio_target_group_arn = module.load_balancers.rstudio_target_group_arn

  shiny_instance_type   = var.shiny_instance_type
  rstudio_instance_type = var.rstudio_instance_type

  min_capacity     = var.min_capacity
  max_capacity     = var.max_capacity
  desired_capacity = var.desired_capacity

  efs_file_system_id = module.storage.efs_file_system_id
  s3_bucket_name     = module.storage.data_bucket_name

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  depends_on = [module.networking, module.load_balancers, module.storage]
}

# Transfer Family Module
module "transfer" {
  source = "./modules/transfer"

  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.private_subnet_ids
  s3_bucket_name = module.storage.data_bucket_name

  sftp_users = var.sftp_users

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  depends_on = [module.networking, module.storage]
}

# Certificates Module
module "certificates" {
  source = "./modules/certificates"

  domain_name       = var.domain_name
  shiny_subdomain   = var.shiny_subdomain
  rstudio_subdomain = var.rstudio_subdomain

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

# DNS Module
module "dns" {
  source = "./modules/dns"

  domain_name = var.domain_name

  shiny_subdomain   = var.shiny_subdomain
  rstudio_subdomain = var.rstudio_subdomain

  shiny_alb_dns_name   = module.load_balancers.shiny_alb_dns_name
  shiny_alb_zone_id    = module.load_balancers.shiny_alb_zone_id
  rstudio_alb_dns_name = module.load_balancers.rstudio_alb_dns_name
  rstudio_alb_zone_id  = module.load_balancers.rstudio_alb_zone_id

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  depends_on = [module.load_balancers]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  vpc_id           = module.networking.vpc_id
  ecs_cluster_name = module.ecs.cluster_name

  shiny_alb_arn   = module.load_balancers.shiny_alb_arn
  rstudio_alb_arn = module.load_balancers.rstudio_alb_arn

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  depends_on = [module.ecs, module.load_balancers]
}