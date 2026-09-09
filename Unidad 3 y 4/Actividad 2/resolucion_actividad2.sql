USE sgbd_u4_act2;

-- ============================================================================
-- ACTIVIDAD 2 - RESOLUCIÓN: La regla que no puede romperse
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Reglas Simples: Validaciones de Precio y Saldo
-- Técnica elegida: Restricciones Declarativas (CHECK)
-- ----------------------------------------------------------------------------
ALTER TABLE producto ADD CONSTRAINT chk_precio_positivo CHECK (precio > 0);
ALTER TABLE cuenta ADD CONSTRAINT chk_saldo_positivo CHECK (saldo >= 0);


-- ----------------------------------------------------------------------------
-- 2. Auditoría de Precios
-- Técnica elegida: Disparador (TRIGGER)
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_update_precio;
DELIMITER //
CREATE TRIGGER trg_update_precio
AFTER UPDATE ON producto 
FOR EACH ROW 
BEGIN
  -- Solo auditamos si el precio realmente cambió
  IF OLD.precio <> NEW.precio THEN
    INSERT INTO auditoria_precio (producto_id, precio_anterior, precio_nuevo) 
    VALUES (OLD.producto_id, OLD.precio, NEW.precio);
  END IF;
END //
DELIMITER ;


-- ----------------------------------------------------------------------------
-- 3. Clasificación de Clientes (con la corrección del profesor)
-- Técnica elegida: Función Almacenada (FUNCTION)
-- *Nota: Se crea una tabla 'venta' mínima para que la función pueda operar
-- ----------------------------------------------------------------------------

-- Creamos la tabla de ventas que faltaba en el script base para que la función tenga de donde leer
CREATE TABLE IF NOT EXISTS venta (
  venta_id INT AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT NOT NULL,
  total DECIMAL(12,2) NOT NULL,
  fecha DATE NOT NULL,
  FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id)
);

-- Inserciones de prueba para que la función devuelva resultados coherentes
INSERT INTO venta (cliente_id, total, fecha) VALUES (1, 1000000, '2026-05-10'), (1, 1500000, '2026-08-20'); -- Cliente 1 en 2026: 2.5M (Plata)
INSERT INTO venta (cliente_id, total, fecha) VALUES (2, 60000000, '2026-10-10'); -- Cliente 2 en 2026: 60M (Oro)
INSERT INTO venta (cliente_id, total, fecha) VALUES (3, 500000, '2026-11-15'); -- Cliente 3 en 2026: 500k (Bronce)

DROP FUNCTION IF EXISTS clasificar_cliente;
DELIMITER //
CREATE FUNCTION clasificar_cliente(p_cliente_id INT, p_anio INT) 
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(14,2) DEFAULT 0;
  DECLARE v_categoria VARCHAR(20);
  
  -- Lógica interna: sumamos el total filtrando por cliente y año
  SELECT COALESCE(SUM(total), 0) INTO v_total
  FROM venta
  WHERE cliente_id = p_cliente_id AND EXTRACT(YEAR FROM fecha) = p_anio;
  
  -- Asignamos la categoría según los umbrales
  IF v_total > 50000000 THEN
    SET v_categoria = 'Oro';
  ELSEIF v_total >= 2000000 THEN
    SET v_categoria = 'Plata';
  ELSE
    SET v_categoria = 'Bronce';
  END IF;
  
  RETURN v_categoria;
END //
DELIMITER ;
