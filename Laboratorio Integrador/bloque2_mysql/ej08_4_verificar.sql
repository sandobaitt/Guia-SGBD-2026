-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 8.4 - Verificaciones de la exportación
--   mysql -t -h 127.0.0.1 -u usr_g11 < ej08_4_verificar.sql
-- =============================================================================
SET NAMES utf8mb4;

-- 1. Por qué no alcanza JSON_OBJECT(): el tipo JSON reordena las claves
SELECT JSON_OBJECT('Ciudad', 'Resistencia', 'CodP', 'ARG') AS con_json_object;

-- 2. Documento armado con CONCAT + JSON_QUOTE: respeta el orden y es JSON válido
SELECT CONCAT('{"Ciudad": ', JSON_QUOTE(Name), ', "CodP": ', JSON_QUOTE(CountryCode), '}') AS exportado
FROM world_x.city WHERE Name = 'Resistencia';

-- 3. Todas las filas generan un JSON válido (incluidos nombres con acentos o comillas)
SELECT COUNT(*) AS ciudades,
       SUM(JSON_VALID(CONCAT('{"Ciudad": ', JSON_QUOTE(Name), ', "CodP": ', JSON_QUOTE(CountryCode), '}'))) AS json_validos
FROM world_x.city;
