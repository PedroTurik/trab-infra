-- =====================================================================
-- T4 - Cadastro / reposicao de produto  (PAPEL: executar SEM inconsistencias)
-- Insere um novo produto 'eletronicos' e commita. Esse INSERT commitado,
-- visto por T1 entre suas duas leituras, e o que provoca o PHANTOM em T1
-- (quando T1 roda em READ COMMITTED).
--
-- Variaveis psql: :sleep1 (deixa T1 fazer a 1a leitura antes do insert).
-- =====================================================================
\if :{?sleep1}
\else
  \set sleep1 1
\endif

\echo '[T4] inicio (cadastro de novo produto + reposicao)'
BEGIN;

\echo '[T4] aguardando (deixa T1 fazer a 1a leitura)...'
SELECT pg_sleep(:sleep1);

\echo '[T4] insere novo produto eletronicos (sera o phantom de T1)'
INSERT INTO produto (nome, categoria, preco, estoque)
  VALUES ('Fone Bluetooth ' || to_char(clock_timestamp(), 'HH24MISSMS'),
          'eletronicos', 199.90, 50);

\echo '[T4] reposicao de estoque do produto 3'
UPDATE produto SET estoque = estoque + 10 WHERE produto_id = 3;

SELECT count(*) AS eletronicos_apos_insert FROM produto WHERE categoria = 'eletronicos';

COMMIT;
\echo '[T4] COMMIT (consistente) - INSERT agora visivel para T1'
