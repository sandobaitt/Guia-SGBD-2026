# Fundamentos Teóricos: U8 - Actividad 1 (Del requerimiento al documento)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)  
**Tópicos:** Modelo documental (BSON), modelado por patrones de acceso, embeber vs. referenciar, arreglos sin cota, patrones de diseño, CRUD y operadores, consultas sobre subdocumentos y arreglos, Aggregation Pipeline, índices compuestos (regla ESR), `explain`, costo de los índices, comparación con el modelo relacional.

---

## 1. De tablas a documentos

### 1.1. El modelo documental
Una base **documental** guarda **documentos** (pares campo-valor, anidables) dentro de **colecciones**. MongoDB los almacena en **BSON**, una representación binaria de JSON con más tipos (`Date`, `Long`, `Decimal128`, `ObjectId`, `Binary`).

| Concepto relacional | Concepto en MongoDB | Diferencia relevante |
| :--- | :--- | :--- |
| Tabla | Colección | La colección **no impone** un esquema (se puede agregar uno con `$jsonSchema`) |
| Fila | Documento | Puede contener **subdocumentos y arreglos**: el dato "anidado" vive dentro de la fila |
| Columna | Campo | Cada documento puede tener campos distintos |
| Clave primaria | `_id` | Obligatorio, único, con índice automático |
| `JOIN` | `$lookup` o **embeber** | El diseño intenta evitar el join guardando junto lo que se lee junto |
| `GROUP BY` | `$group` | Parte de un *pipeline* de varias etapas |
| Transacción | Operación sobre **un documento** (atómica); transacciones multi-documento solo en *replica set* o *cluster* | Un *standalone* no tiene transacciones |

### 1.2. Esquema flexible no significa "sin diseño"
La flexibilidad permite evolucionar sin `ALTER TABLE`, pero el rendimiento y la consistencia dependen de **cómo se agrupa la información**. El error típico es traducir cada tabla relacional a una colección y cada `JOIN` a un `$lookup`: se obtiene lo peor de los dos modelos.

---

## 2. Modelar desde los patrones de acceso

En el modelo relacional se parte de las **entidades** y se normaliza; el rendimiento se resuelve después con índices. En el documental se parte de las **consultas** que debe resolver la aplicación:

1. Listar los **patrones de acceso**: qué se consulta, con qué filtros, con qué frecuencia y con qué prioridad.
2. Identificar la **cardinalidad** de cada relación (1:1, 1:pocos, 1:muchos, 1:muchísimos) y si **crece** con el tiempo.
3. Decidir qué se **embebe** y qué se **referencia**.
4. Decidir qué datos se **duplican** para ahorrar lecturas, y cuánto cuesta mantenerlos.
5. Crear los **índices** que responden a los patrones prioritarios y verificarlos con `explain`.

> **Pregunta guía:** ¿qué datos se leen **juntos** y cuáles **crecen**? Lo que se lee junto y no crece, se embebe. Lo que crece sin cota, se referencia.

---

## 3. Embeber o referenciar

### 3.1. Criterios de decisión
| Criterio | Conviene **embeber** | Conviene **referenciar** |
| :--- | :--- | :--- |
| Se leen siempre juntos | Sí | No: se consulta por separado |
| Cardinalidad | 1:1 o 1:pocos (acotada) | 1:muchos sin cota |
| Crecimiento | El conjunto casi no cambia | Crece indefinidamente |
| Ciclo de vida | El hijo nace y muere con el padre | El hijo tiene vida propia |
| Escrituras | Se actualizan junto con el padre | Se escriben con frecuencia y por separado |
| Consistencia | Se necesita atomicidad (un solo documento) | Aceptable usar dos escrituras |
| Tamaño | El documento sigue siendo chico | Embeber se acercaría al límite de **16 MB** |

### 3.2. Arreglo sin cota (*unbounded array*)
Es el **antipatrón** más común: un arreglo embebido que crece mientras la entidad está activa (eventos, logs, comentarios, telemetría). Problemas:
- Se acerca al **límite de 16 MB** por documento.
- Cada lectura del documento trae **todo el arreglo** al caché (WiredTiger), aunque la consulta solo necesite un campo: se degrada el *working set*.
- Los arreglos muy grandes encarecen las actualizaciones y los índices multiclave.

> En motores antiguos (MMAPv1) el costo se explicaba porque el documento "no entraba en su espacio y se movía en disco". **WiredTiger** no usa relleno ni mueve documentos: genera una nueva versión en cada actualización (MVCC). Hoy los argumentos son el límite de tamaño, el caché y la contención.

