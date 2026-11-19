-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 8.1 - Actualización documental con JSON_SET()
-- Agregar "ClienteVIP": "SÍ" a los clientes con 40 o más alquileres
--   mysql -t -h 127.0.0.1 -u usr_g11 < ej08_1_cliente_vip.sql
-- =============================================================================
USE zakila_json;
SET NAMES utf8mb4;

-- 1. ANTES: clientes que cumplen la condición (cantidad de elementos de $.Rentals)
SELECT id, doc->>'$."First Name"' AS nombre, doc->>'$."Last Name"' AS apellido,
       JSON_LENGTH(doc, '$.Rentals') AS alquileres,
       JSON_CONTAINS_PATH(doc, 'one', '$.ClienteVIP') AS tiene_vip
FROM customers
WHERE JSON_LENGTH(doc, '$.Rentals') >= 40
ORDER BY alquileres DESC, id;

-- 2. Actualización: JSON_SET agrega la clave si no existe (o la reemplaza si existe)
START TRANSACTION;
UPDATE customers
SET doc = JSON_SET(doc, '$.ClienteVIP', 'SÍ')
WHERE JSON_LENGTH(doc, '$.Rentals') >= 40;
SELECT ROW_COUNT() AS filas_actualizadas;
COMMIT;

-- 3. DESPUÉS: clientes marcados como VIP (deben ser exactamente los mismos)
SELECT id, doc->>'$."First Name"' AS nombre, doc->>'$."Last Name"' AS apellido,
       JSON_LENGTH(doc, '$.Rentals') AS alquileres, doc->>'$.ClienteVIP' AS ClienteVIP
FROM customers
WHERE doc->>'$.ClienteVIP' = 'SÍ'
ORDER BY alquileres DESC, id;

-- 4. Control: ningún cliente con menos de 40 alquileres quedó marcado
SELECT SUM(JSON_LENGTH(doc, '$.Rentals') >= 40) AS con_40_o_mas,
       SUM(JSON_CONTAINS_PATH(doc, 'one', '$.ClienteVIP')) AS marcados_vip,
       SUM(JSON_CONTAINS_PATH(doc, 'one', '$.ClienteVIP') AND JSON_LENGTH(doc, '$.Rentals') < 40) AS marcados_por_error
FROM customers;

-- 5. La clave quedó dentro del documento (claves de primer nivel de un cliente VIP)
SELECT id, JSON_KEYS(doc) AS claves FROM customers
WHERE doc->>'$.ClienteVIP' = 'SÍ' ORDER BY id LIMIT 1;
