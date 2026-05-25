#!/usr/bin/env bash
# =====================================================================
# AVALIACAO DE DESEMPENHO (item 5 da spec).
# Abordagens escolhidas (>= 2):
#   (a) Tempo de execucao do lote concorrente.
#   (b) Numero de tentativas de execucao (retries por serialization
#       failure 40001 / deadlock 40P01).
# Compara 3 estrategias de controle de concorrencia sobre a MESMA carga:
#   1) READ COMMITTED         (bloqueio implicito de linha)
#   2) SERIALIZABLE           (SSI -> abortos e retries)
#   3) READ COMMITTED + LOCK TABLE IN EXCLUSIVE MODE
# Carga: W workers concorrentes x REPS transacoes cada (perf_tx.sql).
# =====================================================================
source "$(dirname "$0")/lib.sh"

W=${W:-4}        # workers concorrentes
REPS=${REPS:-10} # transacoes por worker
CAP=50           # limite de tentativas por transacao (anti-livelock)

# Um worker: roda REPS transacoes, com retry em conflitos. Grava o total
# de TENTATIVAS (sucessos + retries) em $outfile.
worker() {
  local iso="$1" lock="$2" outfile="$3"
  local attempts=0 r tries rc out
  for r in $(seq 1 "$REPS"); do
    tries=0
    while :; do
      tries=$((tries + 1)); attempts=$((attempts + 1))
      out=$(docker exec -i "$CID" psql -U "$PGUSER" -d "$PGDB" -q \
              -v ON_ERROR_STOP=1 -v iso="$iso" -v lock="$lock" \
              < "$SQL_DIR/perf_tx.sql" 2>&1); rc=$?
      [ $rc -eq 0 ] && break
      if echo "$out" | grep -qiE "could not serialize|deadlock detected"; then
        [ $tries -ge $CAP ] && { echo "WARN: cap de retries atingido" >&2; break; }
        continue
      fi
      echo "ERRO inesperado: $out" >&2; break
    done
  done
  echo "$attempts" > "$outfile"
}

run_mode() {
  local label="$1" iso="$2" lock="$3"
  reset_db >/dev/null
  local tmp; tmp=$(mktemp -d)
  local i start end
  start=$(date +%s%N)
  for i in $(seq 1 "$W"); do worker "$iso" "$lock" "$tmp/$i" & done
  wait
  end=$(date +%s%N)
  local total=0 f
  for f in "$tmp"/*; do total=$((total + $(cat "$f"))); done
  rm -rf "$tmp"
  local expected=$((W * REPS))
  local retries=$((total - expected))
  local ms=$(((end - start) / 1000000))
  printf '%-34s | %6d | %11d | %8d | %10d\n' "$label" "$expected" "$total" "$retries" "$ms"
}

db_ready || exit 1
hr
echo "AVALIACAO DE DESEMPENHO  (W=$W workers x REPS=$REPS = $((W*REPS)) txs por modo)"
hr
printf '%-34s | %6s | %11s | %8s | %10s\n' "Estrategia" "Txs" "Tentativas" "Retries" "Tempo(ms)"
printf '%-34s-+-%6s-+-%11s-+-%8s-+-%10s\n' "----------------------------------" "------" "-----------" "--------" "----------"
run_mode "1) READ COMMITTED"              "READ COMMITTED" off
run_mode "2) SERIALIZABLE"                "SERIALIZABLE"   off
run_mode "3) READ COMMITTED + LOCK TABLE" "READ COMMITTED" on
hr
echo "Retries = Tentativas - Txs. Em SERIALIZABLE espera-se retries > 0"
echo "(serialization_failure). LOCK TABLE serializa por bloqueio (0 retries)."
