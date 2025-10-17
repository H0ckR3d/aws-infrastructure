# Data source for security group
data "aws_security_group" "alb" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}-alb-sg"]
  }
  vpc_id = var.vpc_id
}

# Shiny Application Load Balancer
resource "aws_lb" "shiny" {
  name               = "${var.name_prefix}-shiny-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "shiny-alb"
    enabled = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-shiny-alb"
    Application = "Shiny"
  })
}

# RStudio Application Load Balancer
resource "aws_lb" "rstudio" {
  name               = "${var.name_prefix}-rstudio-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "rstudio-alb"
    enabled = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-rstudio-alb"
    Application = "RStudio"
  })
}

# S3 Bucket for ALB Access Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.name_prefix}-alb-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb-logs"
    Type = "Logs"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket Policy for ALB Access Logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}

# S3 Bucket Server-side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Data source for ELB service account
data "aws_elb_service_account" "main" {}

# Target Groups
resource "aws_lb_target_group" "shiny" {
  name     = "${var.name_prefix}-shiny-tg"
  port     = 3838
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-shiny-tg"
    Application = "Shiny"
  })
}

resource "aws_lb_target_group" "rstudio" {
  name     = "${var.name_prefix}-rstudio-tg"
  port     = 8787
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/auth-sign-in"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-rstudio-tg"
    Application = "RStudio"
  })
}

# Listeners
resource "aws_lb_listener" "shiny_https" {
  load_balancer_arn = aws_lb.shiny.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shiny.arn
  }
}

resource "aws_lb_listener" "shiny_http" {
  load_balancer_arn = aws_lb.shiny.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "rstudio_https" {
  load_balancer_arn = aws_lb.rstudio.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rstudio.arn
  }
}

resource "aws_lb_listener" "rstudio_http" {
  load_balancer_arn = aws_lb.rstudio.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# WAF Association (conditional)
resource "aws_wafv2_web_acl_association" "shiny" {
  count        = var.waf_web_acl_arn != null ? 1 : 0
  resource_arn = aws_lb.shiny.arn
  web_acl_arn  = var.waf_web_acl_arn
}

resource "aws_wafv2_web_acl_association" "rstudio" {
  count        = var.waf_web_acl_arn != null ? 1 : 0
  resource_arn = aws_lb.rstudio.arn
  web_acl_arn  = var.waf_web_acl_arn
}