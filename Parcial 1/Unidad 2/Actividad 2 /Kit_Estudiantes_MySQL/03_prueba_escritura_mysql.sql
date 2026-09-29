USE sgbd_a2_lab;

-- Ejecutar una vez antes y otra despues de crear indices.
-- La transaccion se revierte: no quedan filas nuevas.
START TRANSACTION;
SET @inicio := NOW(6);

INSERT INTO pedido (pedido_id, cliente_id, fecha, estado, canal, sucursal_id, total)
SELECT 900000001 + n,
       MOD(n * 37, 20000) + 1,
       DATE_ADD('2025-12-01', INTERVAL MOD(n, 86400) SECOND),
       'PENDIENTE',
       'APP',
       MOD(n, 50) + 1,
       ROUND(100 + MOD(n * 97, 100000) / 100, 2)
FROM lab_numero
WHERE n < 10000;

SELECT ROUND(TIMESTAMPDIFF(MICROSECOND, @inicio, NOW(6)) / 1000, 2)
       AS milisegundos_insercion_10000_filas;
ROLLBACK;

SELECT COUNT(*) AS filas_con_id_temporal
FROM pedido
WHERE pedido_id >= 900000001;
