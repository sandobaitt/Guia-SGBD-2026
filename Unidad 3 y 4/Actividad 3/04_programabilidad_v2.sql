-- Actividad 3 - Programabilidad v2
USE sgbd_u34_act3;

-- 1. Trigger de Auditoría de Estados
DROP TRIGGER IF EXISTS trg_auditoria_estado;
DELIMITER //
CREATE TRIGGER trg_auditoria_estado
AFTER UPDATE ON pedido
FOR EACH ROW
BEGIN
  -- Solo auditar si el estado efectivamente cambió
  IF OLD.estado <> NEW.estado THEN
    INSERT INTO auditoria_estado_pedido (pedido_id, estado_anterior, estado_nuevo)
    VALUES (NEW.pedido_id, OLD.estado, NEW.estado);
  END IF;
END //
DELIMITER ;

-- 2. Función reutilizable para calcular total por cliente
DROP FUNCTION IF EXISTS calcular_total_cliente;
DELIMITER //
CREATE FUNCTION calcular_total_cliente(p_cliente_id INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(14,2) DEFAULT 0;
  
  -- COALESCE asegura que si no hay pedidos, retorne 0 y no NULL
  SELECT COALESCE(SUM(total), 0) INTO v_total
  FROM pedido
  WHERE cliente_id = p_cliente_id;
  
  RETURN v_total;
END //
DELIMITER ;
