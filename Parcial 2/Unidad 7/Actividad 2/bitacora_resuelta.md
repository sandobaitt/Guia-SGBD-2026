# Bitácora Técnica: U7 - Actividad 2 (Laboratorio Bisagra)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)  
**Grupo:** G11 — Aguirre Egea, Emiliano · Ghione, Lucas Emanuel · Pagno, Agustin Mario · Sandoval, Lautaro Emanuel  
**Caso:** Catálogo técnico multirubro (`U7_catalogo_multimodelo.jsonl`)  
**Motor SGBD:** MySQL Community Server 9.7.2 LTS (InnoDB) sobre Ubuntu 24.04.4 LTS (VirtualBox, 2 vCPU, 4 GB RAM)  
**Capacidad seleccionada (Radar Act. 1):** Full-Text Search — índice invertido `FULLTEXT` + `MATCH() ... AGAINST()`, complementado con índice multivaluado sobre array JSON.  
**Script:** `solucion_u7_actividad2.sql` · **Salidas completas:** carpeta `evidencias_salidas/`

---

## Introducción y Alcance
En la Actividad 1 elegimos Full-Text Search para resolver la búsqueda por texto libre y ordenada por relevancia sobre un catálogo heterogéneo, donde `LIKE '%palabra%'` obliga a recorrer toda la tabla y no puede rankear resultados. En este laboratorio:
1. **Fase A:** registramos el baseline, verificamos la capacidad y la **configuramos** (`innodb_ft_min_token_size = 2` + stopwords en español) porque la configuración de fábrica no indexa siglas técnicas de 2 caracteres (`TV`, `4K`, `HP`, `Hz`).
2. **Fase B:** modelamos el catálogo en un **esquema híbrido** (núcleo relacional + documento JSON + texto libre), ejecutamos las 3 consultas de validación, creamos los índices especializados y medimos antes/después con `EXPLAIN`, `EXPLAIN ANALYZE`, contadores `Handler_read%` y tiempos, primero sobre 20 filas y luego sobre **200.000 filas**.
3. **Fase C:** completamos la matriz de decisión y emitimos el veredicto de arquitectura.

---

## Fase A: Preparar y Habilitar

### A.1. Baseline del entorno

| Ítem | Valor registrado |
| :--- | :--- |
| Versión / edición | `9.7.2` — MySQL Community Server - GPL |
| Host / SO | `LinuxE` — Ubuntu 24.04.4 LTS, kernel 6.8.0-138, x86_64 |
| Motor por defecto | InnoDB (buffer pool 128 MB) |
| `innodb_ft_min_token_size` | **3** (de fábrica) |
| `innodb_ft_enable_stopword` | ON — lista por defecto de **36 palabras en inglés** |
| Parser `ngram` | ACTIVE (`ngram_token_size = 2`) |
| Tablas de diagnóstico | `INNODB_FT_INDEX_TABLE`, `INNODB_FT_INDEX_CACHE`, `INNODB_FT_DELETED`, `INNODB_FT_CONFIG`, `INNODB_FT_DEFAULT_STOPWORD` → ACTIVE |

```sql
SELECT VERSION(), @@version_comment, @@default_storage_engine;
SHOW VARIABLES LIKE 'innodb_ft%';
SELECT PLUGIN_NAME, PLUGIN_STATUS FROM information_schema.PLUGINS
WHERE PLUGIN_NAME = 'ngram' OR PLUGIN_NAME LIKE 'INNODB_FT%';
```

> **Evidencia 1 — Verificación del entorno:** `mysql --version` → `Ver 9.7.2 for Linux on x86_64 (MySQL Community Server - GPL)` y salida de `SHOW VARIABLES LIKE 'innodb_ft%'` con `innodb_ft_min_token_size = 3`.  
> `[ACCIÓN REQUERIDA: Insertar captura de evidencias_salidas/01_baseline_y_prueba_humo.txt (Sección 0)]`

### A.2. Procedimiento oficial consultado (MySQL 9.7 Reference Manual)

