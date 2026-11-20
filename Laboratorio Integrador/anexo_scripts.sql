/*
============================================================================
LABORATORIO INTEGRADOR - SISTEMAS DE GESTIÓN DE BASES DE DATOS (SGBD)
GRUPO: 11
INTEGRANTES: Aguirre Egea Emiliano, Ghione Lucas, Pagno Agustin, Sandoval Lautaro
CONSOLIDADO DE SCRIPTS (BLOQUES 1, 2 Y 3)
Generado a partir de los archivos de bloque1_mysql/, bloque2_mysql/ y bloque3_mongodb/:
si se modifica un script, regenerar este anexo (no editarlo a mano).
Los archivos .sql se copian tal cual. Los .js y .sh van dentro de comentarios de bloque:
se ejecutan en mongosh, MySQL Shell o Bash, según indica su encabezado.
Ninguna clave figura en los scripts: se piden por teclado o se leen de variables/archivos 600.
============================================================================
*/

/* ****************************************************************************
BLOQUE 1: ADMINISTRACIÓN Y RENDIMIENTO RELACIONAL (MYSQL 9.7)
**************************************************************************** */

-- ============================================================================
-- Archivo: bloque1_mysql/ej01_usuarios.sql
-- ============================================================================
-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 1 - Cuentas de usuario y seguridad granular (MySQL 9.7)
-- Se ejecuta como administrador del servidor (en la VM: sudo mysql). Las claves NO
-- están en el archivo: llegan en las variables @clave_g11 y @clave_backup.
--   sudo mysql -t -vvv --init-command="SET @clave_g11='...', @clave_backup='...'" < ej01_usuarios.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1 Administrador de grupo: 'usr_g11'@'%' (desde cualquier host)
-- -----------------------------------------------------------------------------
SET @sql = CONCAT("CREATE USER IF NOT EXISTS 'usr_g11'@'%' IDENTIFIED BY ", QUOTE(@clave_g11));
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- Bases del laboratorio: todos los privilegios y la posibilidad de delegarlos
-- (GRANT OPTION), pero solo sobre estas bases. No recibe privilegios sobre
-- mysql.* ni sobre bases ajenas, por eso no es un súper-usuario.
GRANT ALL PRIVILEGES ON employees.*   TO 'usr_g11'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON empleados.*   TO 'usr_g11'@'%' WITH GRANT OPTION;   -- Ej. 2 (aún no existe)
GRANT ALL PRIVILEGES ON world_x.*     TO 'usr_g11'@'%' WITH GRANT OPTION;   -- Ej. 8
GRANT ALL PRIVILEGES ON zakila_json.* TO 'usr_g11'@'%' WITH GRANT OPTION;   -- Ej. 7 y 8

-- Privilegios globales administrativos imprescindibles para el Bloque 1:
--   FILE               -> SELECT ... INTO OUTFILE y LOAD DATA INFILE (Ej. 2)
--   PROCESS            -> ver las transacciones de otras sesiones en innodb_trx / data_locks (Ej. 5)
--   RELOAD             -> FLUSH LOGS y mysqldump --flush-logs (Ej. 6)
--   REPLICATION CLIENT -> SHOW BINARY LOGS / SHOW BINARY LOG STATUS (Ej. 6)
GRANT FILE, PROCESS, RELOAD, REPLICATION CLIENT ON *.* TO 'usr_g11'@'%';
-- PROCESS alcanza para information_schema.innodb_trx, pero performance_schema.data_locks
-- y data_lock_waits (Ej. 5) exigen SELECT sobre performance_schema (solo lectura de métricas).
GRANT SELECT ON performance_schema.* TO 'usr_g11'@'%';

-- Con el binlog activo, MySQL exige SUPER para crear triggers y funciones (ERROR 1419),
-- porque podrían dar resultados distintos al reproducirse en una réplica o en un PITR.
-- En vez de dar SUPER (obsoleto y casi ilimitado) a usr_g11, el administrador declara
-- que confía en quienes ya tienen CREATE ROUTINE / TRIGGER (Ej. 4). La variable está
-- marcada como obsoleta en 9.7 (warning 1287) pero sigue vigente.
SET PERSIST log_bin_trust_function_creators = ON;

-- -----------------------------------------------------------------------------
-- 1.2 Usuario de backup: 'usr_backup'@'localhost' (solo desde la propia VM)
-- -----------------------------------------------------------------------------
SET @sql = CONCAT("CREATE USER IF NOT EXISTS 'usr_backup'@'localhost' IDENTIFIED BY ", QUOTE(@clave_backup));
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- Sobre employees, solo lo que mysqldump necesita para leer (nunca escribir):
--   SELECT       -> leer las filas de cada tabla
--   SHOW VIEW    -> volcar la definición de las vistas (current_dept_emp, dept_emp_latest_date)
--   TRIGGER      -> volcar los triggers (--triggers; el del Ej. 4.2)
--   EVENT        -> volcar los eventos (--events; el del Ej. 6.2)
-- No se otorga LOCK TABLES: con --single-transaction el volcado es consistente
-- por MVCC sin bloquear tablas.
GRANT SELECT, SHOW VIEW, TRIGGER, EVENT ON employees.* TO 'usr_backup'@'localhost';

-- Globales, porque el respaldo del Ej. 6 usa --flush-logs --source-data=2 --routines:
--   RELOAD             -> FLUSH LOGS y el bloqueo breve (FLUSH TABLES WITH READ LOCK)
--                         que toma --source-data para fijar la posición del binlog
--   REPLICATION CLIENT -> leer archivo y posición del binlog (SHOW BINARY LOG STATUS)
--   PROCESS            -> mysqldump consulta la información de tablespaces
--                         (sin este privilegio habría que agregar --no-tablespaces)
--   SHOW_ROUTINE       -> leer el cuerpo de procedimientos creados por otro usuario (Ej. 4)
GRANT RELOAD, REPLICATION CLIENT, PROCESS ON *.* TO 'usr_backup'@'localhost';
GRANT SHOW_ROUTINE ON *.* TO 'usr_backup'@'localhost';

-- -----------------------------------------------------------------------------
-- Verificación
-- -----------------------------------------------------------------------------
SELECT user, host, plugin, account_locked FROM mysql.user WHERE user IN ('usr_g11', 'usr_backup');
SHOW GRANTS FOR 'usr_g11'@'%';
SHOW GRANTS FOR 'usr_backup'@'localhost';

-- ============================================================================
-- Archivo: bloque1_mysql/ej01_pruebas.sh
-- ============================================================================
/*
#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 1 - Pruebas de las cuentas: qué puede y qué no puede hacer cada una
# Uso: ./ej01_pruebas.sh      (pide las claves de usr_g11 y usr_backup)
#      MYSQL_CON="-h 127.0.0.1 -P 3306" para cambiar el destino de usr_g11
# =============================================================================
set -uo pipefail
CON_G11=${MYSQL_CON:--h 127.0.0.1}
CON_BK=${MYSQL_CON_BACKUP:-}            # usr_backup es @localhost: por socket
read -rsp "Clave de usr_g11: " PG; echo
read -rsp "Clave de usr_backup: " PB; echo
g11() { MYSQL_PWD="$PG" mysql $CON_G11 -u usr_g11 -t -e "$1" 2>&1; }
bk()  { MYSQL_PWD="$PB" mysql $CON_BK -u usr_backup -t -e "$1" 2>&1; }

echo "=== usr_g11: conectado desde un host remoto (@'%') ==="
g11 "SELECT CURRENT_USER() AS cuenta, USER() AS conectado_como"
echo "--- PERMITIDO: crear y borrar una tabla en una base del laboratorio"
g11 "CREATE TABLE employees.prueba_g11 (id INT PRIMARY KEY); DROP TABLE employees.prueba_g11; SELECT 'DDL en employees: OK' AS resultado"
echo "--- RECHAZADO: leer la base de sistema mysql (no es súper-usuario)"
g11 "SELECT user, host FROM mysql.user"
echo "--- RECHAZADO: crear usuarios"
g11 "CREATE USER 'intruso'@'%' IDENTIFIED BY 'x'"
echo "--- RECHAZADO: apagar el servidor"
g11 "SHUTDOWN"

echo; echo "=== usr_backup: solo lectura y respaldo de employees ==="
bk "SELECT CURRENT_USER() AS cuenta"
echo "--- PERMITIDO: leer employees"
bk "SELECT COUNT(*) AS empleados FROM employees.employees"
echo "--- RECHAZADO: modificar employees"
bk "UPDATE employees.salaries SET salary = 0 WHERE emp_no = 10001"
echo "--- RECHAZADO: leer otra base"
bk "SELECT COUNT(*) FROM world_x.city"
echo "--- PERMITIDO: respaldo completo de employees con mysqldump"
MYSQL_PWD="$PB" mysqldump $CON_BK -u usr_backup --single-transaction --flush-logs --source-data=2 \
  --set-gtid-purged=OFF --skip-masking-policies --routines --triggers --events --databases employees > /tmp/prueba_backup_employees.sql
echo "mysqldump terminó con código $? · tamaño: $(du -h /tmp/prueba_backup_employees.sql | cut -f1)"
grep -m1 "CHANGE REPLICATION SOURCE TO" /tmp/prueba_backup_employees.sql
rm -f /tmp/prueba_backup_employees.sql
*/

