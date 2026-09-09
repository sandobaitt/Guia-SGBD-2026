# Bitácora de Experimentación - Actividad 2

## 1. Verificación Inicial
- **Motor y Versión:** MySQL (Versión: `9.7.2-cluster`)
- **Cantidad de filas:** 300,000 en la tabla `pedido`.
- **Índices existentes:** Solamente la clave primaria `PRIMARY` (sobre la columna `pedido_id`).

## 2. Línea de Base (Planes Iniciales)
- **Consulta A:** Realiza un `Table scan on pedido` leyendo hasta 300,000 filas y luego un `Sort: pedido.fecha DESC` (filesort). 
  - *Costo Estimado:* 30222.
  - *Tiempo Real:* ~108 ms.
- **Consulta B:** Realiza un `Table scan on pedido` leyendo 300,000 filas y luego un `Sort: pedido.fecha` (filesort). 
  - *Costo Estimado:* 30222.
  - *Tiempo Real:* ~101 ms.
- **Consulta C:** Realiza un `Table scan on pedido`. (Costo: 3635, Tiempo: ~159 ms).
- **Prueba de escritura (Inserciones):** El tiempo base de inserción para 10,000 filas fue de **67.59 ms**.

## 3. Hipótesis
Creemos que la **Consulta A** es lenta porque al no existir un índice por `cliente_id`, el motor debe recorrer toda la tabla (Table Scan) y luego ordenar en memoria (filesort) los pedidos de ese cliente por `fecha`.
Creemos que la **Consulta B** sufre del mismo problema: recorre toda la tabla filtrando por `sucursal_id` y `estado`, para luego ordenar por `fecha` en memoria.

**Cambio esperado:** Si creamos un índice compuesto para la Consulta A que incluya `(cliente_id, fecha)` y uno para la Consulta B que incluya `(sucursal_id, estado, fecha)`, el optimizador utilizará estos índices. Esto permitirá:
1. Ir directamente a las filas que cumplen la condición (evitando el Table Scan).
2. Ya obtener los datos ordenados por `fecha`, eliminando el costoso paso de `filesort`.

Como contraparte, esperamos que la prueba de escritura (el `INSERT` masivo de 10.000 filas) sea un poco **más lenta**, dado que el motor ahora deberá actualizar también estos dos nuevos índices en cada inserción.

## 4. Intervención (DDL)
Se propone la creación de los siguientes dos índices:

```sql
-- Índice para la Consulta A
CREATE INDEX idx_a2_g00_cliente_fecha ON pedido (cliente_id, fecha);

-- Índice para la Consulta B
CREATE INDEX idx_a2_g00_sucursal_estado_fecha ON pedido (sucursal_id, estado, fecha);
```

## 5. Segunda Medición y Prueba de Costo
- **Consulta A:** Pasó a usar `Index lookup (reverse)` utilizando `idx_a2_g00_cliente_fecha`. ¡El `filesort` y el `Table scan` desaparecieron!
  - *Costo Estimado bajó a:* 5.25 (vs 30222 inicial).
  - *Tiempo Real bajó a:* ~0.09 ms (vs 108 ms inicial).
- **Consulta B:** Pasó a usar `Index lookup` con `idx_a2_g00_sucursal_estado_fecha`. ¡El `filesort` desapareció!
  - *Costo Estimado bajó a:* 0.35 (vs 30222 inicial).
  - *Tiempo Real bajó a:* ~0.01 ms (vs 101 ms inicial).
- **Consulta C:** Se mantuvo prácticamente igual, realizando su Table scan natural.
- **Prueba de escritura:** El tiempo de inserción de 10,000 filas aumentó a **228.05 ms** (vs 67.59 ms inicial).

## 6. Veredicto
**Decisión:** MANTENER.

**Justificación:**
Se justifican ambos índices. La mejora en las consultas de lectura A y B (prioridad "Muy Alta" y "Alta") es bestial: reducimos el costo del plan de ejecución de 30222 a 5 y 0.35 respectivamente, pasando de tiempos de más de 100 milisegundos a fracciones de un milisegundo. Esto se logró evitando escanear 300,000 filas y ordenarlas en memoria, reemplazándolo por un acceso directo (Index Seek) donde los datos ya vienen preordenados por el B-Tree.
Es cierto que empíricamente comprobamos que el tiempo de escritura de 10,000 filas aumentó de 67.59 ms a 228.05 ms (debido al mantenimiento de los dos nuevos B-Trees). Sin embargo, este deterioro (unos 160 ms extra por cada *diez mil* transacciones) es un precio minúsculo a pagar comparado con el inmenso ahorro de CPU que obtenemos en cada lectura prioritaria.

---

### Decisión Descartada
**Estructura considerada:** Crear un índice simple `CREATE INDEX idx_solo_cliente ON pedido (cliente_id)`.
**Por qué se descartó:** Si bien este índice evitaría el Table Scan, el motor aún tendría que aplicar un *filesort* para ordenar por `fecha` antes de aplicar el `LIMIT 20`. Al incluir `fecha` como segunda columna en nuestro índice propuesto, combinamos filtrado y ordenamiento en la misma estructura sin costo extra de lectura.
