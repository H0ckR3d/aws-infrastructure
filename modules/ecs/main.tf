# Data sources for security groups
data "aws_security_group" "ecs" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}-ecs-sg"]
  }
  vpc_id = var.vpc_id
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ecs-cluster"
  })
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# CloudWatch Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = 30

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-ecs-logs"
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Attach the ECS task execution policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "${var.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# ECS Task Role Policy for S3 and EFS access
resource "aws_iam_role_policy" "ecs_task" {
  name = "${var.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-data-*",
          "arn:aws:s3:::${var.name_prefix}-data-*/*",
          "arn:aws:s3:::${var.name_prefix}-analytics-results-*",
          "arn:aws:s3:::${var.name_prefix}-analytics-results-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECS Task Definition for Shiny
resource "aws_ecs_task_definition" "shiny" {
  family                   = "${var.name_prefix}-shiny"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  volume {
    name = "efs-storage"

    efs_volume_configuration {
      file_system_id          = var.efs_file_system_id
      root_directory          = "/shiny-apps"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name  = "shiny-app"
      image = "rocker/shiny:4.3.0"

      portMappings = [
        {
          containerPort = 3838
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "efs-storage"
          containerPath = "/srv/shiny-server"
          readOnly      = false
        }
      ]

      environment = [
        {
          name  = "SHINY_LOG_LEVEL"
          value = "INFO"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "shiny"
        }
      }

      essential = true
    }
  ])

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-shiny-task"
    Application = "Shiny"
  })
}

# ECS Service for Shiny
resource "aws_ecs_service" "shiny" {
  name            = "${var.name_prefix}-shiny-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.shiny.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [data.aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arns[0]
    container_name   = "shiny-app"
    container_port   = 3838
  }

  depends_on = [aws_iam_role_policy.ecs_task]

  tags = merge(var.common_tags, {
    Name        = "${var.name_prefix}-shiny-service"
    Application = "Shiny"
  })
}

# Data source for current AWS region
data "aws_region" "current" {}