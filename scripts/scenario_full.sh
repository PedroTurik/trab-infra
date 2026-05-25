#!/usr/bin/env bash
# =====================================================================
# Cenario COMPLETO: as 4 transacoes em paralelo (escalonamento T1-T4).
#   T1 (READ COMMITTED) -> phantom (provocado por T4)
#   T2 -> vitima do deadlock (com T3)
#   T3 -> sobrevive ao deadlock, commit consistente
#   T4 -> insere produto, commit consistente (gatilho do phantom de T1)
# A saida final, ordenada por tempo, e a base da tabela de escalonamento.
# =====================================================================
source "$(dirname "$0")/lib.sh"

reset_db
rm -f "$LOG_DIR"/T1.log "$LOG_DIR"/T2.log "$LOG_DIR"/T3.log "$LOG_DIR"/T4.log

hr; echo "### ESCALONAMENTO COMPLETO (T1 | T2 | T3 | T4) ###"; hr

# Inicios escalonados para produzir a interleaving desejada.
run_tx T1 "$TX_DIR/t1_phantom.sql" -v iso="READ COMMITTED" -v sleep1=6 >/dev/null &
sleep 0.2
run_tx T2 "$TX_DIR/t2_deadlock.sql" -v sleep1=1 >/dev/null &
sleep 0.2
run_tx T3 "$TX_DIR/t3_venda.sql"    -v sleep1=1 >/dev/null &
sleep 0.2
run_tx T4 "$TX_DIR/t4_cadastro.sql" -v sleep1=1 >/dev/null &
wait

echo "--- escalonamento (ordenado por tempo) ---"
merge_logs "$LOG_DIR"/T1.log "$LOG_DIR"/T2.log "$LOG_DIR"/T3.log "$LOG_DIR"/T4.log

echo
echo "Estado final (consistencia):"
psql_q "SELECT produto_id, nome, estoque FROM produto WHERE categoria='eletronicos' ORDER BY produto_id;"
