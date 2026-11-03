# Bitácora Técnica: U8 - Actividad 1 (Del requerimiento al documento)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)  
**Grupo:** G11 — Aguirre Egea, Emiliano · Ghione, Lucas Emanuel · Pagno, Agustin Mario · Sandoval, Lautaro Emanuel  
**Escenario:** Logística | Distribución interprovincial  
**Motor SGBD:** MongoDB Community 8.0.34 (`mongosh` 2.14) · base `u8_g11`  
**Scripts:** `solucion_u8_actividad1.js` (carga, CRUD, consultas, pipelines e índices) · `prueba_volumen_u8_actividad1.js` (200.000 envíos para el análisis de índices)

> **Procedencia de la evidencia.** Las capturas de la entrega original (`Bitacora 1.pdf`, `evidencias.pdf`) corresponden a la máquina virtual del grupo y siguen siendo válidas para lo que muestran. Los bloques marcados **[REFUERZO]** se obtuvieron ejecutando, el 03/11/2026, los scripts de esta carpeta en un laboratorio local aislado (Pop!_OS 24.04, MongoDB 8.0.34, `mongosh` 2.14.1, instancia propia en el puerto 27019, sin tocar bases compartidas). Se cargan exactamente los mismos 35 documentos de la entrega. Ninguna salida fue escrita a mano.

---

## Devolución del profesor y cómo se atiende

> *"Se desarrolla el escenario logístico con un modelo documental y consultas. El análisis de índices resulta pertinente, pero sería conveniente **reforzar las evidencias** y **verificar el cumplimiento de los requisitos de carga**."*

| Observación | Qué se detectó en la entrega | Qué se hizo |
| :--- | :--- | :--- |
| **Verificar los requisitos de carga** | La bitácora decía "15 y 20 documentos" pero no mostraba ninguna salida de recuentos ni de variedad. | Sección 2.2: verificación ejecutable de **9 requisitos** (30+ documentos, 2 colecciones, variedad de estados, fechas y valores, integridad referencial, coherencia de `minutos_demora`). |
| **Reforzar las evidencias** | Un único `explain` por estado, sin repeticiones. La tabla decía 7 ms (sin índice) y 27 ms (con índice) y la conclusión afirmaba "0 ms en ambos". | Sección 4: 5 repeticiones por medición, **primera ejecución separada**, tres índices (uno por consulta) y una **prueba a 200.000 documentos** donde la diferencia sí se ve. |
| *(evidencia)* | El CRUD de las capturas se ejecutó sobre la base `test` (prompt `test>`), no sobre `u8_g11`. | Sección 3.1: CRUD sobre `u8_g11`, con recuentos antes y después. |
| *(consigna)* | Faltaba la consulta "por estado y fecha". Los 4 ítems del escenario no distinguían `$elemMatch` de la notación con punto. | Q2 y Q3b en la sección 3.2. |

Otros errores corregidos de la entrega (no mencionados por el profesor): el encabezado decía **"Motor Asignado: MySQL"** (es MongoDB); en `actividad1.txt` el pipeline tenía los operadores perdidos (`{ minutos_demora" }`, se perdieron los `$sum`/`$avg`/`$divide` al copiar), **no había ningún `createIndex`** y había líneas de texto que impedían ejecutarlo. Detalle en la sección 6.

---

## 1. Diseñar

### 1.1 Patrones de acceso (el modelo se deriva de esto, no de un esquema relacional)

