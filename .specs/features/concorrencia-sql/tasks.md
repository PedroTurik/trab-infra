# Controle de Concorrência em SQL — Tasks

**Design:** `.specs/features/concorrencia-sql/design.md`

Legend: `[P]` = parallelizable. Each task lists Done-when + verification.

## T01 — Docker Compose + env (PostgreSQL 18)
- Where: `docker-compose.yml`, `.env.example`, `.gitignore`
- Done when: `docker compose up -d` sobe o postgres e aceita conexão `psql`.
- Reqs: infra para tudo.

## T02 — Schema script (SCHEMA-01)
- Where: `sql/01_schema.sql`
- Depends: T01
- Done when: cria 4 tabelas com PK/FK/CHECK, idempotente (rodar 2× sem erro).

## T03 — Seed script (SCHEMA-02) [P after T02]
- Where: `sql/02_seed.sql`
- Done when: ≥3 produtos `eletronicos` (ids 1–3), ≥5 clientes, 1 pedido.

## T04 — Helpers + init scripts
- Where: `scripts/lib.sh`, `scripts/init_db.sh`, `scripts/reset_db.sh`
- Depends: T01
- Done when: `init_db.sh` aplica schema+seed; `reset_db.sh` recarrega seed.

## T05 — Transações T1–T4 (TXN-01/02)
- Where: `sql/transactions/t1_phantom.sql`, `t2_deadlock.sql`, `t3_venda.sql`, `t4_cadastro.sql`
- Depends: T02
- Done when: cada arquivo tem ≥4 instruções, locks corretos, isolamento explícito em T1.

## T06 — Cenário phantom isolado (SCN-01)
- Where: `scripts/scenario_phantom.sh`
- Depends: T04, T05
- Done when: log mostra COUNT 3 → 4 (phantom) em RC; e igual em SERIALIZABLE.

## T07 — Cenário deadlock isolado (SCN-02)
- Where: `scripts/scenario_deadlock.sh`
- Depends: T04, T05
- Done when: log mostra `deadlock detected` (40P01) e vítima com ROLLBACK; sobrevivente commita.

## T08 — Cenário completo / escalonamento (SCN-04)
- Where: `scripts/scenario_full.sh`
- Depends: T06, T07
- Done when: roda T1–T4 com timestamps; saída permite montar a tabela de escalonamento.

## T09 — Avaliação de desempenho (PERF-01/02)
- Where: `scripts/perf_isolation.sh`
- Depends: T04, T05
- Done when: imprime tabela isolamento × tempo médio × tentativas (RC × SER).

## T10 — Orquestrador run_all (SCN-04 ponta a ponta)
- Where: `scripts/run_all.sh`
- Depends: T06–T09
- Done when: um comando sobe DB, inicializa, roda cenários e perf.

## T11 — Relatório Markdown (RPT-01)
- Where: `report/relatorio.md`
- Depends: T08, T09
- Done when: cobre os 5 itens da ENTREGA (scripts, transações, tabela de escalonamento comentada, avaliação).

## T12 — Verificação end-to-end + README
- Where: `README.md`
- Depends: all
- Done when: `run_all.sh` roda limpo num container fresco; README documenta uso.
