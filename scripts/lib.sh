#!/usr/bin/env bash
# =====================================================================
# lib.sh - funcoes auxiliares para os scripts de concorrencia.
# Carregue com:  source "$(dirname "$0")/lib.sh"
# =====================================================================
set -uo pipefail

# Raiz do projeto = diretorio pai de scripts/
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LIB_DIR/.." && pwd)"
SQL_DIR="$ROOT_DIR/sql"
TX_DIR="$SQL_DIR/transactions"
LOG_DIR="$ROOT_DIR/logs"

# Carrega .env se existir (POSTGRES_USER etc.)
if [ -f "$ROOT_DIR/.env" ]; then
  set -a; . "$ROOT_DIR/.env"; set +a
fi

CID="${CONTAINER_NAME:-trab_infra_pg}"
PGUSER="${POSTGRES_USER:-loja}"
PGDB="${POSTGRES_DB:-loja}"

mkdir -p "$LOG_DIR"

# Espera o banco aceitar conexoes.
db_ready() {
  local i
  for i in $(seq 1 30); do
    if docker exec "$CID" pg_isready -U "$PGUSER" -d "$PGDB" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "ERRO: banco nao ficou pronto (container $CID)." >&2
  return 1
}

# Roda um comando SQL avulso (string) e devolve a saida.
psql_q() {
  docker exec -i "$CID" psql -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 -tAc "$1"
}

# Aplica schema + seed.
init_db() {
  db_ready || return 1
  docker exec -i "$CID" psql -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 < "$SQL_DIR/01_schema.sql" >/dev/null
  docker exec -i "$CID" psql -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 < "$SQL_DIR/02_seed.sql"   >/dev/null
  echo "[init] schema + seed aplicados."
}

# Recarrega apenas os dados (entre execucoes de cenarios).
reset_db() {
  db_ready || return 1
  docker exec -i "$CID" psql -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 < "$SQL_DIR/02_seed.sql" >/dev/null
  echo "[reset] dados recarregados."
}

# Executa um arquivo de transacao como uma sessao psql, prefixando cada
# linha de saida com horario (HH:MM:SS.mmm) e rotulo, gravando em log.
# Uso: run_tx <ROTULO> <arquivo.sql> [args extras do psql...]
run_tx() {
  local label="$1"; shift
  local file="$1"; shift
  local log="$LOG_DIR/${label}.log"
  docker exec -i "$CID" psql -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=0 "$@" < "$file" 2>&1 \
    | while IFS= read -r line; do
        printf '%s | %-3s | %s\n' "$(date '+%H:%M:%S.%3N')" "$label" "$line"
      done | tee "$log"
}

# Junta os logs informados e ordena cronologicamente pelo horario inicial.
merge_logs() {
  cat "$@" 2>/dev/null | sort -s -t'|' -k1,1
}

hr() { printf '%s\n' "------------------------------------------------------------"; }