-- ============================================================================
-- Archivo: bloque1_mysql/ej02_carga_masiva.sh
-- ============================================================================
/*
#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 2 - Exportación a texto delimitado, esquema traducido y carga masiva
# Uso: ./ej02_carga_masiva.sh   (pide la clave de usr_g11)
#      MYSQL_CON="-h 127.0.0.1 -P 3306" para cambiar el destino
# El servidor solo lee y escribe archivos en secure_file_priv (en Ubuntu:
# /var/lib/mysql-files/). LOAD DATA no acepta la ruta en una variable, por eso
# este script la obtiene del servidor y arma las sentencias.
# =============================================================================
set -uo pipefail
CON=${MYSQL_CON:--h 127.0.0.1}
read -rsp "Clave de usr_g11: " P; echo
export MYSQL_PWD="$P"
sql() { mysql $CON -u usr_g11 -t -vvv "$@"; }

DIR=$(mysql $CON -u usr_g11 -N -B -e "SELECT @@secure_file_priv")
echo "secure_file_priv = $DIR"
[ -n "$DIR" ] && [ "$DIR" != "NULL" ] || { echo "El servidor no permite archivos (secure_file_priv vacío o NULL)"; exit 1; }
# INTO OUTFILE falla si el archivo ya existe: se usa un sufijo con la fecha
SUF=$(date +%Y%m%d_%H%M%S)
F_EMP="${DIR}employees_${SUF}.csv"; F_SAL="${DIR}salaries_${SUF}.csv"; F_TIT="${DIR}titles_${SUF}.csv"
CSV="FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n'"

echo; echo "=== 2.1 Exportación a texto delimitado (CSV) con SELECT ... INTO OUTFILE"
sql <<SQL
SELECT * FROM employees.employees INTO OUTFILE '$F_EMP' $CSV;
SELECT * FROM employees.salaries  INTO OUTFILE '$F_SAL' $CSV;
SELECT * FROM employees.titles    INTO OUTFILE '$F_TIT' $CSV;
SQL

echo; echo "=== 2.2 Base empleados con nombres en castellano e integridad referencial"
sql <<'SQL'
DROP DATABASE IF EXISTS empleados;
CREATE DATABASE empleados CHARACTER SET utf8mb4;
USE empleados;
CREATE TABLE empleados (
  nro_empleado     INT          NOT NULL,
  fecha_nacimiento DATE         NOT NULL,
  nombre           VARCHAR(14)  NOT NULL,
  apellido         VARCHAR(16)  NOT NULL,
  genero           ENUM('M','F') NOT NULL,
  fecha_ingreso    DATE         NOT NULL,
  PRIMARY KEY (nro_empleado)
) ENGINE=InnoDB;
CREATE TABLE salarios (
  nro_empleado INT  NOT NULL,
  salario      INT  NOT NULL,
  desde        DATE NOT NULL,
  hasta        DATE NOT NULL,
  PRIMARY KEY (nro_empleado, desde),
  CONSTRAINT fk_salarios_empleados FOREIGN KEY (nro_empleado)
    REFERENCES empleados (nro_empleado) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE cargos (
  nro_empleado INT         NOT NULL,
  cargo        VARCHAR(50) NOT NULL,
  desde        DATE        NOT NULL,
  hasta        DATE,
  PRIMARY KEY (nro_empleado, cargo, desde),
  CONSTRAINT fk_cargos_empleados FOREIGN KEY (nro_empleado)
    REFERENCES empleados (nro_empleado) ON DELETE CASCADE
) ENGINE=InnoDB;
SHOW TABLES;
SQL

echo; echo "=== 2.3 Carga masiva con LOAD DATA INFILE (primero la tabla padre)"
sql <<SQL
USE empleados;
SET @t0 := NOW(6);
LOAD DATA INFILE '$F_EMP' INTO TABLE empleados $CSV
  (nro_empleado, fecha_nacimiento, nombre, apellido, genero, fecha_ingreso);
LOAD DATA INFILE '$F_SAL' INTO TABLE salarios  $CSV (nro_empleado, salario, desde, hasta);
LOAD DATA INFILE '$F_TIT' INTO TABLE cargos    $CSV (nro_empleado, cargo, desde, hasta);
SELECT ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, NOW(6)) / 1000000, 2) AS segundos_carga_total;
SQL

echo; echo "=== Verificación: filas en origen y destino, e integridad referencial"
sql <<'SQL'
SELECT 'empleados' AS tabla, (SELECT COUNT(*) FROM employees.employees) AS origen, (SELECT COUNT(*) FROM empleados.empleados) AS destino
UNION ALL SELECT 'salarios', (SELECT COUNT(*) FROM employees.salaries), (SELECT COUNT(*) FROM empleados.salarios)
UNION ALL SELECT 'cargos',   (SELECT COUNT(*) FROM employees.titles),   (SELECT COUNT(*) FROM empleados.cargos);
SELECT COUNT(*) AS salarios_sin_empleado FROM empleados.salarios s
  LEFT JOIN empleados.empleados e ON e.nro_empleado = s.nro_empleado WHERE e.nro_empleado IS NULL;
SELECT e.nro_empleado, e.nombre, e.apellido, c.cargo, s.salario
FROM empleados.empleados e
JOIN empleados.cargos c   ON c.nro_empleado = e.nro_empleado AND c.hasta = '9999-01-01'
JOIN empleados.salarios s ON s.nro_empleado = e.nro_empleado AND s.hasta = '9999-01-01'
ORDER BY e.nro_empleado LIMIT 3;
-- La integridad referencial rechaza un salario de un empleado inexistente
INSERT INTO empleados.salarios VALUES (999999, 1000, '2026-01-01', '9999-01-01');
SQL
*/

-- ============================================================================
-- Archivo: bloque1_mysql/ej03_consultas.sql
-- ============================================================================
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

-- ============================================================================
-- Archivo: bloque1_mysql/ej03_indices.sql
-- ============================================================================
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

-- ============================================================================
-- Archivo: bloque1_mysql/ej04_programabilidad.sql
-- ============================================================================
-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 4 - Programabilidad: procedimientos y trigger sobre employees
--   mysql -h 127.0.0.1 -u usr_g11 -p --commands --skip-comments -t -vvv employees < ej04_programabilidad.sql
-- (--commands: en el cliente de MySQL 9.7 DELIMITER es un comando del cliente
--  y viene desactivado por defecto cuando se lee un archivo)
-- =============================================================================
USE employees;

DROP PROCEDURE IF EXISTS sp_verificar_gerente;
DROP PROCEDURE IF EXISTS sp_calcular_ayuda_escolar;
DROP TRIGGER   IF EXISTS trg_dept_manager_alta;
DROP TABLE     IF EXISTS asignaciones_familiares;
DROP TABLE     IF EXISTS ayuda_escolar_montos;

DELIMITER //

-- -----------------------------------------------------------------------------
-- 4.1 Verificación de gerentes
--   Si p_emp_no administra HOY un departamento (dept_manager.to_date = 9999-01-01)
--   devuelve: 1) un resumen y 2) los empleados asignados hoy a ese departamento
--   con su antigüedad en años (los p_limite de mayor antigüedad).
--   Si no es gerente vigente, lo informa (y si lo fue, dice hasta cuándo).
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_verificar_gerente(IN p_emp_no INT, IN p_limite INT)
BEGIN
  DECLARE v_dept CHAR(4);
  DECLARE v_hasta DATE;

  SELECT dept_no INTO v_dept FROM dept_manager
  WHERE emp_no = p_emp_no AND to_date = '9999-01-01' LIMIT 1;

  IF v_dept IS NULL THEN
    SELECT MAX(to_date) INTO v_hasta FROM dept_manager WHERE emp_no = p_emp_no;
    SELECT p_emp_no AS emp_no,
           CASE WHEN v_hasta IS NULL THEN 'NO es ni fue gerente'
                ELSE CONCAT('NO es gerente vigente (lo fue hasta ', v_hasta, ')') END AS resultado;
  ELSE
    SELECT p_emp_no AS gerente, CONCAT(g.first_name, ' ', g.last_name) AS nombre,
           d.dept_no, d.dept_name AS departamento,
           COUNT(*) AS empleados_asignados,
           ROUND(AVG(TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE())), 1) AS antiguedad_promedio
    FROM dept_emp de
    JOIN employees e   ON e.emp_no = de.emp_no
    JOIN departments d ON d.dept_no = de.dept_no
    JOIN employees g   ON g.emp_no = p_emp_no
    WHERE de.dept_no = v_dept AND de.to_date = '9999-01-01'
    GROUP BY d.dept_no, d.dept_name, g.first_name, g.last_name;

    SELECT e.emp_no, e.first_name, e.last_name, e.hire_date,
           TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) AS antiguedad_anios
    FROM dept_emp de
    JOIN employees e ON e.emp_no = de.emp_no
    WHERE de.dept_no = v_dept AND de.to_date = '9999-01-01'
    ORDER BY e.hire_date, e.emp_no
    LIMIT p_limite;
  END IF;
