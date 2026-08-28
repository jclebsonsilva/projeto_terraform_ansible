#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"
ANSIBLE_INVENTORY_FILE="${ANSIBLE_DIR}/inventory/hosts.yml"
ANSIBLE_PLAYBOOK_FILE="${ANSIBLE_DIR}/playbooks/site.yml"
ANSIBLE_STATE_DIR="${SCRIPT_DIR}/.ansible"
PROJECT_NAME="projeto-terraform-ansible"

require_env_var() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    echo "Variavel obrigatoria ausente: ${var_name}"
    exit 1
  fi
}

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "Arquivo .env não encontrado em ${ENV_FILE}."
  exit 1
fi

require_env_var "ENVIRONMENT"
require_env_var "PUBLIC_IP"
require_env_var "AWS_KEY_PAIR_NAME"
require_env_var "SSH_PRIVATE_KEY_PATH"

if [[ "$PUBLIC_IP" == */* ]]; then
  SSH_ALLOWED_CIDR_BLOCK="$PUBLIC_IP"
else
  SSH_ALLOWED_CIDR_BLOCK="${PUBLIC_IP}/32"
fi

if [[ "$SSH_ALLOWED_CIDR_BLOCK" == "0.0.0.0/0" ]]; then
  echo "SSH_ALLOWED_CIDR_BLOCK nunca pode ser 0.0.0.0/0."
  exit 1
fi

if [[ "$SSH_PRIVATE_KEY_PATH" = /* ]]; then
  SSH_PRIVATE_KEY_FILE="$SSH_PRIVATE_KEY_PATH"
else
  SSH_PRIVATE_KEY_FILE="${SCRIPT_DIR}/${SSH_PRIVATE_KEY_PATH}"
fi

if [[ ! -f "$SSH_PRIVATE_KEY_FILE" ]]; then
  echo "Chave privada nao encontrada em ${SSH_PRIVATE_KEY_FILE}."
  exit 1
fi

export ENVIRONMENT
export PUBLIC_IP
export AWS_KEY_PAIR_NAME
export SSH_PRIVATE_KEY_PATH="$SSH_PRIVATE_KEY_FILE"
export TF_VAR_ssh_allowed_cidr_block="$SSH_ALLOWED_CIDR_BLOCK"
export TF_VAR_key_name="$AWS_KEY_PAIR_NAME"
PLAN_FILE="plan-${ENVIRONMENT}.tfplan"

cd "$TERRAFORM_DIR"

echo "Ambiente: ${ENVIRONMENT}"
echo "IP publico para SSH: ${TF_VAR_ssh_allowed_cidr_block}"
echo "Key pair AWS: ${AWS_KEY_PAIR_NAME}"

terraform init

if terraform workspace list | sed 's/^[* ]*//' | grep -qx "$ENVIRONMENT"; then
  terraform workspace select "$ENVIRONMENT"
else
  terraform workspace new "$ENVIRONMENT"
fi

terraform fmt -check
terraform validate
terraform plan -out="$PLAN_FILE"
terraform apply "$PLAN_FILE"

WEBSERVER_PUBLIC_IP="$(terraform output -raw webserver_public_ip)"
WEBSERVER_PUBLIC_DNS="$(terraform output -raw webserver_public_dns)"

mkdir -p "${ANSIBLE_DIR}/inventory" "${ANSIBLE_STATE_DIR}/tmp" "${ANSIBLE_STATE_DIR}/collections"

cat > "$ANSIBLE_INVENTORY_FILE" <<EOF
all:
  children:
    webservers:
      hosts:
        ${ENVIRONMENT}-webserver:
          ansible_host: ${WEBSERVER_PUBLIC_IP}
          ansible_user: ec2-user
          ansible_python_interpreter: /usr/bin/python3
          ansible_ssh_private_key_file: ${SSH_PRIVATE_KEY_FILE}
          deployment_environment: ${ENVIRONMENT}
          public_dns: ${WEBSERVER_PUBLIC_DNS}
EOF

export ANSIBLE_CONFIG="${ANSIBLE_DIR}/ansible.cfg"
export ANSIBLE_HOME="${ANSIBLE_STATE_DIR}"
export ANSIBLE_LOCAL_TEMP="${ANSIBLE_STATE_DIR}/tmp"

cd "$ANSIBLE_DIR"

echo "Executando configuracao com Ansible no host ${WEBSERVER_PUBLIC_IP}"

ansible-playbook \
  -i "$ANSIBLE_INVENTORY_FILE" \
  "$ANSIBLE_PLAYBOOK_FILE" \
  --extra-vars "project_name=${PROJECT_NAME} deployment_environment=${ENVIRONMENT}"
