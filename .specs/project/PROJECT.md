# PROJECT — Trabalho 2: Controle de Concorrência em SQL

## Vision

Projeto prático acadêmico (disciplina *Infraestrutura para Gestão de Dados*) que
demonstra, de forma reproduzível, conceitos de **controle de concorrência** em um
banco relacional: bloqueios implícitos/explícitos, níveis de isolamento, phantom
reads, deadlocks e avaliação de desempenho.

## Goals

- Esquema relacional simples num contexto de **loja/vendas** (produto, cliente, pedido, item_pedido).
- 4 transações concorrentes (≥4 instruções cada) que acessam dados em comum.
- Reproduzir, de forma determinística: **T1 phantom read**, **T2 deadlock**, **T3/T4 sem inconsistências**.
- Simulação de acesso concorrente em sessões paralelas, com tabela de escalonamento comentada.
- Avaliação de desempenho comparando **READ COMMITTED × SERIALIZABLE** e o uso de `SELECT ... FOR UPDATE` / `LOCK TABLE`.
- Tudo automatizado via **Docker + scripts shell**; entregável final = relatório em Markdown (convertível a PDF).

## Constraints / Decisions

- SGBD: **PostgreSQL** (em container Docker).
- Orquestração: **Docker Compose + scripts shell** dirigindo múltiplas sessões `psql`.
- Determinismo das interleavings via `pg_sleep()` + `deadlock_timeout`.
- Relatório: **Markdown** (`pandoc` não está instalado; conversão a PDF fica a cargo do usuário).

## Source of truth

`especificacao-trabalho.pdf` (raiz do repositório).