| Tema | Fuente oficial |
| :--- | :--- |
| Full-Text Search (modos natural, booleano, expansión) | https://dev.mysql.com/doc/refman/9.7/en/fulltext-search.html (Sec. 14.9) |
| Ajuste fino: `innodb_ft_min_token_size` es de solo lectura → archivo de opciones + reinicio + **reconstruir índices** | https://dev.mysql.com/doc/refman/9.7/en/fulltext-fine-tuning.html (Sec. 14.9.6) |
| Stopwords personalizadas (`innodb_ft_user_stopword_table`) | https://dev.mysql.com/doc/refman/9.7/en/fulltext-stopwords.html |
| Arquitectura del índice invertido InnoDB (`FTS_DOC_ID`, tablas auxiliares, caché) | https://dev.mysql.com/doc/refman/9.7/en/innodb-fulltext-index.html |
| Índices multivaluados (`CAST(... AS CHAR(n) ARRAY)`) | https://dev.mysql.com/doc/refman/9.7/en/create-index.html#create-index-multi-valued |

Fecha de consulta: 25/10/2026.

### A.3. Prueba de humo y detección de la limitación (configuración de fábrica)
Creamos una tabla mínima con índice `FULLTEXT` para confirmar que la capacidad opera:

```sql
CREATE TABLE prueba_humo (id INT PRIMARY KEY, texto VARCHAR(200) NOT NULL,
                          FULLTEXT KEY ft_texto (texto));
INSERT INTO prueba_humo VALUES (1,'Smart TV 4K con HDR y Google TV'),
  (2,'Notebook gaming con placa RTX'), (3,'Cafetera espresso de 15 bar');
SELECT id, MATCH(texto) AGAINST('gaming') AS score FROM prueba_humo WHERE MATCH(texto) AGAINST('gaming');
SELECT COUNT(*) FROM prueba_humo WHERE MATCH(texto) AGAINST('TV 4K');
```

| Prueba | Resultado |
| :--- | :--- |
| `AGAINST('gaming')` | id 2, score 0,2276 → **la capacidad funciona** |
| `AGAINST('TV 4K')` | **0 filas** |
| Contenido de `INNODB_FT_INDEX_CACHE` | `bar, cafetera, con, espresso, gaming, google, hdr, notebook, placa, rtx, smart` — **no están** `tv`, `4k` ni `15` |

**Diagnóstico:** los tokens de menos de 3 caracteres se descartan al tokenizar. En un catálogo técnico, las siglas cortas (`TV`, `4K`, `HP`, `Hz`, `VA`, `ms`) son justamente términos de búsqueda frecuentes. También observamos que las filas recién insertadas viven en la **caché del índice** (`INDEX_CACHE`) y aún no fueron volcadas a las tablas auxiliares en disco (`INDEX_TABLE` = 0 palabras).

### A.4. Activación / configuración
`innodb_ft_min_token_size` no admite `SET GLOBAL`. Siguiendo la Sec. 14.9.6 creamos un archivo de opciones propio (reversible) y reiniciamos el servicio:

```bash
sudo tee /etc/mysql/mysql.conf.d/u7_fulltext.cnf <<'EOF'
[mysqld]
# U7 Act. 2 - indexar siglas tecnicas de 2 caracteres (TV, 4K, HP, Hz)
innodb_ft_min_token_size = 2
EOF
sudo systemctl restart mysql      # 10,9 s; error.log: "ready for connections. Version: '9.7.2'"
```

Bajar el mínimo a 2 tiene un efecto colateral: pasan a indexarse palabras vacías del español (`con`, `la`, `el`, `un`…). Como la lista por defecto es inglesa, definimos una **tabla de stopwords en español** (30 palabras) y la asociamos a los índices al crearlos (variable dinámica de sesión, sin reinicio):

```sql
CREATE TABLE stopwords_es (value VARCHAR(30) NOT NULL) ENGINE = InnoDB;
INSERT INTO stopwords_es VALUES ('a'),('al'),('con'),('de'),('del'),('el'),('en'), ... ;
SET SESSION innodb_ft_user_stopword_table = 'sgbd_u7_act2/stopwords_es';
```

**¿Por qué no el parser `ngram`?** `ngram` parte todo el texto en bigramas (`ga`, `am`, `mi`…). Está pensado para idiomas sin separador de palabras (chino, japonés, coreano). En español multiplicaría el tamaño del índice y los falsos positivos. Ajustar el tamaño mínimo de token conserva la tokenización por palabras.

### A.5. Verificación post-activación

