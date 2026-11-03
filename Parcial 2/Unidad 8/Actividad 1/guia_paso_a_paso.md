# Guía Paso a Paso: U8 - Actividad 1 (Del requerimiento al documento)
**Grupo:** G11 (Escenario: Logística | Distribución interprovincial)  
**Motor:** MongoDB Community 8.0 · `mongosh` · base `u8_g11`  
**Archivos:** `solucion_u8_actividad1.js` (todo el flujo) · `prueba_volumen_u8_actividad1.js` (200.000 envíos para el análisis de índices) · `actividad1.txt` (la entrega original del grupo; ver `bitacora_resuelta.md`, sección 6, para sus errores)

> Esta guía reproduce la actividad completa y sirve para **rehacer las evidencias** que pidió el profesor: verificación de la carga y mediciones de `explain` repetidas y a escala.

---

## 0. Entorno y conexión

### 0.1. Comprobar que el servidor está activo
En la VM (o en tu PC si trabajás local):
```bash
sudo systemctl status mongod      # debe decir: active (running)
mongod --version | head -1        # db version v8.0.x
mongosh --version
```
Si está detenido: `sudo systemctl start mongod`.

### 0.2. Copiar los scripts a la VM
Desde la PC donde está el repositorio:
```bash
ssh vboxuser@192.168.1.42 'mkdir -p ~/u8_act1'
scp "Parcial 2/Unidad 8/Actividad 1/solucion_u8_actividad1.js" \
    "Parcial 2/Unidad 8/Actividad 1/prueba_volumen_u8_actividad1.js" \
    vboxuser@192.168.1.42:~/u8_act1/
```
*(Si la IP cambió, en la VM ejecutar `ip -4 addr` y buscar la interfaz en modo puente.)*

### 0.3. Dos formas de ejecutar
| Modo | Comando | Cuándo conviene |
| :--- | :--- | :--- |
| **Script completo** | `mongosh "mongodb://127.0.0.1:27017" --file solucion_u8_actividad1.js \| tee salida_act1.txt` | Para verificar que todo funciona de punta a punta y guardar la salida |
| **Interactivo** | `mongosh`, luego pegar de a bloques | Para sacar **una captura por evidencia** |

Si la instancia ya tiene el control de acceso activado (después de la Actividad 2), agregar las credenciales; `-p` sin valor pide la contraseña sin mostrarla:
```bash
mongosh "mongodb://127.0.0.1:27017" -u adminG11 --authenticationDatabase admin -p --file solucion_u8_actividad1.js
```

> **Atención:** el script **elimina y recrea** `envios` y `eventos_seguimiento` en `u8_g11` (así puede reejecutarse desde cero). La base `u8_g11` es la que se usa en la Actividad 2: si ya hiciste pruebas allí, volverá a su estado inicial de 15 y 20 documentos.

---

## 1. Etapa 1 · Diseñar
No hay comandos: es el análisis de la sección 1 de `bitacora_resuelta.md`. Antes de cargar nada, escribir:
1. La lista de **patrones de acceso** (qué consulta hace la aplicación y con qué frecuencia).
2. Qué se **embebe** (datos que se leen juntos, de cardinalidad acotada) y qué se **referencia** (datos que crecen sin cota).
3. Qué dato se **duplica** y cuánto cuesta mantenerlo.

*(Capturar: documento de ejemplo de `envios` y de `eventos_seguimiento`.)*

---

## 2. Etapa 2 · Cargar y verificar (secciones 0 a 3 del script)

```javascript
db = db.getSiblingDB("u8_g11")          // en modo interactivo se puede usar: use u8_g11
db.version()
// ... insertMany de envios (15) y eventos_seguimiento (20) ...
db.envios.countDocuments({})                // 15
db.eventos_seguimiento.countDocuments({})   // 20
```
La sección 3 del script comprueba **uno por uno** los requisitos de la pauta y escribe `[CUMPLE]` o `[NO CUMPLE]`:

| Requisito | Qué mide el script |
| :--- | :--- |
| Base `u8_gXX` | Nombre de la base |
| 2 o más colecciones | `db.getCollectionNames()` |
| 30 o más documentos | Suma de `countDocuments()` (35) |
| Variedad de estados | `$group` por `estado_actual` (5 estados) |
| Variedad de fechas | Rango entre la primera y la última `fecha_despacho` (25,1 días) |
| Variedad de valores | `distinct` de transportistas y rutas; pesos y demoras mínimos y máximos |
| Integridad referencial | `$lookup` de cada evento hacia `envios`: 0 huérfanos |
| Coherencia | `minutos_demora` de los entregados = entrega real − entrega estimada |
| Paquetes | Todo envío tiene al menos un paquete embebido |