END //

-- -----------------------------------------------------------------------------
-- 4.2 Trigger de asignación de cargo
--   Al dar de alta un gerente vigente en dept_manager:
--   - titles: cierra el cargo vigente y abre 'Manager' desde la fecha del alta
--   - dept_emp: lo asigna al departamento que pasa a administrar (cierra la
--     asignación vigente en otro departamento). dept_emp no tiene columna de
--     cargo: el "cargo" del empleado vive en titles.
--   MySQL no permite que un trigger modifique su propia tabla (dept_manager),
--   por eso cerrar al gerente anterior queda fuera del trigger.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_dept_manager_alta
AFTER INSERT ON dept_manager
FOR EACH ROW
BEGIN
  IF NEW.to_date = '9999-01-01' THEN
    UPDATE titles SET to_date = NEW.from_date
    WHERE emp_no = NEW.emp_no AND to_date = '9999-01-01' AND title <> 'Manager';
    INSERT INTO titles (emp_no, title, from_date, to_date)
    VALUES (NEW.emp_no, 'Manager', NEW.from_date, '9999-01-01')
    ON DUPLICATE KEY UPDATE to_date = '9999-01-01';

    UPDATE dept_emp SET to_date = NEW.from_date
    WHERE emp_no = NEW.emp_no AND to_date = '9999-01-01' AND dept_no <> NEW.dept_no;
    INSERT INTO dept_emp (emp_no, dept_no, from_date, to_date)
    VALUES (NEW.emp_no, NEW.dept_no, NEW.from_date, '9999-01-01')
    ON DUPLICATE KEY UPDATE to_date = '9999-01-01';
  END IF;
END //

DELIMITER ;

-- -----------------------------------------------------------------------------
-- 4.3 Ayuda escolar: estructura y cálculo del beneficio
--   Reglas (supuestos del grupo, inspirados en la Ayuda Escolar Anual):
--   - un pago por hijo y ciclo lectivo, según el nivel educativo
--   - solo si se presentó el certificado de escolaridad
--   - solo si el sueldo vigente del empleado no supera el tope (parámetro)
-- -----------------------------------------------------------------------------
CREATE TABLE ayuda_escolar_montos (
  nivel ENUM('INICIAL','PRIMARIO','SECUNDARIO') NOT NULL PRIMARY KEY,
  monto DECIMAL(10,2) NOT NULL CHECK (monto > 0)
) ENGINE=InnoDB;

CREATE TABLE asignaciones_familiares (
  asignacion_id   INT AUTO_INCREMENT PRIMARY KEY,
  emp_no          INT NOT NULL,
  hijo_nombre     VARCHAR(40) NOT NULL,
  hijo_nacimiento DATE NOT NULL,
  nivel           ENUM('INICIAL','PRIMARIO','SECUNDARIO') NOT NULL,
  ciclo_lectivo   YEAR NOT NULL,
  certificado     BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_asignaciones_employees FOREIGN KEY (emp_no) REFERENCES employees (emp_no) ON DELETE CASCADE,
  CONSTRAINT fk_asignaciones_nivel     FOREIGN KEY (nivel)  REFERENCES ayuda_escolar_montos (nivel),
  CONSTRAINT uq_hijo_ciclo UNIQUE (emp_no, hijo_nombre, ciclo_lectivo)
) ENGINE=InnoDB;

DELIMITER //
CREATE PROCEDURE sp_calcular_ayuda_escolar(IN p_ciclo YEAR, IN p_tope INT)
BEGIN
  SELECT a.emp_no, CONCAT(e.first_name, ' ', e.last_name) AS empleado, s.salary AS sueldo_vigente,
         COUNT(*) AS hijos_beneficiarios, SUM(m.monto) AS beneficio_total
  FROM asignaciones_familiares a
  JOIN employees e            ON e.emp_no = a.emp_no
  JOIN salaries s             ON s.emp_no = a.emp_no AND s.to_date = '9999-01-01'
  JOIN ayuda_escolar_montos m ON m.nivel = a.nivel
  WHERE a.ciclo_lectivo = p_ciclo AND a.certificado AND s.salary <= p_tope
  GROUP BY a.emp_no, e.first_name, e.last_name, s.salary
  ORDER BY a.emp_no;

  SELECT COUNT(DISTINCT a.emp_no) AS empleados_beneficiarios, COUNT(*) AS hijos,
         COALESCE(SUM(m.monto), 0) AS total_a_pagar
  FROM asignaciones_familiares a
  JOIN salaries s             ON s.emp_no = a.emp_no AND s.to_date = '9999-01-01'
  JOIN ayuda_escolar_montos m ON m.nivel = a.nivel
  WHERE a.ciclo_lectivo = p_ciclo AND a.certificado AND s.salary <= p_tope;
END //
DELIMITER ;

-- =============================================================================
-- PRUEBAS
-- =============================================================================
-- 4.1 Caso válido: gerente vigente de Marketing (d001)
CALL sp_verificar_gerente(110039, 5);
-- 4.1 Caso inválido: fue gerente de d001 pero ya no lo es
CALL sp_verificar_gerente(110022, 5);
-- 4.1 Caso inválido: nunca fue gerente
CALL sp_verificar_gerente(10001, 5);

-- 4.2 Antes del alta: 10002 es 'Staff' en Sales (d007)
SELECT emp_no, title, from_date, to_date FROM titles   WHERE emp_no = 10002 ORDER BY from_date;
SELECT emp_no, dept_no, from_date, to_date FROM dept_emp WHERE emp_no = 10002 ORDER BY from_date;
-- Alta de 10002 como gerente de Human Resources (d003) -> se dispara el trigger
INSERT INTO dept_manager (emp_no, dept_no, from_date, to_date) VALUES (10002, 'd003', '2026-11-17', '9999-01-01');
-- Después: cargo 'Manager' vigente y asignado a d003
SELECT emp_no, title, from_date, to_date FROM titles   WHERE emp_no = 10002 ORDER BY from_date;
SELECT emp_no, dept_no, from_date, to_date FROM dept_emp WHERE emp_no = 10002 ORDER BY from_date;
-- El procedimiento 4.1 ya lo reconoce como gerente vigente
CALL sp_verificar_gerente(10002, 3);

-- 4.3 Datos de prueba (ciclo 2026) y cálculo con tope de $60.000
INSERT INTO ayuda_escolar_montos VALUES ('INICIAL', 15000), ('PRIMARIO', 20000), ('SECUNDARIO', 25000);
INSERT INTO asignaciones_familiares (emp_no, hijo_nombre, hijo_nacimiento, nivel, ciclo_lectivo, certificado) VALUES
  (10003, 'Lucía Bamford',     '2015-03-10', 'PRIMARIO',   2026, TRUE),   -- sueldo 43.311: cobra
  (10003, 'Tomás Bamford',     '2011-07-22', 'SECUNDARIO', 2026, TRUE),   -- sueldo 43.311: cobra
  (10006, 'Sofía Preusig',     '2021-01-05', 'INICIAL',    2026, TRUE),   -- sueldo 59.755: cobra (cerca del tope)
  (10012, 'Mateo Bridgland',   '2016-09-30', 'PRIMARIO',   2026, FALSE),  -- sin certificado: no cobra
  (10001, 'Valentina Facello', '2014-05-18', 'PRIMARIO',   2026, TRUE);   -- sueldo 88.958 > tope: no cobra
CALL sp_calcular_ayuda_escolar(2026, 60000);
-- Caso límite: tope igual al sueldo de 10006 (59.755) -> sigue cobrando (<=)
CALL sp_calcular_ayuda_escolar(2026, 59755);
-- Caso límite: tope un peso menor -> 10006 queda afuera
CALL sp_calcular_ayuda_escolar(2026, 59754);
-- Caso inválido: un hijo de un empleado inexistente (integridad referencial)
INSERT INTO asignaciones_familiares (emp_no, hijo_nombre, hijo_nacimiento, nivel, ciclo_lectivo, certificado)
VALUES (999999, 'Sin Empleado', '2015-01-01', 'PRIMARIO', 2026, TRUE);

