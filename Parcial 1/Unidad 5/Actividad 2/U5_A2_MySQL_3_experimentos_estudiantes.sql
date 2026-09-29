-- ============================================================
-- SGBD 2026 - Unidad 5 - Actividad 2
-- DOS USUARIOS, UN MISMO DATO
-- GUIA DE LABORATORIO PARA ESTUDIANTES - MySQL / InnoDB
-- ============================================================
--
-- OBJETIVO
-- Reproducir y observar tres fenomenos:
--   1) Espera por lock
--   2) Efecto del nivel de aislamiento
--   3) Deadlock controlado
--
-- IMPORTANTE
-- - Trabajar solamente sobre la base de laboratorio.
-- - Abrir DOS ventanas/conexiones independientes:
--       SESION A
--       SESION B
-- - No ejecutar todo el archivo de una sola vez.
-- - Ejecutar cada bloque cuando la guia lo indique.
-- - Cerrar cada experimento con COMMIT o ROLLBACK.
-- - Registrar capturas/evidencias antes de liberar una espera.
--
-- ============================================================

USE sgbd_u5;

-- ------------------------------------------------------------
-- 0. VERIFICACION INICIAL
-- ------------------------------------------------------------

SELECT VERSION() AS version_motor;
SELECT @@transaction_isolation AS aislamiento_actual;

SELECT cuenta_id, titular, saldo
FROM cuenta
ORDER BY cuenta_id;

-- Verifique que existan al menos las cuentas 1, 2 y 3.
-- Si el setup de la catedra utiliza otros IDs, adapte SOLO los IDs.


-- ============================================================
-- EXPERIMENTO 1 - ESPERA POR LOCK
-- Pregunta:
-- ¿Que ocurre cuando dos transacciones intentan modificar
-- simultaneamente la misma fila?
-- ============================================================

-- ------------------------------------------------------------
-- PASO 1 - EJECUTAR EN SESION A
-- ------------------------------------------------------------

START TRANSACTION;

SELECT 'SESION A - antes del UPDATE' AS paso;
SELECT cuenta_id, saldo FROM cuenta WHERE cuenta_id = 1;

UPDATE cuenta
SET saldo = saldo - 100
WHERE cuenta_id = 1;

SELECT 'SESION A - UPDATE realizado, NO hacer COMMIT todavia' AS paso;
SELECT cuenta_id, saldo FROM cuenta WHERE cuenta_id = 1;

-- DETENERSE AQUI.
-- Mantenga abierta la transaccion de A.


-- ------------------------------------------------------------
-- PASO 2 - EJECUTAR EN SESION B
-- ------------------------------------------------------------

START TRANSACTION;

SELECT 'SESION B - intento de UPDATE sobre la misma cuenta' AS paso;

UPDATE cuenta
SET saldo = saldo + 50
WHERE cuenta_id = 1;

-- ESTA SENTENCIA DEBERIA QUEDAR ESPERANDO.
-- NO cierre la ventana.
-- Mientras B espera, use una tercera pestaña o la SESION A
-- para ejecutar el diagnostico siguiente.


-- ------------------------------------------------------------
-- PASO 3 - DIAGNOSTICO DE LA ESPERA
-- Ejecutar mientras SESION B esta esperando.
-- ------------------------------------------------------------

SHOW PROCESSLIST;

SELECT *
FROM performance_schema.data_lock_waits;

SELECT *
FROM performance_schema.data_locks;

-- Preguntas para registrar:
-- 1. ¿Que sesion esta esperando?
-- 2. ¿Que sesion mantiene el lock?
-- 3. ¿La consulta esta "lenta" o esta esperando un recurso?
-- 4. ¿Que evidencia permite afirmarlo?


-- ------------------------------------------------------------
-- PASO 4 - LIBERAR LA ESPERA
-- Elegir UNA alternativa en SESION A.
-- ------------------------------------------------------------

-- Alternativa A:
-- COMMIT;

-- Alternativa B:
-- ROLLBACK;

-- Observe que ocurre inmediatamente en SESION B.
-- Cuando B termine su UPDATE, cierre tambien B:
-- COMMIT;
-- o
-- ROLLBACK;

-- Comprobar estado final:
SELECT cuenta_id, saldo FROM cuenta WHERE cuenta_id = 1;


-- ============================================================
-- EXPERIMENTO 2 - NIVEL DE AISLAMIENTO
-- Pregunta:
-- Si otra transaccion confirma un cambio,
-- ¿la primera transaccion lo ve en una segunda lectura?
-- ============================================================

-- ------------------------------------------------------------
-- PASO 1 - REGISTRAR EL NIVEL REAL DEL MOTOR
-- ------------------------------------------------------------

