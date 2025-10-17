# Data sources for security groups
data "aws_security_group" "shiny" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}-shiny-sg"]
  }
  vpc_id = var.vpc_id
}

data "aws_security_group" "rstudio" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}-rstudio-sg"]
  }
  vpc_id = var.vpc_id
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM policy for EC2 instances to access S3 and EFS
resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.name_prefix}-ec2-policy"
  role = aws_iam_role.ec2_role.id

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
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
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
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach SSM managed instance core policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = var.common_tags
}

# Launch Template for Shiny servers
resource "aws_launch_template" "shiny" {
  name_prefix   = "${var.name_prefix}-shiny-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.shiny_instance_type

  vpc_security_group_ids = [data.aws_security_group.shiny.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data_shiny.sh", {
    efs_file_system_id = var.efs_file_system_id
    region             = data.aws_region.current.name
    s3_bucket_name     = var.s3_bucket_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name        = "${var.name_prefix}-shiny-instance"
      Application = "Shiny"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template for RStudio servers
resource "aws_launch_template" "rstudio" {
  name_prefix   = "${var.name_prefix}-rstudio-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.rstudio_instance_type

  vpc_security_group_ids = [data.aws_security_group.rstudio.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data_rstudio.sh", {
    efs_file_system_id = var.efs_file_system_id
    region             = data.aws_region.current.name
    s3_bucket_name     = var.s3_bucket_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name        = "${var.name_prefix}-rstudio-instance"
      Application = "RStudio"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for Shiny
resource "aws_autoscaling_group" "shiny" {
  name                      = "${var.name_prefix}-shiny-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.shiny_target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_capacity
  max_size         = var.max_capacity
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.shiny.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-shiny-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for RStudio
resource "aws_autoscaling_group" "rstudio" {
  name                      = "${var.name_prefix}-rstudio-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.rstudio_target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_capacity
  max_size         = var.max_capacity
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.rstudio.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-rstudio-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Data source for current AWS region
data "aws_region" "current" {}