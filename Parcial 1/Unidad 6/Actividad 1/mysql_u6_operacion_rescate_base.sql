-- Unidad 6 - Operacion Rescate - MySQL/MariaDB
-- Uso academico. Ejecutar con un usuario administrador en entorno de laboratorio.

DROP DATABASE IF EXISTS u6_rescate;
CREATE DATABASE u6_rescate CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE u6_rescate;

CREATE TABLE cliente (
  cliente_id INT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL,
  segmento VARCHAR(30) NOT NULL
);

CREATE TABLE cuenta (
  cuenta_id INT PRIMARY KEY,
  cliente_id INT NOT NULL,
  nro_cuenta VARCHAR(30) NOT NULL UNIQUE,
  saldo DECIMAL(14,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_cuenta_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id),
  CONSTRAINT chk_cuenta_saldo CHECK (saldo >= 0)
);

CREATE TABLE movimiento (
  movimiento_id INT PRIMARY KEY,
  cuenta_id INT NOT NULL,
  fecha DATETIME NOT NULL,
  tipo VARCHAR(20) NOT NULL,
  importe DECIMAL(14,2) NOT NULL,
  descripcion VARCHAR(120) NOT NULL,
  CONSTRAINT fk_mov_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id)
);

CREATE TABLE auditoria_evento (
  auditoria_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario VARCHAR(80) NOT NULL,
  evento VARCHAR(80) NOT NULL,
  detalle VARCHAR(255) NOT NULL
);

INSERT INTO cliente VALUES
(1,'Norte SA','EMPRESA'),
(2,'Sur SRL','EMPRESA'),
(3,'Cliente Uno','MINORISTA'),
(4,'Cliente Dos','MINORISTA');

INSERT INTO cuenta VALUES
(101,1,'001-000101',250000.00),
(102,2,'001-000102',180000.00),
(103,3,'001-000103',35000.00),
(104,4,'001-000104',42000.00);

INSERT INTO movimiento VALUES
(1001,101,'2026-09-22 09:00:00','CREDITO',50000.00,'Aporte inicial'),
(1002,101,'2026-09-22 09:10:00','DEBITO',-12000.00,'Pago proveedor'),
(1003,102,'2026-09-22 09:20:00','CREDITO',30000.00,'Cobranza'),
(1004,103,'2026-09-22 09:30:00','DEBITO',-5000.00,'Compra'),
(1005,104,'2026-09-22 09:40:00','CREDITO',10000.00,'Deposito');

INSERT INTO auditoria_evento(usuario, evento, detalle)
VALUES (CURRENT_USER(), 'SETUP', 'Base inicial creada para Unidad 6');

-- Usuarios y roles de laboratorio.
-- Cambiar contrasenas si el entorno lo requiere.
DROP USER IF EXISTS 'u6_app'@'%';
DROP USER IF EXISTS 'u6_analista'@'%';
DROP USER IF EXISTS 'u6_auditor'@'%';
CREATE USER 'u6_app'@'%' IDENTIFIED BY 'Cambiar_2026!';
CREATE USER 'u6_analista'@'%' IDENTIFIED BY 'Cambiar_2026!';
CREATE USER 'u6_auditor'@'%' IDENTIFIED BY 'Cambiar_2026!';

CREATE ROLE IF NOT EXISTS rol_app;
CREATE ROLE IF NOT EXISTS rol_analista;
CREATE ROLE IF NOT EXISTS rol_auditor;

-- Situacion inicial deliberadamente vulnerable para que el grupo la detecte.
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP ON u6_rescate.* TO rol_app;
GRANT SELECT, UPDATE ON u6_rescate.* TO rol_analista;
GRANT SELECT ON u6_rescate.* TO rol_auditor;

GRANT rol_app TO 'u6_app'@'%';
GRANT rol_analista TO 'u6_analista'@'%';
GRANT rol_auditor TO 'u6_auditor'@'%';

-- Verificacion inicial sugerida
SELECT COUNT(*) AS clientes FROM cliente;
SELECT COUNT(*) AS cuentas FROM cuenta;
SELECT COUNT(*) AS movimientos FROM movimiento;
SELECT COALESCE(SUM(importe),0) AS importe_movimientos FROM movimiento;

-- OPERACIONES VALIDAS POSTERIORES AL BACKUP (ejecutar despues del backup)
-- INSERT INTO movimiento VALUES (1006,101,'2026-09-22 10:05:00','CREDITO',15000.00,'Operacion valida posterior al backup');
-- INSERT INTO movimiento VALUES (1007,102,'2026-09-22 10:12:00','DEBITO',-7000.00,'Operacion valida posterior al backup');
-- INSERT INTO auditoria_evento(usuario, evento, detalle) VALUES (CURRENT_USER(), 'OPERACIONES_VALIDAS', 'Se ejecutaron movimientos 1006 y 1007');

-- INCIDENTE A SIMULAR (ejecutar solo cuando lo indique la consigna)
-- DELETE FROM movimiento WHERE cuenta_id = 101;
-- INSERT INTO auditoria_evento(usuario, evento, detalle) VALUES (CURRENT_USER(), 'INCIDENTE', 'Borrado accidental de movimientos de cuenta 101');
