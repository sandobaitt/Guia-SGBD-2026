--GRUPO 5 DLL 
-- Consulta 1
WITH ventas_ordenadas AS ( 
    SELECT
        v.*,
        ROW_NUMBER() OVER (
            PARTITION BY v.cliente_id
            ORDER BY v.fecha DESC, v.venta_id DESC
        ) AS rowc
    FROM venta v
)
SELECT
    c.cliente_id,
    c.nombre,
    c.segmento,
    v.venta_id,
    v.fecha,
    v.total,
    v.canal
FROM cliente c
LEFT JOIN ventas_ordenadas v
    ON c.cliente_id = v.cliente_id
    AND v.rowc = 1
ORDER BY c.cliente_id;

-- Consulta 2
SELECT c.cliente_id, c.nombre, v.venta_id, EXTRACT(MONTH FROM v.fecha) AS Mes, EXTRACT(YEAR FROM v.fecha) AS Año, v.canal, v.total, SUM(v.total) OVER (
    PARTITION BY v.cliente_id, EXTRACT(MONTH FROM v.fecha), EXTRACT(YEAR FROM v.fecha)
    ORDER BY v.fecha ASC, v.venta_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS acumulado_mensual
FROM cliente c
JOIN venta v ON c.cliente_id = v.cliente_id;

-- Consulta 3
WITH totales AS (
    SELECT c.segmento, c.cliente_id, COALESCE(SUM(v.total), 0.00) AS total_vendido
    FROM cliente c
    LEFT JOIN venta v ON c.cliente_id = v.cliente_id
    GROUP BY c.cliente_id, c.segmento
)
SELECT
    segmento, cliente_id, total_vendido,
    DENSE_RANK() OVER (
        PARTITION BY segmento
        ORDER BY total_vendido DESC
    ) AS posicion
FROM totales;

-- Consulta 4
WITH RECURSIVE JerarquiaComercial AS (
    SELECT cliente_id, nombre, responsable_id, 1 as nivel
    FROM cliente
    WHERE responsable_id IS NULL
    UNION ALL
    SELECT c.cliente_id, c.nombre, c.responsable_id, j.nivel + 1
    FROM cliente c
    INNER JOIN JerarquiaComercial j ON c.responsable_id = j.cliente_id
)
SELECT * FROM JerarquiaComercial ORDER BY nivel, nombre;

-- Consulta 5

    --Comparacion consulta 2: Uso de ventana vs subconsulta para calcular el acumulado mensual de ventas por cliente.
    SELECT c.cliente_id, c.nombre, v.venta_id, EXTRACT(MONTH FROM v.fecha) AS Mes, EXTRACT(YEAR FROM v.fecha) AS Año, v.canal, v.total, SUM(v.total) OVER (
        PARTITION BY v.cliente_id, EXTRACT(MONTH FROM v.fecha), EXTRACT(YEAR FROM v.fecha)
        ORDER BY v.fecha ASC, v.venta_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado_mensual
    FROM cliente c
    JOIN venta v ON c.cliente_id = v.cliente_id;


    SELECT c.cliente_id, c.nombre, v1.venta_id, EXTRACT(MONTH FROM v1.fecha) AS Mes, EXTRACT(YEAR FROM v1.fecha) AS Año, v1.canal, v1.total, 
    (SELECT SUM(v2.total) FROM venta v2 WHERE v2.cliente_id = v1.cliente_id
    AND EXTRACT(MONTH FROM v2.fecha) = EXTRACT(MONTH FROM v1.fecha)
    AND EXTRACT(YEAR FROM v2.fecha) = EXTRACT(YEAR FROM v1.fecha)
    AND (v2.fecha < v1.fecha OR (v2.fecha = v1.fecha AND v2.venta_id <= v1.venta_id))) AS acumulado_mensual
    FROM cliente c JOIN venta v1 ON c.cliente_id = v1.cliente_id
    ORDER BY c.cliente_id, Mes, v1.fecha, v1.venta_id;

    
    
    