| # | Patrón de acceso | Prioridad | Cómo lo resuelve el modelo |
| :--- | :--- | :--- | :--- |
| P1 | Buscar envíos por **ruta y rango de fechas** | Prioritaria | `find` sobre `envios` + índice `{ruta, fecha_despacho}` |
| P2 | **Demoras por transportista** | Prioritaria | Pipeline sobre `envios`; `transportista` y `minutos_demora` están en el mismo documento: **sin `$lookup`** |
| P3 | Envíos por **estado y fecha** | Complementaria | `estado_actual` duplicado en el envío + índice `{estado_actual, fecha_despacho}` |
| P4 | Recuperar un envío **completo por identificador** (con su historial) | Complementaria | `_id` + `$lookup` a `eventos_seguimiento` por `envio_id` |
| P5 | Filtrar por un atributo dentro de un **subdocumento o arreglo** | Complementaria | `destino.provincia` y `paquetes.fragil` con `$elemMatch` |
| P6 | **Resumen agrupado** | Complementaria | Aggregation Pipeline |
| P7 | **Registrar un evento** de seguimiento | Escritura frecuente | `insertOne` en `eventos_seguimiento` + `updateOne` del estado en `envios` |

### 1.2 Colecciones y documentos de ejemplo

Se diseñaron **dos colecciones**, porque el dominio tiene dos ciclos de vida distintos (no se forzó una tercera para los paquetes).

**`envios`** (agregado central: transportista, origen, destino y paquetes **embebidos**):

```javascript
{
  _id: "ENV-2026-001",
  tracking_code: "TRK-RN11-001",
  ruta: "Resistencia - Rosario",
  transportista: { id: "TRANS-01", nombre: "Expreso Chaco", cuit: "30-71122334-9" },
  origen:  { provincia: "Chaco", localidad: "Resistencia", centro_distribucion: "Hub Norte" },
  destino: { provincia: "Santa Fe", localidad: "Rosario", direccion: "Bv. Oroño 4520" },
  fecha_despacho:         ISODate("2026-10-01T08:00:00Z"),
  fecha_estimada_entrega: ISODate("2026-10-02T16:00:00Z"),
  fecha_entrega_real:     ISODate("2026-10-02T15:30:00Z"),
  estado_actual: "Entregado",          // duplicado a propósito (ver 1.3, decisión 3)
  minutos_demora: 0,
  paquetes: [
    { tracking_paquete: "PAQ-101", peso_kg: 12.5, fragil: false, tipo: "Repuestos mecánicos" },
    { tracking_paquete: "PAQ-102", peso_kg: 3.2,  fragil: true,  tipo: "Componentes electrónicos" }
  ]
}
```

**`eventos_seguimiento`** (un documento por hito, **referenciado** por `envio_id`):

```javascript
{
  _id: "EVT-002",
  envio_id: "ENV-2026-001",            // referencia al _id de envios
  tipo_evento: "CONTROL_TRANSITO",
  descripcion: "Control de pesaje en balanza vial",
  ubicacion: { localidad: "Vera", provincia: "Santa Fe", km_ruta: 430 },
  timestamp: ISODate("2026-10-01T15:30:00Z"),
  operador: "op_gendarmeria_04"
}
```

### 1.3 Decisiones de diseño y límites de crecimiento

| # | Decisión | Por qué | Límite de crecimiento |
| :--- | :--- | :--- | :--- |
| 1 | **Paquetes embebidos** en el envío | Se leen siempre junto con el envío, nacen y mueren con él y su cantidad es pequeña y acotada: una sola lectura devuelve todo el remito. | Cardinalidad 1 a pocos (1 a 4 en los datos). Aun con cientos de paquetes (cada uno pesa unos 100 bytes, estimado) se está lejos del límite de 16 MB por documento. |
| 2 | **Eventos en otra colección** (referencia) | Los hitos del viaje (controles, paradas, incidencias, telemetría) son **potencialmente ilimitados**. Embebidos formarían un *unbounded array*. | Sin cota: un documento por evento no crece nunca; el envío conserva su tamaño (~0,65 KB medido en la prueba de volumen). |
| 3 | **`estado_actual` duplicado** en el envío | La consulta más frecuente del monitoreo pregunta el estado vigente; sin la copia habría que recorrer los eventos de cada envío. | Un campo escalar: no crece. El costo es de **escritura y consistencia** (ver sección 5). |
| 4 | **Transportista embebido** (`id`, `nombre`, `cuit`) | Permite resolver P2 (demoras por transportista) sin `$lookup`. Es el patrón de *referencia extendida*: se copia solo lo que la consulta necesita. | Se duplica en cada envío (unos 90 bytes, estimado); si el nombre de un transportista cambia hay que usar `updateMany`. |