```sql
SELECT VARIABLE_NAME, VARIABLE_VALUE, VARIABLE_SOURCE, VARIABLE_PATH
FROM performance_schema.variables_info JOIN performance_schema.global_variables USING (VARIABLE_NAME)
WHERE VARIABLE_NAME = 'innodb_ft_min_token_size';
```

| VARIABLE_NAME | VARIABLE_VALUE | VARIABLE_SOURCE | VARIABLE_PATH |
| :--- | :--- | :--- | :--- |
| innodb_ft_min_token_size | **2** | GLOBAL | `/etc/mysql/mysql.conf.d/u7_fulltext.cnf` |

- **Hallazgo 1:** el índice existente **no cambia solo**: `AGAINST('TV 4K')` sigue devolviendo 0 filas hasta reconstruirlo.
- **Hallazgo 2:** `ALTER TABLE prueba_humo DROP INDEX ft_texto, ADD FULLTEXT KEY ft_texto (texto)` **en una sola sentencia no reconstruye nada**: InnoDB detecta la misma definición y solo modifica metadatos (seguía sin `tv`). Hubo que ejecutar **dos sentencias separadas** (`DROP INDEX` y luego `ADD FULLTEXT`).
- Tras la reconstrucción: `AGAINST('TV 4K')` → id 1, score 0,6829; `INNODB_FT_INDEX_TABLE` ahora contiene `15`, `4k` y `tv`.

> **Evidencia 2 — Confirmación de habilitación:** `VARIABLE_SOURCE = GLOBAL` desde `u7_fulltext.cnf` + consulta `TV 4K` que pasa de 0 a 1 fila.  
> `[ACCIÓN REQUERIDA: Insertar captura de evidencias_salidas/02_verificacion_post_activacion.txt]`

---

## Fase B: Resolver el Caso

### B.1. Esquema híbrido y poblado
El JSONL se carga **tal cual** en una tabla de staging (`catalogo_raw`, una línea JSON por fila) y se transforma con rutas JSON hacia la tabla definitiva. Como el dataset no trae texto largo, agregamos una **descripción comercial** por producto, que es el insumo real de Full-Text Search.

```sql
CREATE TABLE producto (
  id          INT           PRIMARY KEY,          -- ┐
  nombre      VARCHAR(120)  NOT NULL,             -- │ núcleo relacional estable
  categoria   VARCHAR(40)   NOT NULL,             -- │ (tipado, CHECK, B-Tree)
  precio      DECIMAL(12,2) NOT NULL CHECK (precio >= 0),
  stock       INT           NOT NULL CHECK (stock >= 0),   -- ┘
  atributos   JSON          NOT NULL,             -- documento variable por categoría
  tags        JSON          NOT NULL,             -- colección de etiquetas
  descripcion TEXT          NOT NULL,             -- texto libre → FULLTEXT
  CONSTRAINT chk_tags_array CHECK (JSON_TYPE(tags) = 'ARRAY'),
  KEY idx_precio (precio)
) ENGINE = InnoDB;

INSERT INTO producto (id, nombre, categoria, precio, stock, atributos, tags, descripcion)
SELECT r.linea->>'$.id', r.linea->>'$.nombre', r.linea->>'$.categoria',
       r.linea->>'$.precio', r.linea->>'$.stock', r.linea->'$.atributos', r.linea->'$.tags',
       d.descripcion
FROM catalogo_raw r JOIN descripcion_carga d ON d.id = r.linea->>'$.id';
```

| productos | categorías | esquemas de atributos distintos |
| :---: | :---: | :---: |
| **20** | **9** | **17** |

Que haya 17 combinaciones de claves distintas en 20 productos muestra la variabilidad del esquema: en una tabla relacional pura harían falta ~40 columnas casi todas `NULL`, o un modelo EAV.

### B.2. Consultas de validación (antes de la intervención)

**Consulta 1 — Escalar relacional:**
```sql
SELECT id, nombre, categoria, precio, stock FROM producto
WHERE precio BETWEEN 300000 AND 900000 AND stock >= 5 ORDER BY precio;
```
8 filas (Taladro Pro 18V … Smart TV Nova 55). Plan: `Index range scan on producto using idx_precio` (cost=4.31). El B-Tree clásico resuelve bien la parte relacional.

