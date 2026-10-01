-- GRUPO 5 Pruebas

-- DESAFIO 1
-- Implementar mecanismo para impedir saldo negativo.
-- CASO VALIDO
UPDATE cuenta
SET saldo = 1000.00 
WHERE cuenta_id = 3;

SELECT * FROM cuenta
WHERE cuenta_id = 3;

-- CASO LIMITE
UPDATE cuenta
SET saldo = 0.00 
WHERE cuenta_id = 3;

SELECT * FROM cuenta
WHERE cuenta_id = 3;

-- CASO INVALIDO
UPDATE cuenta
SET saldo = -1.00
WHERE cuenta_id = 3;

SELECT * FROM cuenta
WHERE cuenta_id = 3;

-- DESAFIO 2
-- Auditar cambios de precio.

-- CASO VÁLIDO
-- Cambio real de precio: debe generar un registro de auditoría.
UPDATE producto
SET precio = 1200
WHERE producto_id = 1;

SELECT * FROM producto
WHERE producto_id = 1;

SELECT * FROM auditoria_precio
ORDER BY auditoria_id;


-- CASO LÍMITE
-- Se ejecuta UPDATE pero el precio no cambia.
-- No debe generarse una nueva auditoría.
UPDATE producto
SET precio = 1200
WHERE producto_id = 1;

SELECT * FROM auditoria_precio
ORDER BY auditoria_id;

-- CASO INVÁLIDO
-- Un precio negativo debe ser rechazado.
UPDATE producto
SET precio = NULL
WHERE producto_id = 1;

SELECT *
FROM producto
WHERE producto_id = 1;

SELECT *
FROM auditoria_precio
ORDER BY auditoria_id;

--DESAFIO 3
-- Crear función o procedimiento de clasificación de cliente.

-- CASO VALIDO
SELECT cliente_id, nombre, clasificar_cliente(cliente_id, 2026) AS categoria_2026 FROM cliente;
SELECT clasificar_cliente(1, 2026);

-- CASO LIMITE
SELECT nombre, clasificar_cliente(cliente_id, 2027) AS categoria 
FROM cliente 
WHERE cliente_id = 1;

-- CASO INVALIDO
SELECT clasificar_cliente(NULL, NULL) AS categoria;


-- DESAFIO 4
-- Agregar restricción para impedir precio <= 0.

-- CASO VALIDO
INSERT INTO producto (producto_id, nombre, precio) VALUES (10, 'Mouse Pad', 2500.00);
-- CASO LIMITE
INSERT INTO producto (producto_id, nombre, precio) VALUES (11, 'Sticker Promo', 0.00);
-- CASO INVALIDO
INSERT INTO producto (producto_id, nombre, precio) VALUES (12, 'Cable Fallado', -100.00);