*(Capturar: **Evidencia 1 — recuentos** y **Evidencia 2 — resultado de la verificación**. Esto es lo que el profesor pidió "verificar".)*

---

## 3. Etapa 3 · Consultar

### 3.1. CRUD sobre `u8_g11` (sección 4 del script)
Ejecutar **con la base `u8_g11` seleccionada** (el prompt debe decir `u8_g11>`, no `test>`): `insertOne`, `findOne`, `updateOne` (`$set`, `$push` y el operador posicional `$`), `deleteOne` y `deleteMany`.

Al final se verifica que la base quedó con 15 y 20 documentos.

*(Capturar: una por operación, con el prompt visible; y el recuento final.)*

### 3.2. Las consultas (sección 5 del script)
| Código | Qué resuelve | Operadores |
| :--- | :--- | :--- |
| Q1 | Envíos por ruta y fecha (prioritaria) | filtro por igualdad + rango, `sort` |
| Q2 | Envíos por estado y fecha | igualdad + rango, `sort` descendente |
| Q3 / Q3b | Filtro en subdocumento y arreglo | `"destino.provincia"`, `$elemMatch` |
| Q4 / Q4b | Envío completo por identificador con su historial | `$match` + `$lookup` (simple y con sub-pipeline) |
| P1 | Demoras por transportista | `$match` → `$group` → `$sort` → `$project` |
| P1b | % de envíos demorados | `$group` con `$cond` → `$addFields` → `$sort` → `$project` |
| P2 | Paquetes y peso por provincia | `$unwind` → `$group` → `$sort` → `$project` |

**Resultados esperados:** Q1 devuelve ENV-2026-001, 002 y 007; Q2 devuelve 012, 008 y 003; Q3 devuelve 001, 007 y 012; Q3b muestra 5 envíos con la notación con punto y 2 con `$elemMatch`; P1 da 720 min para El Norteño (1 envío) y 352,5 min para Logística del Litoral (4 envíos).

> **Cuidado al copiar el pipeline.** Si se pega código desde Word o Google Docs, pueden perderse los símbolos `$` (`{ minutos_demora" }` en lugar de `{ $sum: "$minutos_demora" }`). Copiar desde el `.js` del repositorio o desde VS Code.

---

## 4. Etapa 4 · Optimizar (sección 6 del script)

### 4.1. Cómo medir
```javascript
db.envios.find({ ruta: "Resistencia - Rosario",
                 fecha_despacho: { $gte: ISODate("2026-10-01T00:00:00Z"), $lte: ISODate("2026-10-15T23:59:59Z") } }
).explain("executionStats")
```
Campos a leer en la salida:

| Campo | Qué indica |
| :--- | :--- |
| `queryPlanner.winningPlan.stage` | `COLLSCAN` (recorre la colección) o `FETCH` con `IXSCAN` (usa un índice) |
| `executionStats.nReturned` | Documentos devueltos |
| `executionStats.totalKeysExamined` | Claves de índice recorridas |
| `executionStats.totalDocsExamined` | Documentos leídos de la colección |
| `executionStats.executionTimeMillis` | Tiempo de ejecución (no es confiable con pocos datos) |
| `queryPlanner.optimizationTimeMillis` | Tiempo de **planificación** (alto en la primera ejecución) |
| etapa `SORT` | La consulta ordena en memoria (se evita con un índice que ya entregue el orden) |

### 4.2. Procedimiento
1. `explain` **sin índice** y registrar el plan, los documentos examinados y el tiempo.
2. Crear el índice: `db.envios.createIndex({ ruta: 1, fecha_despacho: 1 })`.
3. `explain` **con índice**.
4. **Repetir cada medición 5 veces** y anotar la primera ejecución por separado (incluye la planificación). El script lo hace con la función `medir()`.
5. Verificar el uso real: `db.envios.aggregate([{ $indexStats: {} }])`.

Los otros dos índices del script: `{ estado_actual: 1, fecha_despacho: -1 }` (Q2) y `{ envio_id: 1, timestamp: 1 }` sobre `eventos_seguimiento` (el `$lookup` y el historial ordenado).

### 4.3. Con 15 documentos el reloj no alcanza
Con 15 documentos todo cabe en memoria: se verá `0 ms` casi siempre, y la primera ejecución con índice puede parecer *más lenta* por la planificación. La métrica que sirve es el **trabajo**: documentos examinados 15 → 3, claves 0 → 3.