**Consulta 2 — Etiqueta / atributo anidado / colección:**
```sql
SELECT id, nombre, tags FROM producto WHERE 'gaming' MEMBER OF (tags);                 -- 2a
SELECT id, nombre, atributos->'$.talles' FROM producto
WHERE categoria = 'calzado' AND 42 MEMBER OF (atributos->'$.talles');                  -- 2b
SELECT id, nombre, atributos->>'$.ram_gb', atributos->>'$.gpu' FROM producto
WHERE atributos->'$.ram_gb' >= 16 AND atributos->>'$.gpu' <> 'integrada';              -- 2c
```
| Consulta | Resultado | Plan |
| :--- | :--- | :--- |
| 2a (tag `gaming`) | Notebook Titan 16, Monitor Game 32 | `Table scan on producto` (rows=20) |
| 2b (talle 42 dentro del array anidado) | Zapatilla Run X, Bota Trek Pro | `Table scan` |
| 2c (RAM ≥ 16 y GPU dedicada) | Notebook Titan 16 (32 GB, RTX 5070) | `Table scan` |

*Observación 2c:* el Ultrabook Air 13 tiene 16 GB pero **no tiene la clave `gpu`**: la ruta devuelve `NULL` y `NULL <> 'integrada'` no es verdadero, así que queda excluido. Con atributos opcionales hay que pensar explícitamente la semántica de las claves ausentes.

**Consulta 3 — Texto libre, sin la capacidad:**
```sql
SELECT id, nombre FROM producto WHERE descripcion LIKE '%gaming%' OR nombre LIKE '%gaming%';
-- Table scan on producto (cost=2.25 rows=20) — sin ranking

SELECT id FROM producto WHERE MATCH(nombre, descripcion) AGAINST('gaming');
-- ERROR 1191 (HY000): Can't find FULLTEXT index matching the column list
```
Sin índice `FULLTEXT`, InnoDB **rechaza** `MATCH()`, y la única alternativa (`LIKE '%…%'`) no puede usar ningún B-Tree porque el patrón empieza con comodín.

> **Evidencia 3 — Consultas sobre el catálogo (antes):** `[ACCIÓN REQUERIDA: Insertar captura de evidencias_salidas/04_consultas_antes.txt con Q1 (range scan), Q2a (table scan) y el ERROR 1191]`

### B.3. Intervención física

```sql
SET SESSION innodb_ft_user_stopword_table = 'sgbd_u7_act2/stopwords_es';
CREATE FULLTEXT INDEX ft_producto_texto ON producto (nombre, descripcion);
-- Warning 124: InnoDB rebuilding table to add column FTS_DOC_ID
CREATE INDEX idx_tags_mv ON producto ((CAST(tags AS CHAR(30) ARRAY)));
```

| Índice | Tipo | Estructura |
| :--- | :--- | :--- |
| `ft_producto_texto (nombre, descripcion)` | FULLTEXT | Índice invertido: término → lista de (doc_id, posición) |
| `idx_tags_mv` | BTREE multivaluado | Una entrada de B-Tree **por cada elemento** del array `tags` |

Inspección del índice invertido (`innodb_ft_aux_table = 'sgbd_u7_act2/producto'`):
- **289 términos** indexados. Los más frecuentes: `pulgadas` (7 docs), `litros` (5), `gb`, `ram`, `resolución`, `taller`, `wifi` (3).
- Siglas presentes: `4k`, `hp`, `hz`, `ms`, `tv`, `va`. Stopwords ausentes: `de`, `con`, `para`.
- `INNODB_FT_CONFIG` registra `stopword_table_name = sgbd_u7_act2/stopwords_es`: la lista queda **asociada al índice**.
- Costo fijo: el índice FULLTEXT se materializa en **11 tablas auxiliares** (`fts_<table_id>_index_1..6`, `deleted`, `being_deleted`, `config`…) que ocupan **1,2 MB para una tabla de 0,2 MB**.

> **Evidencia 4 — Habilitación sobre el caso:** `[ACCIÓN REQUERIDA: Insertar captura de evidencias_salidas/05_intervencion_fisica.txt — SHOW INDEX + Warning 124 + términos del índice]`

### B.4. Consultas después de la intervención

