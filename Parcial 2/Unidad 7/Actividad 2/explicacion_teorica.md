# Fundamentos Teóricos: U7 - Actividad 2 (Laboratorio Bisagra)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)  
**Tópicos:** Bases multimodelo, esquema híbrido relacional/documental, JSON en MySQL, índices multivaluados, índice invertido y Full-Text Search en InnoDB, relevancia, tokenización y stopwords, costo de E/S, mantenimiento de índices FTS, relacional extendido vs. NoSQL especializado.

---

## 1. El problema: datos que no entran cómodos en una tabla

### 1.1. Tensiones del modelo tabular puro
Un catálogo multirubro combina tres "formas" de datos:

| Forma del dato | Ejemplo en el caso | Modelo que mejor lo representa |
| :--- | :--- | :--- |
| **Estable y tipada** | `id`, `nombre`, `precio`, `stock` | Relacional (columnas, `CHECK`, B-Tree) |
| **Variable por categoría** | RAM/GPU, litros/no_frost, talles/material | Documento (JSON) |
| **Texto libre** | Descripciones comerciales | Índice invertido (Full-Text) |

Modelar todo como tabla pura lleva a tres antipatrones:
1. **Tabla ancha con NULLs:** una columna por cada atributo posible (~40 columnas en el caso, la mayoría vacías en cada fila).
2. **EAV (Entidad-Atributo-Valor):** tabla `(producto_id, atributo, valor)` donde todo es `VARCHAR`, sin tipos ni restricciones y con un JOIN por cada atributo que se filtra.
3. **Migraciones constantes:** `ALTER TABLE` cada vez que aparece una categoría nueva.

Y para el texto libre, `LIKE '%palabra%'` obliga a leer todas las filas y no puede ordenar por relevancia.

### 1.2. Base de datos multimodelo
Un SGBD **multimodelo** soporta más de un modelo de datos (relacional, documental, clave-valor, espacial, texto) **dentro del mismo motor**, compartiendo transacciones, seguridad, backup y optimizador. MySQL 9.x es relacional en su núcleo, pero suma tipo `JSON` nativo, índices multivaluados, Document Store (X DevAPI), datos espaciales con R-Tree y Full-Text Search con índices invertidos.

La pregunta "bisagra" de la actividad es: **¿alcanza con extender el relacional, o conviene sumar un motor NoSQL especializado?**

---

## 2. Esquema híbrido: relacional + JSON

### 2.1. Tipo `JSON` nativo
- MySQL **valida** el documento al insertarlo (rechaza JSON mal formado) y lo guarda en un **formato binario** que permite acceder a una clave sin volver a parsear el texto.
- Operadores de ruta: `col->'$.clave'` (equivale a `JSON_EXTRACT`, devuelve JSON) y `col->>'$.clave'` (equivale a `JSON_UNQUOTE(JSON_EXTRACT(...))`, devuelve texto).
- Funciones útiles: `JSON_KEYS`, `JSON_TYPE`, `JSON_CONTAINS`, `JSON_CONTAINS_PATH`, `JSON_OVERLAPS`, `MEMBER OF`.
- **Claves ausentes:** si un documento no tiene la clave, la ruta devuelve `NULL`, y cualquier comparación con `NULL` da `NULL` (no verdadero). Por eso en la actividad el Ultrabook (sin clave `gpu`) quedó fuera de `gpu <> 'integrada'`.

### 2.2. Diseño híbrido
La práctica recomendada es **tipar lo estable y dejar en JSON lo variable**:
- Lo que se filtra, ordena o agrega seguido (precio, stock, categoría) va en columnas con tipos, restricciones e índices B-Tree.
- Lo que varía por categoría va en una columna `JSON` con `CHECK` mínimos (por ejemplo `JSON_TYPE(tags) = 'ARRAY'`).
- Si un atributo JSON se vuelve "caliente" (muy consultado), se lo puede indexar con una **columna generada** o un **índice funcional**, sin sacarlo del documento.

---

## 3. Índices multivaluados sobre arrays JSON

Un B-Tree clásico guarda **una entrada por fila**. Un **índice multivaluado** (MySQL ≥ 8.0.17) guarda **una entrada por cada elemento** de un array JSON:

```sql
CREATE INDEX idx_tags_mv ON producto ((CAST(tags AS CHAR(30) ARRAY)));
```

| Fila | `tags` | Entradas en el índice |
| :--- | :--- | :--- |
| 2 | `["gaming","gpu","alta-gama"]` | `alta-gama→2`, `gaming→2`, `gpu→2` |
| 16 | `["gaming","alta-frecuencia"]` | `alta-frecuencia→16`, `gaming→16` |

