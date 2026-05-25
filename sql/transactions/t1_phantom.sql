-- =====================================================================
-- T1 - Relatorio de catalogo  (PAPEL: causar PHANTOM READ)
-- Le duas vezes a contagem de produtos 'eletronicos'. Entre as leituras,
-- T4 insere e commita um novo produto da categoria. Em READ COMMITTED a
-- 2a leitura ve a linha nova (phantom). Em SERIALIZABLE as duas leituras
-- sao iguais (snapshot estavel).
--
-- Variaveis psql: :iso (nivel de isolamento), :sleep1 (janela p/ T4).
-- =====================================================================
\if :{?iso}
\else
  \set iso 'READ COMMITTED'
\endif
\if :{?sleep1}
\else
  \set sleep1 5
\endif

\echo '[T1] inicio | isolamento =' :'iso'
BEGIN;
SET TRANSACTION ISOLATION LEVEL :iso;

\echo '[T1] 1a leitura: COUNT eletronicos'
SELECT count(*) AS leitura1_eletronicos FROM produto WHERE categoria = 'eletronicos';

\echo '[T1] aguardando (janela para T4 inserir+commitar)...'
SELECT pg_sleep(:sleep1);

\echo '[T1] 2a leitura: COUNT eletronicos (PHANTOM se diferente da 1a)'
SELECT count(*) AS leitura2_eletronicos FROM produto WHERE categoria = 'eletronicos';
SELECT sum(estoque) AS soma_estoque_eletronicos FROM produto WHERE categoria = 'eletronicos';

COMMIT;
\echo '[T1] COMMIT'