### 1.4 Alternativas de modelado (embedding frente a referencias)

| Criterio | Eventos **embebidos** en `envios` | Eventos **referenciados** *(elegido)* | **Híbrido**: últimos N embebidos + todos referenciados |
| :--- | :--- | :--- | :--- |
| Lectura del envío con su historial | 1 lectura | 2 consultas o `$lookup` (con índice en `envio_id`) | Pantalla de monitoreo en 1 lectura; historial completo con `$lookup` |
| Escritura de un evento | `$push` en el envío | `insertOne` + `updateOne` del estado | Las tres operaciones |
| Cardinalidad | Solo sirve si está acotada | 1 a N sin límite | Acotada en el envío (N fijo), ilimitada afuera |
| Crecimiento del documento principal | **Sin cota** (antipatrón) | Constante | Constante |
| Memoria (working set) | Cada lectura del envío trae todo el historial al caché | Solo se leen los eventos cuando se piden | Solo los últimos N |
| Consistencia | Una sola escritura | Dos escrituras, sin transacción en *standalone* | Tres escrituras |

La alternativa **híbrida** no se implementó: queda como evolución si el monitoreo necesita mostrar los últimos hitos sin `$lookup` (se resolvería con `$push` + `$slice: -5` sobre un arreglo `ultimos_eventos`).

---

## 2. Cargar

### 2.1 Carga

La base `u8_g11` se carga con `solucion_u8_actividad1.js` (`insertMany` en dos colecciones). El script elimina las colecciones al empezar para poder **reejecutarse desde cero**.

**[REFUERZO]**

```text
envios              -> acknowledged: true, insertedCount: 15
eventos_seguimiento -> acknowledged: true, insertedCount: 20
```

### 2.2 Verificación de los requisitos de carga **[REFUERZO]**

```text
--- 3.1 Recuentos
db.envios.countDocuments()              = 15
db.eventos_seguimiento.countDocuments() = 20
TOTAL en u8_g11                         = 35

--- 3.2 Variedad de estados (estado_actual)
Entregado: 6 · Demorado: 3 · En tránsito: 3 · En preparación: 2 · Cancelado: 1

--- 3.3 Variedad de fechas, transportistas, rutas y valores
fecha_despacho: 2026-10-01 → 2026-10-26 (25,1 días) · peso de paquetes: 2 a 120 kg · demora máxima: 720 min
Transportistas (4): Expreso Chaco | Logística del Litoral | Transportes El Norteño | Vía Entre Ríos
Rutas (6): Buenos Aires - Concordia | Corrientes - Posadas | Córdoba - Buenos Aires | Resistencia - Rosario | Resistencia - Salta | Rosario - Tucumán
Tipos de evento (9): CANCELACION | CONGESTION_VIAL | CONTROL_TRANSITO | CORTE_CALZADA | DESPACHO | ENTREGA | FALLA_ELECTRICA | INCIDENCIA_MECANICA | PASO_SUCURSAL

--- 3.4 Integridad referencial: eventos cuyo envio_id no existe en envios -> 0
--- 3.5 Entregados con minutos_demora distinto de (entrega real - entrega estimada) -> 0
--- 3.6 Envíos con al menos un evento: 9 de 15 (el resto aún no registró hitos)
```

