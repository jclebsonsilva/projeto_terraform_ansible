#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

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

if [[ "$PUBLIC_IP" == */* ]]; then
  SSH_ALLOWED_CIDR_BLOCK="$PUBLIC_IP"
else
  SSH_ALLOWED_CIDR_BLOCK="${PUBLIC_IP}/32"
fi

if [[ "$SSH_ALLOWED_CIDR_BLOCK" == "0.0.0.0/0" ]]; then
  echo "SSH_ALLOWED_CIDR_BLOCK nunca pode ser 0.0.0.0/0."
  exit 1
fi

export ENVIRONMENT
export PUBLIC_IP
export AWS_KEY_PAIR_NAME
export TF_VAR_ssh_allowed_cidr_block="$SSH_ALLOWED_CIDR_BLOCK"
export TF_VAR_key_name="$AWS_KEY_PAIR_NAME"

cd "$TERRAFORM_DIR"

echo "Ambiente: ${ENVIRONMENT}"
echo "IP publico para SSH: ${TF_VAR_ssh_allowed_cidr_block}"
echo "Key pair AWS: ${AWS_KEY_PAIR_NAME}"

terraform init

if terraform workspace list | sed 's/^[* ]*//' | grep -qx "$ENVIRONMENT"; then
  terraform workspace select "$ENVIRONMENT"
else
  echo "Workspace '${ENVIRONMENT}' não existe. Nada foi destruído."
  exit 1
fi

terraform validate
terraform destroy
