# Controle de Concorrência em SQL — Design

**Spec:** `.specs/features/concorrencia-sql/spec.md`
**Context:** `.specs/features/concorrencia-sql/context.md`

---

## File layout

```
trab-infra/
├── docker-compose.yml          # serviço postgres:18
├── .env.example                # POSTGRES_USER/PASSWORD/DB, porta
├── sql/
│   ├── 01_schema.sql           # SCHEMA-01  (DROP+CREATE idempotente)
│   ├── 02_seed.sql             # SCHEMA-02
│   └── transactions/
│       ├── t1_phantom.sql      # TXN-01/02, SCN-01
│       ├── t2_deadlock.sql     # TXN-01/02, SCN-02
│       ├── t3_venda.sql        # TXN-01/02, SCN-03
│       └── t4_cadastro.sql     # TXN-01/02, SCN-03
├── scripts/
│   ├── lib.sh                  # helpers psql, cores, timing
│   ├── init_db.sh              # aplica schema + seed
│   ├── reset_db.sh             # re-seed rápido entre execuções
│   ├── scenario_phantom.sh     # SCN-01 isolado (T1 × T4)
│   ├── scenario_deadlock.sh    # SCN-02 isolado (T2 × T3)
│   ├── scenario_full.sh        # SCN-04 escalonamento T1–T4 com timestamps
│   ├── perf_isolation.sh       # PERF-01/02 (RC × SER, tempos + retries)
│   └── run_all.sh              # orquestra tudo de ponta a ponta
├── report/
│   └── relatorio.md            # RPT-01
└── logs/                       # saída das sessões (gitignore)
```

## Esquema (PostgreSQL)

- `cliente(cliente_id PK, nome, email UNIQUE)`
- `produto(produto_id PK, nome, categoria, preco NUMERIC(10,2), estoque INT CHECK >= 0)`
- `pedido(pedido_id PK, cliente_id FK, criado_em TIMESTAMP DEFAULT now(), status, total NUMERIC(10,2))`
- `item_pedido(pedido_id FK, produto_id FK, quantidade INT, preco_unitario NUMERIC(10,2), PK(pedido_id, produto_id))`

Seed: ~5 clientes; ~5 produtos sendo ≥3 em `eletronicos` (ids 1,2,3); 1 pedido exemplo.

## As 4 transações (≥4 instruções, dados em comum)

### T1 — Relatório de catálogo (vítima do phantom) — READ COMMITTED
```
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  -- explícito
BEGIN;
SELECT COUNT(*) FROM produto WHERE categoria='eletronicos';   -- 1ª leitura (ex.: 3)
SELECT pg_sleep(N);                                            -- janela p/ T4 inserir+commit
SELECT COUNT(*) FROM produto WHERE categoria='eletronicos';   -- 2ª leitura (ex.: 4) => PHANTOM
SELECT SUM(estoque) FROM produto WHERE categoria='eletronicos';
COMMIT;
```
Bloqueio: implícito de leitura (snapshot por statement em RC). Demonstra que em RC há phantom; em SERIALIZABLE/REPEATABLE READ as duas contagens seriam iguais.

### T2 — Transferência de estoque (causa deadlock; vítima) 
```
BEGIN;
SELECT estoque FROM produto WHERE produto_id=1 FOR UPDATE;   -- trava linha 1 (explícito)
UPDATE produto SET estoque=estoque-5 WHERE produto_id=1;
SELECT pg_sleep(N);                                          -- deixa T3 travar a linha 2
SELECT estoque FROM produto WHERE produto_id=2 FOR UPDATE;   -- espera linha 2 -> DEADLOCK
UPDATE produto SET estoque=estoque+5 WHERE produto_id=2;
COMMIT;   -- não alcançado: PostgreSQL aborta (40P01) => ROLLBACK
```

### T3 — Venda (consistente; sobrevivente do deadlock)
```
BEGIN;
SELECT estoque FROM produto WHERE produto_id=2 FOR UPDATE;   -- trava linha 2 (ordem oposta a T2)
UPDATE produto SET estoque=estoque-1 WHERE produto_id=2;
SELECT pg_sleep(N);                                          -- garante interleaving
INSERT INTO pedido(cliente_id,status,total) VALUES (...);
INSERT INTO item_pedido(...) VALUES (...);
SELECT estoque FROM produto WHERE produto_id=1 FOR UPDATE;   -- após T2 abortar, adquire e segue
UPDATE produto SET estoque=estoque-1 WHERE produto_id=1;
COMMIT;   -- consistente
```