-- ============================================================================
-- Archivo: bloque1_mysql/ej05_bloqueos.sh
-- ============================================================================
/*
#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 5 - Concurrencia y bloqueos sobre employees.salaries
# Reproduce las dos sesiones en paralelo (en el laboratorio se hacen en dos
# terminales: el SQL de cada sesión es el que figura abajo).
# Uso: ./ej05_bloqueos.sh       (pide la clave de usr_g11)
#      MYSQL_CON="-h 127.0.0.1 -P 3306" para cambiar el destino
# =============================================================================
set -uo pipefail
CON=${MYSQL_CON:--h 127.0.0.1}
read -rsp "Clave de usr_g11: " P; echo
export MYSQL_PWD="$P"
m() { mysql $CON -u usr_g11 --skip-comments -t employees "$@"; }
TMP=$(mktemp -d)

S1="SELECT CONNECTION_ID() AS hilo_sesion1;
START TRANSACTION;
UPDATE salaries SET salary = ROUND(salary * 1.10)
WHERE emp_no BETWEEN 10001 AND 10010 AND to_date = '9999-01-01';
SELECT ROW_COUNT() AS sueldos_incrementados_sin_confirmar;
SELECT SLEEP(15) AS transaccion_abierta_15s;
ROLLBACK;
SELECT emp_no, salary FROM salaries WHERE emp_no = 10005 AND to_date = '9999-01-01';"

S2="SELECT CONNECTION_ID() AS hilo_sesion2;
UPDATE salaries SET salary = salary + 500
WHERE emp_no = 10005 AND to_date = '9999-01-01';"

echo "=== 5.1 SESIÓN 1 (transacción abierta, sin COMMIT):"; echo "$S1"; echo
m -e "$S1" > "$TMP/s1.txt" 2>&1 &
sleep 2
echo "=== 5.2 SESIÓN 2 (modifica un registro ya bloqueado por la Sesión 1):"; echo "$S2"; echo
m -e "$S2" > "$TMP/s2.txt" 2>&1 &
sleep 3

echo "=== 5.3 DIAGNÓSTICO (tercera conexión, mientras la Sesión 2 espera)"
m -e "SELECT trx_id, trx_mysql_thread_id AS hilo, trx_state AS estado, trx_started AS inicio,
              trx_wait_started AS espera_desde, trx_rows_locked AS filas_bloqueadas,
              LEFT(trx_query, 70) AS sentencia
       FROM information_schema.innodb_trx ORDER BY trx_started"
m -e "SELECT ENGINE_TRANSACTION_ID AS trx, THREAD_ID, OBJECT_NAME AS tabla, INDEX_NAME AS indice,
              LOCK_TYPE, LOCK_MODE, LOCK_STATUS, LOCK_DATA
       FROM performance_schema.data_locks
       WHERE OBJECT_NAME = 'salaries' AND (LOCK_STATUS = 'WAITING' OR LOCK_DATA LIKE '10005,%' OR LOCK_TYPE = 'TABLE')
       ORDER BY ENGINE_TRANSACTION_ID, LOCK_TYPE DESC"
m -e "SELECT REQUESTING_ENGINE_TRANSACTION_ID AS trx_que_espera, BLOCKING_ENGINE_TRANSACTION_ID AS trx_que_bloquea
       FROM performance_schema.data_lock_waits"

BLOQUEADA=$(mysql $CON -u usr_g11 -N -B -e "SELECT trx_mysql_thread_id FROM information_schema.innodb_trx WHERE trx_state = 'LOCK WAIT' LIMIT 1")
echo "=== 5.4 RESOLUCIÓN: se interrumpe la sesión bloqueada (hilo $BLOQUEADA)"
echo "KILL $BLOQUEADA;"
m -e "KILL $BLOQUEADA"
sleep 1
m -e "SELECT COUNT(*) AS transacciones_esperando FROM information_schema.innodb_trx WHERE trx_state = 'LOCK WAIT'"

wait
echo; echo "=== Salida de la SESIÓN 2 (interrumpida)"; cat "$TMP/s2.txt"
echo; echo "=== Salida de la SESIÓN 1 (termina con ROLLBACK: los sueldos no cambian)"; cat "$TMP/s1.txt"
rm -rf "$TMP"
*/

-- ============================================================================
-- Archivo: bloque1_mysql/ej06_pitr.sh
-- ============================================================================
/*
#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 6 - Binary logs, evento de rotación, backup base y PITR
# Uso: ./ej06_pitr.sh     (pide las claves de usr_g11 y usr_backup)
#   MYSQL_CON="-h 127.0.0.1 -P 3306"   destino para usr_g11
#   MYSQL_CON_BACKUP=""                usr_backup es @localhost (socket)
#   ROOT="sudo mysql"                  administrador para restaurar
#   BINLOG="sudo mysqlbinlog"          lector de binlogs (los archivos son de mysql)
#
# Nota sobre GTID (comprobado en MySQL 9.7): con gtid_mode=ON, un dump con
# GTID_PURGED falla al restaurarse en el mismo servidor (ERROR 3546) y, si el
# binlog se reaplica sin --skip-gtids, el servidor descarta en silencio las
# transacciones que ya ejecutó (se pierden las operaciones válidas). Por eso:
# mysqldump --set-gtid-purged=OFF y mysqlbinlog --skip-gtids (sirve con GTID ON y OFF).
# =============================================================================
set -uo pipefail
CON=${MYSQL_CON:--h 127.0.0.1}
CON_BK=${MYSQL_CON_BACKUP:-}
ROOT=${ROOT:-sudo mysql}
BINLOG=${BINLOG:-sudo mysqlbinlog}
BACKUP=${BACKUP_FILE:-$HOME/backup_employees_pitr.sql}
read -rsp "Clave de usr_g11: " PG; echo
read -rsp "Clave de usr_backup: " PB; echo
g11()  { MYSQL_PWD="$PG" mysql $CON -u usr_g11 --skip-comments -t employees "$@" 2>&1; }
g11n() { MYSQL_PWD="$PG" mysql $CON -u usr_g11 -N -B employees "$@" 2>&1; }
estado() {   # huella de lo que tocan las operaciones válidas y el incidente
  g11 -e "SELECT (SELECT COUNT(*) FROM departments) AS departamentos,
                 (SELECT COUNT(*) FROM employees)   AS empleados,
                 (SELECT COUNT(*) FROM titles)      AS cargos,
                 (SELECT salary FROM salaries WHERE emp_no = 10001 AND to_date = '9999-01-01') AS sueldo_10001,
                 (SELECT COUNT(*) FROM titles WHERE emp_no = 500001) AS cargos_500001"
}

echo "=== 6.1 Binary logs activos"
g11 -e "SELECT @@log_bin AS log_bin, @@log_bin_basename AS ubicacion, @@binlog_format AS formato,
               @@gtid_mode AS gtid_mode, @@binlog_expire_logs_seconds / 86400 AS retencion_dias"
g11 -e "SHOW BINARY LOGS"

echo; echo "=== 6.2 Evento que rota el binlog cada 10 minutos"
g11 -e "SELECT @@event_scheduler AS event_scheduler"
g11 -e "CREATE EVENT IF NOT EXISTS ev_rotar_binlog
          ON SCHEDULE EVERY 10 MINUTE
          COMMENT 'Lab G11 Ej 6.2: cierra el binlog actual cada 10 minutos'
          DO FLUSH LOGS"
g11 -e "SELECT EVENT_NAME, DEFINER, INTERVAL_VALUE, INTERVAL_FIELD, STATUS, LAST_EXECUTED
        FROM information_schema.EVENTS WHERE EVENT_SCHEMA = 'employees'"

echo; echo "=== 6.3 Backup base con usr_backup"
echo "\$ mysqldump -u usr_backup -p --single-transaction --flush-logs --source-data=2 --set-gtid-purged=OFF --skip-masking-policies --routines --triggers --events --databases employees > $BACKUP"
MYSQL_PWD="$PB" mysqldump $CON_BK -u usr_backup --single-transaction --flush-logs --source-data=2 \
  --set-gtid-purged=OFF --skip-masking-policies --routines --triggers --events --databases employees > "$BACKUP"
echo "código de salida: $? · tamaño: $(du -h "$BACKUP" | cut -f1)"
COORD=$(grep -m1 "CHANGE REPLICATION SOURCE TO" "$BACKUP"); echo "$COORD"
INI_FILE=$(echo "$COORD" | grep -o "SOURCE_LOG_FILE='[^']*'" | cut -d"'" -f2)
INI_POS=$(echo "$COORD" | grep -o "SOURCE_LOG_POS=[0-9]*" | cut -d= -f2)
echo "Estado en el momento del backup:"; estado

echo; echo "=== 6.4 Cinco modificaciones identificables posteriores al backup"
g11 -vvv -e "INSERT INTO departments VALUES ('d010', 'PITR Ciberseguridad')"
g11 -vvv -e "INSERT INTO employees VALUES (500001, '1995-05-05', 'Lautaro', 'Pitr', 'M', '2026-11-17')"
g11 -vvv -e "INSERT INTO titles VALUES (500001, 'Engineer', '2026-11-17', '9999-01-01')"
g11 -vvv -e "INSERT INTO salaries VALUES (500001, 70000, '2026-11-17', '9999-01-01')"
g11 -vvv -e "UPDATE salaries SET salary = salary + 1111 WHERE emp_no = 10001 AND to_date = '9999-01-01'"
echo "Estado OBJETIVO de la recuperación:"; estado | tee /tmp/ej06_objetivo.txt

echo; echo "=== 6.5 Incidente: borrado accidental de la tabla crítica titles"
g11 -vvv -e "DROP TABLE titles"
g11 -e "SELECT COUNT(*) FROM titles"

echo; echo "=== 6.6 PITR"
echo "--- Coordenadas de inicio (del backup): $INI_FILE posición $INI_POS"
echo "--- Búsqueda del DROP en los binlogs posteriores al backup (como administrador:"
echo "    SHOW BINLOG EVENTS exige REPLICATION SLAVE, que usr_g11 no tiene a propósito)"
FIN_FILE=""; FIN_POS=""; ARCHIVOS=()
for f in $(g11n -e "SHOW BINARY LOGS" | awk '{print $1}'); do
  [[ "$f" < "$INI_FILE" ]] && continue
  ARCHIVOS+=("$f")
  POS=$($ROOT -N -B -e "SHOW BINLOG EVENTS IN '$f'" | awk -F'\t' '
        $3 ~ /Gtid$/ {inicio = $2}                       # Gtid o Anonymous_Gtid: empieza una transacción
        $3 == "Query" && $6 ~ /DROP TABLE `titles`/ {print inicio; exit}')
  if [ -n "$POS" ]; then FIN_FILE="$f"; FIN_POS="$POS"; break; fi
done
echo "Archivos a reaplicar: ${ARCHIVOS[*]}"
if [ -z "$FIN_POS" ]; then
  echo "No se encontró el DROP en los binlogs: NO se restaura nada (revisar a mano con SHOW BINLOG EVENTS)."; exit 1
fi
echo "El DROP empieza en $FIN_FILE posición $FIN_POS (se corta justo antes)"
$ROOT -t -e "SHOW BINLOG EVENTS IN '$FIN_FILE'" | grep -E "Pos|Gtid|Query|Write_rows|Update_rows|Xid" | tail -12
DIR=$(dirname "$(g11n -e "SELECT @@log_bin_basename")")
RUTAS=(); for f in "${ARCHIVOS[@]}"; do RUTAS+=("$DIR/$f"); done

echo; echo "--- Paso 1: restaurar el backup base"
echo "\$ $ROOT < $BACKUP"
$ROOT < "$BACKUP" && echo "restaurado"
echo "--- Paso 2: reaplicar el binlog desde el backup hasta justo antes del DROP"
echo "\$ $BINLOG --skip-gtids --start-position=$INI_POS --stop-position=$FIN_POS ${ARCHIVOS[*]} | $ROOT"
$BINLOG --skip-gtids --start-position="$INI_POS" --stop-position="$FIN_POS" "${RUTAS[@]}" | $ROOT && echo "binlog reaplicado"

echo; echo "--- Validación: estado recuperado frente al objetivo"
estado | tee /tmp/ej06_recuperado.txt
if diff -q /tmp/ej06_objetivo.txt /tmp/ej06_recuperado.txt >/dev/null; then
  echo "RECUPERACIÓN EXACTA: coincide con el estado previo al incidente (las 5 modificaciones están y titles existe)"
else
  echo "DIFERENCIAS con el estado objetivo:"; diff /tmp/ej06_objetivo.txt /tmp/ej06_recuperado.txt
fi
g11 -e "SELECT e.emp_no, e.first_name, e.last_name, t.title, s.salary
        FROM employees e JOIN titles t USING (emp_no) JOIN salaries s USING (emp_no) WHERE e.emp_no = 500001"
rm -f /tmp/ej06_objetivo.txt /tmp/ej06_recuperado.txt
*/

