# Data source for EFS security group
data "aws_security_group" "efs" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}-efs-sg"]
  }
  vpc_id = var.vpc_id
}

# S3 Buckets
resource "aws_s3_bucket" "data" {
  bucket        = "${var.name_prefix}-data-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-data-bucket"
    Type = "Data"
  })
}

resource "aws_s3_bucket" "analytics_results" {
  bucket        = "${var.name_prefix}-analytics-results-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-analytics-results-bucket"
    Type = "Results"
  })
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.name_prefix}-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-logs-bucket"
    Type = "Logs"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "analytics_results" {
  bucket = aws_s3_bucket.analytics_results.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_results" {
  bucket = aws_s3_bucket.analytics_results.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "analytics_results" {
  bucket = aws_s3_bucket.analytics_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "data_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "analytics_results" {
  bucket = aws_s3_bucket.analytics_results.id

  rule {
    id     = "results_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs_lifecycle"
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

# KMS Key for S3 Encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-s3-kms-key"
  })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token   = "${var.name_prefix}-efs"
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput : null

  encrypted  = true
  kms_key_id = aws_kms_key.efs.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-efs"
  })
}

# KMS Key for EFS Encryption
resource "aws_kms_key" "efs" {
  description             = "KMS key for EFS encryption"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-efs-kms-key"
  })
}

resource "aws_kms_alias" "efs" {
  name          = "alias/${var.name_prefix}-efs"
  target_key_id = aws_kms_key.efs.key_id
}

# EFS Mount Targets
resource "aws_efs_mount_target" "main" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [data.aws_security_group.efs.id]
}

# EFS Access Points
resource "aws_efs_access_point" "shiny_apps" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1001
    uid = 1001
  }

  root_directory {
    path = "/shiny-apps"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "0755"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-efs-shiny-apps-ap"
    Type = "ShinyApps"
  })
}

resource "aws_efs_access_point" "rstudio_home" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/rstudio-home"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-efs-rstudio-home-ap"
    Type = "RStudioHome"
  })
}

resource "aws_efs_access_point" "shared_data" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1002
    uid = 1002
  }

  root_directory {
    path = "/shared-data"
    creation_info {
      owner_gid   = 1002
      owner_uid   = 1002
      permissions = "0755"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-efs-shared-data-ap"
    Type = "SharedData"
  })
}