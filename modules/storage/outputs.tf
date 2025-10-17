output "data_bucket_id" {
  description = "Data S3 bucket ID"
  value       = aws_s3_bucket.data.id
}

output "data_bucket_name" {
  description = "Data S3 bucket name"
  value       = aws_s3_bucket.data.bucket
}

output "data_bucket_arn" {
  description = "Data S3 bucket ARN"
  value       = aws_s3_bucket.data.arn
}

output "analytics_results_bucket_id" {
  description = "Analytics results S3 bucket ID"
  value       = aws_s3_bucket.analytics_results.id
}

output "analytics_results_bucket_name" {
  description = "Analytics results S3 bucket name"
  value       = aws_s3_bucket.analytics_results.bucket
}

output "analytics_results_bucket_arn" {
  description = "Analytics results S3 bucket ARN"
  value       = aws_s3_bucket.analytics_results.arn
}

output "logs_bucket_id" {
  description = "Logs S3 bucket ID"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_name" {
  description = "Logs S3 bucket name"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "Logs S3 bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

output "s3_bucket_names" {
  description = "List of all S3 bucket names"
  value = [
    aws_s3_bucket.data.bucket,
    aws_s3_bucket.analytics_results.bucket,
    aws_s3_bucket.logs.bucket
  ]
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.main.id
}

output "efs_file_system_arn" {
  description = "EFS file system ARN"
  value       = aws_efs_file_system.main.arn
}

output "efs_file_system_dns_name" {
  description = "EFS file system DNS name"
  value       = aws_efs_file_system.main.dns_name
}

output "efs_mount_target_ids" {
  description = "EFS mount target IDs"
  value       = aws_efs_mount_target.main[*].id
}

output "efs_access_point_shiny_apps_id" {
  description = "EFS access point ID for Shiny apps"
  value       = aws_efs_access_point.shiny_apps.id
}

output "efs_access_point_rstudio_home_id" {
  description = "EFS access point ID for RStudio home"
  value       = aws_efs_access_point.rstudio_home.id
}

output "efs_access_point_shared_data_id" {
  description = "EFS access point ID for shared data"
  value       = aws_efs_access_point.shared_data.id
}

output "s3_kms_key_id" {
  description = "S3 KMS key ID"
  value       = aws_kms_key.s3.key_id
}

output "s3_kms_key_arn" {
  description = "S3 KMS key ARN"
  value       = aws_kms_key.s3.arn
}

output "efs_kms_key_id" {
  description = "EFS KMS key ID"
  value       = aws_kms_key.efs.key_id
}

output "efs_kms_key_arn" {
  description = "EFS KMS key ARN"
  value       = aws_kms_key.efs.arn
}