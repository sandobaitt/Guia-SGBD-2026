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
