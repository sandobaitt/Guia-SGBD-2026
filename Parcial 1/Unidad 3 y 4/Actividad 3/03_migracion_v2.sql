-- Actividad 3 - Migración Estructural de v1 a v2
USE sgbd_u34_act3;

-- 1. Agregar estados de pedido (Usamos ENUM para restringir los valores posibles nativamente)
ALTER TABLE pedido 
ADD COLUMN estado ENUM('pendiente', 'pagado', 'enviado', 'cancelado') NOT NULL DEFAULT 'pendiente';

-- 2. Agregar tabla de auditoría de cambios de estado
CREATE TABLE auditoria_estado_pedido (
  auditoria_id INT AUTO_INCREMENT PRIMARY KEY,
  pedido_id INT NOT NULL,
  estado_anterior VARCHAR(20),
  estado_nuevo VARCHAR(20) NOT NULL,
  fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (pedido_id) REFERENCES pedido(pedido_id)
);

-- 3. Regla que impida totales negativos en los pedidos
ALTER TABLE pedido ADD CONSTRAINT chk_total_positivo CHECK (total >= 0);
