-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 7 - Verificación de la carga
--   mysql -t -h 127.0.0.1 -u usr_g11 < ej07_3_verificar.sql
-- =============================================================================
USE zakila_json;

-- Filas por tabla (esperado: 599 / 1000 / 2)
SELECT 'customers' AS tabla, COUNT(*) AS filas FROM customers
UNION ALL SELECT 'films', COUNT(*) FROM films
UNION ALL SELECT 'stores', COUNT(*) FROM stores;

-- El tipo de la columna es JSON nativo y cada valor es un objeto válido
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'zakila_json' AND COLUMN_NAME = 'doc';
SELECT JSON_TYPE(doc) AS tipo, COUNT(*) AS documentos FROM customers GROUP BY tipo;

-- Arreglos anidados: alquileres por cliente (esperado: 16044 en total, 12 a 46)
SELECT COUNT(*) AS clientes, SUM(JSON_LENGTH(doc, '$.Rentals')) AS alquileres,
       MIN(JSON_LENGTH(doc, '$.Rentals')) AS min_alq, MAX(JSON_LENGTH(doc, '$.Rentals')) AS max_alq
FROM customers;
SELECT id, doc->>'$.City' AS ciudad, doc->>'$.Country' AS pais,
       JSON_LENGTH(doc, '$.Inventory') AS items_inventario
FROM stores;

-- Muestra: un cliente y una película con extracción de rutas JSON
SELECT id, doc->>'$."First Name"' AS nombre, doc->>'$."Last Name"' AS apellido,
       doc->>'$.Country' AS pais, doc->>'$.Rentals[0]."Film Title"' AS primer_alquiler
FROM customers WHERE id = 1;
SELECT id, doc->>'$.Title' AS titulo, doc->>'$.Category' AS categoria,
       JSON_LENGTH(doc, '$.Actors') AS actores
FROM films WHERE id = 1;
