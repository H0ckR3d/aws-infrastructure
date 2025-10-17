# CloudWatch Dashboard for Infrastructure Monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-infrastructure"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", basename(var.shiny_alb_arn)],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Shiny ALB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", basename(var.rstudio_alb_arn)],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "RStudio ALB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.name_prefix}-shiny-service", "ClusterName", var.ecs_cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "ECS Service Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarms

# High ALB Response Time Alarm for Shiny
resource "aws_cloudwatch_metric_alarm" "shiny_high_response_time" {
  alarm_name                = "${var.name_prefix}-shiny-high-response-time"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "TargetResponseTime"
  namespace                 = "AWS/ApplicationELB"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "2"
  alarm_description         = "This metric monitors Shiny ALB response time"
  insufficient_data_actions = []

  dimensions = {
    LoadBalancer = basename(var.shiny_alb_arn)
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-shiny-response-time-alarm"
    Application = "Shiny"
  })
}

# High ALB Response Time Alarm for RStudio
resource "aws_cloudwatch_metric_alarm" "rstudio_high_response_time" {
  alarm_name                = "${var.name_prefix}-rstudio-high-response-time"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "TargetResponseTime"
  namespace                 = "AWS/ApplicationELB"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "3"
  alarm_description         = "This metric monitors RStudio ALB response time"
  insufficient_data_actions = []

  dimensions = {
    LoadBalancer = basename(var.rstudio_alb_arn)
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-rstudio-response-time-alarm"
    Application = "RStudio"
  })
}

# High Error Rate Alarm for Shiny
resource "aws_cloudwatch_metric_alarm" "shiny_high_4xx_errors" {
  alarm_name          = "${var.name_prefix}-shiny-high-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors Shiny ALB 4XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = basename(var.shiny_alb_arn)
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-shiny-4xx-errors-alarm"
    Application = "Shiny"
  })
}

# High ECS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.name_prefix}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"

  dimensions = {
    ServiceName = "${var.name_prefix}-shiny-service"
    ClusterName = var.ecs_cluster_name
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ecs-high-cpu-alarm"
    Type = "ECS"
  })
}

# VPC Flow Logs Monitoring
resource "aws_cloudwatch_log_metric_filter" "vpc_flow_rejected" {
  name           = "${var.name_prefix}-vpc-flow-rejected"
  log_group_name = "/aws/vpc/flowlogs/${var.name_prefix}"
  pattern        = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action=\"REJECT\", flowlogstatus]"

  metric_transformation {
    name      = "VPCFlowLogsRejected"
    namespace = "${var.name_prefix}/VPC"
    value     = "1"
  }
}

# Alarm for high number of rejected connections
resource "aws_cloudwatch_metric_alarm" "vpc_flow_rejected" {
  alarm_name          = "${var.name_prefix}-vpc-flow-rejected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "VPCFlowLogsRejected"
  namespace           = "${var.name_prefix}/VPC"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "High number of rejected connections in VPC"
  treat_missing_data  = "notBreaching"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc-rejected-connections-alarm"
    Type = "Security"
  })
}

# Data source for current AWS region
data "aws_region" "current" {}