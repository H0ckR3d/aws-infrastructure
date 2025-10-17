output "shiny_alb_id" {
  description = "Shiny ALB ID"
  value       = aws_lb.shiny.id
}

output "shiny_alb_arn" {
  description = "Shiny ALB ARN"
  value       = aws_lb.shiny.arn
}

output "shiny_alb_dns_name" {
  description = "Shiny ALB DNS name"
  value       = aws_lb.shiny.dns_name
}

output "shiny_alb_zone_id" {
  description = "Shiny ALB Zone ID"
  value       = aws_lb.shiny.zone_id
}

output "rstudio_alb_id" {
  description = "RStudio ALB ID"
  value       = aws_lb.rstudio.id
}

output "rstudio_alb_arn" {
  description = "RStudio ALB ARN"
  value       = aws_lb.rstudio.arn
}

output "rstudio_alb_dns_name" {
  description = "RStudio ALB DNS name"
  value       = aws_lb.rstudio.dns_name
}

output "rstudio_alb_zone_id" {
  description = "RStudio ALB Zone ID"
  value       = aws_lb.rstudio.zone_id
}

output "shiny_target_group_id" {
  description = "Shiny target group ID"
  value       = aws_lb_target_group.shiny.id
}

output "shiny_target_group_arn" {
  description = "Shiny target group ARN"
  value       = aws_lb_target_group.shiny.arn
}

output "rstudio_target_group_id" {
  description = "RStudio target group ID"
  value       = aws_lb_target_group.rstudio.id
}

output "rstudio_target_group_arn" {
  description = "RStudio target group ARN"
  value       = aws_lb_target_group.rstudio.arn
}

output "alb_logs_bucket_name" {
  description = "ALB access logs S3 bucket name"
  value       = aws_s3_bucket.alb_logs.bucket
}