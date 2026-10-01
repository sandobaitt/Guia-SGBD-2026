SET search_path TO sgbd_u34_act3;
--1) Agregar estados de pedido: pendiente, pagado, enviado, cancelado.

ALTER TABLE pedido ADD COLUMN estado CHAR(20) NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente', 'pagado', 'enviado', 'cancelado'));

-- NOT NULL
-- Es una restriccion que no permite que la columna estado quede vacía.

-- DEFAULT 'pendiente'
-- Define qué valor usar automáticamente cuando no se especifica uno. Si insertas pedido sin indicar estado, SQL le pone 'pendiente' solo.
-- Si agregás una columna nueva a una tabla que ya tiene filas (los pedidos de v1), 
-- como no puede quedar en null el estado se define automaticamente en 'pendiente'

-- CHECK
-- Garantiza que la columna estado solo reciba alguno de esos strings de characteres, y nada mas.


-- 2) Agregar una tabla de auditoría de cambios de estado.

CREATE TABLE auditoria_nuevo_estado (
    nro_auditoria SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL REFERENCES pedido(pedido_id),
    estado_viejo CHAR(20),
    estado_nuevo CHAR(20) NOT NULL,
    fecha_cambio TIMESTAMP NOT NULL DEFAULT NOW(),
    usuario CHAR(50)
);

-- 3) Agregar una regla que impida totales negativos.

ALTER TABLE pedido ADD CONSTRAINT regla_totales_no_negativos CHECK (total >= 0);