- El optimizador lo usa con **`MEMBER OF()`**, **`JSON_CONTAINS()`** y **`JSON_OVERLAPS()`**.
- En la actividad: `'gaming' MEMBER OF (tags)` pasó de `Table scan` (cost 2.25) a `Index lookup ... using idx_tags_mv` (cost 0.70), y `JSON_OVERLAPS` se resolvió como un *range scan* con OR de dos búsquedas.
- Restricciones: el tipo del `CAST` debe coincidir con los valores (`CHAR(n)`, `UNSIGNED`, `DATE`…), los elementos más largos que `n` dan error al insertar, y no sirve para búsquedas de texto parcial.

---

## 4. Full-Text Search: el índice invertido

### 4.1. Índice B-Tree vs. índice invertido
- Un **B-Tree** ordena valores completos. Sirve para `=`, rangos y prefijos (`LIKE 'abc%'`), pero **no** para `LIKE '%abc%'`, porque sin un prefijo fijo no hay punto de entrada en el árbol. Por eso el optimizador elige *full table scan*.
- Un **índice invertido** parte cada documento en **términos (tokens)** y guarda, para cada término, la lista de documentos donde aparece (*posting list*) con sus posiciones (los doc_id corresponden al catálogo; las posiciones son ilustrativas):

```
término      → documentos (doc_id: posiciones)
"gaming"     → 2:[12], 16:[8]
"pulgadas"   → 1:[5], 2:[40], 3:[9], 13:[6], 14:[7], 15:[4], 16:[6]
"tv"         → 13:[2,14], 14:[2]
```

Buscar `gaming` es ir **directo a la entrada del término**: el costo depende de cuántos documentos lo contienen, no del tamaño de la tabla. Por eso, en la medición con 200.000 filas, el costo estimado bajó de 22.541 a 1,10.

### 4.2. Arquitectura del índice FULLTEXT en InnoDB
1. **Columna oculta `FTS_DOC_ID`** (BIGINT UNSIGNED): identifica cada documento en el índice. Si la tabla no la tiene, el primer `CREATE FULLTEXT INDEX` **reconstruye toda la tabla** para agregarla. Eso es lo que avisa el *Warning 124: InnoDB rebuilding table to add column FTS_DOC_ID*. En tablas grandes conviene declararla al crear la tabla para evitar esa reconstrucción.
2. **Tablas auxiliares** (tablespaces `fts_<table_id>_...`):
   - `index_1` … `index_6`: el índice invertido propiamente dicho, particionado por rango de la primera letra del término (permite construcción paralela, `innodb_ft_sort_pll_degree`).
   - `deleted` / `deleted_cache`: doc_ids borrados lógicamente y pendientes de purga.
   - `being_deleted` / `being_deleted_cache`: doc_ids que se están purgando durante un `OPTIMIZE`.
   - `config`: metadatos (por ejemplo `synced_doc_id` y `stopword_table_name`).
3. **Caché del índice** (`innodb_ft_cache_size`, por tabla): las filas insertadas se tokenizan **en memoria** y se vuelcan a las tablas auxiliares cuando la caché se llena, en un `OPTIMIZE` o al apagar el servidor. Por eso, en la prueba de humo, los términos estaban en `INNODB_FT_INDEX_CACHE` y `INNODB_FT_INDEX_TABLE` estaba vacía.
4. **Transaccionalidad:** los cambios se aplican al índice **en el `COMMIT`**. Una transacción no ve en `MATCH()` sus propias filas sin confirmar, pero el índice nunca queda inconsistente con los datos confirmados.

### 4.3. Por qué las escrituras se encarecen
En InnoDB FTS, un `UPDATE` de una columna indexada se procesa como **borrado lógico + inserción con un `FTS_DOC_ID` nuevo**:
- El doc_id viejo se registra en `deleted`; el texto nuevo se tokeniza y se agrega a la caché.
- Las entradas viejas siguen físicamente en el índice hasta un `OPTIMIZE TABLE` (con `innodb_optimize_fulltext_only = ON` reorganiza solo el índice), que procesa `innodb_ft_num_word_optimize` términos por pasada (2.000 por defecto).
- En la actividad: el `UPDATE` de 20.000 filas pasó de 0,60 s a 2,83 s (×4,7), dejó 20.000 doc_ids en `INNODB_FT_DELETED`, y una pasada de `OPTIMIZE` no alcanzó porque el índice tenía 210.261 términos (~105 pasadas).

---

## 5. Tokenización, stopwords y configuración

