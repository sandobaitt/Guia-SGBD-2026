-- =============================================================================
-- UNIDAD 6: ACTIVIDAD 1 - OPERACIÓN RESCATE
-- GRUPO 11: LOGÍSTICA Y DEPÓSITOS
-- Script Unificado: Auditoría, Explotación, Hardening PoLP y Validación
-- Motor: MySQL 8.0+
-- =============================================================================

USE u6_rescate;

-- =============================================================================
-- SECCIÓN 0: CONTROL DE LÍNEA DE BASE INICIAL
-- Ejecutar como usuario administrativo (root o dba_admin)
-- =============================================================================
SELECT '--- ESTADO INICIAL (LÍNEA DE BASE) ---' AS etapa;
SELECT COUNT(*) AS total_clientes FROM cliente;
SELECT COUNT(*) AS total_cuentas FROM cuenta;
SELECT COUNT(*) AS total_movimientos FROM movimiento;
SELECT COALESCE(SUM(importe), 0) AS suma_total_importes FROM movimiento;

-- Detalle inicial de movimientos para registro documental
SELECT movimiento_id, cuenta_id, fecha, tipo, importe, descripcion 
FROM movimiento 
ORDER BY movimiento_id;


-- =============================================================================
-- SECCIÓN 1: FASE 1 - DEMOSTRACIÓN DE ACCESOS INDEBIDOS (ANTES DEL HARDENING)
-- Estas consultas evidencian la vulnerabilidad del script base original.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Acceso Indebido 1: u6_app ejecutando DDL destructivo (DROP TABLE)
-- Conexión simulada o ejecutada como 'u6_app'@'%' (contraseña: Cambiar_2026!)
-- Riesgo: Una inyección SQL en la app web podría destruir tablas o la base completa.
-- -----------------------------------------------------------------------------
-- Demostración creando y borrando una tabla de prueba:
/*
-- Conectar como: mysql -u u6_app -p -h localhost u6_rescate
CREATE TABLE u6_rescate.backdoor_test (id INT PRIMARY KEY, test VARCHAR(50));
DROP TABLE u6_rescate.backdoor_test;
-- ¡Éxito indebido! Una aplicación nunca debe poseer privilegios CREATE o DROP en producción.
*/

-- -----------------------------------------------------------------------------
-- Acceso Indebido 2: u6_analista modificando saldos o movimientos financieros
-- Conexión simulada o ejecutada como 'u6_analista'@'%' (contraseña: Cambiar_2026!)
-- Riesgo: Un usuario de BI/Reportes altera datos contables, violando la integridad.
-- -----------------------------------------------------------------------------
/*
-- Conectar como: mysql -u u6_analista -p -h localhost u6_rescate
UPDATE u6_rescate.cuenta 
SET saldo = saldo + 500000.00 
WHERE cuenta_id = 101;
-- ¡Éxito indebido! El rol analista tenía asignado GRANT UPDATE on u6_rescate.*
-- Revertir para mantener la coherencia del laboratorio:
UPDATE u6_rescate.cuenta 
SET saldo = saldo - 500000.00 
WHERE cuenta_id = 101;
*/

-- -----------------------------------------------------------------------------
-- Acceso Indebido 3: u6_app o u6_analista borrando registros de auditoría
-- Conexión simulada o ejecutada como 'u6_app'@'%'
-- Riesgo: Destrucción de la pista de auditoría forense para encubrir fraudes.
-- -----------------------------------------------------------------------------
/*
-- Conectar como: mysql -u u6_app -p -h localhost u6_rescate
DELETE FROM u6_rescate.auditoria_evento WHERE evento = 'SETUP';
-- ¡Éxito indebido! La app tiene permiso DELETE sobre toda la base u6_rescate.*
-- Re-insertar para restaurar el registro original si se ejecutó:
INSERT INTO u6_rescate.auditoria_evento(usuario, evento, detalle)
VALUES ('root@localhost', 'SETUP', 'Base inicial creada para Unidad 6');
*/


