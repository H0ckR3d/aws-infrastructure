output "shiny_certificate_arn" {
  description = "ARN of the validated Shiny certificate"
  value       = aws_acm_certificate_validation.shiny.certificate_arn
}

output "rstudio_certificate_arn" {
  description = "ARN of the validated RStudio certificate"
  value       = aws_acm_certificate_validation.rstudio.certificate_arn
}

output "wildcard_certificate_arn" {
  description = "ARN of the validated wildcard certificate"
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}

output "shiny_certificate_domain_name" {
  description = "Domain name of the Shiny certificate"
  value       = aws_acm_certificate.shiny.domain_name
}

output "rstudio_certificate_domain_name" {
  description = "Domain name of the RStudio certificate"
  value       = aws_acm_certificate.rstudio.domain_name
}

output "wildcard_certificate_domain_name" {
  description = "Domain name of the wildcard certificate"
  value       = aws_acm_certificate.wildcard.domain_name
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}