USE sgbd_a2_lab;

-- Registrar esta informacion en la Bitacora.
SELECT VERSION() AS version_mysql;
SELECT COUNT(*) AS filas_pedido FROM pedido;
SHOW INDEX FROM pedido;

SET @cliente_prueba := 1500;
SET @sucursal_prueba := 12;
SET @desde := '2024-01-01 00:00:00';
SET @hasta := '2024-04-01 00:00:00';

-- CONSULTA A · Ejecutar tres veces y guardar el plan.
EXPLAIN ANALYZE
SELECT pedido_id, fecha, estado, total
FROM pedido
WHERE cliente_id = @cliente_prueba
ORDER BY fecha DESC
LIMIT 20;

-- CONSULTA B · Ejecutar tres veces y guardar el plan.
EXPLAIN ANALYZE
SELECT pedido_id, cliente_id, fecha, total
FROM pedido
WHERE sucursal_id = @sucursal_prueba
  AND estado = 'PENDIENTE'
ORDER BY fecha
LIMIT 100;

-- CONSULTA C · Referencia secundaria del escenario MySQL.
EXPLAIN ANALYZE
SELECT estado, COUNT(*) AS cantidad, SUM(total) AS importe
FROM pedido
WHERE fecha >= @desde AND fecha < @hasta
GROUP BY estado;