### 3.3. Aplicado al escenario de logística
| Relación | Cardinalidad | Decisión | Motivo |
| :--- | :--- | :--- | :--- |
| envío → paquetes | 1:pocos (1 a 4) | **Embeber** | Se leen con el envío, nacen y mueren con él |
| envío → destino / origen | 1:1 | **Embeber** (subdocumento) | Siempre se consultan juntos |
| envío → transportista | N:1, dato casi inmutable | **Embeber una copia** (`id`, `nombre`, `cuit`) | Evita el `$lookup` en "demoras por transportista" |
| envío → eventos de seguimiento | 1:muchos **sin cota** | **Referenciar** (`envio_id`) | Crece mientras el camión está en ruta |

---

## 4. Patrones de diseño relacionados

| Patrón | Idea | En este escenario |
| :--- | :--- | :--- |
| **Referencia extendida** | Referenciar, pero copiar en el documento principal solo los campos que más se consultan | `transportista` con `id`, `nombre` y `cuit` dentro del envío |
| **Dato calculado / pre-agregado** | Guardar el resultado de un cálculo para no repetirlo en cada lectura | `estado_actual` y `minutos_demora` en el envío |
| **Subconjunto** | Embeber solo los últimos N elementos de una colección grande y dejar el resto aparte | `ultimos_eventos` con `$push` + `$slice: -5` (evolución posible) |
| **Cubos** (*bucket*) | Agrupar mediciones consecutivas de un mismo origen en un documento acotado | Telemetría de un camión agrupada por hora |
| **Colecciones de series de tiempo** | Tipo de colección optimizado para mediciones (MongoDB 5.0+) | Alternativa si los eventos fueran telemetría de alta frecuencia |
| **Versionado de esquema** | Campo `schema_version` para convivir con documentos de formas distintas | Cuando el modelo evoluciona sin migración masiva |

---

## 5. CRUD y operadores de actualización

| Operación | Método | Observaciones |
| :--- | :--- | :--- |
| Alta | `insertOne`, `insertMany` | `insertMany` es `ordered` por defecto: se detiene en el primer error |
| Lectura | `find`, `findOne` | El segundo argumento es la **proyección** |
| Modificación | `updateOne`, `updateMany`, `replaceOne` | Se usan **operadores**; sin ellos `replaceOne` reemplazaría el documento completo |
| Baja | `deleteOne`, `deleteMany` | `deleteMany({})` vacía la colección (conserva índices) |
| Alta o modificación | `updateOne(..., { upsert: true })` | Inserta si no encuentra |

| Operador | Efecto |
| :--- | :--- |
| `$set` / `$unset` | Asigna / elimina un campo |
| `$inc` | Suma (o resta) a un número |
| `$push` / `$addToSet` | Agrega al arreglo (el segundo evita duplicados) |
| `$pull` | Quita del arreglo los elementos que cumplen una condición |
| `$` (posicional) | Modifica **el elemento del arreglo** que coincidió con el filtro: `{ "paquetes.$.fragil": false }` |

**Atomicidad.** Cada operación sobre **un documento** es atómica, aunque modifique varios campos y arreglos a la vez. Por eso embeber da consistencia "gratis". Registrar un evento (insertar en una colección y actualizar el estado en otra) **no** es atómico en un *standalone*; con replica set se usan transacciones.

---

## 6. Consultas sobre subdocumentos y arreglos

- **Subdocumento:** notación con punto, `{ "destino.provincia": "Santa Fe" }`.
- **Arreglo:** una condición sobre `paquetes.fragil` se cumple si **algún** elemento la cumple.

### 6.1. `$elemMatch` frente a la notación con punto
```javascript
{ "paquetes.fragil": true, "paquetes.peso_kg": { $gt: 10 } }          // condiciones sobre elementos distintos
{ paquetes: { $elemMatch: { fragil: true, peso_kg: { $gt: 10 } } } }  // el MISMO elemento cumple ambas
```
En los datos del laboratorio la primera devuelve **5** envíos y la segunda **2**: el envío 001 tiene un paquete frágil de 3,2 kg y *otro* de 12,5 kg. Para "un paquete frágil **y** pesado", la correcta es `$elemMatch`.

### 6.2. Otros operadores frecuentes
| Operador | Uso |
| :--- | :--- |
| `$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin` | Comparación |
| `$and`, `$or`, `$not`, `$nor` | Lógicos (varios filtros en un objeto equivalen a `$and`) |
| `$exists`, `$type` | Existencia y tipo (un campo puede faltar) |
| `$regex` | Texto; un patrón anclado al inicio (`^abc`) puede usar índice |
| `sort`, `limit`, `skip` | Orden y paginación (`skip` grande recorre y descarta: costoso) |

---

## 7. Aggregation Pipeline

Un *pipeline* es una **cadena de etapas**; la salida de cada una es la entrada de la siguiente.

