-- Actividad 3 - MySQL - versión inicial v1
DROP DATABASE IF EXISTS sgbd_u34_act3;
CREATE DATABASE sgbd_u34_act3;
USE sgbd_u34_act3;

CREATE TABLE cliente (
  cliente_id INT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL,
  email VARCHAR(120)
);

CREATE TABLE pedido (
  pedido_id INT PRIMARY KEY,
  cliente_id INT NOT NULL,
  fecha DATE NOT NULL,
  total DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id)
);

CREATE TABLE detalle_pedido (
  detalle_id INT PRIMARY KEY,
  pedido_id INT NOT NULL,
  producto VARCHAR(80) NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (pedido_id) REFERENCES pedido(pedido_id)
);

INSERT INTO cliente VALUES
(1,'Norte SA','norte@example.com'),
(2,'Sur SRL','sur@example.com'),
(3,'Cliente Uno',NULL);

INSERT INTO pedido VALUES
(1001,1,'2026-09-01',15000),
(1002,1,'2026-09-12',22000),
(1003,2,'2026-09-15',9000);

INSERT INTO detalle_pedido VALUES
(1,1001,'Servicio Base',1,15000),
(2,1002,'Servicio Premium',1,22000),
(3,1003,'Servicio Base',1,9000);

-- Crear 03_migracion_v2.sql, 04_programabilidad_v2.sql, 05_pruebas_v2.sql y 06_rollback_v2.sql.