| Requisito de la pauta | Resultado |
| :--- | :--- |
| Base nombrada `u8_gXX` | **CUMPLE** — `u8_g11` |
| Al menos 2 colecciones justificadas por el dominio | **CUMPLE** — `envios` y `eventos_seguimiento` |
| Al menos 30 documentos ficticios en total | **CUMPLE** — 35 |
| Variedad de estados | **CUMPLE** — 5 estados |
| Variedad de fechas | **CUMPLE** — 25,1 días de rango |
| Variedad de valores | **CUMPLE** — 4 transportistas, 6 rutas, pesos y demoras distintos |
| Sin eventos huérfanos (integridad referencial) | **CUMPLE** — 0 huérfanos |
| `minutos_demora` coherente con las fechas de los entregados | **CUMPLE** — 0 incoherentes |
| Todo envío tiene al menos un paquete embebido | **CUMPLE** |

> **Observación de modelado.** `ruta` identifica el **corredor** comercial (por ejemplo, "Resistencia - Rosario"), no el destino final: un envío de ese corredor puede terminar en Santa Fe Capital, Reconquista o San Lorenzo. Por eso no se exige que coincida con `destino.localidad`.

---

## 3. Consultar

### 3.1 CRUD sobre `u8_g11` (registro de prueba `ENV-TEST-999`) **[REFUERZO]**

| Operación | Comando | Resultado |
| :--- | :--- | :--- |
| Alta | `db.envios.insertOne({ _id: "ENV-TEST-999", ... })` | `acknowledged: true`, `insertedId: 'ENV-TEST-999'` |
| Lectura | `db.envios.findOne({ _id: "ENV-TEST-999" })` | Devuelve el documento completo (1 paquete) |
| Modificación | `updateOne(..., { $set: { estado_actual: "Demorado", minutos_demora: 60 }, $push: { paquetes: {...PAQ-998} } })` | `matchedCount: 1`, `modifiedCount: 1` → 2 paquetes |
| Modificación de un elemento del arreglo | `updateOne({ _id, "paquetes.tracking_paquete": "PAQ-998" }, { $set: { "paquetes.$.fragil": false } })` | `modifiedCount: 1` |
| Baja | `deleteOne({ _id: "ENV-TEST-999" })` y `deleteMany({ envio_id: "ENV-TEST-999" })` | `deletedCount: 1` en cada colección |

```text
findOne tras la baja: null
Recuentos finales -> envios: 15 | eventos_seguimiento: 20
[CUMPLE]    La base quedó con los mismos documentos que antes del CRUD
```

**Costo del estado duplicado, visible en el CRUD.** Registrar un evento exige **dos escrituras** en dos colecciones (`insertOne` del evento y `updateOne` del `estado_actual`). En una instancia *standalone* no hay transacción que las agrupe; en producción (replica set) se usarían transacciones multi-documento.

### 3.2 Consultas del escenario **[REFUERZO]**

**Q1. Envíos por ruta y fecha (prioritaria)** → 3 envíos, coincide con la captura original.

```javascript
db.envios.find(
  { ruta: "Resistencia - Rosario",
    fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lte: ISODate("2026-10-15T23:59:59Z") } },
  { tracking_code: 1, ruta: 1, fecha_despacho: 1, "transportista.nombre": 1, estado_actual: 1 }
).sort({ fecha_despacho: 1 })
```
```text
ENV-2026-001 (2026-10-01, Entregado) · ENV-2026-002 (2026-10-03, Entregado) · ENV-2026-007 (2026-10-15, En tránsito)
```

**Q2. Envíos por estado y fecha (complementaria)** → 3 envíos demorados, del más reciente al más antiguo.

```javascript
db.envios.find(
  { estado_actual: "Demorado",
    fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lt: ISODate("2026-11-01T00:00:00Z") } }
).sort({ fecha_despacho: -1 })
```
```text
ENV-2026-012 (2026-10-22, 300 min) · ENV-2026-008 (2026-10-16, 480 min) · ENV-2026-003 (2026-10-05, 720 min)
```

