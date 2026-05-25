# STATE — Memory

## Decisions

- **2026-05-20** — SGBD = PostgreSQL. *Why:* gratuito, Docker-friendly, suporta todas as operações da spec (`SELECT ... FOR UPDATE`, `LOCK TABLE IN SHARE/EXCLUSIVE MODE`, READ COMMITTED e SERIALIZABLE real via SSI).
- **2026-05-20** — Domínio = loja/vendas (produto, cliente, pedido, item_pedido). *Why:* usuário pediu "você decide, priorize simplicidade"; é o próprio exemplo da spec e mapeia bem nos 4 comportamentos exigidos.
- **2026-05-20** — Orquestração = Docker Compose + scripts shell dirigindo `psql`. Determinismo via `pg_sleep()`.
- **2026-05-20** — Entregável = relatório Markdown (sem auto-PDF; `pandoc` ausente).

## Key technical note

- Em PostgreSQL o **phantom read ocorre em READ COMMITTED** e é **evitado em REPEATABLE READ/SERIALIZABLE** (snapshot/SSI). Logo T1 demonstra phantom rodando em READ COMMITTED enquanto T4 insere+commita.
- O **deadlock** (T2) surge de duas transações travando as mesmas linhas em ordem oposta; PostgreSQL detecta (`deadlock_timeout`, default 1s) e aborta a vítima (SQLSTATE 40P01).
- **SERIALIZABLE** pode abortar com *serialization failure* (SQLSTATE 40001) → exige retry (métrica de desempenho).

## Status (2026-05-20)

- **CONCLUÍDO e verificado end-to-end** (`scripts/run_all.sh`, exit 0, container fresco).
- Resultados reais: phantom RC 3→4 / SER 3→3; deadlock sempre com **T2 vítima** (ROLLBACK) e T3 commit; estado final consistente (prod1=29, prod2=39, prod3=35 + novo eletronicos).
- Desempenho: RC 0 retries ~1010ms · SER ~102–110 retries ~4200–4500ms · LOCK TABLE 0 retries ~1030ms.

## Achado técnico importante (seleção de vítima de deadlock)

- O `deadlock_timeout` do PostgreSQL é **one-shot** por espera: se a checagem dispara antes do ciclo se fechar, o backend NÃO re-arma e volta a esperar. Logo a vítima é quem **bloqueia primeiro** desde que o ciclo se complete dentro de 1 lance de `deadlock_timeout` (~1s) do seu bloqueio. Para fixar T2 como vítima: T2 bloqueia primeiro e o gap de início T2→T3 deve ser < 1s (usamos sleeps iguais = 1s e offset 0.2s).

## Blockers

- Nenhum.

## Preferences

- Usuário prioriza simplicidade.

## Deferred ideas

- Geração automática de PDF (pandoc/LaTeX) — fora de escopo por ora.