/* ****************************************************************************
BLOQUE 2: DATOS SEMIESTRUCTURADOS EN MYSQL 9.7 (JSON)
**************************************************************************** */

-- ============================================================================
-- Archivo: bloque2_mysql/ej07_0_base_y_permisos.sql
-- ============================================================================
-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 7 (preparación) - Base para los documentos JSON de Sakila
-- Ejecutar como administrador (root):  sudo mysql -t < ej07_0_base_y_permisos.sql
-- =============================================================================

CREATE DATABASE IF NOT EXISTS zakila_json CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- usr_g11 (Ejercicio 1.1) administra las bases del laboratorio: se le suma la nueva
GRANT ALL PRIVILEGES ON zakila_json.* TO 'usr_g11'@'%' WITH GRANT OPTION;

SHOW GRANTS FOR 'usr_g11'@'%';

-- ============================================================================
-- Archivo: bloque2_mysql/ej07_1_tablas_json.sql
-- ============================================================================
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

-- ============================================================================
-- Archivo: bloque2_mysql/ej07_2_importar.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 7 - Importación de documentos JSON con util.importJson (MySQL Shell)
// util.importJson requiere una sesión X Protocol (puerto 33060):
//   mysqlsh --mysqlx -u usr_g11 -h 127.0.0.1 -P 33060 --file ej07_2_importar.js
// Los archivos son JSON Lines (un documento por línea), formato que importJson
// acepta directamente. Cada documento se guarda en la columna JSON "doc".
// =============================================================================

const carpeta = os.getenv("DATOS") || os.getenv("HOME") + "/lab_integrador_g11/datos";

for (const tabla of ["customers", "films", "stores"]) {
  print(`\n=== ${tabla}.json -> zakila_json.${tabla}(doc)\n`);
  util.importJson(`${carpeta}/${tabla}.json`, {
    schema: "zakila_json",
    table: tabla,
    tableColumn: "doc"
  });
}
*/

-- ============================================================================
-- Archivo: bloque2_mysql/ej07_3_verificar.sql
-- ============================================================================
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

-- ============================================================================
-- Archivo: bloque2_mysql/ej08_1_cliente_vip.sql
-- ============================================================================
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

-- ============================================================================
-- Archivo: bloque2_mysql/ej08_2_check_json_schema.sql
-- ============================================================================
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

-- ============================================================================
-- Archivo: bloque2_mysql/ej08_3_cruce_multimodelo.sql
-- ============================================================================
-- =============================================================================
-- LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
-- Ejercicio 8.3 - Cruce multimodelo: documentos JSON de clientes (zakila_json)
-- con la tabla countryinfo de world_x -> Top 10 de películas más alquiladas en
-- América del Sur
--   mysql -t -h 127.0.0.1 -u usr_g11 < ej08_3_cruce_multimodelo.sql
--
-- Cruce: customers.doc->>'$.Country' (nombre del país, en inglés)
--        = countryinfo.doc->>'$.Name', filtrando geography.Continent.
-- JSON_TABLE convierte el arreglo Rentals de cada cliente en filas relacionales.
-- =============================================================================
SET NAMES utf8mb4;

-- 1. Países de América del Sur en world_x y clientes de cada uno (control del cruce)
SELECT ci.doc->>'$.Name' AS pais, ci.doc->>'$.Code' AS codigo, COUNT(c.id) AS clientes
FROM world_x.countryinfo AS ci
LEFT JOIN zakila_json.customers AS c ON c.doc->>'$.Country' = ci.doc->>'$.Name'
WHERE ci.doc->>'$.geography.Continent' = 'South America'
GROUP BY pais, codigo
ORDER BY clientes DESC, pais;

-- 2. Top 10 de películas más alquiladas en América del Sur
--    Desempate por título: hay varias películas con 6 alquileres en el corte.
WITH alquileres_sa AS (
  SELECT r.film_id, r.titulo, ci.doc->>'$.Name' AS pais
  FROM zakila_json.customers AS c
  JOIN world_x.countryinfo AS ci
    ON ci.doc->>'$.Name' = c.doc->>'$.Country'
   AND ci.doc->>'$.geography.Continent' = 'South America'
  JOIN JSON_TABLE(c.doc, '$.Rentals[*]' COLUMNS (
         film_id INT          PATH '$.filmId',
         titulo  VARCHAR(100) PATH '$."Film Title"'
       )) AS r
)
SELECT ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, a.titulo) AS puesto,
       a.titulo AS pelicula,
       f.doc->>'$.Category' AS categoria,
       COUNT(*) AS alquileres,
       COUNT(DISTINCT a.pais) AS paises
FROM alquileres_sa AS a
JOIN zakila_json.films AS f ON f.id = a.film_id
GROUP BY a.film_id, a.titulo, categoria
ORDER BY alquileres DESC, pelicula
LIMIT 10;

