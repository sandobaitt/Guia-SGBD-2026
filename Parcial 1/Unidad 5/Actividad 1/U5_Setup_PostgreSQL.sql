-- ============================================================
-- SGBD 2026 - Unidad 5
-- SETUP UNIFICADO - PostgreSQL
--
-- EJECUCION RECOMENDADA:
--   sudo -u postgres psql -f U5_Setup_PostgreSQL.sql
--
-- Este archivo utiliza metacomandos de psql (\gexec y \connect).
--
-- Este script:
--   1) Crea la base sgbd_u5 si no existe.
--   2) Crea/recrea el schema sgbd_u5 y el dataset.
--   3) Crea usuarios genericos alumno01..alumno06.
--   4) Otorga permisos de trabajo y observacion necesarios.
--
-- IMPORTANTE:
-- - No usar postgres para las actividades de los estudiantes.
-- - Las cuentas alumnoXX son solo para el laboratorio.
-- - El acceso remoto tambien requiere listen_addresses,
--   pg_hba.conf, firewall y red de la VM correctamente configurados.
-- ============================================================

-- ------------------------------------------------------------
-- 1. BASE DE DATOS
-- ------------------------------------------------------------
-- CREATE DATABASE no admite IF NOT EXISTS.
-- Esta forma es propia de psql y crea la base solo si falta.

SELECT 'CREATE DATABASE sgbd_u5'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'sgbd_u5'
)\gexec

\connect sgbd_u5

-- ------------------------------------------------------------
-- 2. DATASET
-- ------------------------------------------------------------

DROP SCHEMA IF EXISTS sgbd_u5 CASCADE;
CREATE SCHEMA sgbd_u5;
SET search_path TO sgbd_u5, public;

CREATE TABLE cuenta (
  cuenta_id INTEGER PRIMARY KEY,
  titular VARCHAR(100) NOT NULL,
  saldo NUMERIC(12,2) NOT NULL CHECK (saldo >= 0),
  estado VARCHAR(15) NOT NULL DEFAULT 'activa'
);

CREATE TABLE movimiento (
  movimiento_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cuenta_id INTEGER NOT NULL REFERENCES cuenta(cuenta_id),
  fecha TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tipo VARCHAR(20) NOT NULL,
  importe NUMERIC(12,2) NOT NULL
);

INSERT INTO cuenta(cuenta_id, titular, saldo) VALUES
(1,'Cuenta Uno',10000.00),
(2,'Cuenta Dos',8000.00),
(3,'Cuenta Tres',15000.00),
(4,'Cuenta Cuatro',5000.00);

CREATE INDEX ix_mov_cuenta_fecha
ON movimiento(cuenta_id, fecha);

-- ------------------------------------------------------------
-- 3. USUARIOS DE LABORATORIO
-- ------------------------------------------------------------
-- Password comun para simplificar el laboratorio.
-- La catedra puede reemplazarlo antes de publicar el archivo.

DO $$
DECLARE
    u text;
BEGIN
    FOREACH u IN ARRAY ARRAY[
        'alumno01','alumno02','alumno03',
        'alumno04','alumno05','alumno06'
    ]
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = u) THEN
            EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', u, 'SgbdU5_2026!');
        ELSE
            EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', u, 'SgbdU5_2026!');
        END IF;
    END LOOP;
END
$$;

-- Permitir conexion a la base.
GRANT CONNECT ON DATABASE sgbd_u5
TO alumno01, alumno02, alumno03, alumno04, alumno05, alumno06;

-- Acceso al schema y a los objetos del laboratorio.
GRANT USAGE ON SCHEMA sgbd_u5
TO alumno01, alumno02, alumno03, alumno04, alumno05, alumno06;

GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA sgbd_u5
TO alumno01, alumno02, alumno03, alumno04, alumno05, alumno06;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA sgbd_u5
TO alumno01, alumno02, alumno03, alumno04, alumno05, alumno06;

-- Mantener permisos si luego el administrador crea mas objetos.
ALTER DEFAULT PRIVILEGES IN SCHEMA sgbd_u5
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES
TO alumno01, alumno02, alumno03, alumno04, alumno05, alumno06;

ALTER DEFAULT PRIVILEGES IN SCHEMA sgbd_u5
GRANT USAGE, SELECT ON SEQUENCES
TO alumno01, alumno02, alumno03, alumno04, alumno05, alumno06;

-- Observacion del servidor para Guardia DBA / Actividad 2.
-- pg_monitor permite consultar estadisticas y actividad sin ser superusuario.
GRANT pg_monitor
TO alumno01, alumno02, alumno03, alumno04, alumno05, alumno06;

-- Hacer que las sesiones de laboratorio encuentren primero el schema sgbd_u5.
ALTER ROLE alumno01 IN DATABASE sgbd_u5 SET search_path = sgbd_u5, public;
ALTER ROLE alumno02 IN DATABASE sgbd_u5 SET search_path = sgbd_u5, public;
ALTER ROLE alumno03 IN DATABASE sgbd_u5 SET search_path = sgbd_u5, public;
ALTER ROLE alumno04 IN DATABASE sgbd_u5 SET search_path = sgbd_u5, public;
ALTER ROLE alumno05 IN DATABASE sgbd_u5 SET search_path = sgbd_u5, public;
ALTER ROLE alumno06 IN DATABASE sgbd_u5 SET search_path = sgbd_u5, public;

-- ------------------------------------------------------------
-- 4. CONTROLES
-- ------------------------------------------------------------

SELECT version();
SHOW port;

SELECT rolname
FROM pg_roles
WHERE rolname LIKE 'alumno%'
ORDER BY rolname;

SELECT cuenta_id, titular, saldo, estado
FROM sgbd_u5.cuenta
ORDER BY cuenta_id;

-- Fin del setup.
