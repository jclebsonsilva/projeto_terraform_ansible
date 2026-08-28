# projeto_terraform_ansible

## Visao geral

Este projeto provisiona infraestrutura AWS com Terraform e configura o servidor web com Ansible.

Responsabilidades de cada ferramenta:

- Terraform: VPC, subnet publica, internet gateway, route table, security group e instancia EC2
- Ansible: instalacao do Nginx, publicacao da pagina HTML e garantia de servico habilitado

## Requisitos

- Terraform instalado
- Ansible instalado
- Credenciais AWS configuradas no ambiente
- Permissao para criar ou reutilizar chaves em `~/.ssh/projeto-terraform-ansible/`

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
- `ansible/playbooks/site.yml`: configuracao do servidor web
- `ansible/templates/index.html.j2`: pagina publicada pelo Nginx
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
3. Seleciona ou cria o workspace Terraform
4. Executa `terraform plan` e `terraform apply`
5. Le o IP publico provisionado
6. Gera `ansible/inventory/hosts.yml`
7. Executa o playbook `ansible/playbooks/site.yml`