-- 3. Empate en el corte: películas con la misma cantidad que el puesto 10
WITH alquileres_sa AS (
  SELECT r.titulo
  FROM zakila_json.customers AS c
  JOIN world_x.countryinfo AS ci
    ON ci.doc->>'$.Name' = c.doc->>'$.Country'
   AND ci.doc->>'$.geography.Continent' = 'South America'
  JOIN JSON_TABLE(c.doc, '$.Rentals[*]' COLUMNS (titulo VARCHAR(100) PATH '$."Film Title"')) AS r
),
ranking AS (
  SELECT titulo, COUNT(*) AS alquileres,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rango
  FROM alquileres_sa GROUP BY titulo
)
SELECT rango, titulo AS pelicula, alquileres
FROM ranking
WHERE alquileres = (SELECT alquileres FROM ranking ORDER BY alquileres DESC, titulo LIMIT 9, 1)
ORDER BY titulo;

-- 4. Totales del universo analizado
SELECT COUNT(DISTINCT c.id) AS clientes_sa, COUNT(*) AS alquileres_sa,
       COUNT(DISTINCT r.titulo) AS peliculas_distintas
FROM zakila_json.customers AS c
JOIN world_x.countryinfo AS ci
  ON ci.doc->>'$.Name' = c.doc->>'$.Country'
 AND ci.doc->>'$.geography.Continent' = 'South America'
JOIN JSON_TABLE(c.doc, '$.Rentals[*]' COLUMNS (titulo VARCHAR(100) PATH '$."Film Title"')) AS r;

-- ============================================================================
-- Archivo: bloque2_mysql/ej08_4_exportar_city.sh
-- ============================================================================
/*
#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 8.4 - Exportar world_x.city a JSON con formato
#                 {"Ciudad": "Resistencia", "CodP": "ARG"}
# Uso: ./ej08_4_exportar_city.sh [archivo_salida]
#
# - Se exporta desde el cliente (no con SELECT ... INTO OUTFILE): el archivo queda
#   en la carpeta del usuario y no en secure_file_priv, listo para el Ej. 10.2.
#   -N sin encabezados, -B una fila por línea, -r sin escapar barras ni comillas.
# - Resultado en formato JSON Lines (un documento por línea): es el que acepta
#   mongoimport en el Ejercicio 10.2.
# - JSON_OBJECT() devuelve las claves ordenadas por longitud ({"CodP":..,"Ciudad":..}),
#   por eso el documento se arma con CONCAT + JSON_QUOTE: respeta el orden pedido
#   y JSON_QUOTE escapa comillas y caracteres especiales de cada nombre.
# =============================================================================
set -euo pipefail
SALIDA="${1:-ciudades.json}"
MYSQL=(mysql -h 127.0.0.1 -u usr_g11 -N -B -r)

"${MYSQL[@]}" -e "
  SELECT CONCAT('{\"Ciudad\": ', JSON_QUOTE(Name), ', \"CodP\": ', JSON_QUOTE(CountryCode), '}')
  FROM world_x.city
  ORDER BY ID" > "$SALIDA"

echo "Archivo: $SALIDA"
wc -l < "$SALIDA" | xargs echo "Líneas (documentos):"
"${MYSQL[@]}" -e "SELECT COUNT(*) FROM world_x.city" | xargs echo "Filas en world_x.city:"
*/

-- ============================================================================
-- Archivo: bloque2_mysql/ej08_4_verificar.sql
-- ============================================================================
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

/* ****************************************************************************
BLOQUE 3: BASE DE DATOS NOSQL DOCUMENTAL (MONGODB 8.0)
**************************************************************************** */

-- ============================================================================
-- Archivo: bloque3_mongodb/ej09_1_crear_admin.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 9.1 - Gestión de accesos: usuario administrador en la base admin
// Motor: MongoDB (mongosh). Ejecutar con la autorización TODAVÍA desactivada:
//   mongosh --quiet --file ej09_1_crear_admin.js
// La clave se pide por teclado (passwordPrompt) o se toma de la variable de
// entorno MONGO_ADMIN_PWD: nunca queda escrita en el script ni en el historial.
// =============================================================================

const admin = db.getSiblingDB("admin");
const clave = process.env.MONGO_ADMIN_PWD || passwordPrompt();

if (admin.getUser("adminG11")) {
  print("El usuario adminG11 ya existe: no se vuelve a crear.");
} else {
  admin.createUser({
    user: "adminG11",
    pwd: clave,
    roles: [
      // Crear y administrar usuarios y roles en cualquier base
      { role: "userAdminAnyDatabase", db: "admin" },
      // Leer y escribir datos en todas las bases (LabMongoDB, LabMongoDB_Restore)
      { role: "readWriteAnyDatabase", db: "admin" },
      // collMod / validadores $jsonSchema e índices (Ejercicio 12.1)
      { role: "dbAdminAnyDatabase", db: "admin" },
      // Ver estado del servidor: serverStatus, currentOp, getCmdLineOpts
      { role: "clusterMonitor", db: "admin" },
      // mongodump y mongorestore (Ejercicio 12.2)
      { role: "backup", db: "admin" },
      { role: "restore", db: "admin" }
    ]
  });
  print("Usuario adminG11 creado en la base admin.");
}

printjson(admin.getUser("adminG11", { showPrivileges: false }));
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej09_1_verificar_auth.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 9.1 - Verificación de la autenticación (con authorization: enabled)
//   mongosh --quiet --file ej09_1_verificar_auth.js
// Forma interactiva equivalente (pide la clave):
//   mongosh "mongodb://127.0.0.1:27017" --authenticationDatabase admin -u adminG11
// =============================================================================

// 1. Sin credenciales: el servidor rechaza los comandos que requieren autorización
print("--- 1. Conexión SIN autenticar ---");
printjson(db.runCommand({ connectionStatus: 1 }).authInfo);
try {
  db.adminCommand({ listDatabases: 1 });
} catch (e) {
  print("listDatabases sin autenticar -> " + e.codeName + ": " + e.message);
}

// 2. Autenticación contra la base admin
print("\n--- 2. Autenticación como adminG11 ---");
const ok = db.getSiblingDB("admin").auth("adminG11", process.env.MONGO_ADMIN_PWD || passwordPrompt());
print("db.auth() -> " + JSON.stringify(ok));

// 3. Identidad y roles de la sesión autenticada
print("\n--- 3. connectionStatus autenticado ---");
printjson(db.runCommand({ connectionStatus: 1 }).authInfo);