| Consulta | Resultado | Plan / observación |
| :--- | :--- | :--- |
| 2a `'gaming' MEMBER OF (tags)` | 2 filas | `Index lookup on producto using idx_tags_mv` (cost **2.25 → 0.70**) |
| 2a' `JSON_OVERLAPS(tags,'["gaming","oled"]')` | 3 filas | `Index range scan ... idx_tags_mv over ('oled' MEMBER OF) OR ('gaming' MEMBER OF)` |
| 3a natural `'notebook gaming RTX'` | Titan 16 **4,6927** · Atlas 14 **2,0** · Monitor Game 32 **1,0** | `Full-text index search on producto using ft_producto_texto` (cost 0.35). **Ranking por relevancia** |
| 3b booleano `'+gaming -notebook'` | Monitor Game 32 | operadores obligatorio/exclusión |
| 3b frase `'"alta frecuencia"'` | Titan 16, Monitor Game 32 | búsqueda por proximidad exacta |
| 3b comodín `'inalambr*'` | Taladro Pro 18V | prefijo (encuentra "inalámbrico") |
| 3c `'+TV +4K'` | Smart TV Nova 55, Smart TV Cinema 65 | **posible solo por la configuración de la Fase A** |
| 3d `'cafe'` | Cafetera Barista, Cafetera Filtro 12 | insensible a acentos (`utf8mb4_0900_ai_ci`): encuentra "café" |
| 3e híbrida: FTS + `precio <= 1.000.000` + `JSON_CONTAINS_PATH(atributos,'one','$.pulgadas')` | Smart TV Nova 55, Monitor Work 27, Monitor Game 32 | combina los **tres modelos** en una sentencia |
| 3f `'espresso' WITH QUERY EXPANSION` | 2 cafeteras + compresor, heladeras, freezer | **ruido**: la 2.ª pasada expande con términos como `litros`/`bar` |
| Límites: `'juego'` / `'juegos'` / `'notebok'` / `'juego*'` | 0 / 2 / 0 / 2 filas | sin stemming ni tolerancia a errores de tipeo; el comodín ayuda en parte |
| `LIKE '%gaming%'` con el índice ya creado | — | sigue siendo `Table scan`: **LIKE no usa el índice FULLTEXT** |

Consulta híbrida representativa:
```sql
SELECT id, nombre, precio, atributos->>'$.pulgadas' AS pulgadas, atributos->>'$.resolucion' AS resolucion,
       MATCH(nombre, descripcion) AGAINST('pulgadas resolución HDR QHD') AS relevancia
FROM producto
WHERE MATCH(nombre, descripcion) AGAINST('pulgadas resolución HDR QHD')
  AND precio <= 1000000
  AND JSON_CONTAINS_PATH(atributos, 'one', '$.pulgadas')
ORDER BY relevancia DESC;
```

### B.5. Medición y comparación a escala (200.000 productos)
Con 20 filas todo tarda menos de 2 ms y la comparación no dice nada. Replicamos el catálogo 10.000 veces en `producto_masivo` (200.000 filas, con un código `SKU` único por fila en la descripción) y medimos **antes** (sin FULLTEXT) y **después**:

| Métrica (200.000 filas) | ANTES: `LIKE '%…%'` | DESPUÉS: `MATCH … AGAINST` |
| :--- | :--- | :--- |
| **M1** término frecuente `gaming` (20.000 coincidencias) — tiempo | 0,32 – 0,63 s | **0,018 – 0,020 s** |
| M1 — `Handler_read_rnd_next` (filas leídas secuencialmente) | **200.001** | **0** |
| M1 — plan | `Table scan` (rows=208.187) → `Filter` | `Rows fetched before execution` (el COUNT se resuelve con el índice durante la optimización) |
| **M2** multi-término `notebook` + `gaming` + `RTX` | 0,52 – 0,56 s (3 LIKE sobre 200.000 filas) | **0,049 – 0,060 s** |
| **M3** código único `SKU0123457` (1 fila) — tiempo | 0,53 – 0,64 s | **0,001 – 0,005 s** |
| M3 — `EXPLAIN ANALYZE` (actual time) | 408..632 ms leyendo 200.000 filas | **0,04..0,09 ms** leyendo 1 fila |
| M3 — costo estimado del optimizador (`estimated_total_cost`) | **22.540,95** | **1,10** |
| M3 — `access_type` (EXPLAIN FORMAT=JSON) | `table` (scan completo) | `index` / `full_text_search` |
| Top-10 por relevancia `notebook gaming RTX` | **imposible** (LIKE no calcula relevancia) | 13,8 – 22,6 ms |

