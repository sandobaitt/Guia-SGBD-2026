USE sgbd_u4_act2;

-- ============================================================================
-- ACTIVIDAD 2 - PRUEBAS DE LA REGLA QUE NO PUEDE ROMPERSE
-- ============================================================================

SELECT '--- INICIANDO PRUEBAS DE PRECIO Y SALDO ---' AS Info;

-- PRUEBA 1: Caso Inválido (Saldo Negativo)
-- Intentamos dejar la cuenta 1 en negativo. 
-- ESPERADO: Debería fallar con error de Check Constraint.
-- Para que el script no se detenga por el error, mysql arrojará el error pero continuará.
UPDATE cuenta SET saldo = -500 WHERE cuenta_id = 1;

-- PRUEBA 2: Caso Límite (Saldo Cero)
-- Intentamos dejar la cuenta 1 en exactamente 0.
-- ESPERADO: Debería funcionar porque la regla es saldo >= 0.
UPDATE cuenta SET saldo = 0 WHERE cuenta_id = 1;

-- PRUEBA 3: Caso Inválido (Precio cero o negativo)
-- ESPERADO: Debería fallar.
UPDATE producto SET precio = 0 WHERE producto_id = 1;

-- PRUEBA 4: Caso Válido (Cambio de precio exitoso para auditar)
-- Aumentamos el precio del producto 1 de 1000 a 1200.
-- ESPERADO: Funciona y además debería disparar el Trigger.
UPDATE producto SET precio = 1200 WHERE producto_id = 1;

-- Verificamos la tabla de auditoría
SELECT '--- RESULTADO DE AUDITORIA ---' AS Info;
SELECT * FROM auditoria_precio;

-- PRUEBA 5: Pruebas de la Función Clasificadora
SELECT '--- PRUEBA DE CLASIFICACION (Bronce, Plata, Oro) ---' AS Info;

-- Evaluamos a los 3 clientes en el año 2026 usando la función:
SELECT 
  cliente_id, 
  nombre, 
  clasificar_cliente(cliente_id, 2026) AS categoria_2026
FROM cliente;
