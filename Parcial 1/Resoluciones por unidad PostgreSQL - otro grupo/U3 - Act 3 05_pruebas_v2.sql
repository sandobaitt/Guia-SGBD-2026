SET search_path TO sgbd_u34_act3, public;

-- PRUEBA 1: Integridad y continuidad de datos de v1
SELECT * FROM cliente ORDER BY cliente_id;
SELECT * FROM pedido ORDER BY pedido_id;
SELECT * FROM detalle_pedido ORDER BY detalle_id;

-- PRUEBA 2: Validación de estados permitidos y restricción CHECK
-- 1. Modificaciones con estados permitidos
UPDATE pedido SET estado = 'pagado' WHERE pedido_id = 1001;
UPDATE pedido SET estado = 'enviado' WHERE pedido_id = 1002;
UPDATE pedido SET estado = 'cancelado' WHERE pedido_id = 1003;

-- Consultar cambios aplicados
SELECT pedido_id, estado FROM pedido ORDER BY pedido_id;

-- 2. Prueba inválida: forzar un estado inexistente (debe rebotar por CHECK)
UPDATE pedido SET estado = 'invalido' WHERE pedido_id = 1001;

-- Verificar que el pedido 1001 conservó su estado válido previo
SELECT pedido_id, estado FROM pedido WHERE pedido_id = 1001;

-- PRUEBA 3: Auditoría automática de transiciones de estado
SELECT * FROM auditoria_nuevo_estado ORDER BY nro_auditoria;

-- PRUEBA 4: Restricción de totales no negativos (CHECK) y caso límite
-- 1. Consultar valor actual del pedido 1003
SELECT pedido_id, total FROM pedido WHERE pedido_id = 1003;

-- 2. Caso inválido: intentar asignar un total negativo (debe fallar por CHECK)
UPDATE pedido SET total = -100 WHERE pedido_id = 1003;

-- 3. Verificar que conservó los 9000 originales tras el rechazo
SELECT pedido_id, total FROM pedido WHERE pedido_id = 1003;

-- 4. Caso límite: total = 0 (debe aceptarse porque la regla es total >= 0)
UPDATE pedido SET total = 0 WHERE pedido_id = 1003;
SELECT pedido_id, total FROM pedido WHERE pedido_id = 1003;

-- 5. Restaurar valor original para no alterar el cálculo de la prueba 5
UPDATE pedido SET total = 9000 WHERE pedido_id = 1003;

-- PRUEBA 5: Función reutilizable de cálculo acumulado por cliente
-- Cliente 1: 15000 + 22000 = 37000
SELECT calcular_total_cliente(1) AS total_cliente_1;

-- Cliente 2: 9000
SELECT calcular_total_cliente(2) AS total_cliente_2;

-- Cliente 3: no tiene pedidos asociados (COALESCE debe devolver 0.00)
SELECT calcular_total_cliente(3) AS total_cliente_3;