### 4.4. Prueba de volumen (la pauta permite cargar más datos)
```bash
mongosh "mongodb://127.0.0.1:27017" --file prueba_volumen_u8_actividad1.js | tee salida_volumen.txt
```
- Genera **200.000 envíos y 400.000 eventos** ficticios en **otra base** (`u8_g11_perf`), con semilla fija: se obtiene siempre el mismo conjunto.
- Tarda del orden de 30 segundos y deja unos 250 MB en el directorio de datos (incluye el *journal*).
- Mide Q1, Q2 y el historial **antes y después** de los índices, el efecto de un índice con el orden de columnas invertido y el **costo de escritura** (50.000 inserciones con y sin índices).
- Resultados de referencia en `bitacora_resuelta.md`, sección 4.2: de 200.000 a 811 documentos examinados en Q1.

*(Capturar: **Evidencia 3 — explain sin índice**, **Evidencia 4 — creación del índice**, **Evidencia 5 — explain con índice**, **Evidencia 6 — resumen a escala**.)*

Al terminar:
```javascript
db.getSiblingDB("u8_g11_perf").dropDatabase()      // NUNCA dropDatabase sobre u8_g11
```

---

## 5. Etapa 5 · Defender
Preparar de forma oral y escrita (secciones 1.4 y 5 de la bitácora):
1. La **alternativa descartada**: eventos embebidos en el envío, y por qué no (arreglo sin cota, memoria, contención).
2. El **costo de la duplicación**: `estado_actual` implica dos escrituras por evento; los índices agregaron un 31 % al tiempo de escritura en la prueba.
3. Cuándo habría que **reevaluar** (si las escrituras de telemetría llegan a dominar a las lecturas).

---

## 6. Armar la entrega
La consigna pide **un único `.zip` con solo tres archivos**:

| Archivo pedido | De dónde sale |
| :--- | :--- |
| `bitacora.pdf` | Exportar a PDF `bitacora_resuelta.md` con las capturas propias (reemplazar los bloques **[REFUERZO]** por capturas de la ejecución del grupo si se quiere evidencia en la VM) |
| `actividad1.txt` | `solucion_u8_actividad1.js` **renombrado** a `actividad1.txt` (es JavaScript de `mongosh`; el nombre `.txt` lo exige la consigna) |
| `evidencias.pdf` o `.txt` | Salidas de `explain` antes y después, tabla comparativa, análisis y conclusiones (secciones 4.1 a 4.3), y la verificación de carga |

Lista de control antes de comprimir:
- [ ] El zip contiene **solo** esos tres archivos (sin `prueba_volumen…`, sin `salida_*.txt`, sin `.DS_Store`).
- [ ] Ningún archivo muestra contraseñas ni puertos publicados fuera del laboratorio.
- [ ] La bitácora dice **MongoDB Community** como motor.
- [ ] El `explain` de la bitácora corresponde a la base `u8_g11` y las capturas del CRUD muestran el prompt `u8_g11>`.
- [ ] Si se incluye la prueba de volumen en `evidencias`, se aclara que se hizo en la base `u8_g11_perf` y con datos generados.

---

## 7. Problemas frecuentes
| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| `SyntaxError` al ejecutar `actividad1.txt` | Líneas de texto mezcladas con código, o `$` perdidos al copiar | Usar `solucion_u8_actividad1.js` |
| El script termina **sin mostrar nada** y sin error (exit 0) | Con `use u8_g11` en la primera línea, `mongosh --file` no ejecuta el resto del archivo (se observó que ni siquiera se imprime un `print`) | `db = db.getSiblingDB("u8_g11")`; `use` solo vale en el shell interactivo |
| `MongoServerError[Unauthorized]` | La instancia ya tiene autenticación | Agregar `-u adminG11 --authenticationDatabase admin -p` |
| `MongoNetworkError: connect ECONNREFUSED` | `mongod` detenido o puerto distinto | `sudo systemctl start mongod`; revisar `net.port` |
| `explain` muestra `COLLSCAN` aunque hay índice | Consulta que no usa el prefijo del índice, o colección muy chica | Revisar el orden de las columnas del índice (igualdad, orden, rango) y el filtro |
| La primera medición con índice tarda más que sin índice | Tiempo de planificación (la caché de planes está fría) | Repetir la medición y comparar medianas y trabajo examinado |
| Los CRUD se ven en otra base | El prompt era `test>` | Comprobar con `db.getName()` o ejecutar `use u8_g11` |
| `E11000 duplicate key` al recargar a mano | Se insertó dos veces el mismo `_id` | Dejar que el script haga el `drop()` previo |
