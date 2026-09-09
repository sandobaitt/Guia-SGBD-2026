-- Actividad 3 - Pruebas v2
USE sgbd_u34_act3;

SELECT '--- VERIFICACION DE DATOS HEREDADOS (v1 a v2) ---' AS Info;
-- PRUEBA 1: Verificar que los datos v1 sigan existiendo y asuman estado 'pendiente' por el DEFAULT
SELECT * FROM pedido;


SELECT '--- PRUEBA VÁLIDA: CAMBIO DE ESTADO Y FUNCION ---' AS Info;
-- PRUEBA 2: Cambiar de estado múltiples veces (Activa el trigger)
UPDATE pedido SET estado = 'pagado' WHERE pedido_id = 1001;
UPDATE pedido SET estado = 'enviado' WHERE pedido_id = 1001;

-- PRUEBA 3: Función de cálculo de total
SELECT cliente_id, nombre, calcular_total_cliente(cliente_id) AS total_historico
FROM cliente;


SELECT '--- PRUEBA INVÁLIDA: RESTRICCIONES ---' AS Info;
-- PRUEBA 4: Intentar asignar un estado que no existe en el ENUM
-- ESPERADO: Error de truncamiento/datos inválidos
UPDATE pedido SET estado = 'entregado_ayer' WHERE pedido_id = 1002;

-- PRUEBA 5: Intentar poner un total negativo
-- ESPERADO: Error Check constraint violated
UPDATE pedido SET total = -500 WHERE pedido_id = 1003;


SELECT '--- VERIFICACION DE AUDITORIA ---' AS Info;
-- PRUEBA 6: Revisar tabla de auditoría para ver el viaje del pedido 1001 (pendiente -> pagado -> enviado)
SELECT * FROM auditoria_estado_pedido;
