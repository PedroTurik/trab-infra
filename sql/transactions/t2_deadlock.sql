-- =====================================================================
-- T2 - Transferencia de estoque entre produtos  (PAPEL: causar DEADLOCK)
-- Trava o produto 1 e depois tenta o produto 2 (FOR UPDATE). T3 faz o
-- caminho inverso (2 e depois 1). Ao se cruzarem formam um ciclo e o
-- PostgreSQL detecta o deadlock (SQLSTATE 40P01), abortando a vitima.
-- Pelo escalonamento desenhado, T2 e a vitima (ROLLBACK).
--
-- Variaveis psql: :sleep1 (janela para T3 travar o produto 2).
-- =====================================================================
\if :{?sleep1}
\else
  \set sleep1 1
\endif

\echo '[T2] inicio (transferencia 5 un. de prod1 -> prod2)'
BEGIN;

\echo '[T2] trava prod 1 (SELECT ... FOR UPDATE) - bloqueio explicito'
SELECT produto_id, estoque FROM produto WHERE produto_id = 1 FOR UPDATE;
UPDATE produto SET estoque = estoque - 5 WHERE produto_id = 1;

\echo '[T2] aguardando (deixa T3 travar o prod 2)...'
SELECT pg_sleep(:sleep1);

\echo '[T2] tenta travar prod 2 (FOR UPDATE) -> ESPERA / DEADLOCK'
SELECT produto_id, estoque FROM produto WHERE produto_id = 2 FOR UPDATE;
UPDATE produto SET estoque = estoque + 5 WHERE produto_id = 2;

COMMIT;
\echo '[T2] fim (se houve deadlock, a transacao foi abortada -> ROLLBACK)'
