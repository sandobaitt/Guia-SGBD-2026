-- ============================================================
-- Sistemas de Gestión de Bases de Datos - UTN FRRe - 2026
-- Unidad 3 - Actividad 1: "El reporte que nadie puede resolver"
-- Setup MySQL 8.x / 9.x
--
-- Dataset funcional:
--   * 20 clientes
--   * 63 ventas significativas
--   * jerarquía de hasta 4 niveles
--   * clientes sin ventas
--   * segmentos NULL
--   * empates de facturación
--   * dos ventas en la misma fecha para un mismo cliente
--
-- Al final se incluye un bloque OPCIONAL, deshabilitado por defecto,
-- que genera 20.000 ventas sintéticas para pruebas de escala.
-- ============================================================

DROP DATABASE IF EXISTS sgbd_u3_act1;
CREATE DATABASE sgbd_u3_act1
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE sgbd_u3_act1;

-- ============================================================
-- 1. ESTRUCTURA
-- ============================================================

CREATE TABLE cliente (
  cliente_id      INT PRIMARY KEY,
  nombre          VARCHAR(80) NOT NULL,
  segmento        VARCHAR(20),
  responsable_id  INT NULL
) ENGINE=InnoDB;

CREATE TABLE venta (
  venta_id    INT PRIMARY KEY,
  cliente_id  INT NOT NULL,
  fecha       DATE NOT NULL,
  total       DECIMAL(12,2) NOT NULL,
  canal       VARCHAR(20),
  CONSTRAINT fk_venta_cliente
    FOREIGN KEY (cliente_id)
    REFERENCES cliente(cliente_id)
) ENGINE=InnoDB;

-- ============================================================
-- 2. CLIENTES
-- ============================================================

INSERT INTO cliente(cliente_id,nombre,segmento,responsable_id) VALUES
(1, 'Casa Central',      'CORPORATIVO', NULL),
(2, 'Norte SA',          'EMPRESA',      1),
(3, 'Sur SRL',           'EMPRESA',      1),
(4, 'Cliente Uno',       'MINORISTA',    2),
(5, 'Cliente Dos',       'MINORISTA',    2),
(6, 'Cliente Tres',      'MINORISTA',    3),
(7, 'Cliente Cuatro',    NULL,           3),
(8, 'Centro SA',         'EMPRESA',      1),
(9, 'Cliente Cinco',     'MINORISTA',    4),
(10,'Cliente Seis',      'MINORISTA',    4),
(11,'Cliente Siete',     'MINORISTA',    5),
(12,'Cliente Ocho',      'MINORISTA',    6),
(13,'Cliente Nueve',     'MINORISTA',    8),
(14,'Cliente Diez',      'MINORISTA',    8),
(15,'Cliente Once',      'MINORISTA',   14),
(16,'Cliente Doce',      'MINORISTA',   14),
(17,'Litoral SA',        'EMPRESA',      1),
(18,'Cliente Trece',     'MINORISTA',   17),
(19,'Cliente Catorce',   NULL,          17),
(20,'Cliente Quince',    'MINORISTA',   17);

ALTER TABLE cliente
  ADD CONSTRAINT fk_cliente_responsable
  FOREIGN KEY (responsable_id)
  REFERENCES cliente(cliente_id);

-- ============================================================
-- 3. VENTAS SIGNIFICATIVAS
-- ============================================================

INSERT INTO venta(venta_id,cliente_id,fecha,total,canal) VALUES
-- Agosto
(101,2, '2026-08-05',  65000.00,'WEB'),
(102,3, '2026-08-08', 180000.00,'SUCURSAL'),
(103,4, '2026-08-12',  12000.00,'APP'),
(104,5, '2026-08-15',  31000.00,'WEB'),
(105,8, '2026-08-21', 155000.00,'SUCURSAL'),

-- Septiembre
(106,2, '2026-09-01', 120000.00,'WEB'),
(107,2, '2026-09-10',  85000.00,'SUCURSAL'),
(108,2, '2026-09-15',  95000.00,'APP'),
(109,3, '2026-09-02', 220000.00,'WEB'),
(110,3, '2026-09-15', 210000.00,'WEB'),
(111,4, '2026-09-05',  15000.00,'APP'),
(112,4, '2026-09-20',  17000.00,'APP'),
(113,4, '2026-09-25',  22000.00,'APP'),
(114,5, '2026-09-07',  45000.00,'WEB'),
(115,5, '2026-09-17',  45000.00,'WEB'),
(116,6, '2026-09-03',  39000.00,'SUCURSAL'),
(117,6, '2026-09-18',  39000.00,'SUCURSAL'),
(118,7, '2026-09-11',   9000.00,'APP'),
(119,8, '2026-09-05', 140000.00,'WEB'),
(120,9, '2026-09-04',  18000.00,'APP'),
(121,9, '2026-09-18',  25000.00,'APP'),
(122,10,'2026-09-11',  27000.00,'WEB'),
(123,11,'2026-09-12',  27000.00,'WEB'),
(124,12,'2026-09-14',  33000.00,'SUCURSAL'),
(125,13,'2026-09-15',  25000.00,'APP'),
(126,14,'2026-09-16',  48000.00,'WEB'),
(127,14,'2026-09-16',  12000.00,'APP'),

