USE sgbd_a2_lab;

-- 1. Escribir primero la hipotesis en la Bitacora.
-- 2. Crear como maximo dos indices. Usar nombres idx_a2_gXX_descripcion.
-- 3. No copiar una solucion de otro grupo: el DDL debe responder a la hipotesis.

-- EJEMPLO DE FORMA, NO DE CONTENIDO:
-- CREATE INDEX idx_a2_gXX_nombre ON pedido (columna1, columna2);

-- PEGAR AQUI EL DDL DEL GRUPO:
CREATE INDEX idx_a2_gXX_cliente_fecha ON pedido (cliente_id, fecha);
CREATE INDEX idx_a2_gXX_sucursal_estado_fecha ON pedido (sucursal_id, estado, fecha);

ANALYZE TABLE pedido;
SHOW INDEX FROM pedido;

SET @cliente_prueba := 1500;
SET @sucursal_prueba := 12;
SET @desde := '2024-01-01 00:00:00';
SET @hasta := '2024-04-01 00:00:00';

-- Repetir exactamente las mismas mediciones de la linea base.
EXPLAIN ANALYZE
SELECT pedido_id, fecha, estado, total
FROM pedido
WHERE cliente_id = @cliente_prueba
ORDER BY fecha DESC
LIMIT 20;

EXPLAIN ANALYZE
SELECT pedido_id, cliente_id, fecha, total
FROM pedido
WHERE sucursal_id = @sucursal_prueba
  AND estado = 'PENDIENTE'
ORDER BY fecha
LIMIT 100;

EXPLAIN ANALYZE
SELECT estado, COUNT(*) AS cantidad, SUM(total) AS importe
FROM pedido
WHERE fecha >= @desde AND fecha < @hasta
GROUP BY estado;
