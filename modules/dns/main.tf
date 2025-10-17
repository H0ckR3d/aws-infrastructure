# Data source for Route 53 hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Route 53 records for Shiny application
resource "aws_route53_record" "shiny" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.shiny_subdomain
  type    = "A"

  alias {
    name                   = var.shiny_alb_dns_name
    zone_id                = var.shiny_alb_zone_id
    evaluate_target_health = true
  }
}

# Route 53 records for RStudio application
resource "aws_route53_record" "rstudio" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.rstudio_subdomain
  type    = "A"

  alias {
    name                   = var.rstudio_alb_dns_name
    zone_id                = var.rstudio_alb_zone_id
    evaluate_target_health = true
  }
}

# Health checks for monitoring
resource "aws_route53_health_check" "shiny" {
  fqdn                            = "${var.shiny_subdomain}.${var.domain_name}"
  port                            = 443
  type                            = "HTTPS_STR_MATCH"
  resource_path                   = "/"
  failure_threshold               = "3"
  request_interval                = "30"
  search_string                   = "Shiny"
  cloudwatch_alarm_region         = data.aws_region.current.name
  cloudwatch_alarm_name           = "${var.name_prefix}-shiny-health-alarm"
  insufficient_data_health_status = "Unhealthy"

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-shiny-health-check"
    Application = "Shiny"
  })
}

resource "aws_route53_health_check" "rstudio" {
  fqdn                            = "${var.rstudio_subdomain}.${var.domain_name}"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/auth-sign-in"
  failure_threshold               = "3"
  request_interval                = "30"
  cloudwatch_alarm_region         = data.aws_region.current.name
  cloudwatch_alarm_name           = "${var.name_prefix}-rstudio-health-alarm"
  insufficient_data_health_status = "Unhealthy"

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-rstudio-health-check"
    Application = "RStudio"
  })
}

# Data source for current AWS region
data "aws_region" "current" {}