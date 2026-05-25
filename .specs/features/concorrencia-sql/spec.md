# Controle de Concorrência em SQL — Specification

## Problem Statement

A disciplina exige um projeto prático em SQL que explore controle de concorrência:
esquema + dados + 4 transações concorrentes que acessam dados em comum, reproduzindo
phantom read, deadlock e execuções consistentes, além de avaliação de desempenho entre
níveis de isolamento. Tudo deve ser demonstrável em sessões paralelas e documentado num
relatório.

## Goals

- [ ] Esquema relacional (contexto loja/vendas) criado por script idempotente.
- [ ] Carga de dados inicial por script.
- [ ] 4 transações (≥4 instruções cada) com dados em comum, usando bloqueios implícitos e explícitos.
- [ ] Cenário de escalonamento determinístico que produz T1=phantom, T2=deadlock, T3/T4=consistentes.
- [ ] Avaliação de desempenho com ≥2 abordagens (tempo de execução + nº de tentativas/retries).
- [ ] Relatório Markdown com todos os scripts, tabela de escalonamento comentada e análise.

## Out of Scope

| Feature | Reason |
| ------- | ------ |
| Geração automática de PDF | `pandoc` ausente; conversão manual pelo usuário |
| Interface gráfica / app | Foco é SQL e concorrência |
| Outros SGBDs (Oracle/MySQL) | Decidido PostgreSQL |
| Tuning de performance de produção | Avaliação é comparativa entre isolamentos, não otimização |

---

## User Stories

### P1: Esquema e carga de dados ⭐ MVP

**User Story**: Como avaliador, quero um script que crie as tabelas e outro que insira dados, para ter base sobre a qual rodar as transações.

**Acceptance Criteria**:
1. WHEN executo `01_schema.sql` THEN o banco SHALL conter produto, cliente, pedido, item_pedido com PKs/FKs e constraints (estoque ≥ 0).
2. WHEN executo `01_schema.sql` novamente THEN ele SHALL ser idempotente (drop/create) sem erro.
3. WHEN executo `02_seed.sql` THEN SHALL existir ≥3 produtos na categoria `eletronicos`, ≥3 clientes e ≥1 pedido.

**Independent Test**: rodar os dois scripts e consultar as tabelas.

---

### P1: Quatro transações concorrentes ⭐ MVP

**User Story**: Como avaliador, quero 4 transações realistas que compartilham dados, para demonstrar concorrência.

**Acceptance Criteria**:
1. WHEN inspeciono cada transação THEN cada uma SHALL ter ≥4 instruções SQL.
2. WHEN inspeciono o conjunto THEN as transações SHALL acessar dados em comum (linhas de `produto`, categoria `eletronicos`).
3. WHEN inspeciono as transações THEN SHALL usar bloqueios implícitos (UPDATE) e explícitos (`SELECT ... FOR UPDATE` e/ou `LOCK TABLE`).
4. WHEN inspeciono T1 THEN ela SHALL configurar nível de isolamento explicitamente.

**Independent Test**: ler os 4 arquivos `tN_*.sql` e conferir instruções/locks.

---

### P1: Cenário de escalonamento determinístico ⭐ MVP

**User Story**: Como avaliador, quero rodar as 4 transações em paralelo e ver os comportamentos exigidos reproduzidos de forma confiável.

**Acceptance Criteria**:
1. WHEN rodo o cenário THEN T1 SHALL observar um **phantom read** (contagem muda entre dois SELECTs por insert commitado de T4) em READ COMMITTED.
2. WHEN rodo o cenário THEN T2 e outra transação SHALL entrar em **deadlock**, com o PostgreSQL abortando a vítima (SQLSTATE 40P01).
3. WHEN rodo o cenário THEN T3 SHALL concluir **sem inconsistências** (commit consistente).
4. WHEN rodo o cenário THEN T4 SHALL concluir **sem inconsistências** (commit consistente).
5. WHEN o cenário termina THEN as saídas das sessões SHALL ser registradas com ordem/tempo para montar a tabela de escalonamento.

**Independent Test**: `scripts/run_all.sh` (ou cenário específico) produz logs evidenciando cada comportamento.

---

### P2: Avaliação de desempenho

**User Story**: Como avaliador, quero comparar isolamentos e mecanismos de bloqueio.

**Acceptance Criteria**:
1. WHEN rodo a avaliação THEN SHALL medir **tempo de execução** das transações em READ COMMITTED e SERIALIZABLE.
2. WHEN rodo a avaliação THEN SHALL registrar **nº de tentativas/retries** (serialization failures 40001 / deadlocks 40P01).
3. WHEN a avaliação termina THEN os números SHALL ser resumidos para análise no relatório.

**Independent Test**: `scripts/perf_isolation.sh` imprime tabela comparativa.

---

### P2: Relatório

**User Story**: Como avaliador, quero um relatório formatado com tudo que a entrega exige.

**Acceptance Criteria**:
1. WHEN abro `report/relatorio.md` THEN SHALL conter: script de criação, script de inserção, código das 4 transações, tabela de escalonamento comentada e avaliação de desempenho.
2. WHEN leio a tabela de escalonamento THEN cada linha SHALL ter Resultado e Observação comentando bloqueios e esperas.

**Independent Test**: revisar o relatório contra os 5 itens da seção ENTREGA do PDF.

---

## Edge Cases

- WHEN estoque insuficiente numa venda (T3) THEN a transação SHALL falhar/abortar sem deixar estado parcial.
- WHEN a vítima do deadlock aborta THEN o estado do banco SHALL permanecer consistente (atomicidade).
- WHEN o container reinicia THEN os scripts de init SHALL recriar o estado de forma idempotente.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| -------------- | ----- | ----- | ------ |
| SCHEMA-01 | P1 Esquema | Design | Pending |
| SCHEMA-02 | P1 Esquema (seed) | Design | Pending |
| TXN-01 | P1 Transações | Design | Pending |
| TXN-02 | P1 Transações (locks) | Design | Pending |
| SCN-01 | P1 Phantom (T1) | Design | Pending |
| SCN-02 | P1 Deadlock (T2) | Design | Pending |
| SCN-03 | P1 Consistentes (T3,T4) | Design | Pending |
| SCN-04 | P1 Logs/escalonamento | Design | Pending |
| PERF-01 | P2 Tempo de execução | Design | Pending |
| PERF-02 | P2 Tentativas/retries | Design | Pending |
| RPT-01 | P2 Relatório | Design | Pending |

**Coverage:** 11 total, mapeados em design/tasks.

---

## Success Criteria

- [ ] `scripts/run_all.sh` sobe o banco, inicializa, roda o cenário e a avaliação de ponta a ponta.
- [ ] Logs evidenciam phantom read, deadlock e duas transações consistentes.
- [ ] Relatório cobre os 5 itens da seção ENTREGA do PDF.
