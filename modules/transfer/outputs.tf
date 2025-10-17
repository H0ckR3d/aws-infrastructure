output "sftp_server_id" {
  description = "Transfer Family SFTP server ID"
  value       = aws_transfer_server.sftp.id
}

output "sftp_endpoint" {
  description = "Transfer Family SFTP endpoint"
  value       = aws_transfer_server.sftp.endpoint
}

output "sftp_server_arn" {
  description = "Transfer Family SFTP server ARN"
  value       = aws_transfer_server.sftp.arn
}

output "sftp_users" {
  description = "List of created SFTP users"
  value       = aws_transfer_user.users[*].user_name
}