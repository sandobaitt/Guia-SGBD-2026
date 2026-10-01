SET search_path TO sgbd_u34_act3;
-- 1. Función para calcular el total por cliente
CREATE OR REPLACE FUNCTION calcular_total_cliente(p_cliente_id INTEGER)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(12,2);
BEGIN
    SELECT COALESCE(SUM(total), 0) INTO v_total
    FROM pedido
    WHERE cliente_id = p_cliente_id;
    
    RETURN v_total;
END;
$$;

-- 2. Función del trigger para la auditoría de estados
CREATE OR REPLACE FUNCTION fn_auditar_nuevo_estado()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        INSERT INTO auditoria_nuevo_estado (pedido_id, estado_viejo, estado_nuevo, usuario)
        VALUES (NEW.pedido_id, OLD.estado, NEW.estado, CURRENT_USER);
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;


-- 3. Trigger asociado a la tabla pedido
CREATE TRIGGER trg_auditar_estado
AFTER UPDATE OF estado ON pedido
FOR EACH ROW EXECUTE FUNCTION fn_auditar_nuevo_estado();