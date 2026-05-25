-- =====================================================================
-- T3 - Venda  (PAPEL: executar SEM inconsistencias)
-- Trava o produto 2 e depois o produto 1 (ordem inversa a T2). Participa
-- do ciclo de deadlock, mas SOBREVIVE: apos T2 ser abortada, T3 adquire
-- o lock do produto 1, conclui a venda e commita de forma consistente.
--
-- Variaveis psql: :sleep1 (espera para formar o ciclo com T2).
-- =====================================================================
\if :{?sleep1}
\else
  \set sleep1 2
\endif

\echo '[T3] inicio (venda de 1 un. do prod 2 e 1 un. do prod 1)'
BEGIN;

\echo '[T3] trava prod 2 (SELECT ... FOR UPDATE) - bloqueio explicito'
SELECT produto_id, estoque FROM produto WHERE produto_id = 2 FOR UPDATE;
UPDATE produto SET estoque = estoque - 1 WHERE produto_id = 2;

\echo '[T3] aguardando (deixa T2 bloquear no prod 2)...'
SELECT pg_sleep(:sleep1);

\echo '[T3] trava prod 1 (FOR UPDATE) -> espera ate T2 abortar, depois segue'
SELECT produto_id, estoque FROM produto WHERE produto_id = 1 FOR UPDATE;
UPDATE produto SET estoque = estoque - 1 WHERE produto_id = 1;

\echo '[T3] registra pedido + item'
INSERT INTO pedido (cliente_id, status, total) VALUES (2, 'FECHADO', 7499.90);
INSERT INTO item_pedido (pedido_id, produto_id, quantidade, preco_unitario)
  VALUES (currval('pedido_pedido_id_seq'), 2, 1, 2999.90);

COMMIT;
\echo '[T3] COMMIT (consistente)'
