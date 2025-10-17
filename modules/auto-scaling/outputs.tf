output "shiny_asg_id" {
  description = "Shiny Auto Scaling Group ID"
  value       = aws_autoscaling_group.shiny.id
}

output "shiny_asg_arn" {
  description = "Shiny Auto Scaling Group ARN"
  value       = aws_autoscaling_group.shiny.arn
}

output "rstudio_asg_id" {
  description = "RStudio Auto Scaling Group ID"
  value       = aws_autoscaling_group.rstudio.id
}

output "rstudio_asg_arn" {
  description = "RStudio Auto Scaling Group ARN"
  value       = aws_autoscaling_group.rstudio.arn
}

output "shiny_launch_template_id" {
  description = "Shiny launch template ID"
  value       = aws_launch_template.shiny.id
}

output "rstudio_launch_template_id" {
  description = "RStudio launch template ID"
  value       = aws_launch_template.rstudio.id
}