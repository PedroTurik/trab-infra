#!/usr/bin/env bash
# =====================================================================
# Cenario isolado: PHANTOM READ (T1 x T4)
# Roda duas vezes: READ COMMITTED (ha phantom) e SERIALIZABLE (sem phantom).
# =====================================================================
source "$(dirname "$0")/lib.sh"

run_phantom() {
  local iso="$1"
  hr; echo "### Isolamento de T1 = $iso ###"; hr
  reset_db
  rm -f "$LOG_DIR/T1.log" "$LOG_DIR/T4.log"

  run_tx T1 "$TX_DIR/t1_phantom.sql" -v iso="$iso" -v sleep1=3 >/dev/null &
  sleep 0.3
  run_tx T4 "$TX_DIR/t4_cadastro.sql" -v sleep1=1 >/dev/null &
  wait

  echo "--- escalonamento (ordenado por tempo) ---"
  merge_logs "$LOG_DIR/T1.log" "$LOG_DIR/T4.log"
}

run_phantom "READ COMMITTED"
echo
run_phantom "SERIALIZABLE"