print("\n--- 4. Comando administrativo permitido ---");
printjson(db.adminCommand({ listDatabases: 1, nameOnly: true }).databases.map(d => d.name));
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej09_2_importar.sh
-- ============================================================================
/*
#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 9.2 - Carga masiva con mongoimport en la base LabMongoDB
# Uso: ./ej09_2_importar.sh <carpeta con customers.json, films.json, stores.json>
#
# - Los archivos son JSON Lines (un documento por línea): no lleva --jsonArray.
# - Colecciones con los nombres en castellano que usa la guía (clientes,
#   peliculas, tiendas), para el $lookup del Ejercicio 11 y el $jsonSchema del 12.1.
# - --drop hace la carga repetible (vacía la colección antes de importar).
# - La clave de adminG11 se lee de un archivo de opciones (--config, YAML con
#   "password: ...") con permisos 600: no queda en la línea de comandos ni en el
#   historial. Sin --config, mongoimport la pide por teclado.
# =============================================================================
set -euo pipefail

DATOS="${1:?Indicar la carpeta con los archivos JSON}"
CONFIG="${MONGO_TOOLS_CONFIG:-$HOME/lab_integrador_g11/tools_admin.yaml}"
DB="LabMongoDB"

importar() {   # $1 = archivo, $2 = colección
  echo "=== $1 -> $DB.$2"
  mongoimport --host 127.0.0.1:27017 \
    --username adminG11 --authenticationDatabase admin --config "$CONFIG" \
    --db "$DB" --collection "$2" --drop \
    --file "$DATOS/$1"
  echo
}

time {
  importar customers.json clientes
  importar films.json     peliculas
  importar stores.json    tiendas
}
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej09_2_verificar_carga.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 9.2 - Verificación de la carga en LabMongoDB
//   mongosh "mongodb://127.0.0.1:27017" --authenticationDatabase admin -u adminG11 --quiet --file ej09_2_verificar_carga.js
// =============================================================================

if (!db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers.length) {
  db.getSiblingDB("admin").auth("adminG11", process.env.MONGO_ADMIN_PWD || passwordPrompt());
}
db = db.getSiblingDB("LabMongoDB");   // en un script, "use LabMongoDB" no tiene efecto

print("Base: " + db.getName());
print("Colecciones: " + JSON.stringify(db.getCollectionNames().sort()));

print("\n--- Documentos por colección (esperado: 599 / 1000 / 2) ---");
["clientes", "peliculas", "tiendas"].forEach(c =>
  print(c.padEnd(10) + db.getCollection(c).countDocuments()));

print("\n--- Arreglos anidados (alquileres por cliente, inventario por tienda) ---");
printjson(db.clientes.aggregate([
  { $project: { n: { $size: "$Rentals" } } },
  { $group: { _id: null, clientes: { $sum: 1 }, alquileres: { $sum: "$n" },
              min: { $min: "$n" }, max: { $max: "$n" } } },
  { $project: { _id: 0 } }
]).toArray()[0]);
printjson(db.tiendas.find({}, { _id: 1, City: 1, Country: 1,
  items_inventario: { $size: "$Inventory" }, empleados: { $size: "$Staff" } }).toArray());

print("\n--- Muestra: un cliente (primer alquiler) y una película ---");
printjson(db.clientes.findOne({ _id: 1 },
  { "First Name": 1, "Last Name": 1, City: 1, Country: 1, Rentals: { $slice: 1 } }));
printjson(db.peliculas.findOne({ _id: 1 }, { Actors: 0 }));
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej10_1_modelo.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 10.1 - Evidencia para el diseño del esquema (embedding vs referencing)
//   mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u adminG11 --file ej10_1_modelo.js
// Mide el tamaño de los documentos y de los arreglos embebidos, y verifica que
// las referencias entre colecciones apunten a documentos existentes.
// =============================================================================
db = db.getSiblingDB("LabMongoDB");

const medir = (coleccion, arreglo) => db.getCollection(coleccion).aggregate([
  { $project: { b: { $bsonSize: "$$ROOT" }, n: { $size: "$" + arreglo } } },
  { $group: { _id: null, docs: { $sum: 1 }, b_prom: { $avg: "$b" }, b_max: { $max: "$b" },
              n_prom: { $avg: "$n" }, n_max: { $max: "$n" } } }
]).toArray()[0];

print("1. EMBEBIDOS: tamaño de documentos y arreglos (límite de un documento BSON: 16 MB)\n");
print("Colección  Arreglo embebido  Docs  Elem.prom  Elem.max  KB prom  KB max");
[["clientes", "Rentals"], ["peliculas", "Actors"], ["tiendas", "Inventory"]].forEach(([c, a]) => {
  const m = medir(c, a);
  print(c.padEnd(10) + "  " + a.padEnd(16) + String(m.docs).padStart(6) +
        m.n_prom.toFixed(1).padStart(11) + String(m.n_max).padStart(10) +
        (m.b_prom / 1024).toFixed(1).padStart(9) + (m.b_max / 1024).toFixed(1).padStart(8));
});
const pagos = db.clientes.aggregate([{ $unwind: "$Rentals" },
  { $group: { _id: null, max: { $max: { $size: "$Rentals.Payments" } } } }]).toArray()[0].max;
print("Pagos por alquiler (máximo): " + pagos);

print("\n2. REFERENCIAS: ¿apuntan a documentos existentes?\n");
const huerfanos = (desde, campo, unwind, hacia, clave) => db.getCollection(desde).aggregate([
  ...(unwind ? [{ $unwind: "$" + unwind }] : []),
  { $group: { _id: "$" + campo } },
  { $lookup: { from: hacia, localField: "_id", foreignField: clave, as: "x" } },
  { $group: { _id: null, distintos: { $sum: 1 }, sin_destino: { $sum: { $cond: [{ $eq: [{ $size: "$x" }, 0] }, 1, 0] } } } }
]).toArray()[0];
[
  ["clientes.Rentals.filmId -> peliculas._id", "clientes", "Rentals.filmId", "Rentals", "peliculas", "_id"],
  ["tiendas.Inventory.filmId  -> peliculas._id", "tiendas", "Inventory.filmId", "Inventory", "peliculas", "_id"],
  ["clientes.Country         -> paises.Name", "clientes", "Country", null, "paises", "Name"],
  ["ciudades.CodP            -> paises.Code", "ciudades", "CodP", null, "paises", "Code"]
].forEach(([t, ...r]) => { const h = huerfanos(...r); print(t + "   valores distintos: " + h.distintos + "   sin destino: " + h.sin_destino); });

print("\n3. Veces que se repite cada película en los alquileres (si se embebiera completa)");
printjson(db.clientes.aggregate([{ $unwind: "$Rentals" }, { $group: { _id: "$Rentals.filmId", n: { $sum: 1 } } },
  { $group: { _id: null, alquileres: { $sum: "$n" }, peliculas: { $sum: 1 }, max_repeticiones: { $max: "$n" } } },
  { $project: { _id: 0 } }]).toArray()[0]);
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej10_2_importar.sh
-- ============================================================================
/*
#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 10.2 - Importación de las colecciones auxiliares ciudades y paises
# Uso: ./ej10_2_importar.sh <carpeta con ciudades.json y paises.json>
#   ciudades.json: exportado de world_x.city en el Ejercicio 8.4 ({"Ciudad", "CodP"})
#   paises.json:   exportado de world_x.countryinfo (documentos JSON de MySQL):
#     mysql -h 127.0.0.1 -u usr_g11 -p -N -B -r -e "SELECT doc FROM world_x.countryinfo ORDER BY doc->>'$.Code'" > paises.json
# La clave de adminG11 se lee de un archivo de opciones (YAML "password: ...", chmod 600).
# =============================================================================
set -euo pipefail
DATOS="${1:?Indicar la carpeta con ciudades.json y paises.json}"
CONFIG="${MONGO_TOOLS_CONFIG:-$HOME/lab_mongodb_g11/tools_admin.yaml}"
HOST="${MONGO_HOST:-127.0.0.1:27017}"

importar() {   # $1 = archivo, $2 = colección
  echo "=== $1 -> LabMongoDB.$2"
  mongoimport --host "$HOST" \
    --username adminG11 --authenticationDatabase admin --config "$CONFIG" \
    --db LabMongoDB --collection "$2" --drop \
    --file "$DATOS/$1"
  echo
}

echo "Documentos en los archivos (JSON Lines: uno por línea):"
wc -l "$DATOS/paises.json" "$DATOS/ciudades.json"; echo
importar paises.json   paises
importar ciudades.json ciudades
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej10_2_verificar.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 10.2 - Verificación de las colecciones auxiliares ciudades y paises
//   mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u adminG11 --file ej10_2_verificar.js
// =============================================================================
db = db.getSiblingDB("LabMongoDB");   // en un script, "use LabMongoDB" no tiene efecto

print("Colecciones: " + JSON.stringify(db.getCollectionNames().sort()));
print("ciudades: " + db.ciudades.countDocuments() + "   (esperado 4079)");
print("paises:   " + db.paises.countDocuments() + "   (esperado 239)");

print("\n--- Una ciudad y su país (referencia CodP -> Code) ---");
printjson(db.ciudades.findOne({ Ciudad: "Resistencia" }, { _id: 0 }));
printjson(db.paises.findOne({ Code: "ARG" }, { _id: 0, Code: 1, Name: 1, geography: 1 }));

print("\n--- Países de América del Sur (filtro del Ejercicio 11) ---");
db.paises.find({ "geography.Continent": "South America" }, { _id: 0, Code: 1, Name: 1 })
  .sort({ Name: 1 }).forEach(p => print("  " + p.Code + "  " + p.Name));

print("\n--- Clientes cuyo Country no tiene país en paises (esperado: solo Runion) ---");
printjson(db.clientes.aggregate([
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "p" } },
  { $match: { p: { $size: 0 } } },
  { $group: { _id: "$Country", clientes: { $sum: 1 } } }
]).toArray());

// Índices de apoyo para los $lookup del Ejercicio 11 (paises.Name) y para ciudades por país
print("\n--- Índices de apoyo ---");
print(db.paises.createIndex({ Name: 1 }) + " / " + db.ciudades.createIndex({ CodP: 1 }));
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej11_pipeline.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 11 - Aggregation Pipeline: Top 10 de películas más alquiladas en
// América del Sur, vinculando clientes, peliculas y paises
//   mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u adminG11 --file ej11_pipeline.js
// Resultado esperado = Ejercicio 8.3 (MySQL): mismo orden y desempate por título.
// =============================================================================
db = db.getSiblingDB("LabMongoDB");

const pipeline = [
  // 1. Cliente -> país (referencia por nombre: clientes.Country = paises.Name)
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "pais" } },
  { $unwind: "$pais" },
  // 2. Solo clientes de América del Sur
  { $match: { "pais.geography.Continent": "South America" } },
  // 3. Un documento por alquiler (el arreglo Rentals está embebido en el cliente)
  { $unwind: "$Rentals" },
  // 4. Alquileres por película y países distintos donde se alquiló
  { $group: { _id: "$Rentals.filmId", alquileres: { $sum: 1 }, paises: { $addToSet: "$pais.Name" } } },
  // 5. Película (referencia filmId -> peliculas._id) para el título y la categoría
  { $lookup: { from: "peliculas", localField: "_id", foreignField: "_id", as: "pelicula" } },
  { $unwind: "$pelicula" },
  { $project: { _id: 0, filmId: "$_id", pelicula: "$pelicula.Title", categoria: "$pelicula.Category",
                alquileres: 1, paises: { $size: "$paises" } } },
  // 6. Mayor cantidad primero; desempate alfabético (13 películas empatan con 6)
  { $sort: { alquileres: -1, pelicula: 1 } },
  { $limit: 10 }
];

const top = db.clientes.aggregate(pipeline).toArray();
print("Top 10 de películas más alquiladas en América del Sur\n");
print("Pos  Película                  Categoría     Alq  Países");
top.forEach((p, i) => print(
  String(i + 1).padStart(3) + "  " + p.pelicula.padEnd(24) + "  " + p.categoria.padEnd(12) +
  "  " + String(p.alquileres).padStart(3) + "  " + String(p.paises).padStart(5)));

// Control del empate en el corte: películas con la misma cantidad que el puesto 10
const corte = top[top.length - 1].alquileres;
const empatadas = db.clientes.aggregate(pipeline.slice(0, 5).concat([
  { $match: { alquileres: corte } }, { $count: "n" }
])).toArray()[0].n;
print("\nPelículas con " + corte + " alquileres (empate en el corte): " + empatadas);
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej12_1_validacion.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 12.1 - Regla de validación $jsonSchema sobre la colección de tiendas
//   mongosh "mongodb://127.0.0.1:27017/LabMongoDB" --authenticationDatabase admin -u adminG11 --file ej12_1_validacion.js
// =============================================================================
db = db.getSiblingDB("LabMongoDB");

const esquema = {
  bsonType: "object",
  required: ["_id", "Address", "City", "Country", "Inventory"],
  properties: {
    _id:            { bsonType: "int", description: "número de tienda (entero)" },
    Address:        { bsonType: "string", minLength: 1 },
    City:           { bsonType: "string", minLength: 1 },
    Country:        { bsonType: "string", minLength: 1 },
    Phone:          { bsonType: "string" },
    // En stores.json viene como texto ("1"): se valida que sea texto numérico
    managerStaffId: { bsonType: "string", pattern: "^[0-9]+$" },
    Staff:          { bsonType: "array" },
    Inventory: {
      bsonType: "array",
      items: {
        bsonType: "object",
        required: ["filmId", "inventoryId", "Film Title"],
        properties: {
          filmId:       { bsonType: "int" },
          inventoryId:  { bsonType: "int" },
          "Film Title": { bsonType: "string" }
        }
      }
    }
  }
};

// 1. Antes de aplicar la regla: las tiendas existentes deben cumplirla (esperado 0).
//    Si no, mongorestore (12.2) crea la regla antes de cargar los datos y las rechaza.
print("Tiendas que NO cumplen el esquema: " + db.tiendas.countDocuments({ $nor: [{ $jsonSchema: esquema }] }));

// 2. Aplicar la regla a la colección existente
printjson(db.runCommand({ collMod: "tiendas", validator: { $jsonSchema: esquema },
                          validationLevel: "strict", validationAction: "error" }));
printjson(db.getCollectionInfos({ name: "tiendas" })[0].options.validationAction);

const probar = (titulo, doc) => {
  print("\n--- " + titulo + " ---");
  try {
    printjson(db.tiendas.insertOne(doc));
  } catch (e) {
    print(e.name + ": " + e.message);
    const det = e.errInfo && e.errInfo.details && e.errInfo.details.schemaRulesNotSatisfied;
    if (det) printjson(det);
  }
};

// 3. Inserciones VÁLIDAS
probar("VÁLIDA 1: tienda nueva con un ítem de inventario", {
  _id: 3, Address: "Av. 9 de Julio 1100", City: "Resistencia", Country: "Argentina",
  Phone: "3624000000", Staff: [],
  Inventory: [{ filmId: 1, inventoryId: 9001, "Film Title": "ACADEMY DINOSAUR" }] });
probar("VÁLIDA 2: tienda nueva con inventario vacío", {
  _id: 4, Address: "Junín 1500", City: "Corrientes", Country: "Argentina", Inventory: [] });

// 4. Inserciones INVÁLIDAS
probar("INVÁLIDA 1: falta el campo obligatorio City", {
  _id: 5, Address: "Calle sin ciudad 1", Country: "Argentina", Inventory: [] });
probar("INVÁLIDA 2: filmId del inventario como texto", {
  _id: 6, Address: "Calle 2", City: "Formosa", Country: "Argentina",
  Inventory: [{ filmId: "uno", inventoryId: 9002, "Film Title": "ACADEMY DINOSAUR" }] });

// 5. Resultado y limpieza (se borran las de prueba; la regla queda activa)
print("\nTiendas: " + JSON.stringify(db.tiendas.find({}, { _id: 1, City: 1 }).sort({ _id: 1 }).toArray()));
print("Borradas las de prueba: " + db.tiendas.deleteMany({ _id: { $in: [3, 4] } }).deletedCount +
      " | tiendas finales: " + db.tiendas.countDocuments());
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej12_2_backup.sh
-- ============================================================================
/*
#!/bin/bash
# =============================================================================
# LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
# Ejercicio 12.2 - Respaldo con mongodump y restauración con mongorestore en la
#                  base local LabMongoDB_Restore
# Uso: ./ej12_2_backup.sh       (cada herramienta pide la clave de adminG11;
#                                o MONGO_TOOLS_CONFIG=archivo.yaml con "password: ...")
# =============================================================================
set -euo pipefail
AUTH=(--host 127.0.0.1:27017 --username adminG11 --authenticationDatabase admin)
[ -n "${MONGO_TOOLS_CONFIG:-}" ] && AUTH+=(--config "$MONGO_TOOLS_CONFIG")
DESTINO="$HOME/backup_labmongodb"

echo "=== 1. Respaldo de LabMongoDB"
rm -rf "$DESTINO"
mongodump "${AUTH[@]}" --db LabMongoDB --out "$DESTINO"

echo; echo "=== 2. Archivos generados (.bson = datos, .metadata.json = índices y opciones)"
ls -lh "$DESTINO/LabMongoDB/"
echo "documentos en tiendas.bson: $(bsondump --quiet "$DESTINO/LabMongoDB/tiendas.bson" | wc -l)"

echo; echo "=== 3. Restauración en LabMongoDB_Restore (no pisa la base original)"
mongorestore "${AUTH[@]}" --drop \
  --nsInclude 'LabMongoDB.*' --nsFrom 'LabMongoDB.*' --nsTo 'LabMongoDB_Restore.*' \
  "$DESTINO"
*/

