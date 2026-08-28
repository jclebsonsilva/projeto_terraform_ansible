terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "bucket-tfstate-remote"
    key    = "terraform-states/projeto-terraform-ansible.tfstate"
    region = "us-east-1"

    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  environment = terraform.workspace

  instance_type_by_workspace = {
    dev  = "t3.micro"
    prod = "t3.micro"
  }

  webserver_instance_type = lookup(
    local.instance_type_by_workspace,
    local.environment,
    local.instance_type_by_workspace.dev
  )

  project_slug = "projeto-terraform-ansible"
  name_prefix  = "${local.project_slug}-${local.environment}"

  common_tags = {
    Ambiente  = local.environment
    Curso     = "DevOps 2025.2"
    ManagedBy = "terraform"
    Projeto   = "projeto_terraform_ansible"
  }
}

module "network" {
  source = "./modules/mod_network"

  ssh_allowed_cidr_block = var.ssh_allowed_cidr_block

  vpc_name                       = "${local.name_prefix}-vpc"
  public_subnet_name             = "${local.name_prefix}-public-subnet"
  internet_gateway_name          = "${local.name_prefix}-igw"
  public_route_table_name        = "${local.name_prefix}-public-rt"
  public_web_security_group_name = "${local.name_prefix}-public-web-sg"
  tags                           = local.common_tags
}

module "webserver" {
  source = "./modules/mod_webserver"

  subnet_id          = module.network.public_subnet_id
  security_group_ids = [module.network.public_web_security_group_id]
  instance_type      = local.webserver_instance_type
  instance_name      = "${local.name_prefix}-webserver"
  key_name           = var.key_name
  tags               = local.common_tags
}