-- =============================================================================
-- SECCIÓN 2: FASE 1 - REDISEÑO DE PERMISOS (PRINCIPIO DE MENOR PRIVILEGIO - PoLP)
-- Ejecutar con usuario administrador (root)
-- =============================================================================

-- 1. Limpieza de privilegios excesivos anteriores en los roles
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_app;
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_analista;
REVOKE ALL PRIVILEGES, GRANT OPTION FROM rol_auditor;

-- 2. Asignación granular basada en la función de negocio:

-- ROL APP:
-- - Lectura y actualización operativa de clientes y cuentas.
-- - Inserción y consulta de movimientos (los movimientos bancarios NO se borran ni modifican: son append-only).
-- - Solo inserción en auditoría de eventos (no puede leer logs de otros ni borrar su propia huella).
-- - CERO privilegios DDL (CREATE, DROP, ALTER).
GRANT SELECT, INSERT, UPDATE ON u6_rescate.cliente TO rol_app;
GRANT SELECT, INSERT, UPDATE ON u6_rescate.cuenta TO rol_app;
GRANT SELECT, INSERT ON u6_rescate.movimiento TO rol_app;
GRANT INSERT ON u6_rescate.auditoria_evento TO rol_app;

-- ROL ANALISTA:
-- - Estrictamente de consulta (solo lectura) sobre datos de negocio.
-- - Cero acceso de escritura (INSERT, UPDATE, DELETE).
-- - Sin acceso a la tabla de auditoría de seguridad.
GRANT SELECT ON u6_rescate.cliente TO rol_analista;
GRANT SELECT ON u6_rescate.cuenta TO rol_analista;
GRANT SELECT ON u6_rescate.movimiento TO rol_analista;

-- ROL AUDITOR:
-- - Lectura total sobre auditoría de eventos para control forense.
-- - Lectura de fiscalización sobre tablas de negocio.
-- - Cero permisos de escritura o modificación en cualquier objeto.
GRANT SELECT ON u6_rescate.auditoria_evento TO rol_auditor;
GRANT SELECT ON u6_rescate.cliente TO rol_auditor;
GRANT SELECT ON u6_rescate.cuenta TO rol_auditor;
GRANT SELECT ON u6_rescate.movimiento TO rol_auditor;

-- 3. Asegurar activación automática de roles por defecto en MySQL 8
SET DEFAULT ROLE ALL TO 'u6_app'@'%';
SET DEFAULT ROLE ALL TO 'u6_analista'@'%';
SET DEFAULT ROLE ALL TO 'u6_auditor'@'%';

FLUSH PRIVILEGES;

INSERT INTO auditoria_evento(usuario, evento, detalle)
VALUES (CURRENT_USER(), 'HARDENING', 'Se implemento el Principio de Menor Privilegio (PoLP) sobre roles u6');


-- =============================================================================
-- SECCIÓN 3: FASE 1 - VALIDACIÓN POST-HARDENING (DEMOSTRACIÓN DE BLOQUEO)
-- Ejecutar con los usuarios respectivos para capturar el Error 1142 (Access denied)
-- =============================================================================

-- Prueba 1 (u6_app intentando DDL destructivo):
-- Conectar como u6_app:
-- DROP TABLE u6_rescate.auditoria_evento;
-- RESULTADO ESPERADO: ERROR 1142 (42000): DROP command denied to user 'u6_app'@'%' for table 'auditoria_evento'

-- Prueba 2 (u6_analista intentando modificar saldos):
-- Conectar como u6_analista:
-- UPDATE u6_rescate.cuenta SET saldo = 999999 WHERE cuenta_id = 101;
-- RESULTADO ESPERADO: ERROR 1142 (42000): UPDATE command denied to user 'u6_analista'@'%' for table 'cuenta'

