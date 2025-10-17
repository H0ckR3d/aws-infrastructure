# Data source for security group
data "aws_security_group" "transfer" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}-transfer-sg"]
  }
  vpc_id = var.vpc_id
}

# AWS Transfer Family Server
resource "aws_transfer_server" "sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  endpoint_type          = "VPC"

  endpoint_details {
    subnet_ids         = var.subnet_ids
    vpc_id             = var.vpc_id
    security_group_ids = [data.aws_security_group.transfer.id]
  }

  logging_role = aws_iam_role.transfer_logging.arn

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-sftp-server"
    Type = "Transfer"
  })
}

# IAM role for Transfer Family logging
resource "aws_iam_role" "transfer_logging" {
  name = "${var.name_prefix}-transfer-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM policy for Transfer Family logging
resource "aws_iam_role_policy" "transfer_logging" {
  name = "${var.name_prefix}-transfer-logging-policy"
  role = aws_iam_role.transfer_logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM role for SFTP users
resource "aws_iam_role" "sftp_user" {
  name = "${var.name_prefix}-sftp-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM policy for SFTP users to access S3
resource "aws_iam_role_policy" "sftp_user" {
  name = "${var.name_prefix}-sftp-user-policy"
  role = aws_iam_role.sftp_user.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      }
    ]
  })
}

# SFTP Users
resource "aws_transfer_user" "users" {
  count = length(var.sftp_users)

  server_id = aws_transfer_server.sftp.id
  user_name = var.sftp_users[count.index].username
  role      = aws_iam_role.sftp_user.arn

  home_directory_type = "PATH"
  home_directory      = "/${var.s3_bucket_name}${var.sftp_users[count.index].home_dir}"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-sftp-user-${var.sftp_users[count.index].username}"
    Type = "SFTPUser"
  })
}

# SSH Keys for SFTP users
resource "aws_transfer_ssh_key" "users" {
  count = length(var.sftp_users)

  server_id = aws_transfer_server.sftp.id
  user_name = aws_transfer_user.users[count.index].user_name
  body      = var.sftp_users[count.index].public_key
}

# CloudWatch Log Group for Transfer Family
resource "aws_cloudwatch_log_group" "transfer" {
  name              = "/aws/transfer/${var.name_prefix}"
  retention_in_days = 30

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-transfer-logs"
  })
}