-- =====================================================================
-- Trabalho 2 - Item 2 da ENTREGA: insercao de dados
-- Re-executavel: limpa as tabelas e recarrega os dados base.
-- =====================================================================

TRUNCATE item_pedido, pedido, produto, cliente RESTART IDENTITY CASCADE;

-- Clientes ----------------------------------------------------------------
INSERT INTO cliente (nome, email) VALUES
    ('Ana Souza',     'ana@example.com'),
    ('Bruno Lima',    'bruno@example.com'),
    ('Carla Dias',    'carla@example.com'),
    ('Diego Alves',   'diego@example.com'),
    ('Elis Martins',  'elis@example.com');

-- Produtos ----------------------------------------------------------------
-- ids 1..3 sao 'eletronicos' (dados em comum das transacoes T1/T2/T3/T4).
INSERT INTO produto (nome, categoria, preco, estoque) VALUES
    ('Notebook Pro',     'eletronicos', 4500.00, 30),  -- produto_id = 1
    ('Smartphone X',     'eletronicos', 2999.90, 40),  -- produto_id = 2
    ('Monitor 27"',      'eletronicos', 1200.00, 25),  -- produto_id = 3
    ('Cadeira Gamer',    'moveis',       899.00, 15),  -- produto_id = 4
    ('Mesa Office',      'moveis',       650.00, 10);  -- produto_id = 5

-- Pedido de exemplo -------------------------------------------------------
INSERT INTO pedido (cliente_id, status, total) VALUES (1, 'FECHADO', 4500.00);
INSERT INTO item_pedido (pedido_id, produto_id, quantidade, preco_unitario)
    VALUES (1, 1, 1, 4500.00);

-- Conferencia -------------------------------------------------------------
SELECT 'clientes' AS tabela, count(*) AS linhas FROM cliente
UNION ALL SELECT 'produtos', count(*) FROM produto
UNION ALL SELECT 'eletronicos', count(*) FROM produto WHERE categoria='eletronicos'
UNION ALL SELECT 'pedidos', count(*) FROM pedido
UNION ALL SELECT 'itens', count(*) FROM item_pedido;
