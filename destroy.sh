#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"
PROJECT_NAME="projeto-terraform-ansible"
SSH_KEY_DIR="${HOME}/.ssh/${PROJECT_NAME}"

require_env_var() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    echo "Variavel obrigatoria ausente: ${var_name}"
    exit 1
  fi
}

ensure_ssh_key_pair() {
  local environment="$1"

  SSH_PRIVATE_KEY_FILE="${SSH_KEY_DIR}/${environment}"
  SSH_PUBLIC_KEY_FILE="${SSH_PRIVATE_KEY_FILE}.pub"

  mkdir -p "$SSH_KEY_DIR"
  chmod 700 "$SSH_KEY_DIR"

  if [[ -f "$SSH_PRIVATE_KEY_FILE" && ! -f "$SSH_PUBLIC_KEY_FILE" ]]; then
    echo "Chave publica ausente para a chave privada ${SSH_PRIVATE_KEY_FILE}."
    exit 1
  fi

  if [[ -f "$SSH_PUBLIC_KEY_FILE" && ! -f "$SSH_PRIVATE_KEY_FILE" ]]; then
    echo "Chave privada ausente para a chave publica ${SSH_PUBLIC_KEY_FILE}."
    exit 1
  fi

  if [[ ! -f "$SSH_PRIVATE_KEY_FILE" && ! -f "$SSH_PUBLIC_KEY_FILE" ]]; then
    ssh-keygen -t ed25519 -f "$SSH_PRIVATE_KEY_FILE" -N "" -C "${PROJECT_NAME}-${environment}" >/dev/null
  fi

  chmod 600 "$SSH_PRIVATE_KEY_FILE"
  chmod 644 "$SSH_PUBLIC_KEY_FILE"
}

if [[ -f "$ENV_FILE" ]]; then
  ENVIRONMENT_OVERRIDE="${ENVIRONMENT:-}"
  PUBLIC_IP_OVERRIDE="${PUBLIC_IP:-}"
  set -a
  source "$ENV_FILE"
  set +a

  if [[ -n "$ENVIRONMENT_OVERRIDE" ]]; then
    ENVIRONMENT="$ENVIRONMENT_OVERRIDE"
  fi

  if [[ -n "$PUBLIC_IP_OVERRIDE" ]]; then
    PUBLIC_IP="$PUBLIC_IP_OVERRIDE"
  fi
else
  echo "Arquivo .env não encontrado em ${ENV_FILE}."
  exit 1
fi

require_env_var "ENVIRONMENT"
require_env_var "PUBLIC_IP"

if [[ "$PUBLIC_IP" == */* ]]; then
  SSH_ALLOWED_CIDR_BLOCK="$PUBLIC_IP"
else
  SSH_ALLOWED_CIDR_BLOCK="${PUBLIC_IP}/32"
fi

if [[ "$SSH_ALLOWED_CIDR_BLOCK" == "0.0.0.0/0" ]]; then
  echo "SSH_ALLOWED_CIDR_BLOCK nunca pode ser 0.0.0.0/0."
  exit 1
fi

ensure_ssh_key_pair "$ENVIRONMENT"
SSH_PUBLIC_KEY_CONTENT="$(< "$SSH_PUBLIC_KEY_FILE")"

export ENVIRONMENT
export PUBLIC_IP
export TF_VAR_ssh_allowed_cidr_block="$SSH_ALLOWED_CIDR_BLOCK"
export TF_VAR_ssh_public_key="$SSH_PUBLIC_KEY_CONTENT"

cd "$TERRAFORM_DIR"

echo "Ambiente: ${ENVIRONMENT}"
echo "IP publico para SSH: ${TF_VAR_ssh_allowed_cidr_block}"
echo "Chave SSH privada local: ${SSH_PRIVATE_KEY_FILE}"
echo "Chave SSH publica registrada: ${SSH_PUBLIC_KEY_FILE}"

terraform init

if terraform workspace list | sed 's/^[* ]*//' | grep -qx "$ENVIRONMENT"; then
  terraform workspace select "$ENVIRONMENT"
else
  echo "Workspace '${ENVIRONMENT}' não existe. Nada foi destruído."
  exit 1
fi

terraform validate
terraform destroy
