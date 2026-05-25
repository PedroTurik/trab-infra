-- =====================================================================
-- Trabalho 2 - Controle de Concorrencia em SQL (PostgreSQL)
-- Item 1 da ENTREGA: criacao do esquema do banco de dados
-- Contexto: loja / vendas
-- Script idempotente (pode ser executado varias vezes).
-- =====================================================================

DROP TABLE IF EXISTS item_pedido CASCADE;
DROP TABLE IF EXISTS pedido      CASCADE;
DROP TABLE IF EXISTS produto     CASCADE;
DROP TABLE IF EXISTS cliente     CASCADE;

CREATE TABLE cliente (
    cliente_id  SERIAL PRIMARY KEY,
    nome        VARCHAR(120) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE produto (
    produto_id  SERIAL PRIMARY KEY,
    nome        VARCHAR(120) NOT NULL,
    categoria   VARCHAR(60)  NOT NULL,
    preco       NUMERIC(10,2) NOT NULL CHECK (preco >= 0),
    estoque     INTEGER       NOT NULL CHECK (estoque >= 0)
);

CREATE INDEX idx_produto_categoria ON produto (categoria);

CREATE TABLE pedido (
    pedido_id   SERIAL PRIMARY KEY,
    cliente_id  INTEGER NOT NULL REFERENCES cliente (cliente_id),
    criado_em   TIMESTAMP NOT NULL DEFAULT now(),
    status      VARCHAR(20) NOT NULL DEFAULT 'ABERTO',
    total       NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (total >= 0)
);

CREATE TABLE item_pedido (
    pedido_id      INTEGER NOT NULL REFERENCES pedido (pedido_id),
    produto_id     INTEGER NOT NULL REFERENCES produto (produto_id),
    quantidade     INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(10,2) NOT NULL CHECK (preco_unitario >= 0),
    PRIMARY KEY (pedido_id, produto_id)
);
