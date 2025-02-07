
output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web_server.public_ip
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.database.endpoint
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}