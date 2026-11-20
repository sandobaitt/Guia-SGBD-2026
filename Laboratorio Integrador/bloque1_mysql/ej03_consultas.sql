-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 3 - Consultas con EXPLAIN ANALYZE (se ejecuta ANTES y DESPUÉS de
-- ej03_indices.sql, sin cambiar nada más, para comparar los planes)
--   mysql -h 127.0.0.1 -u usr_g11 -p -vvv -r employees < ej03_consultas.sql
-- EXPLAIN ANALYZE ejecuta la consulta y muestra, por cada nodo del plan, el costo
-- estimado, las filas estimadas y el tiempo y las filas reales.
-- =============================================================================
USE employees;
SELECT VERSION() AS motor, @@explain_format AS formato_explain;
SELECT INDEX_NAME, TABLE_NAME, COLUMN_NAME FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'employees' AND TABLE_NAME IN ('employees','salaries','titles') AND INDEX_NAME <> 'PRIMARY'
ORDER BY TABLE_NAME, INDEX_NAME;

-- 3.a Consulta 1 (Histórico): datos personales + historial completo de salarios
SELECT COUNT(*) AS filas_3a FROM employees e JOIN salaries s ON s.emp_no = e.emp_no;
EXPLAIN ANALYZE
SELECT e.emp_no, e.birth_date, e.first_name, e.last_name, e.gender, e.hire_date,
       s.salary, s.from_date, s.to_date
FROM employees e
JOIN salaries s ON s.emp_no = e.emp_no
ORDER BY e.emp_no, s.from_date;

-- 3.b Consulta 2 (Búsqueda por apellido), ordenada alfabéticamente
SELECT last_name, COUNT(*) AS empleados FROM employees
WHERE last_name LIKE 'Gut%' OR last_name = 'González' GROUP BY last_name;
EXPLAIN ANALYZE
SELECT emp_no, first_name, last_name, hire_date
FROM employees
WHERE last_name LIKE 'Gut%' OR last_name = 'González'
ORDER BY last_name, first_name;

-- 3.c Consulta 3 (Rangos y vigencia): sueldos vigentes entre 100.000 y 110.000
SELECT COUNT(*) AS filas_3c FROM salaries WHERE salary BETWEEN 100000 AND 110000 AND to_date = '9999-01-01';
EXPLAIN ANALYZE
SELECT emp_no, salary, from_date
FROM salaries
WHERE salary BETWEEN 100000 AND 110000
  AND to_date = '9999-01-01';

-- 3.d Consulta 4 (Combinación con CTE): empleados de 3.b con sueldo vigente
--     en un rango amplio (60.000 a 110.000), con su cargo vigente
EXPLAIN ANALYZE
WITH emp_apellido AS (
  SELECT emp_no, first_name, last_name
  FROM employees
  WHERE last_name LIKE 'Gut%' OR last_name = 'González'
),
sueldo_vigente AS (
  SELECT emp_no, salary
  FROM salaries
  WHERE salary BETWEEN 60000 AND 110000 AND to_date = '9999-01-01'
)
SELECT a.emp_no, a.first_name, a.last_name, v.salary
FROM emp_apellido a
JOIN sueldo_vigente v ON v.emp_no = a.emp_no
ORDER BY a.last_name, a.first_name;

WITH emp_apellido AS (
  SELECT emp_no, first_name, last_name FROM employees
  WHERE last_name LIKE 'Gut%' OR last_name = 'González'),
sueldo_vigente AS (
  SELECT emp_no, salary FROM salaries
  WHERE salary BETWEEN 60000 AND 110000 AND to_date = '9999-01-01')
SELECT COUNT(*) AS filas_3d, MIN(v.salary) AS sueldo_min, MAX(v.salary) AS sueldo_max
FROM emp_apellido a JOIN sueldo_vigente v ON v.emp_no = a.emp_no;

-- 3.f Búsqueda de cargos: LIKE 'Engineer%' frente a = 'Engineer' (y un LIKE con
--     comodín al inicio, que nunca puede usar un índice B-Tree)
SELECT 'LIKE Engineer%' AS condicion, COUNT(*) AS filas FROM titles WHERE title LIKE 'Engineer%'
UNION ALL SELECT '= Engineer', COUNT(*) FROM titles WHERE title = 'Engineer'
UNION ALL SELECT 'LIKE %Engineer', COUNT(*) FROM titles WHERE title LIKE '%Engineer';
EXPLAIN ANALYZE SELECT emp_no, from_date FROM titles WHERE title LIKE 'Engineer%';
EXPLAIN ANALYZE SELECT emp_no, from_date FROM titles WHERE title = 'Engineer';
EXPLAIN ANALYZE SELECT emp_no, from_date FROM titles WHERE title LIKE '%Engineer';
