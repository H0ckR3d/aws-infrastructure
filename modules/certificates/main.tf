# SSL/TLS Certificates using AWS Certificate Manager

# Certificate for Shiny application
resource "aws_acm_certificate" "shiny" {
  domain_name               = "${var.shiny_subdomain}.${var.domain_name}"
  subject_alternative_names = ["*.${var.shiny_subdomain}.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-shiny-certificate"
    Application = "Shiny"
  })
}

# Certificate for RStudio application
resource "aws_acm_certificate" "rstudio" {
  domain_name               = "${var.rstudio_subdomain}.${var.domain_name}"
  subject_alternative_names = ["*.${var.rstudio_subdomain}.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-rstudio-certificate"
    Application = "RStudio"
  })
}

# Wildcard certificate for the main domain
resource "aws_acm_certificate" "wildcard" {
  domain_name = var.domain_name
  subject_alternative_names = [
    "*.${var.domain_name}"
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-wildcard-certificate"
    Type = "Wildcard"
  })
}

# Data source to find the hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# DNS validation records for Shiny certificate
resource "aws_route53_record" "shiny_validation" {
  for_each = {
    for dvo in aws_acm_certificate.shiny.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# DNS validation records for RStudio certificate
resource "aws_route53_record" "rstudio_validation" {
  for_each = {
    for dvo in aws_acm_certificate.rstudio.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# DNS validation records for wildcard certificate
resource "aws_route53_record" "wildcard_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Certificate validation for Shiny
resource "aws_acm_certificate_validation" "shiny" {
  certificate_arn         = aws_acm_certificate.shiny.arn
  validation_record_fqdns = [for record in aws_route53_record.shiny_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# Certificate validation for RStudio
resource "aws_acm_certificate_validation" "rstudio" {
  certificate_arn         = aws_acm_certificate.rstudio.arn
  validation_record_fqdns = [for record in aws_route53_record.rstudio_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# Certificate validation for wildcard
resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for record in aws_route53_record.wildcard_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}