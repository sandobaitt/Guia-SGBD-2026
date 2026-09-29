USE sgbd_u3_act1;

-- ============================================================================
-- ACTIVIDAD 1 - REPORTE ANALÍTICO (RESOLUCIÓN)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONSULTA 1: Última venta de cada cliente
-- Técnica usada: CTE + Función de ventana (ROW_NUMBER)
-- ----------------------------------------------------------------------------
SELECT '--- CONSULTA 1: Última venta ---' AS Info;

WITH ult_ventas AS (
  SELECT 
    c.cliente_id, 
    c.nombre, 
    c.segmento, 
    c.responsable_id, 
    v.venta_id, 
    v.fecha, 
    v.total, 
    v.canal, 
    ROW_NUMBER() OVER (PARTITION BY c.cliente_id ORDER BY v.fecha DESC) AS cont_venta 
  FROM cliente c 
  JOIN venta v ON c.cliente_id = v.cliente_id
) 
SELECT cliente_id, nombre, segmento, responsable_id, venta_id, fecha, total, canal 
FROM ult_ventas  
WHERE cont_venta = 1;

-- Plan de ejecución y medición básica
EXPLAIN ANALYZE 
WITH ult_ventas AS (
  SELECT c.cliente_id, ROW_NUMBER() OVER (PARTITION BY c.cliente_id ORDER BY v.fecha DESC) AS cont_venta 
  FROM cliente c JOIN venta v ON c.cliente_id = v.cliente_id
) SELECT * FROM ult_ventas WHERE cont_venta = 1;

-- ----------------------------------------------------------------------------
-- CONSULTA 2: Acumulado mensual por cliente
-- Técnica usada: Función de ventana (SUM OVER ... ROWS BETWEEN)
-- ----------------------------------------------------------------------------
SELECT '--- CONSULTA 2: Acumulado mensual ---' AS Info;

SELECT
  v.venta_id, 
  v.cliente_id, 
  c.nombre AS cliente_nombre,
  c.segmento,
  v.fecha,
  v.canal,
  v.total,
  SUM(v.total) OVER ( 
    PARTITION BY v.cliente_id, EXTRACT(YEAR FROM v.fecha), EXTRACT(MONTH FROM v.fecha) 
    ORDER BY v.fecha, v.venta_id 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW 
  ) AS acumulado_mes 
FROM venta v 
INNER JOIN cliente c ON v.cliente_id = c.cliente_id 
ORDER BY v.cliente_id, v.fecha, v.venta_id; 

-- Plan de ejecución
EXPLAIN ANALYZE
SELECT v.venta_id, SUM(v.total) OVER (PARTITION BY v.cliente_id ORDER BY v.fecha ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM venta v;

-- ----------------------------------------------------------------------------
-- CONSULTA 3: Ranking de clientes por segmento
-- Técnica usada: CTE + Función de ventana (DENSE_RANK)
-- ----------------------------------------------------------------------------
SELECT '--- CONSULTA 3: Ranking por segmento ---' AS Info;

WITH totales AS (
  SELECT 
    c.cliente_id, 
    c.nombre,
    c.segmento,
    COALESCE(SUM(v.total), 0) AS total_vendido 
  FROM cliente c 
  LEFT JOIN venta v ON c.cliente_id = v.cliente_id 
  GROUP BY c.cliente_id, c.nombre, c.segmento 
)
SELECT 
  cliente_id,
  nombre, 
  segmento,
  total_vendido,
  DENSE_RANK() OVER (PARTITION BY segmento ORDER BY total_vendido DESC) AS posicion 
FROM totales 
ORDER BY segmento, posicion, total_vendido DESC; 

-- Plan de ejecución
EXPLAIN ANALYZE
WITH totales AS (SELECT c.cliente_id, c.segmento, SUM(v.total) AS total_vendido FROM cliente c LEFT JOIN venta v ON c.cliente_id = v.cliente_id GROUP BY 1, 2)
SELECT cliente_id, DENSE_RANK() OVER (PARTITION BY segmento ORDER BY total_vendido DESC) FROM totales;

-- ----------------------------------------------------------------------------
-- CONSULTA 4: Recorrido Jerárquico de clientes/responsables
-- Técnica usada: CTE Recursiva (WITH RECURSIVE)
-- ----------------------------------------------------------------------------
SELECT '--- CONSULTA 4: Recorrido Jerárquico ---' AS Info;

WITH RECURSIVE jerarquia AS (
    -- Miembro ancla (Anchor)
    SELECT 
        cliente_id, 
        nombre, 
        responsable_id,
        0 AS nivel
    FROM cliente
    WHERE responsable_id IS NULL

    UNION ALL

    -- Miembro recursivo
    SELECT 
        c.cliente_id, 
        c.nombre, 
        c.responsable_id,
        j.nivel + 1
    FROM cliente c
    JOIN jerarquia j ON c.responsable_id = j.cliente_id
)
SELECT 
    cliente_id,
    nombre,
    responsable_id,
    nivel
FROM jerarquia
ORDER BY nivel, cliente_id;

-- Plan de ejecución
EXPLAIN ANALYZE
WITH RECURSIVE jerarquia AS (
    SELECT cliente_id, responsable_id, 0 AS nivel FROM cliente WHERE responsable_id IS NULL
    UNION ALL
    SELECT c.cliente_id, c.responsable_id, j.nivel + 1 FROM cliente c JOIN jerarquia j ON c.responsable_id = j.cliente_id
)
SELECT * FROM jerarquia;
