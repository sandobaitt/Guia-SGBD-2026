-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 7 - Tablas con columna de tipo nativo JSON
-- Ejecutar como usr_g11:  mysql -t -h 127.0.0.1 -u usr_g11 < ej07_1_tablas_json.sql
-- Cada documento completo va en la columna doc (JSON). La clave primaria es una
-- columna generada a partir de doc->>'$._id', así el motor garantiza que no se
-- repitan documentos y se puede hacer JOIN por id sin extraer la ruta cada vez.
-- =============================================================================
USE zakila_json;

DROP TABLE IF EXISTS customers, films, stores;

CREATE TABLE customers (
  doc JSON NOT NULL,
  id  INT GENERATED ALWAYS AS (doc->>'$._id') STORED NOT NULL PRIMARY KEY
) ENGINE = InnoDB;

CREATE TABLE films (
  doc JSON NOT NULL,
  id  INT GENERATED ALWAYS AS (doc->>'$._id') STORED NOT NULL PRIMARY KEY
) ENGINE = InnoDB;

CREATE TABLE stores (
  doc JSON NOT NULL,
  id  INT GENERATED ALWAYS AS (doc->>'$._id') STORED NOT NULL PRIMARY KEY
) ENGINE = InnoDB;

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, COLUMN_KEY, EXTRA
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'zakila_json'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
