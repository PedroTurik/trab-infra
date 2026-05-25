# Controle de Concorrência em SQL — Context

**Gathered:** 2026-05-20
**Spec:** `.specs/features/concorrencia-sql/spec.md`
**Status:** Ready for design

---

## Feature Boundary

Entregar código + scripts (e relatório Markdown) que satisfaçam o Trabalho 2: esquema,
dados, 4 transações concorrentes, cenário de escalonamento (phantom/deadlock/consistentes)
e avaliação de desempenho entre níveis de isolamento — tudo em PostgreSQL via Docker.

---

## Implementation Decisions

### SGBD e ambiente
- PostgreSQL em container Docker (`docker-compose.yml`).
- Scripts shell dirigem múltiplas sessões `psql` para simular usuários simultâneos.

### Domínio
- Loja/vendas, mantido **simples**: `produto`, `cliente`, `pedido`, `item_pedido`.
- Dado em comum entre transações: linhas de `produto` (ids 1 e 2) e a categoria `eletronicos`.

### Mapeamento dos comportamentos exigidos (decisão-chave)
- **T1 (relatório/contagem)** roda em READ COMMITTED; lê COUNT por categoria, espera, relê → vê o phantom inserido por T4.
- **T2 (transferência de estoque entre produtos)** trava produto 1 e depois 2.
- **T3 (venda)** trava produto 2 e depois 1 (ordem oposta a T2) → fecha o ciclo de deadlock com T2; T3 sobrevive e commita consistente, T2 é a vítima e dá ROLLBACK.
- **T4 (cadastro/reposição de produto)** insere novo produto em `eletronicos` e commita → dispara o phantom de T1.

### Determinismo
- Interleavings forçadas com `pg_sleep()` posicionados nos scripts de cada sessão.
- `deadlock_timeout` padrão (1s) garante detecção do deadlock.

### Avaliação de desempenho (≥2 abordagens)
- Tempo de execução (READ COMMITTED × SERIALIZABLE).
- Número de tentativas/retries (serialization failure 40001 e deadlock 40P01).

### Agent's Discretion
- Quantidade exata de linhas de seed, nomes de produtos/clientes, valores de `pg_sleep`.
- Layout final do relatório (desde que cubra os 5 itens da ENTREGA).

---

## Specific References

- A tabela de escalonamento deve seguir o modelo do PDF (linhas: Ordem, Resultado, Observação; colunas T1–T4).
- "Comentar todos os bloqueios e esperas a cada linha" → coluna/observação por passo.

---

## Deferred Ideas

- Geração automática de PDF do relatório.
- Variante em outro SGBD para comparação.
