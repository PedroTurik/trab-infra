#!/usr/bin/env bash
# =====================================================================
# Cenario isolado: DEADLOCK (T2 x T3)
# T2 trava prod1->prod2; T3 trava prod2->prod1. Forma-se um ciclo; o
# PostgreSQL detecta (40P01) e aborta a vitima (T2). T3 sobrevive.
# =====================================================================
source "$(dirname "$0")/lib.sh"

reset_db
rm -f "$LOG_DIR/T2.log" "$LOG_DIR/T3.log"

hr; echo "### DEADLOCK: T2 (prod1->prod2)  x  T3 (prod2->prod1) ###"; hr
echo "Estoque inicial prod 1 e 2:"
psql_q "SELECT produto_id, estoque FROM produto WHERE produto_id IN (1,2) ORDER BY produto_id;"

run_tx T2 "$TX_DIR/t2_deadlock.sql" -v sleep1=1 >/dev/null &
sleep 0.2
run_tx T3 "$TX_DIR/t3_venda.sql"    -v sleep1=1 >/dev/null &
wait

echo "--- escalonamento (ordenado por tempo) ---"
merge_logs "$LOG_DIR/T2.log" "$LOG_DIR/T3.log"

echo
echo "Estoque final prod 1 e 2 (T2 vitima revertida; venda de T3 aplicada -> 1:29, 2:39):"
psql_q "SELECT produto_id, estoque FROM produto WHERE produto_id IN (1,2) ORDER BY produto_id;"
