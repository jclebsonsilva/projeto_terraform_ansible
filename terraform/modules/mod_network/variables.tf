variable "vpc_cidr_block" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "Bloco CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpc_name" {
  description = "Nome da VPC"
  type        = string
  default     = "projeto-terraform-ansible-vpc"
}

variable "public_subnet_name" {
  description = "Nome da subnet pública"
  type        = string
  default     = "projeto-terraform-ansible-public-subnet"
}

variable "internet_gateway_name" {
  description = "Nome do internet gateway"
  type        = string
  default     = "projeto-terraform-ansible-igw"
}

variable "public_route_table_name" {
  description = "Nome da route table pública"
  type        = string
  default     = "projeto-terraform-ansible-public-rt"
}

variable "public_web_security_group_name" {
  description = "Nome do security group da página web pública"
  type        = string
  default     = "projeto-terraform-ansible-public-web-sg"
}

variable "ssh_allowed_cidr_block" {
  description = "Bloco CIDR autorizado para SSH"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr_block, 0)) && var.ssh_allowed_cidr_block != "0.0.0.0/0"
    error_message = "O CIDR de SSH deve ser valido e nunca pode ser 0.0.0.0/0."
  }
}

variable "tags" {
  description = "Tags adicionais aplicadas aos recursos de rede"
  type        = map(string)
  default     = {}
}