### 5.1. Parser por defecto
- Separa por espacios y puntuación (`USB-C` → `usb`, `c`; `WiFi 6` → `wifi`, `6`).
- Descarta los tokens más cortos que **`innodb_ft_min_token_size`** (3 por defecto) o más largos que `innodb_ft_max_token_size` (84).
- Descarta las **stopwords** (palabras vacías).
- La comparación sigue la **colación** de la columna: con `utf8mb4_0900_ai_ci` es insensible a mayúsculas y a acentos (`cafe` encuentra "café").

### 5.2. Variables de solo lectura vs. dinámicas
| Variable | Tipo | Cómo se cambia | Efecto sobre índices existentes |
| :--- | :--- | :--- | :--- |
| `innodb_ft_min_token_size` / `max` | Solo lectura | Archivo `.cnf` + reinicio | **Ninguno** hasta reconstruir el índice |
| `innodb_ft_server_stopword_table` | Global dinámica | `SET GLOBAL` | Aplica a índices **creados después** |
| `innodb_ft_user_stopword_table` | Sesión dinámica | `SET SESSION` | Aplica a índices creados **en esa sesión** (tiene prioridad) |
| `innodb_ft_enable_stopword` | Dinámica | `SET` | Ídem: se fija al crear el índice |

**Reconstrucción:** se hace con `DROP INDEX` y `ADD FULLTEXT` en **sentencias separadas**. En la actividad comprobamos que la forma combinada (`ALTER TABLE t DROP INDEX x, ADD FULLTEXT x (...)` con la misma definición) **no** reconstruye el índice: InnoDB lo trata como un cambio de metadatos y el índice conserva los tokens viejos.

### 5.3. Stopwords
- La lista por defecto (`INNODB_FT_DEFAULT_STOPWORD`) tiene 36 palabras **en inglés** (`the`, `of`, `and`… y por casualidad `de`, `en`, `la`).
- Una tabla propia (una sola columna `value VARCHAR`) **reemplaza** la lista por defecto. Al bajar `min_token_size` a 2 se vuelve imprescindible, porque si no se indexan `el`, `un`, `al`, `con`…
- La tabla de stopwords queda registrada en el `config` del índice (`INNODB_FT_CONFIG.stopword_table_name`).

### 5.4. Parser `ngram`
- Divide el texto en secuencias de *n* caracteres (`ngram_token_size`, 2 por defecto): `gaming` → `ga, am, mi, in, ng`.
- Está pensado para idiomas **sin separador de palabras** (chino, japonés, coreano). En español aumenta el tamaño del índice y los falsos positivos, por eso en la actividad se prefirió ajustar `min_token_size`.

---

## 6. Modos de búsqueda y relevancia

### 6.1. Lenguaje natural (por defecto)
```sql
MATCH(nombre, descripcion) AGAINST('notebook gaming RTX')
```
- Devuelve las filas que contienen **algún** término, con un **score de relevancia**.
- La relevancia de InnoDB es una variante de **TF-IDF**: sube cuantas más veces aparece el término en el documento (*term frequency*) y cuanto más raro es en la colección (*inverse document frequency*). Por eso `rtx`, que aparece en un solo documento, pesa mucho más que `pulgadas`, que aparece en siete.
- Si el mismo `MATCH()` está en el `SELECT` y en el `WHERE`, se calcula una sola vez.
- `MATCH()` exige un índice FULLTEXT con **exactamente** esas columnas. Si no existe, da ERROR 1191.

### 6.2. Modo booleano
```sql
AGAINST('+gaming -notebook' IN BOOLEAN MODE)
```
| Operador | Significado | Ejemplo de la actividad |
| :--- | :--- | :--- |
| `+` | término obligatorio | `+TV +4K` |
| `-` | término excluido | `+gaming -notebook` → solo el monitor |
| `*` | comodín de prefijo | `inalambr*` → "inalámbrico"; `juego*` → "juegos" |
| `"..."` | frase exacta | `"alta frecuencia"` |
| `> <` `~` `()` | ajustan el peso / agrupan | — |

### 6.3. Expansión de consulta (`WITH QUERY EXPANSION`)
Hace dos pasadas: busca el término, toma las palabras más relevantes de los primeros resultados y vuelve a buscar con ellas. Sirve con consultas muy cortas, pero **agrega ruido**. En la actividad, `espresso` trajo heladeras y un compresor por términos compartidos como `litros` o `bar`.

### 6.4. Lo que FTS de InnoDB no hace
- **Stemming / lematización:** `juego` no encuentra `juegos`.
- **Tolerancia a errores de tipeo (fuzzy):** `notebok` no encuentra `notebook`.
- **Sinónimos, facetas, resaltado, autocompletado, búsqueda semántica/vectorial.**

