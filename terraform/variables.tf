variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "ssh_allowed_cidr_block" {
  description = "Bloco CIDR autorizado para SSH"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr_block, 0)) && var.ssh_allowed_cidr_block != "0.0.0.0/0"
    error_message = "O CIDR de SSH deve ser valido e nunca pode ser 0.0.0.0/0."
  }
}

variable "key_name" {
  description = "Nome do key pair da AWS usado para acesso SSH da automacao Ansible"
  type        = string
}