**Costos de la intervención (el otro lado de la balanza):**

| Costo | Medición |
| :--- | :--- |
| Construcción del índice sobre 200.000 filas | **50,2 – 50,7 s** (incluye reconstruir la tabla por `FTS_DOC_ID`, Warning 124) |
| `UPDATE` de la descripción en 20.000 filas | **0,60 s → 2,83 s** sin/con índice (×4,7; ×5,5 en la 2.ª corrida) |
| Espacio en disco | tabla 104 MB + índice FULLTEXT **58 – 67 MB** (+56 % a +64 %) en 11 tablas auxiliares |
| Vocabulario | 210.261 términos distintos (los SKU únicos inflan el diccionario) |
| Borrados lógicos tras el UPDATE | `INNODB_FT_DELETED` = **20.000** doc_ids pendientes de purga |
| `OPTIMIZE TABLE` (con `innodb_optimize_fulltext_only=ON`) | 10,7 s por pasada; procesa 2.000 términos (`innodb_ft_num_word_optimize`) → los 20.000 doc_ids **siguen pendientes**; harían falta ~105 pasadas |

> **Evidencia 5 — Comparación de planes y métricas:** `[ACCIÓN REQUERIDA: Insertar captura de evidencias_salidas/07_medicion_200k.txt — EXPLAIN ANALYZE de M3 antes (Table scan, 200000 rows) y después (Full-text index search, rows=1) + Handler_read_rnd_next 200001 vs 0]`

### B.6. Análisis del comportamiento del optimizador y de la E/S
1. **Por qué LIKE no escala:** con `'%texto%'` no hay prefijo fijo que permita recorrer un B-Tree. El optimizador elige `Table scan` y lee las 200.000 filas: `Handler_read_rnd_next = 200.001` y un costo de 22.541 que crece de forma lineal con la tabla. Además estimó 23.130 filas para un resultado real de 1, porque aplica una selectividad por defecto a los LIKE con comodín inicial.
2. **Por qué FTS sí:** el índice invertido va directo del **término** a la lista de documentos que lo contienen. El costo depende de cuántos documentos tienen el término, no del tamaño de la tabla. Para un SKU único se lee una sola entrada (costo 1,10, 0 lecturas secuenciales). Para `COUNT(*)` en modo booleano, MySQL resuelve el conteo con el índice antes de ejecutar (`Rows fetched before execution`).
3. **Escrituras más caras:** en InnoDB FTS un `UPDATE` sobre una columna indexada equivale a **borrado lógico + reinserción con un `FTS_DOC_ID` nuevo**. Los cambios pasan por la caché del índice (`innodb_ft_cache_size`), se sincronizan a las tablas auxiliares y dejan entradas en `INNODB_FT_DELETED` hasta un `OPTIMIZE`. Eso explica el ×4,7 en escritura y la necesidad de mantenimiento periódico.
4. **El objetivo no fue solo velocidad:** la diferencia cualitativa es que FTS ofrece capacidades que el modelo relacional con LIKE no tiene: **relevancia**, operadores booleanos, frases, prefijos, stopwords por idioma e insensibilidad a acentos.
5. **Límites observados:** no hay stemming en español (`AGAINST('juego')` → 0 filas, `'juegos'` → 2; el comodín `'juego*'` lo mitiga en parte → 2), ni sinónimos, ni tolerancia a errores de tipeo (`'notebok'` → 0 filas). La expansión de consulta agrega ruido. Bajar `min_token_size` obliga a mantener una lista de stopwords propia, y cambiar la configuración exige reiniciar el servidor y **reconstruir manualmente** cada índice.

---

## Fase C: Veredicto

### C.1. Matriz de decisión técnica

