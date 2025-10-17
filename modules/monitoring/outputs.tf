output "dashboard_arn" {
  description = "CloudWatch dashboard ARN"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alarms" {
  description = "List of CloudWatch alarm names"
  value = [
    aws_cloudwatch_metric_alarm.shiny_high_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.rstudio_high_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.shiny_high_4xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.ecs_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.vpc_flow_rejected.alarm_name
  ]
}