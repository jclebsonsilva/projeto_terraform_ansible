output "environment" {
  description = "Workspace Terraform usado como ambiente"
  value       = terraform.workspace
}

output "webserver_instance_type" {
  description = "Tipo da instancia EC2 escolhido para o ambiente atual"
  value       = local.webserver_instance_type
}

output "webserver_instance_id" {
  description = "ID da instancia EC2 do servidor web"
  value       = module.webserver.instance_id
}

output "webserver_public_ip" {
  description = "IP publico do servidor web"
  value       = module.webserver.public_ip
}

output "webserver_public_dns" {
  description = "DNS publico do servidor web"
  value       = module.webserver.public_dns
}

output "webserver_ssh_user" {
  description = "Usuario SSH padrao para a instancia EC2"
  value       = "ec2-user"
}

output "key_pair_name" {
  description = "Nome do key pair registrado pelo Terraform na AWS"
  value       = aws_key_pair.automation.key_name
}
