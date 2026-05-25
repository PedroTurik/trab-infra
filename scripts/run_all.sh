#!/usr/bin/env bash
# =====================================================================
# Orquestrador ponta a ponta:
#   1) sobe o container PostgreSQL
#   2) aplica schema + seed
#   3) roda os cenarios (phantom, deadlock, escalonamento completo)
#   4) roda a avaliacao de desempenho
# Saidas tambem ficam em logs/ (run_*.log) para alimentar o relatorio.
# =====================================================================
source "$(dirname "$0")/lib.sh"

mkdir -p "$LOG_DIR"

hr; echo "[1/4] subindo container e inicializando banco"; hr
docker compose -f "$ROOT_DIR/docker-compose.yml" up -d
init_db

hr; echo "[2/4] cenario PHANTOM READ (T1 x T4)"; hr
bash "$LIB_DIR/scenario_phantom.sh"   | tee "$LOG_DIR/run_phantom.log"

hr; echo "[3/4] cenario DEADLOCK (T2 x T3)"; hr
bash "$LIB_DIR/scenario_deadlock.sh"  | tee "$LOG_DIR/run_deadlock.log"

hr; echo "[3b]  ESCALONAMENTO COMPLETO (T1-T4)"; hr
bash "$LIB_DIR/scenario_full.sh"      | tee "$LOG_DIR/run_full.log"

hr; echo "[4/4] AVALIACAO DE DESEMPENHO"; hr
bash "$LIB_DIR/perf_isolation.sh"     | tee "$LOG_DIR/run_perf.log"

hr; echo "Concluido. Logs em $LOG_DIR/"; hr
