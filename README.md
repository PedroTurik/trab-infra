# Trabalho 2 — Controle de Concorrência em SQL (PostgreSQL)

Projeto prático que demonstra controle de concorrência em PostgreSQL: esquema +
dados + 4 transações concorrentes que reproduzem **phantom read**, **deadlock** e
execuções **consistentes**, mais uma **avaliação de desempenho** entre níveis de
isolamento. Tudo automatizado via Docker + scripts shell.

Autor: Pedro Turik Firmino
Matrícula: 22200699

O relatório de entrega está em [`report/relatorio.pdf`](report/relatorio.pdf).

## Pré-requisitos

- Docker + Docker Compose
- Bash

## Como rodar tudo

```bash
cp .env.example .env        # opcional (há defaults)
bash scripts/run_all.sh     # sobe o banco, inicializa e roda todos os cenários
```

`run_all.sh` executa, em ordem: subida do container → schema + seed → cenário de
phantom → cenário de deadlock → escalonamento completo (T1–T4) → avaliação de
desempenho. As saídas também são gravadas em `logs/`.

## Scripts individuais

| Comando | O que faz |
|---------|-----------|
| `bash scripts/init_db.sh` | Sobe o container e aplica `01_schema.sql` + `02_seed.sql` |
| `bash scripts/reset_db.sh` | Recarrega apenas os dados (mantém o schema) |
| `bash scripts/scenario_phantom.sh` | T1×T4 em READ COMMITTED (com phantom) e SERIALIZABLE (sem) |
| `bash scripts/scenario_deadlock.sh` | T2×T3 — deadlock, T2 é a vítima (ROLLBACK), T3 sobrevive |
| `bash scripts/scenario_full.sh` | As 4 transações em paralelo (base da tabela de escalonamento) |
| `bash scripts/perf_isolation.sh` | Desempenho: READ COMMITTED × SERIALIZABLE × LOCK TABLE |

Parâmetros de carga do desempenho: `W=8 REPS=20 bash scripts/perf_isolation.sh`.

## Estrutura

```
docker-compose.yml          # PostgreSQL 18
sql/01_schema.sql           # criação das tabelas (idempotente)
sql/02_seed.sql             # inserção de dados
sql/transactions/t1..t4.sql # as 4 transações
sql/perf_tx.sql             # transação usada na avaliação de desempenho
scripts/                    # orquestração (Docker + psql + timing)
report/relatorio.md         # relatório da entrega
logs/                       # saídas das execuções
.specs/                     # planejamento (spec, design, tasks)
```

## Como funciona a concorrência

Cada transação roda como uma sessão `psql` independente, em paralelo (`&`). A
interleaving é tornada **determinística** com `pg_sleep()` posicionado nos pontos
certos de cada `.sql`, e cada linha de saída é carimbada com horário para montar a
tabela de escalonamento (`scripts/lib.sh`).

Limpar tudo: `docker compose down -v`.
