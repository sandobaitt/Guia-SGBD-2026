# Bitácora de Experimentación - Actividad 1

### 1. Problema a resolver
El área comercial requiere un reporte analítico complejo sobre clientes, ventas y jerarquías organizacionales. El desafío principal es resolver todo esto nativamente dentro de MySQL, sin exportar los datos a planillas de cálculo, y obteniendo un rendimiento óptimo.

### 2. Decisiones técnicas
Para resolver los requerimientos evitando múltiples lecturas a las mismas tablas (que afectarían el rendimiento), se tomaron las siguientes decisiones:
- **Consulta 1 (Última venta):** Se eligió una Función de Ventana (`ROW_NUMBER`) combinada con una CTE en lugar de un `GROUP BY` clásico. Esto permite enumerar las ventas por fecha descendente y filtrar fácilmente la más reciente sin necesidad de hacer múltiples subconsultas o auto-joins complejos.
- **Consulta 2 (Acumulado mensual):** Se usó `SUM() OVER(PARTITION BY ... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` para calcular un "running total". Se prefirió esto antes que los joins triangulares (self-joins) porque procesa el set de datos en una sola pasada.
- **Consulta 3 (Ranking):** Se eligió `DENSE_RANK()` sobre `RANK()` para evitar saltos en la numeración si dos clientes empatan en ventas.
- **Consulta 4 (Jerarquías):** Se implementó una CTE Recursiva (`WITH RECURSIVE`). Se eligió este objeto porque la profundidad de la jerarquía comercial (cuántos empleados tiene un jefe hacia abajo) es dinámica, y no se puede resolver hardcodeando la cantidad de `LEFT JOINs`.

### 3. Comandos y evidencias
A continuación se documentan las consultas finales y un extracto de su evidencia de ejecución en el motor (se adjuntan capturas PDF con los resultados tabulares).

**Consulta 1: Última venta (CTE + Función de ventana)**
```sql
WITH ult_ventas AS (
  SELECT c.cliente_id, c.nombre, c.segmento, v.venta_id, v.fecha, v.total, 
  ROW_NUMBER() OVER (PARTITION BY c.cliente_id ORDER BY v.fecha DESC) AS cont_venta 
  FROM cliente c JOIN venta v ON c.cliente_id = v.cliente_id
) 
SELECT * FROM ult_ventas WHERE cont_venta = 1;
```
*Evidencia EXPLAIN ANALYZE:* El motor resuelve esto sin agrupar toda la tabla de ventas repetidas veces, solo ordenando y filtrando.
```text
-> Filter: (ult_ventas.cont_venta = 1)  (actual time=0.075..0.089 rows=15 loops=1)
    -> Window aggregate: row_number() OVER (PARTITION BY c.cliente_id ORDER BY v.fecha desc)  (actual time=0.073..0.086 rows=63 loops=1)
```

**Consulta 2: Acumulado mensual (SUM OVER)**
```sql
SELECT v.venta_id, v.cliente_id, c.nombre, v.fecha, v.total,
  SUM(v.total) OVER ( 
    PARTITION BY v.cliente_id, EXTRACT(YEAR FROM v.fecha), EXTRACT(MONTH FROM v.fecha) 
    ORDER BY v.fecha, v.venta_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW 
  ) AS acumulado_mes 
FROM venta v INNER JOIN cliente c ON v.cliente_id = c.cliente_id;
```
*Evidencia EXPLAIN ANALYZE:* Demuestra que no hay Subconsultas Correlacionadas costosas.
```text
-> Window aggregate: sum(v.total) OVER (PARTITION BY v.cliente_id ORDER BY v.fecha ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) (actual time=0.058..0.080 rows=63 loops=1)
```

**Consulta 3: Ranking de clientes (DENSE_RANK)**
```sql
WITH totales AS (
  SELECT c.cliente_id, c.segmento, COALESCE(SUM(v.total), 0) AS total_vendido 
  FROM cliente c LEFT JOIN venta v ON c.cliente_id = v.cliente_id GROUP BY c.cliente_id, c.segmento 
)
SELECT cliente_id, segmento, total_vendido, DENSE_RANK() OVER (PARTITION BY segmento ORDER BY total_vendido DESC) AS posicion 
FROM totales ORDER BY segmento, posicion, total_vendido DESC; 
```
*Evidencia EXPLAIN ANALYZE:*
```text
-> Window aggregate: dense_rank() OVER (PARTITION BY totales.segmento ORDER BY totales.total_vendido desc ) (actual time=0.185..0.197 rows=20 loops=1)
```

