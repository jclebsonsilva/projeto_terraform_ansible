output "public_subnet_id" {
  description = "ID da subnet publica"
  value       = aws_subnet.public.id
}

output "public_web_security_group_id" {
  description = "ID do security group da pagina web publica"
  value       = aws_security_group.public_web.id
}
