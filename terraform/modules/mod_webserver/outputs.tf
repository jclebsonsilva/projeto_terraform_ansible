output "instance_id" {
  description = "ID da instancia EC2"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "IP publico da instancia EC2"
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "DNS publico da instancia EC2"
  value       = aws_instance.web.public_dns
}
