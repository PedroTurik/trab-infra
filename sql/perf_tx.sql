-- =====================================================================
-- Transacao usada na AVALIACAO DE DESEMPENHO (item 5 / PERF).
-- Faz uma leitura por predicado (categoria) seguida de escrita em linhas
-- desse predicado. Em SERIALIZABLE isso gera rw-conflito (SSI) e pode
-- falhar com serialization_failure (40001), exigindo retry. Em READ
-- COMMITTED nao falha. Com LOCK TABLE EXCLUSIVE serializa por bloqueio.
--
-- Variaveis psql: :iso (nivel), :lock (on/off para LOCK TABLE).
-- =====================================================================
\if :{?iso}
\else
  \set iso 'READ COMMITTED'
\endif
\if :{?lock}
\else
  \set lock off
\endif

BEGIN;
SET TRANSACTION ISOLATION LEVEL :iso;
\if :lock
  LOCK TABLE produto IN EXCLUSIVE MODE;
\endif
SELECT count(*) FROM produto WHERE categoria = 'eletronicos';
SELECT pg_sleep(0.02);
UPDATE produto SET estoque = estoque WHERE produto_id IN (1, 2);
COMMIT;
