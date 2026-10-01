-- GRUPO 5 OBJETOS

-- DESAFIO 1
-- Implementar mecanismo para impedir saldo negativo.
ALTER TABLE cuenta
ADD CONSTRAINT chk_cuenta_saldo
CHECK (saldo >= 0);


-- DESAFIO 2
-- Auditar cambios de precio.
-- FUNCION
CREATE FUNCTION registrar_cambio_precio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO auditoria_precio (
        producto_id,
        precio_anterior,
        precio_nuevo
    )
    VALUES (
        OLD.producto_id,
        OLD.precio,
        NEW.precio
    );

    RETURN NEW;
END;
$$;
--TRIGGER
CREATE TRIGGER trg_auditar_precio
AFTER UPDATE OF precio
ON producto
FOR EACH ROW
WHEN (OLD.precio IS DISTINCT FROM NEW.precio)
EXECUTE FUNCTION registrar_cambio_precio();

-- DESAFIO 3
-- Crear función o procedimiento de clasificación de cliente.
-- FUNCION
CREATE OR REPLACE FUNCTION clasificar_cliente(p_cliente_id INTEGER, p_anio INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_anual NUMERIC(14,2);
BEGIN
    SELECT COALESCE(SUM(total), 0)
    INTO v_total_anual
    FROM venta
    WHERE cliente_id = p_cliente_id 
      AND EXTRACT(YEAR FROM fecha) = p_anio;
    IF v_total_anual < 2000000 THEN
        RETURN 'Bronce';
    ELSIF v_total_anual <= 50000000 THEN
        RETURN 'Plata';
    ELSE
        RETURN 'Oro';
    END IF;
END;
$$;

-- DESAFIO 4
-- Agregar restricción para impedir precio <= 0.
ALTER TABLE producto
ADD CONSTRAINT chk_producto_precio
CHECK (precio > 0);