-- ============================================================================
-- Archivo: bloque3_mongodb/ej12_2_verificar.js
-- ============================================================================
/*
// =============================================================================
// LABORATORIO INTEGRADOR SGBD 2026 - GRUPO 11
// Ejercicio 12.2 - Comparación entre LabMongoDB y LabMongoDB_Restore
//   mongosh "mongodb://127.0.0.1:27017/admin" --authenticationDatabase admin -u adminG11 --file ej12_2_verificar.js
// =============================================================================
const orig = db.getSiblingDB("LabMongoDB"), rest = db.getSiblingDB("LabMongoDB_Restore");

print("Colección     LabMongoDB  LabMongoDB_Restore  Índices(orig/rest)  ¿Igual?");
orig.getCollectionNames().sort().forEach(c => {
  const a = orig.getCollection(c).countDocuments(), b = rest.getCollection(c).countDocuments();
  const ia = orig.getCollection(c).getIndexes().length, ib = rest.getCollection(c).getIndexes().length;
  print(c.padEnd(12) + String(a).padStart(11) + String(b).padStart(20) +
        (ia + "/" + ib).padStart(20) + "  " + (a === b && ia === ib ? "SÍ" : "NO"));
});

// La regla $jsonSchema del 12.1 viaja en el .metadata.json y queda activa en la copia
const v = rest.getCollectionInfos({ name: "tiendas" })[0].options;
print("\nValidador en LabMongoDB_Restore.tiendas: " + (v.validator ? "presente (" + v.validationAction + ")" : "NO"));

// El mismo pipeline del Ejercicio 11 sobre la copia da el mismo primer puesto
printjson(rest.clientes.aggregate([
  { $lookup: { from: "paises", localField: "Country", foreignField: "Name", as: "pais" } },
  { $unwind: "$pais" }, { $match: { "pais.geography.Continent": "South America" } },
  { $unwind: "$Rentals" }, { $group: { _id: "$Rentals.Film Title", alquileres: { $sum: 1 } } },
  { $sort: { alquileres: -1, _id: 1 } }, { $limit: 1 }
]).toArray());
*/

