# projeto_terraform_ansible

## Visao geral

Este projeto provisiona infraestrutura AWS com Terraform e prepara a instancia EC2 com Ansible para executar a aplicacao Docker nas proximas etapas do fluxo final.

Responsabilidades de cada ferramenta:

- Terraform: VPC, subnet publica, internet gateway, route table, security group e instancia EC2
- Ansible: conexao, descoberta dinamica da EC2, instalacao do Docker Engine e orquestracao da configuracao da instancia

## Requisitos

- Terraform instalado
- Ansible instalado
- Credenciais AWS configuradas no ambiente
- Permissao para criar ou reutilizar chaves em `~/.ssh/projeto-terraform-ansible/`

Instale as collections Ansible do projeto com:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

## Configuracao

Crie o arquivo `.env` a partir do exemplo:

```bash
cp .env.example .env
```

Preencha as variaveis:

```bash
ENVIRONMENT=dev
PUBLIC_IP=SEU_IP_PUBLICO/32
```

Ao executar `./deploy.sh`, o projeto gera ou reutiliza a chave ED25519 em `~/.ssh/projeto-terraform-ansible/<environment>`.

Somente a chave publica e enviada ao Terraform/AWS. A chave privada permanece exclusivamente na sua maquina, fora do Terraform state e fora dos arquivos versionados.

## Execucao

Provisionar infraestrutura e configurar a instancia com Ansible:

```bash
./deploy.sh
```

O `deploy.sh` usa inventario dinamico AWS para validar a descoberta da EC2 antes de executar o playbook. Se `ANSIBLE_VAULT_PASSWORD_FILE` nao estiver definido no ambiente, o script solicita a senha do Vault interativamente.

Para executar o playbook manualmente com o inventario dinamico AWS e o arquivo do Ansible Vault:

```bash
ansible-playbook \
  -i ansible/inventory/aws_ec2.yml \
  ansible/playbooks/site.yml \
  --ask-vault-pass
```

Destruir o ambiente selecionado:

```bash
./destroy.sh
```

Tambem e possivel sobrescrever o ambiente sem editar o `.env`:

```bash
ENVIRONMENT=prod ./deploy.sh
ENVIRONMENT=prod ./destroy.sh
```

## Estrutura

- `terraform/`: infraestrutura como codigo
- `ansible/playbooks/site.yml`: orquestracao da configuracao da instancia
- `ansible/inventory/aws_ec2.yml`: inventario dinamico via AWS
- `ansible/requirements.yml`: collections Ansible do projeto
- `ansible/group_vars/all/vars.yml`: variaveis compartilhadas do Ansible
- `ansible/roles/docker/`: instalacao e ativacao do Docker Engine
- `ansible/roles/getting_started_app/`: obtencao do codigo oficial, build da imagem e execucao do container
- `deploy.sh`: executa Terraform e depois Ansible
- `destroy.sh`: remove a infraestrutura com Terraform

## Backend remoto e ambientes

O estado do Terraform permanece em backend S3 remoto, mas agora usa uma chave propria do projeto:

- Bucket: `bucket-tfstate-remote`
- Chave: `terraform-states/projeto-terraform-ansible.tfstate`
- Regiao: `us-east-1`

Os ambientes continuam separados por `terraform workspace`:

- `dev`: instancia EC2 `t3.micro`
- `prod`: instancia EC2 `t3.micro`

## Fluxo da integracao

O `deploy.sh` executa este fluxo:

1. Carrega o `.env`
2. Gera ou reutiliza a chave SSH local do ambiente
3. Exporta `TF_VAR_ssh_allowed_cidr_block` e `TF_VAR_ssh_public_key`
4. Executa `terraform init`
5. Seleciona ou cria o workspace Terraform
6. Executa `terraform fmt -check`, `terraform validate`, `terraform plan` e `terraform apply`
7. Consulta a AWS API com base nas tags da EC2
8. Valida o inventario dinamico em `ansible/inventory/aws_ec2.yml`
9. Executa o playbook `ansible/playbooks/site.yml`
10. Exibe IP, DNS e URL final da aplicacao

## Ansible Vault

O projeto versiona uma variavel sensivel simulada em `ansible/group_vars/all/vault.yml`, criptografada com Ansible Vault para atender ao requisito da atividade.

A senha do Vault nao fica salva no repositorio e deve ser informada apenas no momento da execucao.