**Q3. Filtro sobre subdocumento y arreglo:** destino en Santa Fe con algún paquete frágil.

```javascript
db.envios.find({ "destino.provincia": "Santa Fe", paquetes: { $elemMatch: { fragil: true } } })
```
```text
ENV-2026-001 (Rosario) · ENV-2026-007 (Reconquista) · ENV-2026-012 (San Lorenzo)
```

**Q3b. `$elemMatch` frente a la notación con punto** (¿algún paquete frágil **y** de más de 10 kg?):

```text
{ "paquetes.fragil": true, "paquetes.peso_kg": { $gt: 10 } }                -> 5 envíos: 001, 003, 012, 014, 015
{ paquetes: { $elemMatch: { fragil: true, peso_kg: { $gt: 10 } } } }        -> 2 envíos: 012, 014
```

La notación con punto evalúa cada condición **por separado** sobre el arreglo: el envío 001 aparece porque tiene un paquete frágil (3,2 kg) y *otro* de más de 10 kg (12,5 kg). `$elemMatch` exige que **el mismo paquete** cumpla ambas. Para esta pregunta corresponde `$elemMatch`.

**Q4. Un envío completo por identificador, con su historial** (`$match` + `$lookup` + `$addFields`) → `ENV-2026-001` con 3 eventos (`DESPACHO`, `CONTROL_TRANSITO`, `ENTREGA`), coincide con la captura original. La variante **Q4b** usa un `$lookup` con sub-pipeline para devolver el historial **ordenado por fecha** y proyectado:

```text
ENV-2026-002 → DESPACHO (Resistencia, 03/10 09:30) · INCIDENCIA_MECANICA (San Justo, 04/10 08:15) · ENTREGA (Santa Fe Capital, 04/10 18:30)
```

### 3.3 Pipelines de agregación **[REFUERZO]**

**P1. Demoras por transportista** (4 etapas: `$match` → `$group` → `$sort` → `$project`). Mismo criterio que la entrega, con los operadores restituidos:

```javascript
db.envios.aggregate([
  { $match: { minutos_demora: { $gt: 0 } } },
  { $group: { _id: "$transportista.nombre",
              cantidad_envios_demorados: { $sum: 1 },
              total_minutos_demora: { $sum: "$minutos_demora" },
              promedio_minutos_demora: { $avg: "$minutos_demora" } } },
  { $sort: { promedio_minutos_demora: -1 } },
  { $project: { _id: 0, transportista: "$_id", cantidad_envios_demorados: 1,
                total_horas_demora: { $round: [{ $divide: ["$total_minutos_demora", 60] }, 1] },
                promedio_minutos_demora: { $round: ["$promedio_minutos_demora", 1] } } }
])
```

| transportista | envíos demorados | horas totales | promedio (min) |
| :--- | ---: | ---: | ---: |
| Transportes El Norteño | 1 | 12,0 | 720,0 |
| Logística del Litoral | 4 | 23,5 | 352,5 |

> En la captura original el promedio de Logística del Litoral figura como `352` porque se redondeó a 0 decimales (`$round` redondea la mitad al par más cercano: 352,5 → 352). Con 1 decimal el valor es inequívoco.

**P1b. Proporción de envíos demorados por transportista** (4 etapas; cuenta también a los que **no** tienen demoras, que P1 oculta porque filtra primero):

| transportista | envíos | demorados | % demorados |
| :--- | ---: | ---: | ---: |
| Logística del Litoral | 4 | 4 | 100 |
| Transportes El Norteño | 4 | 1 | 25 |
| Expreso Chaco | 5 | 0 | 0 |
| Vía Entre Ríos | 2 | 0 | 0 |

**P2. Paquetes y peso por provincia de destino** (`$unwind` → `$group` → `$sort` → `$project`): Buenos Aires 185,5 kg (3 paquetes) · Santa Fe 94,7 kg (6 paquetes, 3 frágiles) · Tucumán 78 kg · Santiago del Estero 42,5 kg · Misiones 30 kg · Entre Ríos 27 kg · Salta 23 kg · Jujuy 14 kg.

