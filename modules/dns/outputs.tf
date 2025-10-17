output "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "shiny_record_name" {
  description = "Shiny DNS record name"
  value       = aws_route53_record.shiny.name
}

output "rstudio_record_name" {
  description = "RStudio DNS record name"
  value       = aws_route53_record.rstudio.name
}

output "shiny_health_check_id" {
  description = "Shiny health check ID"
  value       = aws_route53_health_check.shiny.id
}

output "rstudio_health_check_id" {
  description = "RStudio health check ID"
  value       = aws_route53_health_check.rstudio.id
}