-- Actividad 2 - MySQL base
DROP DATABASE IF EXISTS sgbd_u4_act2;
CREATE DATABASE sgbd_u4_act2;
USE sgbd_u4_act2;

CREATE TABLE cliente (
  cliente_id INT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL
);

CREATE TABLE cuenta (
  cuenta_id INT PRIMARY KEY,
  cliente_id INT NOT NULL,
  saldo DECIMAL(12,2) NOT NULL DEFAULT 0,
  FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id)
);

CREATE TABLE producto (
  producto_id INT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL,
  precio DECIMAL(12,2) NOT NULL
);

CREATE TABLE auditoria_precio (
  auditoria_id INT AUTO_INCREMENT PRIMARY KEY,
  producto_id INT NOT NULL,
  precio_anterior DECIMAL(12,2),
  precio_nuevo DECIMAL(12,2),
  fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO cliente VALUES (1,'Norte SA'),(2,'Sur SRL'),(3,'Cliente Uno');
INSERT INTO cuenta VALUES (1,1,100000),(2,2,50000),(3,3,10000);
INSERT INTO producto VALUES (1,'Servicio Base',1000),(2,'Servicio Premium',5000);

-- Desafío:
-- 1. Agregar restricción para impedir precio <= 0.
-- 2. Implementar mecanismo para impedir saldo negativo.
-- 3. Auditar cambios de precio.
-- 4. Crear función o procedimiento de clasificación de cliente.
-- 5. Agregar pruebas válidas, inválidas y límite.
