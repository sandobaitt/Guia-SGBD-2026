-- ACTIVIDAD 2 · LABORATORIO MYSQL
-- Ejecutar con un usuario que pueda crear bases de datos.
-- ATENCION: elimina solamente la base de laboratorio sgbd_a2_lab.

DROP DATABASE IF EXISTS sgbd_a2_lab;
CREATE DATABASE sgbd_a2_lab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sgbd_a2_lab;

CREATE TABLE lab_numero (
    n INT NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

INSERT INTO lab_numero (n)
WITH digitos AS (
    SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
)
SELECT u.d + 10*d.d + 100*c.d + 1000*m.d + 10000*dm.d + 100000*cm.d
FROM digitos u
CROSS JOIN digitos d
CROSS JOIN digitos c
CROSS JOIN digitos m
CROSS JOIN digitos dm
CROSS JOIN digitos cm;

CREATE TABLE cliente (
    cliente_id INT NOT NULL PRIMARY KEY,
    provincia VARCHAR(40) NOT NULL,
    segmento VARCHAR(20) NOT NULL,
    fecha_alta DATE NOT NULL
) ENGINE=InnoDB;

CREATE TABLE producto (
    producto_id INT NOT NULL PRIMARY KEY,
    categoria_id INT NOT NULL,
    activo BOOLEAN NOT NULL,
    precio DECIMAL(12,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE pedido (
    pedido_id BIGINT NOT NULL PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha DATETIME NOT NULL,
    estado VARCHAR(20) NOT NULL,
    canal VARCHAR(12) NOT NULL,
    sucursal_id INT NOT NULL,
    total DECIMAL(14,2) NOT NULL,
    CHECK (estado IN ('PENDIENTE','PREPARACION','ENVIADO','CANCELADO')),
    CHECK (canal IN ('WEB','APP','SUCURSAL'))
) ENGINE=InnoDB;

CREATE TABLE pedido_item (
    pedido_id BIGINT NOT NULL,
    nro_item SMALLINT NOT NULL,
    producto_id INT NOT NULL,
    cantidad SMALLINT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (pedido_id, nro_item)
) ENGINE=InnoDB;

INSERT INTO cliente (cliente_id, provincia, segmento, fecha_alta)
SELECT n + 1,
       ELT(MOD(n, 6) + 1, 'Chaco', 'Corrientes', 'Formosa', 'Misiones', 'Santa Fe', 'Cordoba'),
       ELT(MOD(n, 3) + 1, 'MINORISTA', 'PYME', 'CORPORATIVO'),
       DATE_ADD('2019-01-01', INTERVAL MOD(n * 17, 1825) DAY)
FROM lab_numero
WHERE n < 20000;

INSERT INTO producto (producto_id, categoria_id, activo, precio)
SELECT n + 1, MOD(n, 40) + 1, MOD(n, 20) <> 0,
       ROUND(50 + MOD(n * 1543, 500000) / 100, 2)
FROM lab_numero
WHERE n < 5000;

SET @cantidad_pedidos := 300000;

INSERT INTO pedido (pedido_id, cliente_id, fecha, estado, canal, sucursal_id, total)
SELECT n + 1,
       MOD(n * 37, 20000) + 1,
       DATE_ADD(DATE_ADD('2022-01-01', INTERVAL MOD(n * 13, 1460) DAY),
                INTERVAL MOD(n * 7919, 86400) SECOND),
       CASE
           WHEN MOD(n, 20) = 0 THEN 'PENDIENTE'
           WHEN MOD(n, 20) IN (1,2,3) THEN 'PREPARACION'
           WHEN MOD(n, 20) = 4 THEN 'CANCELADO'
           ELSE 'ENVIADO'
       END,
       ELT(MOD(n, 3) + 1, 'WEB', 'APP', 'SUCURSAL'),
       MOD(n * 11, 50) + 1,
       ROUND(10 + MOD(n * 7919, 250000) / 100, 2)
FROM lab_numero
WHERE n < @cantidad_pedidos;

-- PEDIDO_ITEM se mantiene sin carga masiva porque no participa en las consultas del laboratorio.
-- Las claves foraneas se omiten deliberadamente para observar el diseño de indices desde una linea base controlada.

ANALYZE TABLE cliente, producto, pedido;

SELECT 'LABORATORIO MYSQL INSTALADO' AS resultado;
SELECT VERSION() AS version_mysql;
SELECT COUNT(*) AS clientes FROM cliente;
SELECT COUNT(*) AS pedidos FROM pedido;
SHOW INDEX FROM pedido;