| Etapa | Función | Equivalente SQL |
| :--- | :--- | :--- |
| `$match` | Filtra documentos | `WHERE` / `HAVING` |
| `$group` | Agrupa y calcula (`$sum`, `$avg`, `$min`, `$max`, `$count`) | `GROUP BY` |
| `$sort` | Ordena | `ORDER BY` |
| `$project` / `$addFields` | Elige o calcula campos | `SELECT` con expresiones |
| `$lookup` | Une con otra colección (*left outer join*) | `LEFT JOIN` |
| `$unwind` | Convierte cada elemento de un arreglo en un documento | `UNNEST` / `CROSS JOIN LATERAL` |
| `$limit` / `$skip` | Corta resultados | `LIMIT` / `OFFSET` |

**Reglas para escribir pipelines eficientes**
1. **`$match` lo antes posible**: es la única etapa que, al comienzo, puede aprovechar un índice y reducir lo que reciben las demás.
2. Un `$sort` inicial (o precedido por `$match`) puede resolverse con un índice; después de `$group` ya no.
3. El `$lookup` usa el índice de `foreignField` si existe: sin índice en `envio_id`, cada envío recorre toda `eventos_seguimiento`.
4. Las expresiones llevan `$` delante del **nombre de campo** (`"$minutos_demora"`) y de los **operadores** (`$sum`). Si se pierde un `$`, el valor deja de ser una referencia y el pipeline falla o devuelve datos incorrectos.

**Ejemplo del laboratorio** (demoras por transportista): `$match` (solo demorados) → `$group` por `transportista.nombre` con `$sum` y `$avg` → `$sort` por promedio → `$project` con `$round` y `$divide`. Como `transportista` y `minutos_demora` están **en el mismo documento**, no hace falta ningún `$lookup`: esa es la ventaja de la referencia extendida.

---

## 8. Índices

### 8.1. Tipos
| Tipo | Para qué sirve |
| :--- | :--- |
| `_id` | Automático y único |
| Simple / **compuesto** | Búsquedas por uno o varios campos (B-tree) |
| **Multiclave** | Se crea sobre un campo que es un arreglo: indexa cada elemento (un índice compuesto admite **un solo** arreglo) |
| Parcial (`partialFilterExpression`) | Indexa solo los documentos que cumplen una condición |
| Único (`unique`) | Impide valores repetidos (por ejemplo, `tracking_code`) |
| TTL | Elimina documentos al vencer una fecha |
| Texto / geoespacial | Búsqueda de texto / consultas por ubicación |

### 8.2. Índice compuesto y regla **ESR**
El orden de las columnas decide qué consultas ayuda a resolver:

> **E**quality (igualdad) → **S**ort (orden) → **R**ange (rango)

| Consulta | Índice | Resultado en el laboratorio (200.000 envíos) |
| :--- | :--- | :--- |
| `ruta = X` y `fecha` en un rango | `{ ruta: 1, fecha_despacho: 1 }` | 811 claves examinadas para 811 devueltos |
| La misma consulta | `{ fecha_despacho: 1, ruta: 1 }` (rango primero) | **1.531** claves para los mismos 811 |
| `estado = X`, rango de fecha, orden por fecha ↓ | `{ estado_actual: 1, fecha_despacho: -1 }` | Sin etapa `SORT` |
| Historial: `envio_id = X` ordenado por `timestamp` | `{ envio_id: 1, timestamp: 1 }` | 2 claves, sin `SORT` |

Un índice compuesto sirve también para sus **prefijos** (`{ruta}` sí, `{fecha_despacho}` sola no).

### 8.3. Costo de un índice
| Costo | Detalle (medido en el laboratorio) |
| :--- | :--- |
| Escritura | Cada `insert`, `update` de campos indexados y `delete` mantiene todos los índices: **+31 %** de tiempo con 2 índices secundarios |
| Espacio | 4,4 MB de índices secundarios sobre 124 MB de datos |
| Memoria | Los índices compiten con los datos por el caché de WiredTiger |

> Se crea un índice por **patrón de acceso real**, no por columna. `$indexStats` muestra cuántas veces se usó cada uno y permite descartar los que no se usan.

---

## 9. Leer un `explain`

```javascript
db.envios.find({ ... }).explain("executionStats")
```

| Modo | Qué hace |
| :--- | :--- |
| `queryPlanner` (por defecto) | Solo muestra el plan ganador y los rechazados; **no ejecuta** la consulta |
| `executionStats` | **Ejecuta** la consulta y agrega métricas reales |
| `allPlansExecution` | Además mide los planes candidatos que compitieron |

