-- Actividad 3 - Plan de Rollback (Revertir a v1)
USE sgbd_u34_act3;

-- =========================================================================
-- PLAN DE ROLLBACK DE V2 A V1
-- =========================================================================
-- ADVERTENCIA DE PÉRDIDA DE DATOS: 
-- Al eliminar la columna 'estado' y la tabla 'auditoria_estado_pedido', 
-- se perderá irrevocablemente el historial y el estado actual de todos 
-- los pedidos procesados durante la vigencia de la v2. 
-- Se recomienda imperativamente hacer un backup (mysqldump) antes de ejecutar.
-- =========================================================================

-- 1. Eliminar Programabilidad (Trigger y Función)
DROP TRIGGER IF EXISTS trg_auditoria_estado;
DROP FUNCTION IF EXISTS calcular_total_cliente;

-- 2. Eliminar Restricciones
ALTER TABLE pedido DROP CONSTRAINT chk_total_positivo;

-- 3. Eliminar Estructuras Nuevas
ALTER TABLE pedido DROP COLUMN estado;
DROP TABLE IF EXISTS auditoria_estado_pedido;

SELECT 'Rollback a v1 completado. La base de datos vuelve a su estado estructural original.' AS Estado;
