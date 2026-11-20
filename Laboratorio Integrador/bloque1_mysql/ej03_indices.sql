-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 3.e - Índices B-Tree (y el índice que evalúa 3.f)
--   mysql -h 127.0.0.1 -u usr_g11 -p -t -vvv employees < ej03_indices.sql
-- =============================================================================
USE employees;

-- 3.e Índices pedidos por la consigna
CREATE INDEX idx_employees_last_name ON employees (last_name);   -- 3.b y 3.d
CREATE INDEX idx_salaries_salary     ON salaries (salary);       -- 3.c y 3.d

-- 3.f titles solo tiene la PK (emp_no, title, from_date): title no es la primera
--     columna, así que ninguna búsqueda por cargo puede usarla. Se agrega un índice
--     por title para evaluar LIKE 'Engineer%' frente a = 'Engineer'.
CREATE INDEX idx_titles_title        ON titles (title);

-- Estadísticas actualizadas para que el optimizador conozca los índices nuevos
ANALYZE TABLE employees, salaries, titles;

SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, CARDINALITY, INDEX_TYPE
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'employees' AND INDEX_NAME LIKE 'idx\_%'
ORDER BY TABLE_NAME, INDEX_NAME;