SELECT @@transaction_isolation AS aislamiento_actual;

-- NO asumir el valor: copiarlo en la bitacora.


-- ------------------------------------------------------------
-- PASO 2 - SESION A
-- ------------------------------------------------------------

START TRANSACTION;

SELECT 'SESION A - primera lectura' AS paso;
SELECT cuenta_id, saldo
FROM cuenta
WHERE cuenta_id = 3;

-- Anotar el saldo observado.
-- NO cerrar la transaccion.


-- ------------------------------------------------------------
-- PASO 3 - SESION B
-- ------------------------------------------------------------

START TRANSACTION;

UPDATE cuenta
SET saldo = saldo + 1000
WHERE cuenta_id = 3;

COMMIT;

SELECT 'SESION B - cambio confirmado' AS paso;
SELECT cuenta_id, saldo
FROM cuenta
WHERE cuenta_id = 3;


-- ------------------------------------------------------------
-- PASO 4 - VOLVER A SESION A
-- ------------------------------------------------------------

SELECT 'SESION A - segunda lectura dentro de la misma transaccion' AS paso;
SELECT cuenta_id, saldo
FROM cuenta
WHERE cuenta_id = 3;

-- Preguntas para registrar:
-- 1. ¿La segunda lectura de A muestra el mismo saldo que la primera?
-- 2. ¿Ve el cambio confirmado por B?
-- 3. ¿Como se relaciona lo observado con @@transaction_isolation?

-- Cerrar SESION A:
COMMIT;


-- ------------------------------------------------------------
-- EXTENSION OPCIONAL
-- Repetir explicitamente con READ COMMITTED.
-- Ejecutar ANTES de START TRANSACTION.
-- ------------------------------------------------------------

-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
-- ... repetir la secuencia ...

-- Para volver al comportamiento del servidor al finalizar,
-- cerrar la conexion o restablecer el nivel correspondiente.


-- ============================================================
-- EXPERIMENTO 3 - DEADLOCK CONTROLADO
-- Pregunta:
-- ¿Que ocurre cuando A espera un recurso de B
-- y B espera un recurso de A?
-- ============================================================

-- ATENCION:
-- Este experimento requiere coordinacion entre SESION A y SESION B.
-- Ejecutar UN PASO POR VEZ.


-- ------------------------------------------------------------
-- PASO 1A - SESION A
-- ------------------------------------------------------------

START TRANSACTION;

UPDATE cuenta
SET saldo = saldo - 10
WHERE cuenta_id = 1;

-- A mantiene bloqueada la cuenta 1.


-- ------------------------------------------------------------
-- PASO 1B - SESION B
-- ------------------------------------------------------------

START TRANSACTION;

UPDATE cuenta
SET saldo = saldo - 20
WHERE cuenta_id = 2;

-- B mantiene bloqueada la cuenta 2.


-- ------------------------------------------------------------
-- PASO 2 - SESION A
-- ------------------------------------------------------------

UPDATE cuenta
SET saldo = saldo + 20
WHERE cuenta_id = 2;

-- A deberia quedar esperando a B.


-- ------------------------------------------------------------
-- PASO 3 - SESION B
-- Ejecutar ahora, mientras A espera.
-- ------------------------------------------------------------

UPDATE cuenta
SET saldo = saldo + 10
WHERE cuenta_id = 1;

-- Se forma el ciclo:
-- A necesita cuenta 2, retenida por B.
-- B necesita cuenta 1, retenida por A.
--
-- El motor deberia detectar el deadlock y abortar una transaccion.


-- ------------------------------------------------------------
-- PASO 4 - DIAGNOSTICO
-- ------------------------------------------------------------

SHOW ENGINE INNODB STATUS;

-- Buscar la seccion:
-- LATEST DETECTED DEADLOCK

SELECT *
FROM performance_schema.data_lock_waits;

-- Preguntas para registrar:
-- 1. ¿Que transaccion fue elegida como victima?
-- 2. ¿Que locks formaban el ciclo?
-- 3. ¿Por que esto es un deadlock y no una simple espera?
-- 4. ¿Que estrategia de diseño/aplicacion podria prevenirlo?

-- IMPORTANTE:
-- La sesion que continue activa debe cerrarse:
-- COMMIT;
-- o
-- ROLLBACK;

-- La transaccion abortada puede requerir ROLLBACK segun el cliente.


-- ============================================================
-- CONTROL FINAL
-- ============================================================

SELECT cuenta_id, titular, saldo
FROM cuenta
WHERE cuenta_id IN (1,2,3)
ORDER BY cuenta_id;

-- Fin del laboratorio.