**Consulta 4: Jerarquías (WITH RECURSIVE)**
```sql
WITH RECURSIVE jerarquia AS (
    SELECT cliente_id, nombre, responsable_id, 0 AS nivel FROM cliente WHERE responsable_id IS NULL
    UNION ALL
    SELECT c.cliente_id, c.nombre, c.responsable_id, j.nivel + 1 FROM cliente c JOIN jerarquia j ON c.responsable_id = j.cliente_id
)
SELECT * FROM jerarquia ORDER BY nivel, cliente_id;
```
*Evidencia EXPLAIN ANALYZE:* El motor itera la subconsulta (`Repeat until convergence`) para recorrer el árbol.
```text
-> Materialize recursive CTE jerarquia (actual time=0.059..0.059 rows=20 loops=1)
    -> Repeat until convergence
        -> Nested loop inner join (actual time=0.002..0.017 rows=9.5 loops=2)
```

### 4. Pruebas realizadas
- **Caso válido:** Se corrieron las 4 consultas con el set de datos inicial (20 clientes, 63 ventas). Todas arrojaron el resultado esperado y los cálculos acumulados coincidieron perfectamente.
- **Caso inválido:** Se intentó filtrar el `ROW_NUMBER()` directamente en el `WHERE` de la misma consulta (ej. `WHERE ROW_NUMBER() = 1`). El motor arrojó error de sintaxis porque las funciones de ventana ocurren después del `WHERE`. Se validó que obligatoriamente se debe envolver en una CTE primero.
- **Caso límite:** ¿Qué pasa si un cliente no tiene ninguna venta? En la Consulta 3 de ranking, gracias al uso de `LEFT JOIN` y la función `COALESCE(SUM(v.total), 0)`, el cliente sigue apareciendo en el listado con total 0, garantizando que nadie desaparezca del reporte comercial.

### 5. Errores y diagnóstico
**Falla:** Inicialmente en la Consulta 2 de acumulado, los totales se mezclaban entre distintos clientes y meses porque la partición de la ventana estaba incompleta.
**Detección:** Al revisar la salida, el acumulado del Cliente 2 empezaba sumando el último valor del Cliente 1.
**Corrección:** Se corrigió añadiendo rigurosamente `PARTITION BY v.cliente_id, EXTRACT(YEAR FROM v.fecha), EXTRACT(MONTH FROM v.fecha)` para que el acumulador se reinicie a cero con cada cliente nuevo y cada mes nuevo.

### 6. Uso de IA
Se utilizó la IA (Antigravity) como copiloto de programación (pair-programming). 
- **Para qué se usó:** Para estructurar la sintaxis final de las consultas (especialmente la CTE recursiva), formatear el código SQL, añadir los comandos de `EXPLAIN ANALYZE` y redactar la explicación teórica de las decisiones.
- **Qué se validó:** Se validó que el código SQL generado por la IA corriera de forma nativa en MySQL ejecutándolo por consola contra la base de datos `sgbd_u3_act1`.
- **Qué se descartó:** Se descartó generar un plan de implementación a gran escala y en su lugar se prefirió un enfoque paso a paso validando cada script localmente.

### 7. Aprendizajes
Queda consolidado el poder de las **Funciones de Ventana** (`OVER`, `PARTITION BY`). Aprendimos que operaciones que tradicionalmente tomaban cientos de líneas de código y bloqueos en bases de datos relacionales, ahora pueden resolverse con consultas declarativas muy elegantes y de alto rendimiento. Además, interiorizamos el uso de `EXPLAIN ANALYZE` para ver tiempos reales y no solo estimaciones. Todo este conocimiento sobre el rendimiento del motor es clave para la próxima actividad donde introduciremos lógica transaccional.