---

## 4. Optimizar

### 4.1 Con el dataset de la actividad (15 envíos y 20 eventos) **[REFUERZO]**

Cada medición ejecuta `explain("executionStats")` **5 veces**; se informa la primera ejecución (que incluye la planificación, con la caché de planes fría) y el mínimo, la mediana y el máximo.

| Consulta | Plan sin índice | Docs examinados | Plan con índice | Claves | Docs examinados | ms (primera · min/med/máx) |
| :--- | :--- | ---: | :--- | ---: | ---: | :--- |
| Q1 ruta + fecha | `COLLSCAN` | 15 | `FETCH > IXSCAN(ruta_1_fecha_despacho_1)` | 3 | 3 | 0 · 0/0/0 → 2 · 0/0/2 |
| Q2 estado + fecha ↓ | `SORT > COLLSCAN` | 15 | `FETCH > IXSCAN(estado_actual_1_fecha_despacho_-1)`, **sin SORT** | 3 | 3 | 0 · 0/0/0 → 2 · 0/0/2 |
| Historial de un envío | `SORT > COLLSCAN` | 20 | `FETCH > IXSCAN(envio_id_1_timestamp_1)`, **sin SORT** | 3 | 3 | 0 · 0/0/0 → 1 · 0/0/1 |

`indexBounds` de Q1 con el índice: `ruta: ["Resistencia - Rosario", "Resistencia - Rosario"]` y `fecha_despacho: [2026-10-01T00:00:00Z, 2026-10-15T23:59:59Z]`: la igualdad fija la ruta y el rango recorre un tramo contiguo del índice.

`$indexStats` confirma el uso real de cada índice tras ejecutar las consultas: `ruta_1_fecha_despacho_1`: 1 · `estado_actual_1_fecha_despacho_-1`: 1 · `envio_id_1_timestamp_1`: 1. (`explain` no cuenta como uso.)

**Cómo se interpreta la evidencia original (7 ms y 27 ms).** En la captura de la entrega el `explain` sin índice informa `executionTimeMillis: 7` y el posterior `27`, con `optimizationTimeMillis: 25`. Esos 25 ms son **tiempo de planificación de la primera ejecución** (se evalúan los planes candidatos y la caché de planes aún no tiene el resultado), no costo del índice: con 15 documentos la ejecución en sí dura 0 ms. Una sola corrida no permite concluir nada sobre el tiempo; la métrica que sí es estable y comparable es el **trabajo realizado**: documentos examinados 15 → 3, claves examinadas 0 → 3.

### 4.2 Prueba de volumen: 200.000 envíos y 400.000 eventos **[REFUERZO]**

La pauta permite *"cargar más datos"* cuando el dataset es pequeño. `prueba_volumen_u8_actividad1.js` genera datos ficticios con semilla fija en una base **aparte** (`u8_g11_perf`), para no alterar `u8_g11`, que se conserva para la Actividad 2.

| Consulta | Sin índice: plan · docs examinados · ms (mediana) | Con índice: plan · claves/docs · ms (mediana) | Devueltos |
| :--- | :--- | :--- | ---: |
| Q1 ruta + fecha | `COLLSCAN` · **200.000** · 86 | `IXSCAN` · **811 / 811** · 3 | 811 |
| Q2 estado + fecha ↓ | `SORT > COLLSCAN` · **200.000** · 91 | `IXSCAN`, sin SORT · **2.287 / 2.287** · 8 | 2.287 |
| Historial de un envío | `SORT > COLLSCAN` · **400.000** · 143 | `IXSCAN`, sin SORT · **2 / 2** · 0 | 2 |