### T4 — Cadastro/reposição de produto (consistente; gatilho do phantom)
```
BEGIN;
INSERT INTO produto(nome,categoria,preco,estoque)
  VALUES ('Fone Bluetooth','eletronicos',199.90,50);        -- novo item -> phantom p/ T1
UPDATE produto SET estoque=estoque+10 WHERE produto_id=3;
SELECT COUNT(*) FROM produto WHERE categoria='eletronicos';
COMMIT;   -- consistente; torna o insert visível a T1
```

Dados em comum: produtos 1 e 2 (T2×T3), categoria `eletronicos` (T1×T4), produto 3 (T4 atualiza).

## Orquestração / determinismo

- Cada transação roda como processo `psql` independente em background (`&`), lendo seu `.sql`.
- `pg_sleep()` nos pontos certos cria a ordem temporal; `lib.sh` faz timestamp das linhas para a tabela de escalonamento.
- `scenario_full.sh` lança T1,T2,T3,T4 com offsets de início para produzir o escalonamento abaixo.
- Logs em `logs/Tn.log`; um merge ordenado por tempo gera a evidência.

## Cenário de escalonamento alvo (modelo do PDF)

| Ordem | T1 | T2 | T3 | T4 |
|------|----|----|----|----|
| 1 | SELECT COUNT eletronicos = 3 | — | — | — |
| 2 | — | SELECT...FOR UPDATE prod 1 (trava 1) | — | — |
| 3 | — | — | SELECT...FOR UPDATE prod 2 (trava 2) | — |
| 4 | — | — | — | INSERT produto eletronicos; COMMIT |
| 5 | SELECT COUNT eletronicos = 4 **(phantom)** | — | — | — |
| 6 | — | SELECT...FOR UPDATE prod 2 → **espera** (T3 detém) | — | — |
| 7 | — | — | INSERT pedido/item; SELECT...FOR UPDATE prod 1 → **espera** (T2 detém) | — |
| 8 | — | **DEADLOCK 40P01 → ROLLBACK (vítima)** | T3 adquire prod 1; UPDATE; COMMIT | — |
| 9 | COMMIT | — | — | — |

Cada célula vira "Resultado" + "Observação" (bloqueio adquirido / espera / vítima) no relatório.

## Avaliação de desempenho

- **PERF-01 Tempo:** `perf_isolation.sh` roda o cenário de venda concorrente (T3-like) K vezes em RC e em SER, medindo wall-time por transação (`date +%s%N` no shell e/ou `\timing`).
- **PERF-02 Retries:** loop de retry em torno de cada transação contando abortos (40001 em SER, 40P01 em deadlock) até sucesso; soma tentativas por isolamento.
- Saída: tabela comparativa (isolamento × tempo médio × tentativas) impressa e copiada ao relatório.

## Decisões técnicas / riscos

- Phantom em PostgreSQL **só** aparece em READ COMMITTED → T1 fixa esse nível (key note em STATE.md).
- Deadlock depende de ordem oposta de locks (T2: 1→2; T3: 2→1) + janela de `pg_sleep`.
- Vítima do deadlock é escolhida pelo PostgreSQL; o desenho favorece T2 como vítima, mas o relatório deve registrar qual foi de fato.
- `LOCK TABLE IN SHARE/EXCLUSIVE MODE`: demonstrado adicionalmente na avaliação de desempenho (comparar com FOR UPDATE), atendendo a menção explícita da spec.

## Requirement coverage

SCHEMA-01→01_schema.sql · SCHEMA-02→02_seed.sql · TXN-01/02→t1..t4 · SCN-01→t1+t4/scenario_phantom · SCN-02→t2+t3/scenario_deadlock · SCN-03→t3,t4 · SCN-04→scenario_full · PERF-01/02→perf_isolation · RPT-01→relatorio.md
