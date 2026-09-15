-- ============================================================
-- SGBD 2026 - Unidad 5
-- SETUP UNIFICADO - MySQL
-- Ejecutar con una cuenta administrativa del motor.
--
-- Este script:
--   1) Crea/recrea la base de laboratorio sgbd_u5.
--   2) Crea las tablas y datos usados en las actividades.
--   3) Crea usuarios genericos alumno01..alumno06.
--   4) Otorga permisos de trabajo y observacion necesarios.
--
-- IMPORTANTE:
-- - No usar root para las actividades de los estudiantes.
-- - Las cuentas alumnoXX son solo para el laboratorio.
-- - El acceso remoto tambien requiere bind-address, firewall y red
--   de la VM correctamente configurados.
-- ============================================================

CREATE DATABASE IF NOT EXISTS sgbd_u5;
USE sgbd_u5;

-- ------------------------------------------------------------
-- 1. DATASET
-- ------------------------------------------------------------

DROP TABLE IF EXISTS movimiento;
DROP TABLE IF EXISTS cuenta;

CREATE TABLE cuenta (
  cuenta_id INT PRIMARY KEY,
  titular VARCHAR(100) NOT NULL,
  saldo DECIMAL(12,2) NOT NULL,
  estado VARCHAR(15) NOT NULL DEFAULT 'activa',
  CONSTRAINT chk_cuenta_saldo CHECK (saldo >= 0)
) ENGINE=InnoDB;

CREATE TABLE movimiento (
  movimiento_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  cuenta_id INT NOT NULL,
  fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo VARCHAR(20) NOT NULL,
  importe DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_mov_cuenta
    FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id)
) ENGINE=InnoDB;

INSERT INTO cuenta(cuenta_id, titular, saldo) VALUES
(1,'Cuenta Uno',10000.00),
(2,'Cuenta Dos',8000.00),
(3,'Cuenta Tres',15000.00),
(4,'Cuenta Cuatro',5000.00);

CREATE INDEX ix_mov_cuenta_fecha
ON movimiento(cuenta_id, fecha);

-- ------------------------------------------------------------
-- 2. USUARIOS DE LABORATORIO
-- ------------------------------------------------------------
-- Password comun para simplificar el laboratorio.
-- La catedra puede reemplazarlo antes de publicar el archivo.

CREATE USER IF NOT EXISTS 'alumno01'@'%' IDENTIFIED BY 'SgbdU5_2026!';
CREATE USER IF NOT EXISTS 'alumno02'@'%' IDENTIFIED BY 'SgbdU5_2026!';
CREATE USER IF NOT EXISTS 'alumno03'@'%' IDENTIFIED BY 'SgbdU5_2026!';
CREATE USER IF NOT EXISTS 'alumno04'@'%' IDENTIFIED BY 'SgbdU5_2026!';
CREATE USER IF NOT EXISTS 'alumno05'@'%' IDENTIFIED BY 'SgbdU5_2026!';
CREATE USER IF NOT EXISTS 'alumno06'@'%' IDENTIFIED BY 'SgbdU5_2026!';

ALTER USER 'alumno01'@'%' IDENTIFIED BY 'SgbdU5_2026!';
ALTER USER 'alumno02'@'%' IDENTIFIED BY 'SgbdU5_2026!';
ALTER USER 'alumno03'@'%' IDENTIFIED BY 'SgbdU5_2026!';
ALTER USER 'alumno04'@'%' IDENTIFIED BY 'SgbdU5_2026!';
ALTER USER 'alumno05'@'%' IDENTIFIED BY 'SgbdU5_2026!';
ALTER USER 'alumno06'@'%' IDENTIFIED BY 'SgbdU5_2026!';

-- Trabajo sobre la base de laboratorio.
GRANT SELECT, INSERT, UPDATE, DELETE
ON *.* TO 'alumno01'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE
ON *.* TO 'alumno02'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE
ON *.* TO 'alumno03'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE
ON *.* TO 'alumno04'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE
ON *.* TO 'alumno05'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE
ON *.* TO 'alumno06'@'%';

-- Observacion de sesiones y locks para Guardia DBA / Actividad 2.
GRANT PROCESS ON *.* TO 'alumno01'@'%';
GRANT PROCESS ON *.* TO 'alumno02'@'%';
GRANT PROCESS ON *.* TO 'alumno03'@'%';
GRANT PROCESS ON *.* TO 'alumno04'@'%';
GRANT PROCESS ON *.* TO 'alumno05'@'%';
GRANT PROCESS ON *.* TO 'alumno06'@'%';

GRANT SELECT ON performance_schema.* TO 'alumno01'@'%';
GRANT SELECT ON performance_schema.* TO 'alumno02'@'%';
GRANT SELECT ON performance_schema.* TO 'alumno03'@'%';
GRANT SELECT ON performance_schema.* TO 'alumno04'@'%';
GRANT SELECT ON performance_schema.* TO 'alumno05'@'%';
GRANT SELECT ON performance_schema.* TO 'alumno06'@'%';

-- ------------------------------------------------------------
-- 3. CONTROLES
-- ------------------------------------------------------------

SELECT VERSION() AS version_mysql;
SHOW VARIABLES LIKE 'port';

SELECT user, host
FROM mysql.user
WHERE user LIKE 'alumno%'
ORDER BY user;

SELECT cuenta_id, titular, saldo, estado
FROM sgbd_u5.cuenta
ORDER BY cuenta_id;

-- Fin del setup.
