variable "subnet_id" {
  description = "ID da subnet onde a instancia sera criada"
  type        = string
}

variable "security_group_ids" {
  description = "IDs dos security groups associados a instancia"
  type        = list(string)
}

variable "instance_type" {
  description = "Tipo da instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Nome da instancia EC2"
  type        = string
  default     = "projeto-terraform-ansible-webserver"
}

variable "key_name" {
  description = "Nome do key pair para acesso SSH"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags adicionais aplicadas a instancia EC2"
  type        = map(string)
  default     = {}
}
