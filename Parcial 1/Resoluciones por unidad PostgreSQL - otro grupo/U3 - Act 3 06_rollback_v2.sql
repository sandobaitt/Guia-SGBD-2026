SET search_path TO sgbd_u34_act3, public;

-- 1. Eliminar capa de automatización y funciones (programabilidad)
DROP TRIGGER IF EXISTS trg_auditar_estado ON pedido;
DROP FUNCTION IF EXISTS fn_auditar_nuevo_estado();
DROP FUNCTION IF EXISTS calcular_total_cliente(INTEGER);

-- 2. Eliminar restricciones agregadas en v2
ALTER TABLE pedido DROP CONSTRAINT IF EXISTS regla_totales_no_negativos;

-- 3. Respaldo preventivo de datos generados en v2 antes de la eliminación definitiva
-- NOTA: Al eliminar la tabla de auditoría y la columna estado se pierde
-- toda la trazabilidad operativa generada en v2 si no se resguarda antes.
CREATE TABLE IF NOT EXISTS backup_auditoria_v2 AS SELECT * FROM auditoria_nuevo_estado;
CREATE TABLE IF NOT EXISTS backup_estados_v2 AS SELECT pedido_id, estado FROM pedido;

-- 4. Eliminar tabla de auditoría y columna nueva de pedido
DROP TABLE IF EXISTS auditoria_nuevo_estado;
ALTER TABLE pedido DROP COLUMN IF EXISTS estado;