#!/usr/bin/env bash
# Script para resetar, criar e popular o banco de dados MySQL (Linux)
# - Lê variáveis de um arquivo .env
# - Evita expor a senha no comando (usa MYSQL_PWD no ambiente)
# - Executa arquivos SQL na ordem: RESET -> SCHEMA -> TRIGGERS -> SEED

set -euo pipefail

### ==== Utilidades ====
color() { # uso: color green "texto"
  local c=$1; shift
  case "$c" in
    green) echo -e "\033[32m$*\033[0m" ;;
    yellow) echo -e "\033[33m$*\033[0m" ;;
    cyan) echo -e "\033[36m$*\033[0m" ;;
    red) echo -e "\033[31m$*\033[0m" ;;
    *) echo "$*";;
  esac
}

# Resolve caminhos relativos ao diretório do script
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### ==== Carregar .env ====
ENV_FILE="${SCRIPT_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
  # Torna variáveis do .env exportáveis e faz source.
  # Observação: isso espera um .env “bash-friendly” (sem espaços ao redor de "=" e sem caracteres especiais não escapados).
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
else
  color yellow "Aviso: arquivo .env não encontrado em: $ENV_FILE"
fi

### ==== Variáveis esperadas ====
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-visiona}"
DB_USER="${DB_USER:-root}"
MYSQL_BIN="mysql"

# Arquivos SQL (podem ser caminhos absolutos ou relativos ao script)
RESET="${RESET:-${SCRIPT_DIR}/reset.sql}"
SCHEMA="${SCHEMA:-${SCRIPT_DIR}/schema.sql}"
TRIGGERS="${TRIGGERS:-${SCRIPT_DIR}/triggers.sql}"
SEED="${SEED:-${SCRIPT_DIR}/seed.sql}"

### ==== Mostrar variáveis carregadas (sem senha) ====
echo
color cyan "========================"
color cyan " Variáveis carregadas"
color cyan "========================"
echo "DB_HOST=${DB_HOST}"
echo "DB_PORT=${DB_PORT}"
echo "DB_NAME=${DB_NAME}"
echo "DB_USER=${DB_USER}"
echo "MYSQL_BIN=${MYSQL_BIN}"
echo "RESET=${RESET}"
echo "SCHEMA=${SCHEMA}"
echo "TRIGGERS=${TRIGGERS}"
echo "SEED=${SEED}"

### ==== Solicitar senha se não definida ====
# Use MYSQL_PWD para não expor no 'ps'. (observação: ainda aparece para processos filhos em alguns cenários;
# para máxima segurança, você pode omitir DB_PASSWORD e deixar o mysql pedir interativamente com -p)
if [[ -z "${DB_PASSWORD:-}" ]]; then
  read -r -s -p "Digite a senha MySQL: " DB_PASSWORD
  echo
fi
export MYSQL_PWD="${DB_PASSWORD:-}"

### ==== Função para executar SQL de arquivo ====
run_sql_file() {
  local label="$1"
  local file="$2"
  if [[ -z "$file" ]]; then
    color yellow "Pulado: $label (arquivo não definido)."
    return 0
  fi
  # Se caminho for relativo e não existir, tenta relativo ao diretório do script
  if [[ ! -f "$file" && -f "${SCRIPT_DIR}/${file}" ]]; then
    file="${SCRIPT_DIR}/${file}"
  fi
  if [[ ! -f "$file" ]]; then
    color yellow "Pulado: $label (arquivo não encontrado: $file)"
    return 0
  fi

  echo
  color cyan "========================"
  color cyan " $label"
  color cyan "========================"

  # Importante: não coloque a senha na linha de comando.
  # O -D seleciona o database quando fizer sentido (RESET pode dropar/criar banco sem -D).
  # Estratégia: se o arquivo contém 'CREATE DATABASE' / 'DROP DATABASE', não usar -D.
  if grep -Eqi '^\s*(CREATE|DROP)\s+DATABASE' "$file"; then
    "$MYSQL_BIN" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" < "$file"
  else
    "$MYSQL_BIN" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" < "$file"
  fi
}

### ==== Execução ====
run_sql_file "Executando reset do banco" "$RESET"
run_sql_file "Criando schema" "$SCHEMA"
run_sql_file "Criando triggers" "$TRIGGERS"
run_sql_file "Inserindo dados (seed)" "$SEED"

echo
color green "========================"
color green " Concluído!"
color green "========================"