-- Prueba 3 (u6_app intentando borrar registros contables o auditoría):
-- Conectar como u6_app:
-- DELETE FROM u6_rescate.movimiento WHERE movimiento_id = 1001;
-- RESULTADO ESPERADO: ERROR 1142 (42000): DELETE command denied to user 'u6_app'@'%' for table 'movimiento'

-- Prueba 4 (Operaciones legítimas que SÍ deben funcionar):
-- u6_app insertando movimiento válido:
-- INSERT INTO u6_rescate.movimiento VALUES (1999, 101, NOW(), 'CREDITO', 10.00, 'Test App');
-- DELETE FROM u6_rescate.movimiento WHERE movimiento_id = 1999; -- Esto fallará con Error 1142 (Protección efectiva!)
-- (Limpiar desde root si se ejecutó la prueba 4)


-- =============================================================================
-- SECCIÓN 4: FASE 2 - SIMULACIÓN DE INCIDENTE Y OPERACIONES
-- =============================================================================

-- PASO 4.1: Realizar BACKUP desde terminal del sistema operativo:
-- mysqldump -u root -p --single-transaction --flush-logs --source-data=2 --databases u6_rescate > /home/sando/Documents/SGBD/Unidad\ 6/Actividad\ 1/backup_u6_rescate_inicial.sql

-- PASO 4.2: Operaciones válidas posteriores al backup (ejecutar en MySQL):
INSERT INTO movimiento VALUES (1006, 101, '2026-09-22 10:05:00', 'CREDITO', 15000.00, 'Operacion valida posterior al backup');
INSERT INTO movimiento VALUES (1007, 102, '2026-09-22 10:12:00', 'DEBITO', -7000.00, 'Operacion valida posterior al backup');
INSERT INTO auditoria_evento(usuario, evento, detalle) VALUES (CURRENT_USER(), 'OPERACIONES_VALIDAS', 'Se ejecutaron movimientos 1006 y 1007');

-- Estado post-operaciones válidas:
-- total_clientes: 4, total_cuentas: 4, total_movimientos: 7, suma_importes: $81.000,00

-- PASO 4.3: Incidente a simular (Borrado accidental):
DELETE FROM movimiento WHERE cuenta_id = 101;
INSERT INTO auditoria_evento(usuario, evento, detalle) VALUES (CURRENT_USER(), 'INCIDENTE', 'Borrado accidental de movimientos de cuenta 101');

-- Estado post-incidente (Daño en producción):
-- Total movimientos baja a 4 (se borraron el 1001, 1002 y 1006 pertenecientes a cuenta 101).
-- Suma de importes se desvirtúa drásticamente.

SELECT '--- ESTADO POST-INCIDENTE (PRODUCCIÓN CORRUPTA) ---' AS etapa;
SELECT COUNT(*) AS total_movimientos FROM movimiento;
SELECT COALESCE(SUM(importe), 0) AS suma_total_importes FROM movimiento;


-- =============================================================================
-- SECCIÓN 5: FASE 2 - VALIDACIÓN DEL ESTADO FINAL TRAS PITR
-- Ejecutar como root luego de completar el procedimiento de restauración y replay
-- =============================================================================

SELECT '--- ESTADO POST-RESTAURACIÓN PITR (PRODUCCIÓN RECUPERADA) ---' AS etapa;
SELECT COUNT(*) AS total_clientes FROM cliente;
SELECT COUNT(*) AS total_cuentas FROM cuenta;
SELECT COUNT(*) AS total_movimientos FROM movimiento;
SELECT COALESCE(SUM(importe), 0) AS suma_total_importes FROM movimiento;

-- Verificación de que los movimientos de la cuenta 101 (1001, 1002, 1006) están presentes:
SELECT movimiento_id, cuenta_id, fecha, tipo, importe, descripcion 
FROM movimiento 
ORDER BY movimiento_id;

-- Verificación de auditoría:
SELECT * FROM auditoria_evento ORDER BY auditoria_id;
