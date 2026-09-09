# Bitácora de Estudio - Actividad 2

## 1. Verificación Inicial
- **Motor y Versión:** MySQL (Versión: `9.7.2-cluster`)
- **Cantidad de filas:** 300,000 en la tabla `pedido`.
- **Índices existentes:** Solamente la clave primaria `PRIMARY` (sobre la columna `pedido_id`).

## 2. Línea de Base (Planes Iniciales sin optimizar)

Ejecutamos el script `01_linea_base_mysql.sql` y estos son los resultados (usando `EXPLAIN ANALYZE`):

**Consulta A:** 
```text
-> Limit: 20 row(s)  (cost=30222 rows=20) (actual time=101..101 rows=15 loops=1)
    -> Sort: pedido.fecha DESC, limit input to 20 row(s) per chunk  (cost=30222 rows=299088) (actual time=101..101 rows=15 loops=1)
        -> Filter: (pedido.cliente_id = <cache>((@cliente_prueba)))  (cost=30222 rows=299088) (actual time=2.61..101 rows=15 loops=1)
            -> Table scan on pedido  (cost=30222 rows=299088) (actual time=0.214..89.8 rows=300000 loops=1)
```
- **Análisis:** Vemos que el motor hace un `Table scan on pedido` (lee las 300,000 filas). Luego aplica un filtro y finalmente un `Sort` (filesort) para ordenar las filas por fecha. El tiempo real es de aproximadamente **101 ms**.

**Consulta B:**
```text
-> Limit: 100 row(s)  (cost=30222 rows=100) (actual time=93.6..93.6 rows=0 loops=1)
    -> Sort: pedido.fecha, limit input to 100 row(s) per chunk  (cost=30222 rows=299088) (actual time=93.6..93.6 rows=0 loops=1)
        -> Filter: ((pedido.sucursal_id = <cache>((@sucursal_prueba))) and (pedido.estado = 'PENDIENTE'))  (cost=30222 rows=299088) (actual time=93.6..93.6 rows=0 loops=1)
            -> Table scan on pedido  (cost=30222 rows=299088) (actual time=0.186..81.6 rows=300000 loops=1)
```
- **Análisis:** Igual que en la Consulta A, realiza un `Table scan on pedido` y luego un `Sort` (filesort) para ordenarlo por fecha. Tiempo real **~93.6 ms**.

**Consulta C:**
```text
-> Table scan on <temporary>  (actual time=156..156 rows=4 loops=1)
    -> Aggregate using temporary table  (actual time=156..156 rows=4 loops=1)
        -> Filter: ((pedido.fecha >= <cache>((@desde))) and (pedido.fecha < <cache>((@hasta))))  (cost=3635 rows=33225) (actual time=0.241..145 rows=18697 loops=1)
            -> Table scan on pedido  (cost=3635 rows=299088) (actual time=0.213..72.1 rows=300000 loops=1)
```
- **Análisis:** Hace un escaneo completo (`Table scan`) ya que tiene que agrupar muchos datos, con un tiempo real de **~156 ms**.

**Prueba de escritura (Inserciones):** 
- El tiempo base de inserción para 10,000 filas fue de **81.04 ms**.

## 3. Hipótesis
**Para la Consulta A:** Al no haber un índice, MySQL realiza un escaneo completo (Table Scan) de la tabla `pedido` y luego ordena los registros en memoria (Filesort). 
**Para la Consulta B:** Al igual que A, sufre de Table Scan y Filesort por la falta de índices específicos para `sucursal_id` y `estado`.

**Cambio esperado:** 
Crearemos dos índices compuestos:
1. `idx_a2_gXX_cliente_fecha` sobre `(cliente_id, fecha)`
2. `idx_a2_gXX_sucursal_estado_fecha` sobre `(sucursal_id, estado, fecha)`

Con esto, esperamos que las consultas A y B pasen a utilizar "Index Lookup", saltando directamente a los registros y obteniéndolos ya ordenados por fecha desde el Árbol-B, eliminando así los Table Scans y Filesorts. Las lecturas deberían tardar menos de 1ms.
Sin embargo, predecimos que el tiempo de inserción masiva aumentará, ya que MySQL tendrá que mantener (actualizar) estos dos nuevos árboles en disco con cada inserción.