Estas son las funciones que justifican un motor de búsqueda dedicado (Elasticsearch/OpenSearch, basados en Lucene).

---

## 7. Cómo medir: plan, costo y E/S

### 7.1. Herramientas usadas
| Herramienta | Qué muestra |
| :--- | :--- |
| `EXPLAIN` (formato TREE por defecto en 9.x) | Plan elegido y **costo estimado** de cada nodo |
| `EXPLAIN FORMAT=JSON` (esquema 2.0) | `access_type`, `index_access_type` (`full_text_search`), `estimated_rows`, `estimated_total_cost` |
| `EXPLAIN ANALYZE` | **Ejecuta** la consulta y muestra `actual time=primera..última fila` y filas reales por nodo |
| `FLUSH STATUS` + `SHOW SESSION STATUS LIKE 'Handler_read%'` | Contadores de E/S lógica del motor: `Handler_read_rnd_next` = filas leídas en recorrido secuencial (scan) |
| Tiempo de cliente `(x.xxx sec)` con `mysql -vvv` | Latencia observada de punta a punta |

### 7.2. Interpretación de los resultados
- `Table scan` + `Handler_read_rnd_next ≈ filas de la tabla` → la consulta es **O(n)**: si la tabla se duplica, el tiempo se duplica.
- `Full-text index search` + `Handler_read_rnd_next = 0` → el costo depende del **tamaño de la posting list** del término, no de *n*.
- `Rows fetched before execution` → el optimizador resolvió el resultado (por ejemplo un `COUNT(*)` booleano) **durante la optimización**, usando el índice.
- Las estimaciones del optimizador para `LIKE '%...%'` son pobres (estimó 23.130 filas para un resultado real de 1) porque no hay estadísticas sobre subcadenas y aplica una selectividad por defecto.

### 7.3. Por qué se escaló a 200.000 filas
Con 20 filas cualquier plan tarda menos de 2 ms: el *full scan* lee una o dos páginas de 16 KB, ya en el buffer pool, y la diferencia queda dentro del ruido. Para ver el **crecimiento** del costo hace falta un volumen donde la lectura secuencial pese. Aun así, en las 20 filas el plan ya cambia (`Table scan` → `Full-text index search`), y eso es lo que importa para razonar sobre el optimizador.

---

## 8. Relacional extendido vs. NoSQL especializado

### 8.1. Qué gana y qué pierde cada opción
| Criterio | MySQL extendido (JSON + FTS) | Almacén documental (MongoDB) | Motor de búsqueda (Elasticsearch/OpenSearch) |
| :--- | :--- | :--- | :--- |
| Consistencia | ACID, índice FTS transaccional | ACID a nivel documento (y multi-documento en versiones recientes) | **Eventual**: índice *near real-time*, sin transacciones |
| Joins | Nativos | Limitados (`$lookup`) | No |
| Búsqueda textual | Palabras clave + relevancia TF-IDF | Índice de texto básico | Analizadores por idioma, stemming, fuzzy, sinónimos, facetas, BM25, vectores |
| Escala | Vertical + réplicas de lectura | Sharding nativo | Sharding y réplicas de índice nativos |
| Operación | Un solo motor, un backup, una seguridad | Otro motor que operar | Otro clúster más un pipeline de sincronización (CDC/colas) |

### 8.2. Patrón híbrido típico
Cuando la búsqueda pasa a ser crítica, la arquitectura más común **no reemplaza** al relacional sino que lo complementa:

```
 [ App ] ──escrituras──► [ MySQL: fuente de verdad (precio, stock, pedidos) ]
    │                                  │
    │                         CDC (binlog → Debezium/Kafka)
    │                                  ▼
    └──búsquedas────────►  [ Elasticsearch: réplica de lectura para búsqueda ]
```

- MySQL sigue siendo la **fuente de verdad** (transacciones de stock y precio).
- El motor de búsqueda es una **proyección de lectura**, eventualmente consistente, reconstruible desde MySQL.
- El costo es operativo: sincronización, monitoreo del retraso (*lag*), doble infraestructura y resolución de inconsistencias.

### 8.3. Regla práctica para decidir
1. ¿El modelo relacional extendido resuelve el patrón de consulta con planes razonables? → **Mantener**.
2. ¿Aparecen requisitos que el motor **no puede** cumplir (stemming, fuzzy, facetas, semántica, escala distribuida)? → **Híbrido**: sumar el especializado como réplica de lectura.
3. ¿No hay núcleo transaccional que proteger y el dato es intrínsecamente documental o distribuido? → Recién ahí, **migrar** a un NoSQL dedicado.