-- Octubre
(128,2, '2026-10-03',  99000.00,'WEB'),
(129,2, '2026-10-12', 110000.00,'WEB'),
(130,3, '2026-10-07', 190000.00,'SUCURSAL'),
(131,4, '2026-10-05',  19000.00,'APP'),
(132,4, '2026-10-19',  24000.00,'WEB'),
(133,5, '2026-10-09',  41000.00,'WEB'),
(134,6, '2026-10-01',  41000.00,'WEB'),
(135,6, '2026-10-15',  52000.00,'SUCURSAL'),
(136,8, '2026-10-03', 175000.00,'WEB'),
(137,9, '2026-10-08',  23000.00,'APP'),
(138,10,'2026-10-09',  28000.00,'APP'),
(139,11,'2026-10-11',  28000.00,'WEB'),
(140,12,'2026-10-14',  37000.00,'SUCURSAL'),
(141,13,'2026-10-20',  28000.00,'APP'),
(142,14,'2026-10-22',  51000.00,'WEB'),
(143,15,'2026-10-23',  16000.00,'APP'),
(144,16,'2026-10-24',  17000.00,'APP'),
(145,17,'2026-10-05', 135000.00,'SUCURSAL'),
(146,18,'2026-10-15',  32000.00,'WEB'),

-- Noviembre
(147,2, '2026-11-02', 125000.00,'SUCURSAL'),
(148,3, '2026-11-03', 205000.00,'WEB'),
(149,4, '2026-11-04',  26000.00,'APP'),
(150,5, '2026-11-05',  49000.00,'WEB'),
(151,6, '2026-11-06',  49000.00,'SUCURSAL'),
(152,8, '2026-11-07', 160000.00,'WEB'),
(153,9, '2026-11-08',  29000.00,'APP'),
(154,10,'2026-11-09',  35000.00,'WEB'),
(155,11,'2026-11-10',  35000.00,'APP'),
(156,12,'2026-11-11',  42000.00,'SUCURSAL'),
(157,13,'2026-11-12',  35000.00,'WEB'),
(158,14,'2026-11-13',  56000.00,'WEB'),
(159,15,'2026-11-14',  19000.00,'APP'),
(160,17,'2026-11-15', 145000.00,'SUCURSAL'),
(161,18,'2026-11-16',  38000.00,'WEB'),
(162,19,'2026-11-17',  14000.00,'APP'),

-- Caso intencional: mismo cliente y misma fecha máxima.
(163,18,'2026-11-16',  12000.00,'APP');

-- ============================================================
-- 4. VALIDACIÓN BÁSICA DEL SETUP
--    No resuelve el desafío; solo permite comprobar la carga.
-- ============================================================

SELECT COUNT(*) AS cantidad_clientes FROM cliente;
SELECT COUNT(*) AS cantidad_ventas FROM venta;
SELECT MIN(fecha) AS primera_fecha, MAX(fecha) AS ultima_fecha FROM venta;

-- Resultado esperado antes del bloque opcional:
-- cantidad_clientes = 20
-- cantidad_ventas   = 63

-- ============================================================
-- 5. BLOQUE OPCIONAL: 20.000 VENTAS SINTÉTICAS
--
-- OBJETIVO:
--   Ejecutar el desafío primero con el dataset funcional.
--   Luego habilitar este bloque para comparar planes y mediciones.
--
-- CARACTERÍSTICAS:
--   * No genera ventas para cliente_id = 20.
--   * Usa datos determinísticos: al recrear la BD genera lo mismo.
--   * venta_id comienza en 100001 para no colisionar con las ventas base.
--
-- Para habilitarlo, quitar los marcadores de comentario /* y */.
-- ============================================================

/*

CREATE TEMPORARY TABLE digito (
  n INT PRIMARY KEY
);

INSERT INTO digito(n) VALUES
(0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

INSERT INTO venta(venta_id, cliente_id, fecha, total, canal)
SELECT
  100000 + s.n AS venta_id,
  2 + MOD(s.n - 1, 18) AS cliente_id,
  DATE_ADD('2024-01-01', INTERVAL MOD(s.n * 13, 1000) DAY) AS fecha,
  CAST(5000 + MOD(s.n * 7919, 245000) AS DECIMAL(12,2)) AS total,
  CASE MOD(s.n, 3)
    WHEN 0 THEN 'WEB'
    WHEN 1 THEN 'APP'
    ELSE 'SUCURSAL'
  END AS canal
FROM (
  SELECT
    a.n
    + b.n * 10
    + c.n * 100
    + d.n * 1000
    + e.n * 10000
    + 1 AS n
  FROM digito a
  CROSS JOIN digito b
  CROSS JOIN digito c
  CROSS JOIN digito d
  CROSS JOIN digito e
) AS s
WHERE s.n <= 20000;

DROP TEMPORARY TABLE digito;

SELECT COUNT(*) AS cantidad_ventas_con_volumen
FROM venta;

-- Resultado esperado:
-- 20.063 ventas

*/

-- ============================================================
-- 6. PISTAS DE EVIDENCIA
-- ============================================================

-- Plan estimado:
-- EXPLAIN <consulta>;

-- Ejecución real y tiempos (MySQL 8.0.18+ / 9.x):
-- EXPLAIN ANALYZE <consulta>;

-- Desafío:
--   * última venta por cliente
--   * acumulado mensual conservando detalle
--   * ranking por segmento
--   * jerarquía con WITH RECURSIVE
--   * comparación entre dos alternativas SQL
-- ============================================================