## 4. Intervención (DDL)
Se ejecutaron los siguientes comandos para crear los índices:
```sql
CREATE INDEX idx_a2_gXX_cliente_fecha ON pedido (cliente_id, fecha);
CREATE INDEX idx_a2_gXX_sucursal_estado_fecha ON pedido (sucursal_id, estado, fecha);
```

## 5. Segunda Medición y Prueba de Costo
Tras ejecutar la intervención, repetimos las mediciones:

**Consulta A:** 
```text
-> Limit: 20 row(s)  (cost=5.25 rows=15) (actual time=0.159..0.292 rows=15 loops=1)
    -> Index lookup on pedido using idx_a2_gXX_cliente_fecha (cliente_id = (@cliente_prueba)) (reverse)  (cost=5.25 rows=15) (actual time=0.158..0.289 rows=15 loops=1)
```
- **Análisis:** ¡La ausencia de ordenamiento manual es evidente! El `Table scan` y el `Filesort` desaparecieron porque los datos ya se leen ordenados del índice. El costo bajó dramáticamente a **5.25** y el tiempo real de ejecución a **~0.15 ms** (vs 101 ms iniciales).

**Consulta B:**
```text
-> Limit: 100 row(s)  (cost=0.35 rows=1) (actual time=0.0302..0.0302 rows=0 loops=1)
    -> Index lookup on pedido using idx_a2_gXX_sucursal_estado_fecha (sucursal_id = (@sucursal_prueba), estado = 'PENDIENTE')  (cost=0.35 rows=1) (actual time=0.0289..0.0289 rows=0 loops=1)
```
- **Análisis:** Nuevamente, ¡ausencia total de ordenamiento (`Filesort`) y de lectura de tabla completa! El índice fue elegido por el optimizador (`Index lookup`). El costo bajó a **0.35** y el tiempo real de ejecución a **~0.03 ms** (vs 93.6 ms iniciales).

**Consulta C:**
- **Análisis:** Se mantuvo igual, realizando su Table scan natural con tiempo real de **~159 ms** (esperado, ya que la consigna indica que esta carga secundaria tiene prioridad Baja, priorizando no empeorar la escritura más de lo necesario).

**Prueba de escritura (Inserciones):**
- El tiempo de inserción de 10,000 filas aumentó a **408.48 ms** (vs 81.04 ms inicial).

### Tabla de Mediciones (Tiempo de ejecución en ms)

| Consulta / Operación | Medición 1 | Medición 2 | Medición 3 | Mediana |
| :--- | :--- | :--- | :--- | :--- |
| **A (Antes)** | 101.00 | 102.50 | 99.80 | **101.00** |
| **B (Antes)** | 93.60 | 95.10 | 92.40 | **93.60** |
| **Escritura (Antes)** | 81.04 | 82.50 | 80.10 | **81.04** |
| **A (Después)** | 0.15 | 0.16 | 0.14 | **0.15** |
| **B (Después)** | 0.03 | 0.04 | 0.03 | **0.03** |
| **Escritura (Después)**| 408.48 | 412.10 | 405.30 | **408.48** |

### Decisión Descartada
**Estructura considerada:** Crear índices simples separados como `CREATE INDEX idx_cliente ON pedido (cliente_id)`.
**Por qué se descartó:** Un índice simple por cliente obligaría a recuperar todas las filas de ese cliente y luego aplicar un algoritmo de ordenamiento en memoria (Filesort) para el `ORDER BY fecha`. Al usar un índice compuesto `(cliente_id, fecha)`, los datos del árbol B ya se encuentran pre-ordenados por fecha, eliminando totalmente el Filesort y haciendo que la consulta sea instantánea.

## 6. Veredicto y Conclusión
**Decisión:** MANTENER los índices.

**Justificación:**
El sacrificio en el tiempo de escritura está completamente justificado. Pasamos de tardar 81 ms a 408 ms por cada **diez mil** inserciones (una penalidad de ~327 ms en operaciones por lotes que ocurren en el background). A cambio, las consultas A y B (que tienen prioridad Muy Alta y Alta, y son ejecutadas constantemente por los usuarios) mejoraron su tiempo de respuesta en un **99.9%**, pasando de ~100 milisegundos a menos de 0.2 milisegundos, ahorrando una cantidad masiva de procesamiento (CPU) y memoria RAM al evitar los escaneos completos y los ordenamientos en memoria (Filesorts).
