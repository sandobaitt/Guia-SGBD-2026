-- Actividad 3 - MySQL - versión inicial v1 (Esquema)
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