### 9.1. Etapas del plan
| Etapa | Significado |
| :--- | :--- |
| `COLLSCAN` | Recorre toda la colección |
| `IXSCAN` | Recorre un tramo de un índice (`indexBounds` muestra los límites) |
| `FETCH` | Trae el documento completo desde la colección |
| `SORT` | Ordena en memoria (un índice con el orden adecuado la elimina) |
| `PROJECTION_COVERED` | La consulta se resuelve **solo con el índice** (`totalDocsExamined: 0`) |

### 9.2. Métricas
| Métrica | Interpretación |
| :--- | :--- |
| `nReturned` | Documentos devueltos |
| `totalKeysExamined` | Entradas de índice recorridas |
| `totalDocsExamined` | Documentos leídos de la colección |
| `executionTimeMillis` | Tiempo (ruidoso con pocos datos) |
| `optimizationTimeMillis` | Tiempo de **planificación** |

**Relación ideal: `keys ≈ docs ≈ returned`.** Si `docsExamined` es mucho mayor que `nReturned`, el motor lee trabajo que descarta. En el laboratorio: sin índice 200.000 → 811; con índice 811 → 811.

### 9.3. Trampas al medir
1. **Primera ejecución.** Incluye la planificación (la *caché de planes* aún no guarda el plan): puede ser más lenta *con* índice que *sin* índice en colecciones pequeñas. Se repite la medición y se compara la mediana.
2. **Colección pequeña.** Si todo cabe en memoria, el tiempo es 0 ms: se evalúa el trabajo examinado o se genera volumen.
3. **`executionStats` ejecuta la consulta**: cuidado con las escrituras.
4. `explain` no incrementa los contadores de `$indexStats`: para verificar el uso real hay que ejecutar la consulta.

---

## 10. Comparación con los motores de la primera parte

| Tema | MySQL / PostgreSQL | MongoDB |
| :--- | :--- | :--- |
| Plan de ejecución | `EXPLAIN ANALYZE` / `EXPLAIN (ANALYZE, BUFFERS)` | `explain("executionStats")` |
| Recorrido completo | `Table scan` / `Seq Scan` | `COLLSCAN` |
| Acceso por índice | `Index lookup` / `Index Scan` | `IXSCAN` + `FETCH` |
| Ordenamiento | `filesort` / `Sort` | `SORT` |
| Índice compuesto | Misma regla del prefijo izquierdo | Misma regla + ESR |
| Datos semiestructurados | `JSON` + índice multivaluado (MySQL), `jsonb` + `GIN` (PostgreSQL) | Tipo nativo del modelo |
| Integridad | `FOREIGN KEY`, `CHECK` | No hay claves foráneas; `$jsonSchema` para validar |
| Transacciones | Siempre | Un documento siempre; varios documentos solo con replica set |

**Cuándo conviene un modelo documental.** Cuando el dato se lee como un agregado (un envío con todo lo suyo), el esquema evoluciona seguido y no hay muchas relaciones N:M. **Cuándo no:** cuando hay mucha integridad referencial entre entidades, consultas ad hoc con muchos `JOIN` o necesidad de transacciones multi-entidad frecuentes (ahí un relacional, o relacional extendido con JSON, suele ser mejor).

---

## 11. Preguntas de defensa (respuestas breves)

- **"¿Por qué dos colecciones y no una?"** Porque los eventos no tienen cota. Embebidos formarían un arreglo ilimitado que crece mientras el envío está activo, se acerca al límite de 16 MB y obliga a traer el historial completo al caché en cada consulta de estado. Los paquetes, en cambio, están acotados y se leen con el envío: se embeben.
- **"¿Por qué duplican `estado_actual`?"** Porque la consulta más frecuente del monitoreo es por estado y fecha. Sin la copia habría que consultar el último evento de cada envío. El costo es una escritura extra por evento y el riesgo de inconsistencia, que se mitiga con transacciones o actualizando solo si el evento es más nuevo.
- **"¿Qué pasa si el transportista cambia de nombre?"** Hay que actualizar los envíos con `updateMany`; es aceptable porque el dato casi no cambia y evita un `$lookup` en cada consulta de demoras.
- **"El `explain` con índice tardó más que sin índice, ¿el índice empeoró la consulta?"** No: se comparó una primera ejecución con planificación contra una ejecución sin planificar, con 15 documentos. Se repite la medición y se compara el trabajo: documentos examinados 15 → 3, y a escala 200.000 → 811.
- **"¿Por qué `{ ruta, fecha }` y no `{ fecha, ruta }`?"** Igualdad primero, rango después (ESR): con la igualdad el índice se acota a las claves de esa ruta y el rango recorre un tramo contiguo. Al invertirlo se leyeron 1.531 claves para devolver 811.
- **"¿Qué haría si el volumen de eventos fuera de telemetría cada pocos segundos?"** Evaluaría una colección de series de tiempo o el patrón de cubos, y reconsideraría la copia de `estado_actual` si las escrituras dominaran a las lecturas.
