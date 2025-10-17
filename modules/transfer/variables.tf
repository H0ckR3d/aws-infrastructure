variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Transfer Family endpoint"
  type        = list(string)
}

variable "s3_bucket_name" {
  description = "S3 bucket name for SFTP access"
  type        = string
}

variable "sftp_users" {
  description = "List of SFTP users"
  type = list(object({
    username   = string
    public_key = string
    home_dir   = string
  }))
  default = []
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}