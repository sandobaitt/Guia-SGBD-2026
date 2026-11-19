-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 8.2 - Restricción de esquema: CHECK con JSON_SCHEMA_VALID()
--   mysql -t -vvv --force -h 127.0.0.1 -u usr_g11 < ej08_2_check_json_schema.sql
-- (--force: continúa después de los dos INSERT que el motor debe rechazar)
-- =============================================================================
USE zakila_json;
SET NAMES utf8mb4;

-- Esquema (JSON Schema draft 4, el que implementa MySQL):
--   _id entero; First Name, Last Name y Country texto no vacío; Rentals arreglo;
--   ClienteVIP es opcional, pero si aparece solo puede valer "SÍ" o "NO".
SET @esquema = '{
  "type": "object",
  "required": ["_id", "First Name", "Last Name", "Country", "Rentals"],
  "properties": {
    "_id":          { "type": "integer" },
    "First Name":   { "type": "string", "minLength": 1 },
    "Last Name":    { "type": "string", "minLength": 1 },
    "Country":      { "type": "string", "minLength": 1 },
    "Rentals":      { "type": "array" },
    "ClienteVIP":   { "type": "string", "enum": ["SÍ", "NO"] }
  }
}';

-- 1. Antes de crear la restricción: los 599 documentos existentes deben cumplirla,
--    porque MySQL valida todas las filas al agregar un CHECK
SELECT COUNT(*) AS documentos,
       SUM(JSON_SCHEMA_VALID(@esquema, doc)) AS validos,
       SUM(NOT JSON_SCHEMA_VALID(@esquema, doc)) AS invalidos
FROM customers;

-- 2. Restricción (el CHECK no admite variables: el esquema va escrito literal,
--    idéntico a @esquema)
ALTER TABLE customers ADD CONSTRAINT chk_customers_esquema CHECK (JSON_SCHEMA_VALID('{
  "type": "object",
  "required": ["_id", "First Name", "Last Name", "Country", "Rentals"],
  "properties": {
    "_id":          { "type": "integer" },
    "First Name":   { "type": "string", "minLength": 1 },
    "Last Name":    { "type": "string", "minLength": 1 },
    "Country":      { "type": "string", "minLength": 1 },
    "Rentals":      { "type": "array" },
    "ClienteVIP":   { "type": "string", "enum": ["SÍ", "NO"] }
  }
}', doc));

SELECT CONSTRAINT_NAME, ENFORCED FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'zakila_json' AND TABLE_NAME = 'customers' AND CONSTRAINT_TYPE = 'CHECK';

-- 3. Inserción VÁLIDA 1: cliente nuevo sin ClienteVIP (la clave es opcional)
INSERT INTO customers (doc) VALUES ('{"_id": 9001, "First Name": "LUCIA", "Last Name": "BENITEZ",
  "Country": "Argentina", "City": "Resistencia", "Rentals": []}');

-- 4. Inserción VÁLIDA 2: cliente con ClienteVIP = "NO" (valor permitido por el enum)
INSERT INTO customers (doc) VALUES ('{"_id": 9002, "First Name": "MARTIN", "Last Name": "ACOSTA",
  "Country": "Paraguay", "Rentals": [], "ClienteVIP": "NO"}');

-- 5. Inserción INVÁLIDA 1: falta "Last Name" (campo requerido)
INSERT INTO customers (doc) VALUES ('{"_id": 9003, "First Name": "SIN",
  "Country": "Chile", "Rentals": []}');

-- 6. Inserción INVÁLIDA 2: ClienteVIP con un valor fuera del enum
INSERT INTO customers (doc) VALUES ('{"_id": 9004, "First Name": "ANA", "Last Name": "ROJAS",
  "Country": "Uruguay", "Rentals": [], "ClienteVIP": "TAL VEZ"}');

-- 7. Motivo de cada rechazo según el validador (regla que falló y dónde)
SELECT r.id,
       JSON_UNQUOTE(JSON_EXTRACT(r.rep, '$.valid'))                   AS valido,
       JSON_UNQUOTE(JSON_EXTRACT(r.rep, '$."schema-failed-keyword"')) AS regla_fallida,
       JSON_UNQUOTE(JSON_EXTRACT(r.rep, '$."document-location"'))     AS ubicacion_en_doc,
       JSON_UNQUOTE(JSON_EXTRACT(r.rep, '$."schema-location"'))       AS ubicacion_en_esquema
FROM (
  SELECT 9003 AS id, JSON_SCHEMA_VALIDATION_REPORT(@esquema,
    '{"_id": 9003, "First Name": "SIN", "Country": "Chile", "Rentals": []}') AS rep
  UNION ALL
  SELECT 9004, JSON_SCHEMA_VALIDATION_REPORT(@esquema,
    '{"_id": 9004, "First Name": "ANA", "Last Name": "ROJAS",
      "Country": "Uruguay", "Rentals": [], "ClienteVIP": "TAL VEZ"}')
) AS r;

-- 8. Resultado: solo entraron las dos válidas
SELECT id, doc->>'$."First Name"' AS nombre, doc->>'$."Last Name"' AS apellido,
       doc->>'$.Country' AS pais, IFNULL(doc->>'$.ClienteVIP', '(sin clave)') AS ClienteVIP
FROM customers WHERE id >= 9000 ORDER BY id;

-- 9. Limpieza: se quitan los documentos de prueba para que customers vuelva a
--    los 599 originales (no alteran el cruce del 8.3). La restricción queda activa.
DELETE FROM customers WHERE id IN (9001, 9002);
SELECT COUNT(*) AS customers_final FROM customers;