Con un índice bien construido la relación entre claves examinadas, documentos examinados y documentos devueltos es **1 : 1 : 1** (no se lee nada que no se devuelve). Sin índice se examinan 200.000 documentos para devolver 811.

**El orden de las columnas importa.** Con el índice invertido `{fecha_despacho: 1, ruta: 1}` la misma consulta Q1 examina **1.531 claves** para devolver los mismos 811 documentos (recorre todas las claves del tramo de fechas y solo 811 corresponden a la ruta buscada) y tarda 6 ms frente a 3 ms. La regla es **igualdad primero, orden después, rango al final** (ESR).

**Costo de los índices.**

| Concepto | Resultado |
| :--- | :--- |
| Construcción de los 3 índices (con la colección ya cargada) | 408 ms · 367 ms · 556 ms |
| Espacio de `envios` | datos 124,1 MB sin comprimir (28,5 MB almacenados) · índices 6,8 MB (`_id_` 2,4 + 2,2 + 2,2) |
| Escritura: 50.000 `insertMany` sin índices secundarios | medianas **888 ms** (955 / 888 / 887) |
| Escritura: 50.000 `insertMany` con 2 índices secundarios | medianas **1.160 ms** (1.160 / 1.081 / 1.182) → **+31 %** |

### 4.3 Limitaciones de `explain`

- `executionStats` **ejecuta** la consulta; en consultas de escritura hay que usar un entorno de prueba.
- Con colecciones pequeñas el tiempo de reloj no sirve; hay que mirar `totalDocsExamined` y `totalKeysExamined`.
- La primera ejecución incluye la planificación; deben repetirse las mediciones.
- Los tiempos de una VM compartida varían; el trabajo (documentos y claves examinados) es lo comparable entre corridas.
- `explain` de un `aggregate` con `$lookup` informa por etapa; por eso el historial se midió con el `find` equivalente sobre `eventos_seguimiento`.

---

## 5. Defender

### 5.1 Alternativa descartada

**Una sola colección `envios` con el historial completo embebido** (`eventos: [...]` dentro de cada envío). Se descartó porque:

1. **Arreglo sin cota** (*unbounded array*): un viaje interprovincial acumula paradas, pesajes y reportes de telemetría; la cardinalidad no tiene techo y el documento crece mientras el envío está activo, con el riesgo del límite de 16 MB.
2. **Memoria (working set):** el patrón más frecuente (estado actual, ruta y fecha) obligaría a traer al caché de WiredTiger el historial completo de cada envío, aunque la pantalla no lo use.
3. **Contención de escritura:** cada hito modifica el mismo documento que leen las consultas de monitoreo.

> **Precisión técnica.** La entrega original justificaba el descarte con "el motor debe reasignar espacio y mover el documento en disco". Eso describía el motor MMAPv1 (eliminado en MongoDB 4.2). **WiredTiger** no usa relleno (*padding*) ni "mueve" documentos: cada actualización genera una nueva versión del documento (MVCC). Los argumentos sólidos son los tres anteriores.

### 5.2 Costo de mantener datos duplicados

| Dato duplicado | Dónde | Costo | Cómo se mitiga |
| :--- | :--- | :--- | :--- |
| `estado_actual` (derivable del último evento) | `envios` | Una escritura extra por cada evento (sección 3.1: 2 escrituras); riesgo de inconsistencia si falla la segunda. | Transacción (replica set); o actualizar con `updateOne({ _id, ultimo_evento_ts: { $lt: ts } }, ...)` para que un evento tardío no pise un estado más nuevo; verificación periódica con un pipeline. |
| `transportista` (`nombre`, `cuit`) | cada `envio` | Espacio (unos 90 bytes por envío, estimado) y `updateMany` si el dato cambia. | Es un dato casi inmutable; se copia solo lo que consulta P2. |
| Índices secundarios | `envios`, `eventos_seguimiento` | **+31 % de tiempo de escritura** y 4,4 MB sobre 124 MB de datos (medido). | Solo se crean los que responden a patrones de acceso reales. |