| Dimensión | ¿Extender el relacional alcanza? | ¿Cuándo tendría sentido un NoSQL especializado? |
| :--- | :--- | :--- |
| **Variabilidad del esquema** | **Sí.** El núcleo estable (`id`, `nombre`, `precio`, `stock`) queda tipado con `CHECK` y B-Tree; los 17 esquemas de atributos distintos entran en una columna `JSON` validada, consultable por rutas e indexable con índices multivaluados o columnas generadas. Sin `ALTER TABLE` por categoría nueva. | Cuando **todo** el agregado es variable y anidado en varios niveles, cambia en cada release y no existe un núcleo común que valga la pena tipar: ahí un almacén documental (MongoDB) evita la columna-documento. |
| **Patrón de consulta** | **Sí, para búsqueda por palabras clave.** FTS dio relevancia, modo booleano, frases y prefijos, con costo 1,10 frente a 22.541 y tiempos de ms frente a 0,5 s sobre 200.000 filas, combinado en la misma sentencia con filtros relacionales y JSON. | Cuando el buscador es **el producto**: stemming/análisis lingüístico en español, sinónimos, tolerancia a errores de tipeo, facetas y agregaciones, autocompletado o búsqueda semántica. Ahí conviene un motor de búsqueda (Elasticsearch/OpenSearch). |
| **Transacciones / Joins** | **Sí, y es la ventaja principal.** Precio, stock y descripción se actualizan en la misma transacción ACID de InnoDB. El índice FULLTEXT es transaccional (los cambios son visibles al `COMMIT`) y el catálogo puede hacer `JOIN` con pedidos, clientes o proveedores. | Rara vez en este caso. Un motor de búsqueda externo es *eventualmente consistente* con la fuente (indexación asíncrona, sin joins), por eso funciona como réplica de lectura y no como fuente de verdad del stock. |
| **Escala / Distribución** | **Sí, hasta el volumen de un catálogo comercial** (cientos de miles a pocos millones de productos) en un nodo con réplicas de lectura. Escalar escrituras sobre texto indexado es caro (×4,7 en UPDATE, índice de +56–64 % de espacio, `OPTIMIZE` periódico). | Con decenas de millones de documentos, alto volumen de escrituras de texto o búsqueda distribuida en varios nodos: sharding nativo y réplicas de índice son el terreno de los NoSQL de búsqueda. |
| **Complejidad operativa** | **Baja.** Un solo motor, un solo backup/PITR, un solo modelo de seguridad, sin paquetes extra. El costo real fue un `.cnf`, un reinicio, una tabla de stopwords y saber reconstruir el índice con dos `ALTER` separados. | Solo se justifica si el beneficio de búsqueda supera el costo de operar otro clúster: sincronización (CDC/colas), monitoreo, backups y seguridad duplicados, y resolución de inconsistencias entre la fuente y el índice. |

### C.2. Conclusión

Recomendamos **mantener el relacional extendido** como arquitectura del catálogo y dejar planificada una evolución **híbrida** solo si el buscador pasa a ser un diferencial del negocio. La evidencia muestra que MySQL 9.7 resuelve los tres patrones del caso dentro de un único motor transaccional: el núcleo estable se filtra con B-Tree (`Index range scan`), los atributos variables viven en JSON con índice multivaluado (de *table scan* a *index lookup*) y el texto libre se busca con un índice invertido FULLTEXT que, sobre 200.000 productos, bajó el costo estimado de 22.541 a 1,10 y el tiempo de más de 0,5 s a pocos milisegundos, además de agregar relevancia, operadores booleanos y frases que LIKE no tiene. Los costos medidos son reales pero acotados: índice de +56–64 % de espacio, UPDATE ×4,7, 50 s de construcción, reinicio para configurar y mantenimiento con OPTIMIZE. Incorporar un NoSQL de búsqueda tendría sentido si aparecen requisitos que InnoDB no cubre (stemming en español, tolerancia a errores de tipeo, facetas, búsqueda semántica o escala distribuida), siempre como réplica de lectura alimentada desde MySQL, que seguiría siendo la fuente de verdad de precio y stock.

---

## Uso de IA
Se utilizó un asistente de IA para organizar el script por secciones, interpretar la salida de `EXPLAIN FORMAT=JSON` (esquema 2.0 de MySQL 9.x) y diagnosticar dos comportamientos inesperados: el índice que no se reconstruía con `DROP INDEX, ADD FULLTEXT` en una sola sentencia, y la tabla `INNODB_FT_INDEX_TABLE` vacía mientras los términos estaban en `INNODB_FT_INDEX_CACHE`. Todas las afirmaciones se validaron contra el MySQL 9.7 Reference Manual (fuentes de la sección A.2) y contra salidas reales de nuestra instancia, guardadas en `evidencias_salidas/`.