**Por qué la decisión es ventajosa:** el sistema es de lectura dominante (cientos de consultas de rastreo por cada evento que reporta un camión). Pagar una escritura extra por hito a cambio de que P1, P2 y P3 resuelvan con un solo acceso al índice (1 : 1 : 1) es un intercambio favorable. Si las escrituras llegaran a dominar (telemetría cada pocos segundos), habría que reevaluar la copia del estado.

---

## 6. Errores y diagnóstico

| # | Qué falló | Cómo se detectó | Corrección |
| :--- | :--- | :--- | :--- |
| 1 | `actividad1.txt`: en el pipeline faltaban los operadores (`total_minutos_demora: { minutos_demora" }`). | Revisión del archivo frente a la captura, que sí muestra `$sum: "$minutos_demora"`. Al copiar el código desde un documento de texto se perdieron los `$`. | Operadores restituidos en `solucion_u8_actividad1.js`; el script se verifica ejecutándolo con `mongosh --file`. |
| 2 | `actividad1.txt` no tenía ningún `createIndex` (solo el `explain`). | Revisión del archivo. | Los tres `createIndex` forman parte del script, entre cada medición. |
| 3 | `actividad1.txt` mezclaba código con líneas de texto (`________________`, títulos sin `//`) y empezaba con `use u8_g11;`: con `mongosh --file` ese archivo **no ejecuta nada** (se comprobó: termina con código 0, sin error y sin salida). | Ejecución del archivo. | Todo es JavaScript válido y se usa `db.getSiblingDB("u8_g11")`. |
| 4 | El CRUD de las capturas corrió sobre la base `test`. | Prompt `test>` en las capturas. | CRUD ejecutado sobre `u8_g11`, con recuentos de control. |
| 5 | La conclusión de `evidencias.pdf` decía "0 ms en ambos" mientras la tabla daba 7 ms y 27 ms. | Lectura cruzada del texto y de la captura. | Sección 4.1: se explica la primera ejecución y se basa la conclusión en documentos y claves examinados. |
| 6 | Encabezado de la bitácora: "Motor Asignado: MySQL". | Lectura. | MongoDB Community. |
| 7 | El modelo se describía con cadenas (`"embebido (subdocumento con id, nombre y cuit)"`) en vez de documentos reales. | Lectura de la sección 1. | Sección 1.2: documentos de ejemplo reales. |

---

## 7. Uso de IA

Se utilizó Claude Code como asistente para **revisar la entrega** (cruzando scripts, capturas y consigna), **reescribir los scripts** y **ejecutarlos** en un laboratorio local aislado para producir la evidencia de refuerzo. Qué se validó: todos los resultados citados provienen de ejecuciones reales de los scripts de esta carpeta; los recuentos, los planes (`COLLSCAN`/`IXSCAN`) y las métricas se compararon con las capturas originales del grupo (por ejemplo, Q1 devuelve los mismos 3 envíos y P1 las mismas cantidades). Qué se descartó: usar los tiempos de reloj con 15 documentos como evidencia de mejora, y cualquier cifra que no hubiera salido de una ejecución.

## 8. Aprendizajes

- En MongoDB el modelo se deriva de los **patrones de acceso**, no de las tablas: la decisión de fondo es **qué se embebe y qué se referencia**, según cardinalidad y crecimiento.
- Duplicar un dato (`estado_actual`, `transportista`) es una decisión de ingeniería con costo de escritura y de consistencia, que debe poder cuantificarse (+31 % de escritura con 2 índices).
- Un índice se evalúa por el **trabajo que evita** (documentos y claves examinados), no por el reloj con pocos datos. El orden de sus columnas decide cuántas claves se recorren.
- Con colecciones pequeñas hay que **generar volumen** para mostrar el efecto, y decir con honestidad qué dato es de la corrida real y cuál no.
