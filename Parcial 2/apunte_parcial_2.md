# Apunte guiado · Parcial 2 · Sistemas de Gestión de Bases de Datos (2026)

**Bloque temático 2: Bases de datos NoSQL y en la nube**
Unidades 7 a 10 · Datos semiestructurados y multimodelo (MySQL 9.7 y PostgreSQL 18), MongoDB, Redis, Cassandra, Neo4j, CAP y DBaaS

---

## Cómo usar este apunte

El segundo bloque sigue evaluando **criterio**, no sintaxis memorizada. Lo nuevo es que ya no alcanza con preguntar *cómo* se resuelve algo en un motor: hay que justificar **qué modelo de datos** conviene y **qué se paga** por elegirlo. El esquema de respuesta del Parcial 1 se amplía así:

> **Patrón de acceso → modelo y motor → garantía que ofrece → evidencia → costo de operarlo.**

**La base del apunte son las clases de la cátedra** (clases 7 a 10 de 2026). Cada unidad tiene dos partes:

1. **La clase, en su orden**: la pregunta disparadora, los conceptos, las tablas comparativas, los ejemplos de código de las diapositivas y la actividad propuesta con sus criterios de logro. Es lo primero que hay que dominar.
2. **La profundización con las resoluciones**: lo que se comprobó en las actividades (las nuestras y, en las Unidades 7 y 10, también las de otro grupo, que trabajó con PostgreSQL). Cada una empieza con un aviso "Desde acá, profundización...".

Dentro de cada tema se mantiene el formato del apunte del Parcial 1: **idea central**, **tablas comparativas**, **ejemplos**, **trampas frecuentes** (recuadros de advertencia) y **preguntas de repaso** al final de la unidad, primero las de la clase y después las de las actividades.

Al final están las **resoluciones de las actividades** y el **laboratorio integrador**, con lo que hay que saber explicar de cada uno. Para practicar con preguntas de opción múltiple está el [preguntero del Parcial 2](preguntas_simulacro_parcial_2.md).

> **Regla de oro de la cátedra, versión NoSQL:** un motor no se elige porque "es más rápido" o "es el más usado". Se elige porque el patrón de acceso lo pide, y la elección se **demuestra con evidencia**: un `explain`, un error de permiso esperado, un recuento antes y después de restaurar.

### Índice

- [Unidad 7 · Cuando el modelo relacional empieza a quedar corto](#unidad-7--cuando-el-modelo-relacional-empieza-a-quedar-corto)
- [Unidad 8 · MongoDB: de guardar JSON a diseñar agregados](#unidad-8--mongodb-de-guardar-json-a-diseñar-agregados)
- [Unidad 9 · Redis, Cassandra, Neo4j y CAP](#unidad-9--redis-cassandra-neo4j-y-cap)
- [Unidad 10 · Operar como servicio: DBaaS y Cloud](#unidad-10--operar-como-servicio-dbaas-y-cloud)
- [Integración: preguntas que cruzan unidades](#integración-preguntas-que-cruzan-unidades)
- [Chuleta de comandos por motor](#chuleta-de-comandos-por-motor)
- [Resoluciones de las actividades](#resoluciones-de-las-actividades)
- [Laboratorio integrador](#laboratorio-integrador)

### El hilo conductor del bloque

| Unidad (clase) | Pregunta disparadora de la clase | Idea que no hay que perder |
| :--- | :--- | :--- |
| 7 · Cuando el relacional empieza a quedar corto | ¿Por qué el modelo relacional deja de ser suficiente en algunos escenarios? | Cinco tensiones (estructura, jerarquía, relaciones, escala, acceso). Antes de sumar un motor, **ver si una extensión del relacional alcanza**: mantener, extender o complementar. |
| 8 · MongoDB | Si ya decidimos usar documentos, ¿cómo evitamos que MongoDB sea "tablas convertidas a JSON"? | Se diseña **desde los patrones de acceso**: lecturas, cambios y crecimiento. Lo que se lee y cambia junto, vive junto. Todo se **demuestra** con `explain()` y validación. |
| 9 · Redis, Cassandra, Neo4j y CAP | ¿Qué motor elegirías y por qué? | Tres modelos, tres preguntas: **clave**, **partición** y **recorrido**. NoSQL no significa "sin ACID", y CAP es un compromiso **ante una partición de red**, no un menú. |
| 10 · Operar como servicio (DBaaS) | Si el proveedor administra el servidor, los backups y la HA, ¿qué queda por administrar? | **Responsabilidad compartida:** el proveedor opera la plataforma; **los datos, el acceso, la recuperación probada y el costo siguen siendo del equipo**. DBaaS no elimina al DBA: eleva su nivel. |

### Puente con el Parcial 1

Casi todo lo del primer bloque reaparece con otro nombre. Conviene reconocerlo, porque las preguntas suelen mezclar ambos bloques:

| Concepto del Parcial 1 | Cómo reaparece en el Parcial 2 |
| :--- | :--- |
| Índice B-Tree, prefijo izquierdo | Índice multivaluado sobre arreglos JSON (U7), regla **ESR** de MongoDB (U8), clave de partición y clustering en Cassandra (U9) |
| `EXPLAIN ANALYZE` y lectura del plan | `explain("executionStats")` en MongoDB: `COLLSCAN`, `IXSCAN`, documentos examinados frente a devueltos |
| ACID, aislamiento, MVCC | ACID **por motor y por alcance** (documento, partición, comando), CAP, PACELC y consistencia eventual (U9) |
| Mínimo privilegio y roles | RBAC de MongoDB, ACL de Redis, roles de Cassandra, Neo4j Community sin roles, permisos de plataforma en Atlas |
| Backup, restore, PITR | `mongodump`/`mongorestore`, RDB en Redis, snapshot en Cassandra, dump offline en Neo4j, respaldo en Atlas |
| "Alta disponibilidad no es backup" | "La replicación de Atlas no es un respaldo": un borrado se replica a los tres nodos |
| Integridad declarativa (`CHECK`, FK) | `CHECK` con `JSON_SCHEMA_VALID()` (U7) y validador `$jsonSchema` (U8); en NoSQL la integridad referencial no es declarativa |

---

# Unidad 7 · Cuando el modelo relacional empieza a quedar corto

La unidad sigue la **clase 7** de la cátedra (*Datos semiestructurados, capacidades multimodelo y transición hacia NoSQL*). Las secciones 7.1 a 7.13 recorren la clase en su orden. Desde la 7.14 viene la **profundización**: lo que resolvieron los grupos en las actividades, con **MySQL 9.7** (nuestro grupo) y **PostgreSQL 18** (otro grupo), tema por tema y en los dos motores.

## 7.1 La pregunta de la unidad

> *¿Por qué el modelo relacional deja de ser suficiente en algunos escenarios?*

**Objetivo de la clase:** reconocer cuándo el modelo relacional empieza a generar **fricción**, explorar cómo MySQL y PostgreSQL incorporan capacidades no relacionales y justificar cuándo conviene **mantener, extender o complementar** el SGBD.

| Paso | Qué se hace |
| :--- | :--- |
| **1 · Identificar** | La tensión o limitación del escenario |
| **2 · Explorar** | Las capacidades extendidas del motor real |
| **3 · Decidir** | Relacional, relacional extendido o un modelo especializado |

No se busca reemplazar SQL. Se busca reconocer cuándo el problema pide **otra forma de representación o de acceso**.

### Las cinco tensiones

La unidad no parte de una tecnología nueva, sino de **tensiones concretas** del modelo que ya conocemos:

| Tensión | Qué pasa | Dónde se retoma |
| :--- | :--- | :--- |
| **Estructura** | La forma de los datos cambia con frecuencia | [7.3](#73-primera-tensión-el-esquema-se-vuelve-una-fricción), Unidad 8 |
| **Jerarquía** | Los datos llegan naturalmente anidados | [7.4](#74-tres-formas-de-mirar-los-datos) y [7.5](#75-relación-frente-a-agregado), Unidad 8 |
| **Relaciones** | Algunos recorridos requieren demasiados `JOIN` | Modelo de grafos ([7.12](#712-qué-significa-nosql)), Neo4j en la Unidad 9 |
| **Escala** | Una sola instancia deja de alcanzar | [7.10](#710-segunda-tensión-una-instancia-deja-de-alcanzar), Cassandra en la Unidad 9 |
| **Acceso** | El patrón de consulta no tiene forma tabular | Clave-valor y *wide-column* ([7.12](#712-qué-significa-nosql)), Unidad 9 |

## 7.2 El relacional sigue siendo excelente

NoSQL no invalida nada de lo aprendido en el Bloque 1:

| Fortaleza | Qué aporta |
| :--- | :--- |
| **ACID** | Transacciones y reglas fuertes |
| **Integridad** | Claves foráneas, restricciones y consistencia estructural |
| **SQL** | Lenguaje declarativo y un optimizador maduro |
| **Operación** | Respaldo, seguridad, concurrencia y alta disponibilidad resueltos |

> El punto de partida profesional no es "SQL contra NoSQL", sino **¿qué parte del problema representa mejor cada modelo?**

## 7.3 Primera tensión: el esquema se vuelve una fricción

> *Un catálogo empieza simple, pero cada categoría agrega atributos distintos. Una notebook tiene RAM, CPU, GPU, pantalla y batería; una heladera, litros, no frost, puertas y eficiencia; un calzado, talle, color, material y temporada. ¿Una tabla por categoría? ¿80 columnas opcionales? ¿EAV? ¿Un documento flexible?*

| Opción | Cómo es | Problema |
| :--- | :--- | :--- |
| **Una tabla por categoría** | `notebook`, `heladera`, `calzado`... | Cada categoría nueva es una tabla nueva; listar "todos los productos" exige un `UNION` |
| **Tabla ancha** (80 columnas opcionales) | Una columna por cada atributo posible | La mayoría de las celdas quedan en `NULL`; cada atributo nuevo es un `ALTER TABLE` |
| **EAV** (entidad-atributo-valor) | Una tabla `(producto_id, atributo, valor)` con todo en texto | Sin tipos ni restricciones; filtrar por dos atributos exige un `JOIN` por cada uno |
| **Documento flexible** | Los atributos variables en un documento JSON | Hay que validar e indexar de otra forma (es lo que explora la unidad) |

**Cómo aparece la fricción:** el esquema estable se llena de columnas `NULL`; los cambios se vuelven frecuentes; cada cambio es una migración, y las migraciones constantes frenan al equipo. Pero no todo dato variable exige NoSQL:

| | Caso A · Esquema estable | Caso B · Cambios frecuentes |
| :--- | :--- | :--- |
| Situación | La estructura es estable y las relaciones e invariantes dominan el problema | Los atributos cambian por entidad y el agregado se consume como una unidad |
| Decisión | **El relacional funciona muy bien** | **Conviene flexibilizar** esa parte del esquema |

> La flexibilidad es una **tensión de diseño**, no una excusa para abandonar la integridad y las transacciones.

A la tensión del esquema se suma la **búsqueda por palabras**: `WHERE descripcion LIKE '%inalambrico%'` recorre la tabla completa y no ordena por relevancia. Es la otra necesidad del catálogo que las actividades resolvieron con índices de texto completo ([7.17](#717-full-text-search-el-índice-invertido)).

## 7.4 Tres formas de mirar los datos

La estructura observable de los datos condiciona cómo se representan y se consultan:

| Tipo | Qué tiene | Ejemplos |
| :--- | :--- | :--- |
| **Estructurados** | Esquema explícito y estable | Tablas, columnas, tipos, restricciones |
| **Semiestructurados** | Estructura presente, pero **flexible o anidada** | XML, JSON, eventos |
| **No estructurados** | Ninguna estructura interna utilizable directamente | Texto libre, imagen, audio o video: requieren otras técnicas de interpretación |

> **Semiestructurado no significa "sin estructura"**: significa estructura flexible, **autocontenida** (cada dato describe sus propios campos) o variable.

### XML: el antecedente importante

```xml
<producto id="10">
  <nombre>Notebook</nombre>
  <atributos>
    <ram unidad="GB">32</ram>
    <gpu>RTX</gpu>
  </atributos>
</producto>
```

- Es un **árbol** de elementos anidados con atributos (`id="10"`, `unidad="GB"`).
- Es **autodescriptivo** y **validable**: un **XSD** (*XML Schema*) puede imponer estructura y tipos.
- Sigue siendo relevante en **integraciones empresariales, mensajería y sistemas heredados**.

### JSON: estructura flexible para aplicaciones modernas

```json
{
  "producto": "Notebook",
  "marca": "X",
  "atributos": { "ram": 32, "gpu": "RTX" },
  "tags": ["gaming", "portable"]
}
```

- Un **objeto** es un conjunto de pares clave-valor; un **array** es una colección ordenada de valores. Los dos se pueden anidar.
- Es más liviano que XML y es el formato nativo de las aplicaciones web. Su equivalente al XSD es **JSON Schema**.

> **JSON es una representación**: no es por sí mismo un modelo de base de datos ni una arquitectura NoSQL. Un motor relacional puede guardar JSON, y un motor NoSQL puede no usarlo.

## 7.5 Relación frente a agregado

La pregunta de diseño cambia: **¿qué datos se usan juntos?**

| | Modelo relacional | Agregado documental |
| :--- | :--- | :--- |
| Forma | `CLIENTE`, `PEDIDO`, `ITEM` y `PRODUCTO` en tablas separadas | Un objeto autocontenido: el pedido con su cliente y sus ítems adentro |
| Cómo se lee | `JOIN` entre tablas | Una sola lectura |
| Qué garantiza | Reglas entre tablas (FK, restricciones) | Que el agregado se lee y se escribe como una unidad |
| Se diseña para | Cualquier consulta futura | **Un patrón de acceso** concreto |

```json
{
  "pedido": 8123,
  "cliente": { "id": 42, "nombre": "Ana" },
  "items": [ { "sku": "A1", "cant": 2 }, { "sku": "B7", "cant": 1 } ]
}
```

La pregunta clave del agregado es **qué hay que preservar**: si el pedido se consume siempre completo, conviene guardarlo junto. Es la idea que la Unidad 8 desarrolla con MongoDB.

### JSON no resuelve todo

La flexibilidad de esquema es **solo una** de las tensiones:

| | Tensión | Qué pide |
| :--- | :--- | :--- |
| ✓ **JSON ayuda** | Atributos variables, jerarquía, propiedades opcionales | Un documento |
| ✗ Distribución | Los datos viven en varios nodos | Particionado y replicación |
| ✗ Recorridos | Relaciones profundas o conectividad | Un grafo |
| ✗ Caché | Acceso mínimo por clave | Clave-valor en memoria |
| ✗ Escala | Patrones masivos y particionados | *Wide-column* |

> NoSQL no puede reducirse a "guardar JSON": **distintos problemas empujan hacia distintos modelos**.

## 7.6 Cómo reaccionan los SGBD relacionales

Las fronteras entre familias se vuelven menos rígidas. Los motores relacionales fueron sumando capas:

```text
Tablas + SQL → Tipos extendidos → JSON / arrays → Índices especializados → APIs / vistas documentales
└── RDBMS clásico ──┘└──────────── RDBMS extendido: capacidades multimodelo ────────────┘
```

> **Idea clave:** los motores relacionales modernos absorben patrones documentales, clave-valor, texto completo y espacial **sin dejar de ser relacionales**.

### Multimodelo no es lo mismo que persistencia políglota

| | **Base multimodelo** | **Persistencia políglota** |
| :--- | :--- | :--- |
| Qué es | **Un solo motor** que soporta varios modelos: relacional, documentos JSON, texto, espacial | **Varios motores**, cada uno donde mejor encaja |
| Ejemplo | MySQL 9 con `JSON`, índices multivaluados, Document Store y `FULLTEXT`; PostgreSQL con `JSONB`, arreglos, `hstore`, `tsvector` y PostGIS | Un relacional para pedidos, Redis para sesiones y Neo4j para recomendaciones |
| Ventaja | Una sola seguridad, un solo respaldo, un solo optimizador, transacciones que abarcan todo | Cada dato en el motor óptimo para su patrón |
| Costo | El motor no es el mejor en cada modelo | Operar, asegurar, respaldar e **integrar** varios motores (Unidad 9) |

> La Unidad 7 responde una pregunta previa a la Unidad 9: **¿el motor que ya tengo alcanza?** Si alcanza, no se suma otro.

**Dos estilos de motor multimodelo:**

- **MySQL** suma modelos **dentro del núcleo**: el tipo `JSON`, los índices multivaluados, `FULLTEXT`, los datos espaciales y el Document Store (que necesita un cliente aparte).
- **PostgreSQL** es **extensible por diseño**: trae varios tipos no relacionales en el núcleo (`JSONB`, arreglos, `tsvector`) y el resto se agrega con `CREATE EXTENSION` (`hstore`, `pg_trgm`, `unaccent`, `btree_gin`, PostGIS). Por eso en su radar aparecen más capacidades **habilitables**.

## 7.7 MySQL 9.7: del JSON nativo al Document Store

### JSON nativo

```sql
CREATE TABLE producto (
  id        BIGINT PRIMARY KEY,
  nombre    VARCHAR(100),
  atributos JSON
);

SELECT nombre, atributos->>'$.marca' FROM producto;
```

- **Validar:** el tipo `JSON` garantiza que lo guardado es JSON válido (si no, rechaza el `INSERT`).
- **Consultar:** rutas (`'$.marca'`) y funciones acceden a las propiedades internas.

> Seguimos dentro de una tabla: la flexibilidad aparece **en una parte del esquema**, no desaparece el modelo relacional.

### De dato flexible a acceso eficiente

Una propiedad interna que se consulta seguido puede convertirse en una **decisión de diseño físico**: se expone como columna generada y se indexa.

```sql
ALTER TABLE producto
  ADD marca VARCHAR(50) GENERATED ALWAYS AS (atributos->>'$.marca');
CREATE INDEX ix_producto_marca ON producto (marca);
```

```text
atributos JSON → propiedad frecuente → columna generada → índice → plan
```

> **Conexión con la Unidad 2:** un índice solo tiene sentido frente a un **patrón de consulta**, y tiene un costo de escritura y mantenimiento. El detalle (índices funcionales, multivaluados) está en [7.16](#716-índices-sobre-json-en-detalle).

### Document Store

El mismo servidor expone **un modo de trabajo documental**:

```text
Cliente / aplicación ── X DevAPI (MySQL Shell o conectores)
        │
        ▼  X Protocol (puerto 33060)
MySQL Server ── X Plugin ── Collections + Documents
```

| Pieza | Qué es |
| :--- | :--- |
| **X Plugin** | Componente del servidor que atiende el protocolo documental (`mysqlx`) |
| **X Protocol** | El protocolo, en el puerto **33060**; el protocolo SQL clásico sigue en el **3306** |
| **X DevAPI** | La API de los clientes: MySQL Shell (`mysqlsh`) y los conectores oficiales |
| **Collection** | Un conjunto de documentos JSON, con CRUD documental |

Ofrece **CRUD documental sin abandonar las capacidades ACID** del servidor.

> **MySQL no se convierte en MongoDB:** ofrece una interfaz documental **adicional** sobre el mismo motor. Por dentro, una colección es una tabla InnoDB con una columna `doc` de tipo `JSON` y un `_id` generado.

**Cómo lo resolvimos (U7 · A1):** en MySQL 9.7.2, `SHOW PLUGINS` mostró `mysqlx` activo y el servidor escuchaba en 3306 y en 33060. El X Plugin es **Core**, pero el cliente SQL común no habla X Protocol: hace falta **MySQL Shell** o un conector. Por eso la capacidad quedó clasificada como **Extensión / Plugin / Cliente**.

```javascript
// mysqlsh <usuario>@localhost:33060 --js   (la clave se pide por teclado)
var col = db.createCollection('productos')
col.add({ nombre: 'Notebook', atributos: { ram: 32, gpu: 'RTX' } })
col.find("atributos.ram >= 16")
col.modify("nombre = 'Notebook'").set('atributos.ram', 64)
col.remove("nombre = 'Notebook'")
```

### Más allá de una columna JSON

| Capacidad | Qué hace |
| :--- | :--- |
| **JSON Duality Views** | Mapean tablas relacionales a documentos JSON jerárquicos y permiten **leer y escribir con los dos modelos** |
| **Document Store** | Collections, Documents, X DevAPI y X Protocol |
| **Full Text** | Búsqueda textual con índices especializados ([7.17](#717-full-text-search-el-índice-invertido)) |
| **Spatial** | Tipos geométricos, GeoJSON e índices espaciales |

> La frontera más interesante de MySQL 9.7 son las **JSON Duality Views**: unifican la representación relacional y la jerárquica **sin duplicar los datos**. Los datos viven en tablas normalizadas (con PK y FK) y la vista los presenta como documentos.

**Cómo lo resolvimos (U7 · A1):**

- **Duality Views:** disponibles en el **Core** de MySQL 9.7.2 Community, para lectura y, con la anotación `WITH (INSERT, UPDATE, DELETE)`, también para escritura. Se definen con `CREATE JSON DUALITY VIEW ... AS SELECT JSON_DUALITY_OBJECT(...)`; el documento raíz expone la clave primaria como `_id`. La evidencia fue el soporte registrado en el diccionario de datos (`INFORMATION_SCHEMA`).
- **Spatial:** **Core** de InnoDB. Para usar un `SPATIAL INDEX` (árbol R-Tree), la columna geométrica debe ser `NOT NULL` y declarar un sistema de referencia (`SRID 4326`, las coordenadas GPS). Convierte desde y hacia GeoJSON (`ST_GeomFromGeoJSON`) y mide distancias con `ST_Distance_Sphere`.
- **Full Text:** **Core** (índice `FULLTEXT` y parser `ngram`); ajustar el tamaño mínimo de palabra o las *stopwords* lo vuelve **Habilitable**.

```sql
-- Sintaxis de referencia de una vista de dualidad (MySQL 9)
CREATE JSON DUALITY VIEW pedido_dv AS
SELECT JSON_DUALITY_OBJECT( WITH (INSERT, UPDATE, DELETE)
         '_id'     : p.id,
         'cliente' : p.cliente,
         'items'   : (SELECT JSON_ARRAYAGG(JSON_DUALITY_OBJECT( WITH (INSERT, UPDATE, DELETE)
                                 'sku' : i.sku, 'cant' : i.cantidad))
                      FROM item i WHERE i.pedido_id = p.id) )
FROM pedido p;
```

## 7.8 PostgreSQL 18: JSON, JSONB y extensibilidad

### `json` y `jsonb`

Dos representaciones **similares en la entrada y distintas en el procesamiento**:

| | `json` | `jsonb` |
| :--- | :--- | :--- |
| Qué guarda | Una **copia del texto** de entrada | Una representación **descompuesta, binaria** |
| Procesamiento | Debe **reprocesarse** en muchas operaciones | Más eficiente |
| Formato | Preserva espacios, orden de claves y claves duplicadas | No conserva el orden; ante una clave repetida, se queda con la **última** |
| Indexación general | No | **Sí** (`GIN`) |

> Para la mayoría de las aplicaciones que **consultan el contenido**, la documentación de PostgreSQL recomienda **preferir `jsonb`**. `json` solo conviene si hay que devolver el texto exactamente como llegó. Usar `json` "porque se llama igual que en MySQL" deja la columna sin índice general.

### `JSONB` + `GIN`

```sql
CREATE TABLE producto (
  id        BIGSERIAL PRIMARY KEY,
  atributos JSONB
);
CREATE INDEX idx_producto_json ON producto USING GIN (atributos);
```

Un **índice invertido** permite buscar claves, valores y **contención** dentro de muchos documentos. En lugar de ordenar valores completos, guarda **cada componente** con la lista de filas donde aparece:

```text
documento { marca: "X", tags: ["rojo", "portable"] }
GIN:  marca → filas   X → filas   rojo → filas   portable → filas
```

> El documento sigue dentro de una fila, pero el acceso interno **ya no se parece a un B-Tree por columna**. Las clases de operadores, qué consultas lo usan y cuáles no, en [7.16](#716-índices-sobre-json-en-detalle).

### Más allá del documento

La **extensibilidad** permite incorporar otros patrones dentro del mismo SGBD:

| Capacidad | Qué es | Ejemplo |
| :--- | :--- | :--- |
| **Arrays** | Colecciones nativas dentro de una fila, con operadores de pertenencia y contención | `tags text[]`, `tags @> ARRAY['gaming']` |
| **hstore** | Extensión **clave-valor** para pares de texto, con operadores e índices | `CREATE EXTENSION hstore;` · `'color=>rojo, talle=>42'::hstore -> 'color'` |
| **Full Text** | Tokenización, `tsvector` y búsqueda indexada | `to_tsvector('spanish', descripcion) @@ to_tsquery('spanish', 'juego')` |
| **Extensiones** | Tipos, funciones e índices adicionales según el problema | `pg_trgm`, `unaccent`, `btree_gin`, PostGIS |

> PostgreSQL se aproxima al multimodelo principalmente por **tipos, operadores, índices y extensiones integradas al SQL**; MySQL, además, por una **API documental** aparte.

## 7.9 Dos caminos para extender el relacional

MySQL y PostgreSQL resuelven tensiones similares con **mecanismos diferentes**:

| Capacidad | MySQL 9.7 | PostgreSQL 18 |
| :--- | :--- | :--- |
| Documento | `JSON` | `json` / `jsonb` |
| API o modelo documental | Document Store + X DevAPI | SQL + tipos y extensiones |
| Índice documental | Columnas generadas, índices funcionales y multivaluados | `GIN` sobre `jsonb` |
| Clave-valor | Documento JSON | `hstore` |
| Full Text | Sí (`FULLTEXT`) | Sí (`tsvector`) |
| Spatial | Sí (nativo) | Tipos + extensiones (PostGIS) |

> **Mismo problema de ingeniería, mecanismos distintos:** comparar capacidades, no memorizar nombres.

## 7.10 Segunda tensión: una instancia deja de alcanzar

La flexibilidad del esquema **no resuelve** el crecimiento, la distribución ni la latencia global.

| | Qué es | Límite |
| :--- | :--- | :--- |
| **Escalar verticalmente** (*scale up*) | Más CPU, RAM o almacenamiento en el **mismo servidor** | Tiene techo y costo creciente |
| **Escalar horizontalmente** (*scale out*) | **Más nodos** que comparten datos y carga | Aparece la nueva pregunta |

**La nueva pregunta:** ¿cómo particiono, replico y mantengo una visión consistente? Distribuir no es solamente agregar servidores: **cambia el problema** de consistencia, particionado y operación.

### Replicación: copias para disponibilidad y lectura

Un concepto de la Unidad 6 que reaparece como **pieza estructural** de los sistemas distribuidos: un nodo **primario (líder)** y nodos **réplica** con copias.

| Beneficio | Costo | Decisión |
| :--- | :--- | :--- |
| Disponibilidad, lectura y recuperación | Red, almacenamiento y operación de las réplicas | Síncrona, asíncrona, quórum u otro mecanismo según el motor |

### Sharding: una sola base lógica, varios fragmentos

**Particionar horizontalmente**: una **clave de partición** (*shard key*) reparte el conjunto de datos entre nodos. Por ejemplo, por rango: shard A con las claves 0 a 33, B con 34 a 66 y C con 67 a 99.

| Ventaja | Riesgo | Costo |
| :--- | :--- | :--- |
| Crece horizontalmente y reparte almacenamiento y carga | **Una mala *shard key*** concentra el tráfico en un fragmento (*hotspot*) o complica las consultas | Consultas que cruzan fragmentos (*cross-shard*), rebalanceo y operación distribuida |

| | Replicación | Sharding |
| :--- | :--- | :--- |
| Cada nodo tiene | **Todos** los datos | **Una parte** de los datos |
| Resuelve | Disponibilidad y escala de **lectura** | Volumen y escala de **escritura** |
| En la práctica | Se combinan: cada fragmento suele ser a su vez un conjunto replicado | |

## 7.11 ACID, BASE y CAP

### ACID y BASE no son etiquetas de familias

| | ACID | BASE |
| :--- | :--- | :--- |
| Qué es | Propiedades que describen **transacciones**: atomicidad, consistencia, aislamiento y durabilidad | Enfoque **histórico** de algunos sistemas distribuidos: *Basically Available, Soft state, Eventual consistency* |
| Prioriza | Que cada transacción sea correcta | Responder siempre y que las copias converjan con el tiempo |

> **Trampa:** "SQL = ACID / NoSQL = BASE" es una simplificación. Hoy existen motores NoSQL con transacciones fuertes (MongoDB, Neo4j) y motores relacionales distribuidos con distintos compromisos de consistencia.

### CAP: cuando la red falla, aparece una decisión

En presencia de una **partición real** de la red, un sistema distribuido debe decidir cómo balancear consistencia y disponibilidad.

| Letra | Significado |
| :--- | :--- |
| **C** · Consistencia | Todos los clientes observan una visión coherente del dato según el modelo del sistema |
| **A** · Disponibilidad | Cada solicitud recibe una respuesta útil, aun cuando algunos nodos no estén disponibles |
| **P** · Partición | La red puede separar nodos; el sistema debe seguir operando bajo esa condición |

**La pregunta útil:** si dos grupos de nodos no pueden comunicarse, ¿respondemos con datos **potencialmente desactualizados**, o esperamos y rechazamos operaciones para **proteger la consistencia**? La formulación precisa y sus malentendidos se profundizan en la clase 9 ([9.8](#98-cap-formulación-correcta)).

## 7.12 ¿Qué significa NoSQL?

> Sistemas que utilizan **modelos de datos distintos o complementarios** al relacional y suelen optimizar **flexibilidad, distribución o patrones específicos de acceso**. Es una familia de sistemas, no una única tecnología.

| NoSQL... | |
| :--- | :--- |
| **No significa** | "Sin SQL" necesariamente (Cassandra tiene CQL; muchos traducen SQL) |
| **No garantiza** | Que no existan transacciones |
| **No elimina** | El diseño ni los *trade-offs* |
| **Sí exige** | Pensar desde el **patrón de datos y de acceso** |

### No existe "el modelo NoSQL": cuatro familias

| Familia | Idea | Cuándo | Referencia |
| :--- | :--- | :--- | :--- |
| **Clave-valor** | Una clave identifica un valor; acceso directo con mínimo *overhead* | Sesión (estado temporal), caché (lectura muy frecuente), contador (actualización simple). Ej.: `session:9f13 → { usuario: 42, carrito: 8, expira: ... }` | Redis |
| **Documental** | Documentos jerárquicos y agregados flexibles | Cuando el agregado es la unidad natural de lectura y escritura; los documentos de una colección pueden variar **controladamente** | MongoDB (Unidad 8) |
| ***Wide-column*** | Partición y columnas orientadas al patrón de acceso distribuido | Cuando el particionado y el acceso distribuido dominan el diseño (`cliente=10 → ts, evento, valor`) | Cassandra |
| **Grafo** | Nodos, relaciones y recorridos como elementos de primera clase | "¿Qué caminos conectan estas entidades?": recorridos y relaciones variables | Neo4j |

> **Trampa:** *wide-column* **no** es lo mismo que un *column-store* analítico (que guarda por columnas para agregar rápido). En *wide-column* el diseño gira alrededor de la **partición, la distribución y las consultas previstas**.

### Un mismo sistema puede tener varios problemas

| Necesidad | Modelo |
| :--- | :--- |
| Pedidos y pagos | Relacional |
| Catálogo flexible | Documental |
| Sesión y carrito | Clave-valor |
| Eventos masivos | *Wide-column* |
| Fraude y conexiones | Grafo |

Una arquitectura profesional puede **conservar el relacional donde aporta valor** y complementar solo donde aparece una necesidad distinta. Eso es la **persistencia políglota**: muchas veces no se reemplaza el relacional, se complementa.

### El árbol de decisión

```text
¿El relacional representa bien el problema?
├── SÍ → mantener el relacional
└── NO → ¿alcanza una extensión del motor?
        ├── SÍ → JSONB, Document Store, Full Text, Spatial...
        └── NO → modelo especializado (documental, clave-valor, wide-column, grafo)
```

> **Pregunta de cierre de la clase:** ¿estamos eligiendo tecnología **por moda** o porque el problema realmente pide otro modelo?

## 7.13 La actividad: ¿hasta dónde puede llegar nuestro motor relacional?

Cada grupo convirtió su instancia del Bloque 1 en un **laboratorio multimodelo**. No había receta: había que localizar documentación oficial, verificar qué trae la edición Community, habilitar lo necesario y construir evidencia.

```text
1 Descubrir → 2 Habilitar → 3 Probar → 4 Medir → 5 Decidir
qué trae la    plugin,       un escenario   consulta,   ¿alcanza o
versión        extensión,    no puramente   plan o      necesitamos
instalada      índice        tabular        evidencia   NoSQL?
```

**Núcleo obligatorio por motor:**

| MySQL 9.7 Community | PostgreSQL 18 Community |
| :--- | :--- |
| Verificar X Plugin / X Protocol | Crear documentos `JSONB` |
| Usar Document Store y una Collection | Construir y probar un índice `GIN` |
| Investigar JSON Duality Views si están disponibles | |
| **Capacidad adicional:** Full Text, Spatial o indexación JSON | **Capacidad adicional:** arrays, `hstore`, Full Text u otra extensión justificable |

> La investigación es parte de la actividad: documentar **qué es core, qué es plugin o extensión y qué requiere instalación adicional**.

### El radar multimodelo

| Clasificación | Significado |
| :--- | :--- |
| **Core** | Disponible de forma nativa, sin instalar nada |
| **Habilitable** | Viene con el motor, pero requiere activación o configuración |
| **Extensión / Plugin / Cliente** | Requiere componentes o clientes adicionales |
| **No disponible** | El entorno no lo permite: se explica la limitación |

| Capacidad | MySQL 9.7 | PostgreSQL 18 |
| :--- | :--- | :--- |
| Documentos JSON | `JSON` nativo: **Core** | `json` y `JSONB`: **Core** |
| Índice para documentos | Generado, funcional y multivaluado: **Core** | `GIN` (`jsonb_ops`, `jsonb_path_ops`): **Core** |
| Document Store | X Plugin activo en el puerto 33060, pero hace falta **MySQL Shell** (`mysqlsh`) o un conector de X Protocol: **Extensión/Plugin/Cliente** | No aplica |
| Arreglos | Arreglos JSON con índice multivaluado: **Core** | Arreglos nativos (`text[]`): **Core** |
| Clave-valor | Dentro de JSON | `hstore`: **Habilitable** (viene en `contrib`; se activa con `CREATE EXTENSION hstore`) |
| Texto completo | `FULLTEXT`: **Core**; ajustar el tamaño mínimo o las *stopwords* lo vuelve **Habilitable** | `tsvector`, `tsquery`, configuración `spanish`: **Core** |
| Búsqueda difusa, acentos | No | `pg_trgm`, `unaccent`: **Habilitable** (`contrib`) |
| Índices mixtos escalar + documento | No aplica | `btree_gin`: **Habilitable** (`contrib`) |
| Espacial | `GEOMETRY`, `SPATIAL INDEX` (R-Tree), `ST_Contains`: **Core** | PostGIS: **Extensión** (paquete del sistema operativo + `CREATE EXTENSION postgis`); en la instancia del otro grupo, **No disponible** |
| Vistas de dualidad JSON | `CREATE JSON DUALITY VIEW`: **Core** en MySQL 9 | No aplica |

**Cómo se demuestra cada clasificación** (la evidencia es un comando, no una cita del manual):

| Qué se quiere probar | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Versión | `SELECT VERSION();` | `SELECT version();` |
| El tipo existe | `SELECT JSON_TYPE('{"a":1}');` | `SELECT typname FROM pg_type WHERE typname IN ('json','jsonb');` |
| El método de índice existe | `SHOW INDEX` tras crearlo | `SELECT amname FROM pg_am WHERE amname = 'gin';` |
| Qué se puede habilitar | `SHOW PLUGINS;` · `SHOW VARIABLES LIKE 'innodb_ft%';` | `SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name IN ('hstore','pg_trgm','postgis');` |
| Qué está habilitado | `SHOW PLUGINS` (`mysqlx` en `ACTIVE`) | `SELECT extname, extversion FROM pg_extension;` |

En PostgreSQL, `pg_available_extensions` distingue los tres casos de un vistazo: con `installed_version` vacío la extensión es **habilitable**; con versión, ya está **activa**; si la fila no aparece, el paquete **no está instalado** en el sistema operativo.

> La consigna pedía que la capacidad elegida para la segunda fase **no fuera solo guardar JSON en una columna con `SELECT` simples**: tenía que usar algo avanzado (multivaluados, `GIN` con contención, Full-Text, Document Store).

### Qué se evaluaba

La meta no era "hacer funcionar una *feature*", sino **justificar qué problema resuelve y qué costo introduce**:

| 1 · Problema | 2 · Capacidad | 3 · Evidencia | 4 · Costo | 5 · Veredicto |
| :--- | :--- | :--- | :--- | :--- |
| Qué limitación del relacional se intenta resolver | Qué se instaló o habilitó y cómo funciona | Consulta, documento, plan, captura o medición **reproducible** | Complejidad, mantenimiento, escritura, portabilidad u operación | ¿Alcanza la capacidad o conviene un motor NoSQL especializado? |

| Logrado | Parcial | No logrado |
| :--- | :--- | :--- |
| Implementa, demuestra y justifica con evidencia y costos | La capacidad funciona, pero la decisión o la evidencia es incompleta | No demuestra el funcionamiento o no puede explicar la relación problema-capacidad |

## 7.14 Consultar y modificar JSON en los dos motores

> **Desde acá, profundización con las resoluciones.** Lo que sigue amplía la clase con lo que los grupos resolvieron en la segunda actividad (catálogo con JSON y búsqueda de texto completo).

La diferencia de sintaxis más visible: **MySQL usa rutas** (`'$.marca'`) y **PostgreSQL usa nombres de clave** (`'marca'`).

| Qué se quiere | MySQL | PostgreSQL (`JSONB`) |
| :--- | :--- | :--- |
| Valor JSON de una clave | `doc->'$.marca'` (o `JSON_EXTRACT`) | `doc->'marca'` |
| Texto de una clave | `doc->>'$.marca'` | `doc->>'marca'` |
| Clave anidada | `doc->>'$.pantalla.hz'` | `doc->'pantalla'->>'hz'` o `doc#>>'{pantalla,hz}'` |
| Elemento de un arreglo | `doc->>'$.tags[0]'` | `doc->'tags'->>0` |
| ¿Existe la clave? | `JSON_CONTAINS_PATH(doc, 'one', '$.gpu')` | `doc ? 'gpu'` (también `?\|` "alguna" y `?&` "todas") |
| ¿Contiene este par o este elemento? | `JSON_CONTAINS(doc, '16', '$.ram_gb')` | `doc @> '{"ram_gb": 16}'` |
| Agregar o reemplazar una clave | `JSON_SET(doc, '$.gpu', 'RTX')` | `jsonb_set(doc, '{gpu}', '"RTX"')` o `doc \|\| '{"gpu": "RTX"}'` |
| Quitar una clave | `JSON_REMOVE(doc, '$.gpu')` | `doc - 'gpu'` |
| Tamaño de un arreglo | `JSON_LENGTH(doc, '$.tags')` | `jsonb_array_length(doc->'tags')` |
| Arreglo a filas | `JSON_TABLE(...)` | `jsonb_array_elements(...)`; `JSON_TABLE` desde la versión 17 |
| Condición con *jsonpath* | — | `doc @? '$.ram_gb ? (@ >= 16)'` |

El **operador de contención `@>`** es el corazón del modelo documental en PostgreSQL. Pregunta "¿el documento de la izquierda contiene al de la derecha?", sirve para objetos y arreglos y se puede indexar:

```sql
SELECT '{"categoria": "notebook", "ram_gb": 16}'::jsonb @> '{"ram_gb": 16}';  -- true
SELECT '["gaming", "portable"]'::jsonb @> '["gaming"]';                       -- true
SELECT '{"talles": [40, 41, 42]}'::jsonb -> 'talles' @> '[41]';               -- true
```

### Trampa: los tipos dentro del documento

- En los dos motores, `->>` devuelve **texto**. En PostgreSQL, para comparar números hay que convertir: `(atributos->>'ram_gb')::int >= 16`. Si algún documento guarda ese valor como texto no numérico, **la consulta entera falla** con `invalid input syntax for type integer`.
- La contención **respeta el tipo**: `{"ram_gb": 16}` no está contenido en `{"ram_gb": "16"}`. Si la carga mezcla números y textos, `@>` deja afuera filas sin avisar.

### Trampa: las claves ausentes

```sql
-- Tres notebooks: gpu "integrada", gpu "RTX 4060" y un ultrabook SIN la clave gpu
SELECT nombre FROM producto WHERE atributos->>'$.gpu' <> 'integrada';  -- MySQL
SELECT nombre FROM producto WHERE atributos->>'gpu'   <> 'integrada';  -- PostgreSQL
-- Los dos devuelven solo la de RTX
```

En el ultrabook la clave devuelve `NULL`, y `NULL <> 'integrada'` no es verdadero: es desconocido, y el `WHERE` lo descarta. Es la lógica de tres valores del Parcial 1 aplicada a JSON. Para incluirlo hay que pedirlo:

| Motor | Forma explícita | Forma segura con `NULL` |
| :--- | :--- | :--- |
| MySQL | `... OR atributos->>'$.gpu' IS NULL` | `NOT (atributos->>'$.gpu' <=> 'integrada')` |
| PostgreSQL | `... OR atributos->>'gpu' IS NULL` | `atributos->>'gpu' IS DISTINCT FROM 'integrada'`, o `NOT atributos @> '{"gpu": "integrada"}'` |

La negación de la contención funciona porque `@>` devuelve `false`, y no `NULL`, cuando la clave no existe.

## 7.15 Esquema híbrido: qué va en columna y qué en JSON

| Va en **columnas tipadas** | Va en la columna **`JSON` / `JSONB`** |
| :--- | :--- |
| Lo que se filtra, ordena o agrega seguido (precio, stock, categoría) | Lo que varía por categoría y se consulta poco |
| Lo que necesita `PRIMARY KEY`, `UNIQUE`, `FOREIGN KEY` o `CHECK` | Atributos opcionales y listas de etiquetas |
| Lo que se une con otras tablas | Lo que se muestra completo con el producto |

La regla es la misma en los dos motores. Cambian la sintaxis y la forma de validar:

```sql
-- MySQL
CREATE TABLE producto (
  id         INT PRIMARY KEY,
  nombre     VARCHAR(120) NOT NULL,
  categoria  VARCHAR(40)  NOT NULL,
  precio     DECIMAL(12,2) NOT NULL CHECK (precio >= 0),
  atributos  JSON,
  tags       JSON,
  CHECK (JSON_TYPE(tags) = 'ARRAY')
);
```

```sql
-- PostgreSQL (resolución de otro grupo): la categoría es una FK a una tabla maestra
CREATE TABLE categorias (
  categoria_id       VARCHAR(50) PRIMARY KEY,
  rubro              VARCHAR(50) NOT NULL,
  garantia_meses     INT NOT NULL DEFAULT 12,
  permite_devolucion BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE productos (
  id         INT PRIMARY KEY,
  nombre     VARCHAR(150) NOT NULL,
  categoria  VARCHAR(50) NOT NULL REFERENCES categorias(categoria_id),
  precio     NUMERIC(14,2) NOT NULL CHECK (precio > 0),
  stock      INT NOT NULL CHECK (stock >= 0),
  atributos  JSONB NOT NULL,
  tags       JSONB NOT NULL,
  CHECK (jsonb_typeof(tags) = 'array')   -- agregado: la resolución original no lo tenía
);
```

### Validar la forma del documento

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| JSON Schema en el motor | `JSON_SCHEMA_VALID()` dentro de un `CHECK` (borrador 4); rechaza con `ERROR 3819`, y `JSON_SCHEMA_VALIDATION_REPORT()` dice qué regla falló | **No viene en el núcleo**. Existen extensiones de terceros, pero no son estándar |
| Reglas puntuales | `CHECK (JSON_TYPE(tags) = 'ARRAY')` | `CHECK (jsonb_typeof(tags) = 'array')`, `CHECK (atributos ? 'marca')`, `CHECK ((atributos->>'litros')::int > 0)` |
| Detalle del laboratorio | Un `CHECK` no admite variables: el esquema va escrito literal en la restricción | Un `CHECK` no admite subconsultas: lo que dependa de otra tabla va en un trigger |

### Arreglos: `JSON` o tipo nativo

PostgreSQL tiene además **arreglos nativos** (`text[]`, `int[]`). Para una lista de etiquetas simples son una alternativa al arreglo dentro de `JSONB`:

| | `tags JSONB` (`'["gaming","gpu"]'`) | `tags text[]` (`'{gaming,gpu}'`) |
| :--- | :--- | :--- |
| Tipo de los elementos | Libre: puede mezclar números, textos y objetos | Uno solo, el declarado |
| Contiene | `tags @> '["gaming"]'` | `tags @> ARRAY['gaming']` |
| Tiene alguno de | `tags ?\| array['gaming','oled']` | `tags && ARRAY['gaming','oled']` |
| Índice | `GIN` | `GIN` |

> **Trampa:** `WHERE 'gaming' = ANY(tags)` es la forma más "natural" de escribirlo, pero **no usa el índice `GIN`**. Para que lo use hay que escribirlo con `@>` o `&&`.

## 7.16 Índices sobre JSON en detalle

Acá está la diferencia más grande entre los dos motores.

### MySQL: un índice por atributo

En MySQL **no existe un índice general sobre toda la columna `JSON`**. Cada atributo que se filtra seguido necesita su propia herramienta:

| Herramienta | Cómo se crea | La usa la consulta que... |
| :--- | :--- | :--- |
| **Columna generada + índice** | `ADD COLUMN marca VARCHAR(40) AS (atributos->>'$.marca')` y un índice común sobre ella | filtra por esa columna o por la misma expresión |
| **Índice funcional** | `CREATE INDEX ix ON producto ((CAST(atributos->>'$.marca' AS CHAR(40))))` | repite exactamente la misma expresión |
| **Índice multivaluado** (MySQL ≥ 8.0.17) | `CREATE INDEX idx_tags_mv ON producto ((CAST(tags AS CHAR(30) ARRAY)))` | usa `MEMBER OF`, `JSON_CONTAINS` o `JSON_OVERLAPS` |

El **índice multivaluado** guarda **una entrada por cada elemento** del arreglo:

```sql
SELECT nombre FROM producto WHERE 'gaming' MEMBER OF (tags);
-- Antes: Table scan (costo 2,25). Después: Index lookup on producto using idx_tags_mv (costo 0,70)
```

Trampas del multivaluado: el tipo del `CAST` tiene que coincidir con el de los valores; un elemento más largo que `CHAR(n)` da error al insertar; no sirve para buscar texto parcial (`LIKE '%gam%'`) ni para mirar una posición (`tags->>'$[0]'`).

### PostgreSQL: un índice `GIN` para todo el documento

`GIN` (*Generalized Inverted Index*) es un **índice invertido**: en lugar de ordenar valores completos, guarda **cada componente** del documento (claves, valores, pares) con la lista de filas donde aparece. Un solo índice sobre la columna sirve para filtrar por **cualquier clave**, aunque no se sepa de antemano cuál:

```sql
CREATE INDEX idx_atrib_gin ON productos USING gin (atributos jsonb_path_ops);
CREATE INDEX idx_tags_gin  ON productos USING gin (tags);   -- clase por defecto: jsonb_ops
```

| Clase de operadores | Qué indexa | Operadores que acelera | Tamaño |
| :--- | :--- | :--- | :--- |
| **`jsonb_ops`** (por defecto) | Cada clave y cada valor por separado | `@>`, `?`, `?\|`, `?&`, `@?`, `@@` | Mayor |
| **`jsonb_path_ops`** | Un *hash* de cada camino completo (claves que llevan al valor + el valor) | Solo `@>`, `@?`, `@@` | Menor y más rápido para contención |

> **Trampa:** el `GIN` acelera **operadores**, no expresiones. `WHERE atributos->>'ram_gb' = '16'` **no usa** el índice `GIN`, ni siquiera forzándolo: hay que escribirlo como `atributos @> '{"ram_gb": 16}'`. Y con `jsonb_path_ops`, una pregunta por existencia de clave (`atributos ? 'gpu'`) tampoco lo usa.

Para una clave que se filtra por **rango u orden** (litros entre 300 y 400), el `GIN` no sirve: se usa un **índice B-Tree de expresión**, el equivalente al índice funcional de MySQL:

```sql
CREATE INDEX idx_litros ON productos (((atributos->>'litros')::int));
SELECT nombre FROM productos WHERE (atributos->>'litros')::int BETWEEN 300 AND 400;
```

**`btree_gin`** es una extensión del paquete `contrib` (`CREATE EXTENSION btree_gin`) que permite poner **columnas escalares y `JSONB` en el mismo índice `GIN`**, por ejemplo `(categoria, atributos)`. Sirve cuando casi todas las consultas combinan un filtro por columna con uno por documento.

**Costo de escritura del `GIN`:** cada `INSERT` o `UPDATE` agrega muchas entradas (una por componente). Para amortizarlo, PostgreSQL usa por defecto **`fastupdate = on`**: las entradas nuevas van a una *lista pendiente* que se incorpora al índice en lote (al llenarse `gin_pending_list_limit`, 4 MB por defecto, o al pasar `VACUUM`). Mientras tanto, las búsquedas también recorren esa lista.

### Comparación directa

| | MySQL (`JSON`) | PostgreSQL (`JSONB`) |
| :--- | :--- | :--- |
| Índice general | No existe: un índice por atributo filtrado | Un único `GIN` cubre la contención (`@>`) sobre cualquier clave |
| Igualdad sobre una clave conocida | Columna generada o índice funcional | `@>` con `GIN`, o índice de expresión |
| Rango u orden sobre una clave | Columna generada o índice funcional | Índice B-Tree de expresión |
| Elementos de un arreglo | Índice multivaluado (`MEMBER OF`) | `GIN` sobre `JSONB` o sobre `text[]` (`@>`, `&&`) |
| Atributos impredecibles | Hay que prever qué índice crear | **Ventaja real de PostgreSQL** |
| Mediciones en las actividades | 150.000 productos (U9): un atributo sin índice tardó ≈ 88 ms y con índice, menos de 1 ms | 20.000 productos (U7, otro grupo): de `Seq Scan` (costo 760, 510 bloques) a `Bitmap Index Scan` (costo 558, 3 bloques de índice), ≈ 2,5 ms; el índice ocupó 192 kB, el 4,7 % de la tabla |

> Si los filtros son predecibles, el costo en MySQL es declarar los índices. Si no lo son, es un argumento válido para preferir PostgreSQL.

## 7.17 Full-Text Search: el índice invertido

Un **B-Tree** ordena valores completos: sirve para `=`, rangos y prefijos (`LIKE 'inal%'` se resuelve como un rango). Con el comodín al inicio (`'%inal%'`) no hay por dónde entrar al árbol, y se recorre todo.

Un **índice invertido** guarda cada **término** con la lista de documentos donde aparece (*posting list*):

```text
"notebook" → 2, 7, 11
"gaming"   → 2, 11, 14
"tv"       → 13, 14
```

| | B-Tree | Índice invertido |
| :--- | :--- | :--- |
| Unidad indexada | El valor completo de la columna | Cada palabra (término) |
| Sirve para | `=`, rangos, prefijos, `ORDER BY` | Buscar palabras dentro del texto y **ordenar por relevancia** |
| En MySQL | `WHERE`, `LIKE 'abc%'` | Índice `FULLTEXT` + `MATCH(columnas) AGAINST('...')` |
| En PostgreSQL | `WHERE`, `LIKE 'abc%'` | Índice `GIN` sobre un `tsvector` + `tsvector @@ tsquery` |
| Con 200.000 filas en la actividad (MySQL) | `LIKE '%SKU0123457%'`: costo estimado 22.541, entre 0,5 y 0,6 s | `MATCH ... AGAINST`: costo 1,10, entre 1 y 5 ms |

### Cómo se arma en PostgreSQL

PostgreSQL no tiene un tipo de índice "de texto": convierte el texto en un **`tsvector`** (la lista de *lexemas* normalizados con su posición) y la búsqueda en un **`tsquery`**. El operador `@@` dice si coinciden.

```sql
SELECT to_tsvector('spanish', 'Notebook gamer con placas RTX y juegos incluidos');
-- 'gam':2 'inclu':8 'jueg':7 'notebook':1 'plac':4 'rtx':5

-- Opción 1: índice de expresión (la consulta tiene que repetir la misma expresión)
CREATE INDEX idx_desc_fts ON productos USING gin (to_tsvector('spanish', descripcion));
SELECT nombre FROM productos
WHERE to_tsvector('spanish', descripcion) @@ websearch_to_tsquery('spanish', 'juego rtx');

-- Opción 2: columna generada almacenada (más simple de consultar)
ALTER TABLE productos ADD COLUMN desc_tsv tsvector
  GENERATED ALWAYS AS (to_tsvector('spanish', coalesce(descripcion, ''))) STORED;
CREATE INDEX idx_desc_tsv ON productos USING gin (desc_tsv);
```

> **Trampa:** el índice solo se puede crear con la forma de **dos argumentos**, `to_tsvector('spanish', ...)`. La forma de un argumento depende de la variable `default_text_search_config`; como no es inmutable, PostgreSQL rechaza el índice con `functions in index expression must be marked IMMUTABLE`. Si la consulta usa una configuración distinta a la del índice, **no lo usa**.

### Cómo es el `FULLTEXT` de InnoDB por dentro

- Cada fila recibe un identificador oculto, **`FTS_DOC_ID`**. Si la tabla no lo tiene, el primer índice `FULLTEXT` **reconstruye la tabla** para agregarlo (aparece la advertencia 124).
- El índice se reparte en **tablas auxiliares** (`index_1` a `index_6` por rango de términos, más `deleted`, `being_deleted` y `config`).
- Las inserciones pasan primero por una **caché** en memoria (`innodb_ft_cache_size`) y se ven en `INFORMATION_SCHEMA.INNODB_FT_INDEX_CACHE` hasta que se vuelcan.
- Los cambios se aplican al **`COMMIT`**: una transacción no encuentra con `MATCH` sus propias filas sin confirmar.
- `MATCH()` exige un índice `FULLTEXT` con **exactamente las mismas columnas**; si no existe, da `ERROR 1191`.

### Por qué las escrituras se encarecen

**En MySQL**, un `UPDATE` de una columna indexada se registra como **borrado lógico + inserción con un `FTS_DOC_ID` nuevo**. Las entradas viejas siguen en el índice, listadas en `INNODB_FT_DELETED`, hasta que se purgan con `OPTIMIZE TABLE` (activando `innodb_optimize_fulltext_only`), que procesa una cantidad limitada de términos por pasada (`innodb_ft_num_word_optimize`, 2.000 por defecto). En la actividad, un `UPDATE` de 20.000 descripciones pasó de 0,60 s a 2,83 s con el índice, y dejó 20.000 identificadores en `INNODB_FT_DELETED`. El índice tenía 210.261 términos: unas 105 pasadas de `OPTIMIZE`.

**En PostgreSQL**, el índice de texto es un `GIN` común: sigue las reglas de MVCC del Parcial 1. Un `UPDATE` deja una versión muerta de la fila y entradas viejas en el índice, que limpia **`VACUUM`** (o autovacuum). La lista pendiente de `fastupdate` reduce el costo de cada escritura, a cambio de búsquedas algo más lentas hasta que se vacía.

| | MySQL `FULLTEXT` | PostgreSQL `GIN` sobre `tsvector` |
| :--- | :--- | :--- |
| Una transacción ve sus propias filas nuevas en la búsqueda | **No**: el índice se actualiza al `COMMIT` | **Sí**: es un índice MVCC como cualquier otro |
| Entradas viejas tras un `UPDATE` | `INNODB_FT_DELETED`, se purgan con `OPTIMIZE TABLE` | Tuplas muertas, las limpia `VACUUM` |
| Amortiguador de escritura | Caché `innodb_ft_cache_size` | Lista pendiente (`fastupdate`, `gin_pending_list_limit`) |
| Varias columnas | Un índice con exactamente las columnas de `MATCH` | Se concatenan en el `tsvector`, con pesos `A` a `D` (`setweight`) |

## 7.18 Tokenización y configuración

Acá los motores toman caminos opuestos: MySQL corta palabras con reglas fijas y deja la configuración en variables del servidor; PostgreSQL aplica **diccionarios por idioma** elegidos en cada consulta.

### MySQL

| Configuración | Valor por defecto | Cómo se cambia | Efecto sobre índices existentes |
| :--- | :--- | :--- | :--- |
| `innodb_ft_min_token_size` | 3 | Solo lectura: archivo `.cnf` + reinicio | **Ninguno hasta reconstruir** el índice |
| `innodb_ft_max_token_size` | 84 | Ídem | Ídem |
| `innodb_ft_server_stopword_table` | Lista interna de 36 palabras en inglés | Dinámica y global (`SET GLOBAL`) | Solo para índices creados después |
| `innodb_ft_user_stopword_table` | Vacía | Variable de sesión, con prioridad sobre la global | Ídem |

- El **parser por defecto** corta en espacios y signos de puntuación: `USB-C` se indexa como `usb` y `c`.
- Las palabras más cortas que el mínimo **no se indexan**: por eso `TV`, `4K` o `HP` no aparecen con el valor de fábrica.
- Al bajar el mínimo a 2 hace falta una **tabla propia de *stopwords* en español**; si no, se indexan `el`, `un`, `al`, `de`. La tabla propia **reemplaza** a la lista por defecto.
- **Reconstruir** se hace con `DROP INDEX` y `ADD FULLTEXT` **en sentencias separadas**. En la actividad se comprobó que la forma combinada (`ALTER TABLE t DROP INDEX x, ADD FULLTEXT x (...)` con la misma definición) **no reconstruye**: InnoDB la trata como un cambio de metadatos y el índice conserva los términos viejos.
- El parser **`ngram`** corta el texto en fragmentos de 2 caracteres (`ngram_token_size`). Está pensado para idiomas sin separador de palabras, como chino o japonés; en español agranda el índice y suma falsos positivos.
- La comparación sigue la **colación** de la columna: con `utf8mb4_0900_ai_ci` la búsqueda no distingue mayúsculas ni acentos.

### PostgreSQL

Una **configuración de búsqueda** (`spanish`, `english`, `simple`) combina un *parser* y una cadena de **diccionarios**. La de español quita *stopwords* y reduce cada palabra a su **raíz** con un diccionario Snowball: `juegos` y `juego` quedan como `jueg`.

| Tema | Comportamiento | Cómo se ajusta |
| :--- | :--- | :--- |
| Idioma | Se elige en cada llamada: `to_tsvector('spanish', ...)` | `default_text_search_config` para la forma de un argumento |
| *Stopwords* | La configuración `spanish` ya trae una lista en español | Una configuración propia con otro archivo de *stopwords* |
| Palabras cortas | **No hay tamaño mínimo**: `tv` y `4k` se indexan | — |
| Palabras con guion | `USB-C` se indexa entero **y** por partes: `usb-c`, `usb` y `c` | — |
| Acentos | La configuración `spanish` los quita al reducir a la raíz: `inalámbrico` e `inalambrico` quedan como `inalambr`. La configuración `simple` **no** los quita | Extensión `unaccent` en una configuración propia, si se usa `simple` o hay que normalizar nombres propios |
| Ver qué se indexa | `SELECT * FROM ts_debug('spanish', 'Cable USB-C 4K');` muestra cada *token*, su tipo y el lexema que produce | — |
| Cambiar la configuración | Los `tsvector` ya calculados no cambian | Recalcular la columna o recrear el índice: **mismo problema que reconstruir en MySQL** |

## 7.19 Modos de búsqueda y relevancia

**Lenguaje natural en MySQL** (el modo por defecto): devuelve los documentos con cualquiera de los términos, ordenados por una relevancia de la familia **TF-IDF**. Pesa más un término que se repite en el documento (TF) y, sobre todo, uno **raro en la colección** (IDF). En la actividad, `notebook gaming RTX` dejó primero al único producto con `rtx`.

**Relevancia en PostgreSQL:** `ts_rank` (frecuencia de los términos) y `ts_rank_cd` (además, cercanía entre ellos), con los pesos `A` a `D` de `setweight` para que el título valga más que la descripción. **No usa información global de la colección**: un término raro no pesa más que uno común. El orden se pide explícitamente:

```sql
SELECT nombre, ts_rank(desc_tsv, q) AS rel
FROM productos, websearch_to_tsquery('spanish', 'notebook gaming rtx') AS q
WHERE desc_tsv @@ q
ORDER BY rel DESC;
```

> **Diferencia con MySQL:** `websearch_to_tsquery('spanish', 'notebook gaming rtx')` produce `'notebook' & 'gaming' & 'rtx'`: exige los tres términos. El modo natural de MySQL los une con **O** y ordena. Para el comportamiento de MySQL en PostgreSQL hay que escribir `'notebook or gaming or rtx'`.

**Operadores booleanos en los dos motores:**

| Intención | MySQL (`IN BOOLEAN MODE`) | PostgreSQL (`to_tsquery`) | PostgreSQL (`websearch_to_tsquery`) |
| :--- | :--- | :--- | :--- |
| Término obligatorio | `+gaming` | `gaming & ...` | `gaming` (todos son obligatorios) |
| Término excluido | `-notebook` | `!notebook` | `-notebook` |
| Cualquiera de dos | `gaming rtx` (opcionales) | `gaming \| rtx` | `gaming or rtx` |
| Prefijo | `inalambr*` | `inalambr:*` | — |
| Frase exacta | `"alta frecuencia"` | `alta <-> frecuencia` | `"alta frecuencia"` |

**Expansión de consulta** (`WITH QUERY EXPANSION`, solo MySQL): hace una segunda búsqueda con las palabras más relevantes de los primeros resultados. Sirve con consultas muy cortas, pero **agrega ruido**: en la actividad, `espresso` trajo heladeras y un compresor, por términos compartidos como `litros` o `bar`. PostgreSQL no tiene un equivalente directo; lo más parecido es un diccionario de sinónimos o de tesauro.

### Lo que cada motor no hace

| Necesidad | MySQL `FULLTEXT` | PostgreSQL | Qué haría falta |
| :--- | :--- | :--- | :--- |
| *Stemming* (raíces) | **No**: `juego` → 0 filas; `juegos` → 2. `juego*` lo mitiga en parte | **Sí**, con la configuración `spanish` | — |
| Tolerancia a errores de tipeo | **No**: `notebok` → 0 filas | No en `tsvector`; **sí con la extensión `pg_trgm`** (similitud por trigramas, `%` y `similarity()`, indexable con `GIN`) | Búsqueda difusa (*fuzzy*) en un motor de búsqueda |
| Ignorar acentos | Sí, por la colación | Sí con `spanish`; con `simple`, mediante `unaccent` | — |
| Sinónimos | No | Diccionarios de sinónimos y tesauro, configurados a mano | Elasticsearch u OpenSearch |
| Facetas, autocompletado, búsqueda semántica | No | No en el núcleo | Elasticsearch u OpenSearch |

> Con la misma necesidad del catálogo, PostgreSQL resuelve en el motor dos cosas (raíces y errores de tipeo) que en MySQL eran argumentos para sumar un buscador.

## 7.20 Cómo medir

| Herramienta | MySQL | PostgreSQL | Cuidado |
| :--- | :--- | :--- | :--- |
| Plan estimado | `EXPLAIN` (formato árbol, el predeterminado en MySQL 9) · `EXPLAIN FORMAT=JSON` (`"index_access_type": "full_text_search"`) | `EXPLAIN` | Son estimaciones |
| Plan real | `EXPLAIN ANALYZE` | `EXPLAIN (ANALYZE, BUFFERS)` | **Ejecuta** la consulta |
| Trabajo de E/S | `SHOW SESSION STATUS LIKE 'Handler_read%'` (`Handler_read_rnd_next`: filas leídas en un recorrido) | `Buffers: shared hit/read` en el plan | Comparar antes y después, en la misma sesión |
| Tamaño del índice | `INFORMATION_SCHEMA` (`index_length`) | `pg_relation_size('idx')`, `pg_total_relation_size('tabla')` | Es el costo en disco y en memoria |
| Uso del índice | `sys.schema_unused_indexes` | `pg_stat_user_indexes` (`idx_scan`) | — |

**Cómo se ve el cambio de plan:**

| Situación | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Sin índice | `Table scan` + `Filter` | `Seq Scan` + `Filter` |
| Con índice de texto | `Full-text index search` | `Bitmap Index Scan` sobre el `GIN` + `Bitmap Heap Scan` con `Recheck Cond` |
| Con índice sobre un arreglo | `Index lookup ... using idx_tags_mv` | `Bitmap Index Scan` sobre el `GIN` |

> El `Recheck Cond` de PostgreSQL es normal con `GIN`: el índice entrega candidatos y el motor confirma la condición sobre la fila. Con `jsonb_path_ops`, que guarda *hashes*, ese control es obligatorio.

**Lecciones de las actividades, iguales en los dos motores:**

- **Con 20 filas el optimizador elige recorrer la tabla** y tiene razón. En PostgreSQL toda la tabla entraba en **un bloque de 8 kB**: el `Seq Scan` costaba 1,25 y el índice, forzado con `SET enable_seqscan = off`, costaba 12,55. En MySQL todo tardaba menos de 2 ms. Lo que importa es el **cambio de plan**, por eso los dos grupos escalaron: 200.000 filas en MySQL y 20.000 en PostgreSQL.
- **`enable_seqscan = off` sirve solo para la prueba:** muestra cuánto costaría el plan alternativo. Hay que volver a `on` y no dejarlo en producción.
- **Las estimaciones de `LIKE '%...%'` son malas**: en MySQL el plan estimaba 23.130 filas y devolvió 1. Para medir se usa el plan real (`EXPLAIN ANALYZE`).
- **La selectividad decide la ganancia:** en PostgreSQL la consulta por `ram_gb = 16` devolvía el 10 % de la tabla, y el costo bajó solo de 760 a 558. Con un filtro más selectivo la diferencia es mucho mayor.

## 7.21 Relacional extendido frente a NoSQL especializado

| Aspecto | Relacional extendido (MySQL o PostgreSQL) | NoSQL especializado (por ejemplo, Elasticsearch o MongoDB) |
| :--- | :--- | :--- |
| Transacciones | Las búsquedas ven los datos confirmados en el mismo motor; claves foráneas y `CHECK` sobre las columnas fijas | Copia con consistencia eventual ("casi en tiempo real"), o modelo sin uniones |
| Operación | Un motor, un respaldo, una seguridad | Un clúster más para operar, asegurar y respaldar |
| Búsqueda | Palabras, relevancia, booleano; en PostgreSQL además raíces y búsqueda difusa | Raíces, errores de tipeo, sinónimos, facetas, búsqueda semántica |
| Integración | Ninguna | Sincronizar desde la fuente |

**Patrón híbrido típico:** el relacional sigue siendo la **fuente de verdad** y un proceso de captura de cambios (CDC) alimenta al buscador, que funciona como **réplica de lectura especializada**. Lo que cambia es de dónde lee el CDC:

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Fuente de los cambios | El **registro binario** (`binlog`) en formato de filas | El **WAL**, mediante *decodificación lógica* (`wal_level = logical` y un *slot* de replicación) |
| Herramienta típica | Debezium | Debezium (plugin `pgoutput`) |

**Regla práctica para decidir**, la misma con los dos motores:

1. **Quedarse en el relacional** si resuelve el patrón de consulta con el plan y el tiempo esperados.
2. **Pasar a un esquema híbrido** si el motor no puede resolver algo concreto: facetas, búsqueda semántica, distribución, o (en MySQL) raíces y errores de tipeo.
3. **Migrar** solo si no hay un núcleo transaccional que mantener.

Los dos grupos llegaron a la misma conclusión por caminos distintos: en MySQL, que `FULLTEXT` alcanza para buscar palabras con relevancia; en PostgreSQL, que `JSONB` con `GIN` alcanza para el catálogo heterogéneo. Ninguno encontró una ganancia que justificara un motor documental aparte para ese volumen.

## Preguntas de repaso · Unidad 7

1. ¿Cuáles son las cinco tensiones que plantea la clase? Da un ejemplo de cada una y el modelo que la resuelve mejor.
2. En el catálogo con notebooks, heladeras y calzado, ¿qué problema tiene cada opción: tabla por categoría, 80 columnas opcionales, EAV y documento flexible? ¿Cuándo el relacional "funciona muy bien" y cuándo "conviene flexibilizar"?
3. ¿Qué significa que un dato sea semiestructurado? ¿Por qué "JSON es una representación, no un modelo"?
4. ¿Qué cambia al pensar en agregados en lugar de relaciones? Nombrá cuatro tensiones que JSON no resuelve.
5. ¿Qué piezas forman el Document Store de MySQL y en qué puerto escucha cada protocolo? ¿Por qué "MySQL no se convierte en MongoDB"?
6. ¿Qué resuelven las JSON Duality Views y por qué no duplican los datos?
7. ¿En qué se diferencian `json` y `jsonb`? ¿Cuál recomienda la documentación y por qué?
8. Completá la tabla "dos caminos": documento, API documental, índice documental, clave-valor, Full Text y Spatial en cada motor.
9. ¿Qué diferencia hay entre replicación y sharding? ¿Qué riesgo tiene una mala *shard key*?
10. ¿Por qué "SQL = ACID / NoSQL = BASE" es una simplificación? ¿Qué decisión plantea CAP cuando la red se corta?
11. ¿Qué no significa, qué no garantiza y qué sí exige NoSQL? ¿Por qué *wide-column* no es un *column-store* analítico?
12. Recorré el árbol de decisión para el catálogo: ¿se mantiene, se extiende o se especializa?
13. ¿Por qué `atributos->>'gpu' <> 'integrada'` excluye a los productos que no tienen la clave `gpu`? ¿Cómo se incluyen en MySQL y en PostgreSQL?
14. ¿Qué diferencia hay entre `->` y `->>`, y cuál conviene en un `WHERE`? ¿Qué cambia en la forma de escribir la clave entre los dos motores?
15. ¿Por qué en PostgreSQL se prefiere `JSONB` a `json`?
16. Creaste un `GIN` con `jsonb_path_ops` sobre `atributos`. ¿Lo usa `WHERE atributos->>'ram_gb' = '16'`? ¿Y `WHERE atributos ? 'gpu'`? ¿Cómo reescribirías cada una?
17. ¿Qué índice necesitás en PostgreSQL para filtrar `litros BETWEEN 300 AND 400` dentro del `JSONB`? ¿Y en MySQL?
18. ¿Por qué un índice B-Tree no sirve para `LIKE '%texto%'` y un índice invertido sí?
19. Bajaste `innodb_ft_min_token_size` a 2 y reiniciaste, pero `TV` sigue sin aparecer. ¿Qué te faltó? ¿Pasaría lo mismo en PostgreSQL?
20. Buscás `juego` y el producto dice `juegos`. ¿Qué devuelve MySQL? ¿Y PostgreSQL con la configuración `spanish`? ¿Por qué?
21. ¿Por qué no se puede indexar `to_tsvector(descripcion)` sin indicar el idioma?
22. ¿Por qué un `UPDATE` masivo sobre una columna con índice de texto se vuelve más lento, y qué queda pendiente después en cada motor?
23. ¿Qué condición puede aprovechar un índice multivaluado de MySQL? ¿Y cuál no? ¿Por qué `'gaming' = ANY(tags)` no usa el `GIN` en PostgreSQL?
24. Con 20 filas, el plan de PostgreSQL muestra `Seq Scan` aunque exista el `GIN`. ¿Está mal el índice? ¿Cómo lo demostrás?
25. ¿Cuándo justificarías sumar Elasticsearch al lado del relacional, y de dónde leería los cambios el CDC en cada motor?

---

# Unidad 8 · MongoDB: de guardar JSON a diseñar agregados

La unidad sigue la **clase 8** de la cátedra (*Profundizar el modelo documental: diseñar, consultar, optimizar y justificar*). Las secciones 8.1 a 8.19 recorren la clase en su orden: documento, diseño, operación, rendimiento y control. Desde la 8.20 viene la **profundización** con las resoluciones: el escenario de logística de la primera actividad ya está integrado en las secciones de diseño, y la segunda actividad (seguridad y respaldo) se desarrolla aparte.

## 8.1 La pregunta de la unidad

> *Si ya decidimos usar documentos, ¿cómo evitamos que MongoDB sea simplemente "tablas convertidas a JSON"?*

**Objetivo de la clase:** diseñar y operar una base documental en MongoDB **a partir de patrones de acceso**, justificando estructura, consultas, índices y controles **con evidencia del motor**.

| Modelar | Consultar | Demostrar |
| :--- | :--- | :--- |
| Definir agregados, *embedding* y referencias | CRUD, filtros, proyección y agregaciones | Índices, `explain()`, validación y evidencia |

**Las tres preguntas de diseño** que cambian la cabeza respecto del modelo relacional:

| 1 · Lecturas | 2 · Cambios | 3 · Crecimiento |
| :--- | :--- | :--- |
| ¿Qué información necesito **recuperar junta**? | ¿Qué datos **cambian juntos** y con qué frecuencia? | ¿Qué arrays o relaciones pueden **crecer sin límite**? |

**Mapa de la clase:** 1 · Documento (BSON, `_id`, anidamiento) → 2 · Diseño (patrones de acceso y relaciones) → 3 · Operación (CRUD y consultas) → 4 · Rendimiento (índices, `explain` y *pipeline*) → 5 · Control (validación, atomicidad y desafío).

## 8.2 De fila a documento

La unidad natural deja de ser la **fila aislada**. En el modelo relacional, un pedido son tres tablas (`PEDIDO`, `ITEM_PEDIDO` y `PRODUCTO`); en MongoDB puede ser **un documento**:

```javascript
{
  _id: 501,
  clienteId: 77,
  fecha: ISODate("2026-10-07"),
  items: [
    { sku: "A10", cant: 2, precio: 1500 },
    { sku: "B22", cant: 1, precio: 900 }
  ]
}
```

| Concepto relacional | En MongoDB | Diferencia que importa |
| :--- | :--- | :--- |
| Base de datos | Base de datos | Igual |
| Tabla | **Colección** | No impone esquema (salvo un validador opcional) |
| Fila | **Documento** BSON | Puede tener subdocumentos y arreglos anidados |
| Columna | Campo | Cada documento puede tener campos distintos |
| Clave primaria | `_id` | Obligatorio, único e indexado automáticamente |
| `JOIN` | `$lookup` o **embeber** | Lo habitual es guardar junto lo que se lee junto |

## 8.3 El documento, BSON y `_id`

Un documento es un **objeto BSON**: campos, valores, documentos anidados y arrays.

| Rasgo | Qué es |
| :--- | :--- |
| **Campo → valor** | Cada documento reúne datos relacionados en una estructura autocontenida |
| **Anidamiento** | Un campo puede contener otro documento: dirección, pago, perfil |
| **Arrays** | Listas de valores o de subdocumentos: ítems, etiquetas, eventos |
| **BSON** | Amplía JSON con tipos útiles para una base de datos |

**Jerarquía lógica:**

```text
Deployment (implementación o clúster) → Database → Collection → Document → Field
```

Una colección **no obliga** a que todos sus documentos tengan exactamente los mismos campos.

### BSON no es "solo JSON"

| Tipo | Para qué |
| :--- | :--- |
| `ObjectId` | Clave única de **12 bytes**, asignada automáticamente para identificar cada documento sin duplicados |
| `Date` | Un momento exacto (fecha y hora en **UTC**) |
| `Decimal128` | Números de alta precisión de 128 bits: **montos de dinero** y cálculos financieros |
| `Array` | Listas ordenadas de valores o elementos dentro de un mismo campo |
| `Object` | Subdocumentos incrustados para agrupar datos relacionados (una dirección) |

> **Trampa:** los tipos BSON importan al respaldar. `mongoexport` a JSON plano **pierde** `Date`, `ObjectId` o `Decimal128`; por eso no es un respaldo ([8.26](#826-respaldo-y-recuperación)).

### `_id` y `ObjectId`

```javascript
{ _id: ObjectId("..."), nroPedido: "P-2026-501", estado: "confirmado" }
```

Todo documento de una colección estándar tiene un `_id` **único**. Si no se informa, el driver o MongoDB generan un `ObjectId`. **No conviene apoyar reglas de negocio en la estructura interna del `ObjectId`** (por ejemplo, deducir la fecha de alta de sus primeros bytes); el dato de negocio va en su propio campo (`nroPedido`).

## 8.4 Esquema flexible ≠ ausencia de diseño

| Puede variar | Debe ser coherente | Puede validarse |
| :--- | :--- | :--- |
| Los documentos de una colección pueden diferir en campos o estructura | La aplicación necesita nombres, tipos y reglas previsibles | MongoDB permite validadores por colección, incluido `$jsonSchema` ([8.15](#815-validación-de-esquema)) |

> La flexibilidad sirve para **evolucionar**; no justifica almacenar "cualquier cosa". Si cada documento escribe la fecha de una forma distinta, ninguna consulta funciona bien.

## 8.5 El agregado como frontera de diseño

**Lo que se lee y cambia junto suele vivir junto.** Un pedido con cabecera, dirección de entrega, `items[]` y totales:

- Si el pedido debe poder **leerse y persistirse como una unidad coherente**, el documento puede representar esa frontera.
- Si una relación **crece o cambia independientemente**, probablemente convenga **referenciar**.

### Diseñar desde los patrones de acceso

**Primero preguntas; después estructura:**

| 1 · Listar consultas | 2 · Identificar escrituras | 3 · Medir cardinalidad | 4 · Diseñar el documento |
| :--- | :--- | :--- | :--- |
| ¿Qué lecturas son frecuentes y críticas? | ¿Qué cambia junto? ¿Qué se actualiza mucho? | ¿Uno a pocos o uno a millones? | *Embed*, referencia o duplicación controlada |

En la resolución se agregó un quinto paso: **crear los índices** de los patrones prioritarios y **verificarlos con `explain`** ([8.12](#812-índices-con-intención)).

## 8.6 *Embedding* frente a *referencing*

No es una traducción mecánica de PK y FK:

| **Embeber** (incrustar) conviene cuando... | **Referenciar** conviene cuando... |
| :--- | :--- |
| Se consulta junto casi siempre | El dato vive y cambia por separado |
| La relación está **acotada** | Hay **alta cardinalidad** |
| Se actualiza como una unidad | El crecimiento puede ser **no acotado** |
| La duplicación es aceptable | Muchos documentos **comparten** la entidad |

### Ejemplo: embeber los ítems de un pedido

```javascript
items: [
  { sku: "A10", descripcion: "Teclado", cantidad: 2, precioUnitario: 1500 },
  { sku: "B22", descripcion: "Mouse",   cantidad: 1, precioUnitario: 900 }
]
```

El ítem es una **"foto" del momento de compra**: el precio y la descripción del pedido deben conservar el estado histórico. Referenciar siempre al producto actual podría **alterar la interpretación** de un pedido pasado (si el teclado sube de precio, el pedido viejo mostraría un total que nunca se cobró).

### Ejemplo: referenciar al cliente

```javascript
// pedidos
{ _id: 501, clienteId: ObjectId("..."), fecha: ISODate("2026-10-07"), items: [...] }
// clientes
{ _id: ObjectId("..."), nombre: "Ana Pérez", email: "ana@ejemplo.com" }
```

El cliente es una **entidad con vida propia**: participa en muchos pedidos y se actualiza independientemente.

## 8.7 Cardinalidad, duplicación y antipatrones

### El riesgo no es tener arrays: es que crezcan sin límite

| Cardinalidad | Ejemplos | Decisión |
| :--- | :--- | :--- |
| **Uno a pocos** | Teléfonos, direcciones frecuentes, ítems razonables | *Embedding* suele ser natural |
| **Uno a muchos** | Pedidos de un cliente, eventos de un equipo | Evaluar acceso y crecimiento |
| **Uno a muchísimos** | Logs, telemetría, historial continuo | **Evitar arrays no acotados**: separar en otra colección o usar patrones específicos |

Embeber algo que crece sin límite (*unbounded array*) es el antipatrón más citado:

- Se acerca al **límite de 16 MB por documento**.
- Cada lectura trae el arreglo completo a la **caché** de WiredTiger (el *working set* crece).
- Cada actualización y cada índice multiclave sobre el arreglo se encarecen.

> **Trampa de defensa:** "WiredTiger mueve el documento en el disco cuando crece" era el argumento del motor viejo **MMAPv1**. WiredTiger escribe una versión nueva en cada actualización. Los argumentos actuales son el tamaño, la caché y el costo de mantener arreglos grandes.

### Duplicación controlada

Desnormalizar es **"una negociación permanente"**, no un objetivo:

| Beneficio | Costo | Regla |
| :--- | :--- | :--- |
| Menos lecturas cruzadas y documentos más cercanos al caso de uso | Más espacio y la necesidad de decidir **cómo sincronizar** los datos duplicados | Duplicar cuando el beneficio de lectura **supera** el costo de mantener la consistencia |

### Antipatrón: SQL traducido 1:1

```text
CLIENTES → PEDIDOS → ITEMS → PRODUCTOS → DIRECCIONES     ✗
```

Muchas colecciones pequeñas con referencias para todo: si cada lectura obliga a **reconstruir el agregado como si fueran `JOIN` relacionales**, no se aprovechó el modelo documental. Da lo peor de los dos mundos: ni la integridad declarativa del relacional ni la lectura de una sola vez del documental.

### Microdesafío de la clase

| Escenario | Decisión | Por qué |
| :--- | :--- | :--- |
| **Perfil de usuario** (direcciones + preferencias) | **Embeber** | Pocas direcciones, se leen siempre con el perfil |
| **Catálogo** (producto + categorías + stock) | **Híbrido**: referenciar las categorías y embeber el stock | Las categorías se comparten entre muchos productos; el stock se lee con el producto |
| **IoT** (dispositivo + millones de mediciones) | **Colección separada**, con el *bucket pattern* o una colección *time series* | Uno a muchísimos: un array embebido crecería sin cota |

### Aplicado al escenario de logística (U8 · A1)

| Elemento | Decisión | Por qué |
| :--- | :--- | :--- |
| Paquetes (1 a 4 por envío) | **Embebidos** en `envios` | Se leen con el envío, son pocos y nacen con él |
| Origen y destino | **Subdocumentos** | Siempre se muestran con el envío |
| Transportista | **Copiado** (`id`, `nombre`, `cuit`) | Evita un `$lookup` en la consulta de demoras por transportista |
| Eventos de seguimiento | **Referenciados** en `eventos_seguimiento` con `envio_id` | Crecen sin cota mientras el camión viaja |
| `estado_actual` y `minutos_demora` | **Duplicados** en el envío | La consulta prioritaria no tiene que recorrer los eventos |

## 8.8 Patrones de diseño documental

| Patrón | Idea | Ejemplo | Costo |
| :--- | :--- | :--- | :--- |
| **Referencia extendida** | Copiar los campos más consultados de un dato casi inmutable | `transportista: { id, nombre, cuit }` en cada envío | Si cambia el nombre, `updateMany` sobre todas las copias |
| **Calculado** | Guardar un resultado en lugar de recalcularlo en cada lectura | `estado_actual`, `minutos_demora` | Una escritura extra al registrar cada evento |
| **Subconjunto** | Embeber solo los N más recientes y referenciar el resto | `$push` con `$each` y `$slice: -5` | Dos lugares donde mirar |
| **Cubo** (*bucket*) | Agrupar muchos eventos pequeños en un documento por período | Un documento por camión y hora | Consultas por rango más complejas |
| **Series temporales** | Colección especial para mediciones con fecha (desde 5.0) | Telemetría de los camiones | Restricciones de actualización |
| **Versionado de esquema** | Un campo `version` indica la forma del documento | Migrar documentos de a poco | La aplicación debe entender varias formas |

## 8.9 Herramientas para trabajar con MongoDB

Mismo motor, distintas interfaces:

| Herramienta | Qué es |
| :--- | :--- |
| **mongosh** | Shell interactiva para ejecutar comandos y scripts |
| **Compass** | Cliente gráfico para explorar datos, consultas, índices y *pipelines* |
| **Drivers** | APIs oficiales para las aplicaciones: Java, Python, Node.js, C#, etc. |

## 8.10 CRUD

### Crear y cargar

```javascript
use sgdb2026
db.pedidos.insertOne({ nroPedido: "P-501", clienteId: 77, estado: "nuevo", total: 3900 })
db.pedidos.insertMany([ {...}, {...} ])
```

- La base y la colección se **materializan al primer uso**.
- `_id` se genera si no se informa.
- El viejo `insert()` se reemplaza por los métodos explícitos `insertOne` e `insertMany`.

### Consultar: `find()`

```javascript
db.pedidos.find(
  { estado: "nuevo", total: { $gte: 3000 } },     // filtro     ≈ WHERE
  { nroPedido: 1, total: 1, _id: 0 }              // proyección ≈ columnas del SELECT
).sort({ total: -1 }).limit(5)                    // operan sobre el cursor
```

No todo concepto SQL tiene traducción 1:1.

### Actualizar

```javascript
db.pedidos.updateOne(
  { nroPedido: "P-501" },
  {
    $set:  { estado: "confirmado" },
    $inc:  { intentosPago: 1 },
    $push: { eventos: { tipo: "PAGO_OK", fecha: new Date() } }
  }
)
```

Los **operadores expresan la intención del cambio**. Se usan `updateOne()` y `updateMany()` con operadores de actualización; `upsert` sigue disponible cuando el caso lo requiere.

### Eliminar con intención explícita

```javascript
db.pedidos.deleteOne({ nroPedido: "P-501" })
db.pedidos.deleteMany({ estado: "cancelado", fecha: { $lt: ISODate("2025-01-01") } })
```

> **Práctica segura:** antes de borrar, ejecutar **el mismo filtro** con `find()` o `countDocuments()` y guardar evidencia del conjunto afectado.

**Checkpoint de la clase:** cargar al menos 8 documentos con subdocumentos y arrays; resolver 4 preguntas con filtros, proyección, orden y arrays; aplicar `updateOne`/`updateMany` y **verificar antes y después**. No memorizar comandos: demostrar comportamiento.

### Detalles que suelen preguntarse

| Operación | Comando | Detalle que suele preguntarse |
| :--- | :--- | :--- |
| Alta | `insertOne`, `insertMany` | `insertMany` es **ordenado** por defecto: se detiene en el primer error. Con `{ ordered: false }` sigue con el resto |
| Lectura | `find`, `findOne`, `countDocuments` | El segundo argumento de `find` es la **proyección** |
| Modificación | `updateOne`, `updateMany` | Sin operadores (`$set`...) no se permite: para reemplazar todo está `replaceOne` |
| Reemplazo | `replaceOne` | Reemplaza el documento **completo**, salvo `_id` |
| Alta o modificación | `updateOne(filtro, cambios, { upsert: true })` | Si no existe, lo crea |
| Baja | `deleteOne`, `deleteMany` | `deleteMany({})` borra los documentos pero **conserva los índices**; `drop()` borra todo |

| Operador | Qué hace |
| :--- | :--- |
| `$set` / `$unset` | Fija un valor / quita un campo |
| `$inc` | Suma (atómico): sirve para contadores |
| `$push` | Agrega a un arreglo, aunque se repita |
| `$addToSet` | Agrega solo si el valor no está |
| `$pull` | Quita de un arreglo los elementos que cumplen una condición |
| `$` posicional | Modifica el elemento del arreglo que coincidió con el filtro: `{ "paquetes.$.fragil": true }` |

## 8.11 Operadores de consulta y arreglos

| Operador | Qué expresa |
| :--- | :--- |
| `$gt` / `$gte` | Mayor / mayor o igual (también `$lt`, `$lte`, `$ne`) |
| `$in` | Pertenece a un conjunto (`$nin`, no pertenece) |
| `$exists` | El campo está presente (distinto de "vale `null`") |
| `$and` / `$or` | Composición lógica |
| `$elemMatch` | Una condición sobre **un mismo elemento** de un array |

- A un subdocumento se llega con **notación con punto**: `{ "destino.provincia": "Santa Fe" }`.
- Una condición sobre un arreglo se cumple si **algún elemento** la cumple: `{ "paquetes.fragil": true }`.

### `$elemMatch` frente a la notación con punto

```javascript
// ¿Algún paquete frágil Y de más de 10 kg?
{ "paquetes.fragil": true, "paquetes.peso_kg": { $gt: 10 } }               // 5 envíos
{ paquetes: { $elemMatch: { fragil: true, peso_kg: { $gt: 10 } } } }      // 2 envíos
```

Con la notación con punto, **cada condición puede cumplirla un paquete distinto**. En la actividad, un envío tenía un paquete frágil de 3,2 kg y **otro** de 12,5 kg que no era frágil: la primera consulta lo devolvía. `$elemMatch` exige que **el mismo elemento** cumpla todas las condiciones. Para "un paquete frágil y pesado", la correcta es `$elemMatch`.

| Otros operadores | Uso | Detalle |
| :--- | :--- | :--- |
| `$type` | Filtrar por tipo BSON | Detecta datos cargados con el tipo equivocado |
| `$regex` | Expresión regular | Solo anclada al inicio (`^Res`) puede usar un índice |
| `sort`, `limit`, `skip` | Ordenar y paginar | Un `skip` grande recorre igual todo lo que saltea |

## 8.12 Índices con intención

**Índices: reducir trabajo.** Sin índice, el plan es un **`COLLSCAN`**: examina muchos documentos. Con el índice adecuado (por ejemplo, `estado + fecha`), es un **`IXSCAN`**: ubicación selectiva y menos documentos examinados.

```javascript
db.pedidos.createIndex({ estado: 1 })
db.pedidos.createIndex({ clienteId: 1, fecha: -1 })
```

> **El índice debe responder a consultas reales.** Acelera las lecturas compatibles, pero consume almacenamiento y agrega trabajo a las escrituras. No se crean "por si acaso". Pregunta de la clase: **¿qué consulta concreta justifica cada índice?**

| Tipo | Uso |
| :--- | :--- |
| `_id` | Automático y único |
| Simple y compuesto | Uno o varios campos, con orden ascendente o descendente |
| **Multiclave** | Automático si el campo es un arreglo: una entrada por elemento. Un índice compuesto admite **un solo** campo arreglo |
| Parcial | Solo los documentos que cumplen `partialFilterExpression` |
| Único | Rechaza duplicados (`E11000`) |
| TTL | Borra documentos vencidos según un campo de fecha |
| Texto y geoespacial | Búsqueda por palabras y por ubicación |

### Índice compuesto y regla ESR

El orden de los campos sigue la regla **ESR**: primero los campos de **igualdad** (*Equality*), después los de **ordenamiento** (*Sort*) y al final los de **rango** (*Range*). Es la regla del prefijo izquierdo del Parcial 1, con el ordenamiento en el medio.

| Índice | Consulta: `ruta` igual a un valor y `fecha_despacho` en un rango (200.000 envíos) |
| :--- | :--- |
| `{ ruta: 1, fecha_despacho: 1 }` | **811 claves examinadas para 811 resultados**: la igualdad acota a esa ruta y el rango recorre un tramo contiguo |
| `{ fecha_despacho: 1, ruta: 1 }` | **1.531 claves**: recorre las fechas de todas las rutas y descarta las ajenas |

Un índice compuesto sirve también para consultas sobre su **prefijo**: `{ ruta: 1, fecha_despacho: 1 }` atiende un filtro solo por `ruta`, pero no uno solo por `fecha_despacho`.

### Todo índice tiene costo

- Cada inserción, borrado y modificación de un campo indexado **mantiene el índice**. En la actividad, dos índices secundarios sumaron un **31 %** al tiempo de escritura.
- Ocupan espacio y compiten por la caché: 4,4 MB de índices sobre 124 MB de datos en la prueba de volumen.
- `db.coleccion.aggregate([{ $indexStats: {} }])` muestra cuántas veces se usó cada índice, para detectar los que sobran. Las ejecuciones de `explain()` no suman en esos contadores.

## 8.13 `explain()`: evidencia del plan

**No afirmar "mejoró": demostrar qué cambió.**

```javascript
db.pedidos.find({ clienteId: 77 }).sort({ fecha: -1 }).explain("executionStats")
```

| Qué mirar | Qué dice |
| :--- | :--- |
| `winningPlan` | El plan elegido: `COLLSCAN` o `IXSCAN` |
| `totalDocsExamined` | Documentos leídos |
| `totalKeysExamined` | Entradas de índice recorridas |
| `nReturned` | Documentos devueltos |

Se compara **antes y después** del índice. La evidencia importa más que el comando.

| Modo | Ejecuta la consulta | Para qué |
| :--- | :--- | :--- |
| `queryPlanner` (por defecto) | No | Ver qué plan eligió |
| `executionStats` | **Sí** | Medir trabajo real (cuidado: con una escritura, la ejecuta) |
| `allPlansExecution` | Sí | Comparar el plan ganador con los descartados |

| Etapa | Significa | Equivalente en SQL |
| :--- | :--- | :--- |
| `COLLSCAN` | Recorre la colección completa | `Table scan` / `Seq Scan` |
| `IXSCAN` | Recorre un índice | `Index range scan` / `Index Scan` |
| `FETCH` | Trae los documentos señalados por el índice | Acceso a la fila |
| `SORT` | Ordena en memoria | `filesort` / `Sort` |
| `PROJECTION_COVERED` | Se resuelve **solo con el índice** (`totalDocsExamined: 0`) | Índice de cobertura |

**Las tres cifras clave:** `totalKeysExamined`, `totalDocsExamined` y `nReturned`. Lo ideal es que sean parecidas: `keys ≈ docs ≈ returned`. En la actividad, sin índice se examinaban 200.000 documentos para devolver 811; con el índice adecuado, 811 para 811.

### Trampas al medir

- **La primera ejecución incluye la planificación.** Con 15 documentos, la consulta con índice tardó 27 ms frente a 7 ms sin índice, porque 25 ms eran de `optimizationTimeMillis`. El trabajo, en cambio, bajó de 15 a 3 documentos examinados.
- **Con colecciones chicas el tiempo es ruido**: se compara el trabajo y se prueba con volumen.
- **`executionStats` ejecuta**: un `explain` de un `updateMany` modifica datos.

## 8.14 Aggregation Pipeline

Los documentos atraviesan **etapas de transformación**: cada una recibe los documentos de la anterior y entrega los suyos a la siguiente.

```text
$match → $unwind → $group → $project → $sort
```

Pensarlo como una **tubería** ayuda a razonar qué entra, qué sale y cuánto trabajo hace cada etapa.

### Pipeline aplicado: ventas por producto a partir de `items[]`

```javascript
db.pedidos.aggregate([
  { $match: { estado: "confirmado" } },
  { $unwind: "$items" },
  { $group: {
      _id: "$items.sku",
      unidades: { $sum: "$items.cantidad" },
      importe:  { $sum: { $multiply: ["$items.cantidad", "$items.precioUnitario"] } }
  } },
  { $sort: { importe: -1 } }
])
```

| Etapa | Qué hace acá |
| :--- | :--- |
| `$match` | **Reduce** el conjunto: solo los pedidos confirmados |
| `$unwind` | **Abre** el array: un documento por ítem |
| `$group` | **Calcula** métricas por SKU |
| `$sort` | **Ordena** el resultado |

> El **orden de las etapas** puede afectar el trabajo y el rendimiento: `$match` va primero.

### Las etapas y su equivalente SQL

| Etapa | Equivalente SQL aproximado | Nota |
| :--- | :--- | :--- |
| `$match` | `WHERE` / `HAVING` | Al comienzo, es la **única** etapa que aprovecha un índice para filtrar |
| `$group` | `GROUP BY` | `_id` es la clave de agrupación: `{ _id: "$transportista.nombre", total: { $sum: 1 } }` |
| `$sort` | `ORDER BY` | Puede usar un índice solo antes de cualquier `$group` |
| `$project` / `$addFields` | Lista del `SELECT` | Elegir, renombrar o calcular campos |
| `$lookup` | `LEFT OUTER JOIN` | Usa el índice de `foreignField` en la colección que se une, si existe |
| `$unwind` | Un documento por elemento | Sin `preserveNullAndEmptyArrays`, descarta los documentos con el arreglo vacío |
| `$limit`, `$skip` | `LIMIT`, `OFFSET` | |

```javascript
// Demoras por transportista (la consulta prioritaria del escenario de logística)
db.envios.aggregate([
  { $match: { minutos_demora: { $gt: 0 } } },
  { $group: { _id: "$transportista.nombre",
              envios_demorados: { $sum: 1 },
              promedio_min: { $avg: "$minutos_demora" } } },
  { $sort: { promedio_min: -1 } },
  { $project: { _id: 0, transportista: "$_id", envios_demorados: 1,
                promedio_min: { $round: ["$promedio_min", 0] } } }
])
```

**El orden de las etapas cambia el trabajo.** Hacer `$lookup` de todos los envíos y filtrar al final procesa todo para descartarlo después. El `$match` va primero, y no conviene confiar en que el optimizador reordene. Un error frecuente: escribir `"transportista.nombre"` sin el `$` dentro de `$group`, que lo convierte en un texto fijo en lugar de una referencia al campo.

## 8.15 Validación de esquema

**Flexibilidad con reglas explícitas:**

```javascript
db.createCollection("pedidos", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["nroPedido", "estado", "total"],
    properties: {
      nroPedido: { bsonType: "string" },
      total:     { bsonType: "decimal" }
    }
  } }
})
```

> **MongoDB sí valida en el motor.** Puede exigir campos, tipos y reglas por colección. La afirmación "toda la validación queda en la aplicación" (de versiones viejas del material) hoy es **incompleta**.

### Validar una colección que ya tiene datos

```javascript
db.runCommand({
  collMod: "tiendas",
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["Address", "City", "Country", "Inventory"],
    properties: { Inventory: { bsonType: "array" } }
  } },
  validationLevel: "strict",     // también "moderate"
  validationAction: "error"      // también "warn"
})
```

| Opción | Efecto |
| :--- | :--- |
| `validationLevel: "strict"` | Valida **todas** las inserciones y actualizaciones |
| `validationLevel: "moderate"` | No valida las actualizaciones de documentos que ya eran inválidos |
| `validationAction: "error"` | Rechaza la escritura (código 121, `DocumentValidationFailure`) |
| `validationAction: "warn"` | Acepta y registra una advertencia |

> **Antes de aplicar la regla, verificar los documentos existentes:** `countDocuments({ $nor: [{ $jsonSchema: esquema }] })` debe dar 0. `collMod` no revisa ni borra lo que ya está, pero con `strict` fallará toda actualización que deje inválido un documento, y `mongorestore` crea la colección **con el validador antes de cargar los datos**: rechazaría los documentos inválidos del propio respaldo.

## 8.16 Atomicidad y transacciones

**Modelar bien puede reducir la necesidad de transacciones distribuidas.**

| Documento único | Varios documentos |
| :--- | :--- |
| Una escritura sobre **un único documento es atómica**, aunque modifique varios campos o subdocumentos | MongoDB soporta **transacciones multidocumento** cuando el caso realmente necesita atomicidad entre documentos o colecciones |

Por eso embeber es atractivo: lo que se modifica junto, se modifica de una vez. Las transacciones multidocumento requieren un **replica set** o un clúster fragmentado: en un `mongod` *standalone* no hay. Y son más costosas: si el diseño las necesita en cada operación, conviene revisar el agregado.

## 8.17 Replica set y sharding

Dos problemas distintos: **disponibilidad** y **distribución**.

| | Replica set | Sharded cluster |
| :--- | :--- | :--- |
| Qué es | Varios procesos `mongod` mantienen **copias** del conjunto de datos | Distribuye los datos **entre shards** |
| Piezas | Un **primary** y varios **secondaries**; ante una falla puede ocurrir una **elección automática** | **`mongos`** enruta las consultas; los **config servers** guardan los metadatos del clúster |
| Objetivo principal | Redundancia y **alta disponibilidad** | **Escalar** datos y carga horizontalmente |

Son las dos piezas de la [segunda tensión](#710-segunda-tensión-una-instancia-deja-de-alcanzar) de la Unidad 7 (replicación y sharding) aplicadas a MongoDB. Un replica set también es el requisito para las transacciones multidocumento y para la recuperación a un punto en el tiempo con el *oplog*.

## 8.18 Seguridad: lo mínimo que un DBA no puede omitir

| Autenticación | RBAC | Red / TLS | Backups |
| :--- | :--- | :--- | :--- |
| Habilitar el control de acceso; **no operar una instancia expuesta sin autenticación** | Usuarios y roles con **privilegio mínimo** | Limitar la exposición y **cifrar** las comunicaciones | **Probar la restauración**: un backup sin restore probado no alcanza |

La segunda actividad de la unidad desarrolló cada uno de estos cuatro puntos: está en las secciones [8.20](#820-la-guardia-dba-qué-revisar-al-tomar-una-instancia) a [8.27](#827-diagnosticar-puedo-leer-pero-no-modificar).

## 8.19 Desafío MongoDB y criterios de logro

**Del requerimiento al documento**, en grupo:

| 1 · Diseñar | 2 · Cargar | 3 · Consultar | 4 · Optimizar | 5 · Controlar |
| :--- | :--- | :--- | :--- | :--- |
| Proponer colecciones y documentos; justificar *embedding* y referencias | Dataset pequeño pero representativo, con arrays y subdocumentos | CRUD + 4 consultas + 1 *pipeline* de agregación | Crear un índice y comparar `explain()` antes y después | Agregar validación y defender una decisión técnica |

**Escenarios sugeridos:** e-commerce (pedidos, catálogo, clientes), reservas (alojamientos, reservas, huéspedes), **logística** (envíos, estados, eventos: el que resolvimos), IoT (dispositivos, mediciones, alertas), soporte (tickets, comentarios, historial) y contenido (publicaciones, autores, etiquetas).

**Evidencias de entrega:** el **modelo** (documento de ejemplo + justificación), el **motor real** (salidas de `mongosh` o Compass: CRUD, *pipeline*, validador) y el **rendimiento** (`explain()` antes y después, con su lectura técnica).

| Criterio | Logrado | Parcial | No logrado |
| :--- | :--- | :--- | :--- |
| Modelo documental | Coherente con accesos y crecimiento | Funciona con decisiones poco justificadas | **Traducción 1:1 del relacional** |
| Consultas y *pipeline* | Resuelven el escenario y se verifican | Resolución incompleta | No ejecutan o no responden |
| Índice + `explain` | Evidencia clara antes y después | Índice sin análisis suficiente | Sin evidencia |
| Validación y defensa | Reglas útiles y decisión defendida | Reglas o defensa débiles | Sin control ni justificación |

> **Cierre de la clase.** Aprender MongoDB **no es** memorizar comandos ni convertir cada tabla en una colección. **Es** diseñar desde los patrones de acceso y comprender el costo de cada decisión, y **demostrarlo**: ejecutar, medir, validar y defender con evidencia del motor. Pregunta de salida: *¿qué decisión de diseño cambiarías si la cardinalidad creciera 100 veces?*

## 8.20 La guardia DBA: qué revisar al tomar una instancia

> **Desde acá, profundización con la segunda actividad** (seguridad y respaldo en MongoDB): cómo se llevan a la práctica los cuatro mínimos de [8.18](#818-seguridad-lo-mínimo-que-un-dba-no-puede-omitir).

| Qué | Cómo se ve | Por qué |
| :--- | :--- | :--- |
| Versión y estado | `db.version()`, `db.serverStatus().uptime`, `.connections` | Saber con qué se trabaja y si hay presión de conexiones |
| Autenticación | `db.adminCommand({ getCmdLineOpts: 1 }).parsed.security` | Muestra la configuración **efectiva**, no la del archivo |
| Exposición en la red | `net.bindIp`; `ss -ltnp` en el servidor; el firewall | Si escucha en todas las interfaces, cualquiera de la red llega al puerto |
| Cifrado | `net.tls.mode` | Sin TLS, credenciales y datos viajan en claro |
| Recuperabilidad | Último respaldo y última restauración probada | Un respaldo nunca restaurado es una promesa |

> Desde MongoDB 3.6 los binarios escuchan por defecto **solo en `localhost`**. El cambio llegó después de años de filtraciones masivas de instancias sin autenticación expuestas a internet.

## 8.21 Tres capas, tres fallas distintas

| Capa | Pregunta | Error típico | Código |
| :--- | :--- | :--- | :--- |
| **Conexión** | ¿Llego al puerto? | `ECONNREFUSED`, *timeout*, error de TLS | — |
| **Autenticación** | ¿Soy quien digo ser? | `Authentication failed` | 18 |
| **Autorización** | ¿Puedo hacer esto? | `not authorized on <base> to execute command` | 13 |

Se diagnostica **de abajo hacia arriba**. Si `find()` funciona, la conexión y la autenticación están bien: un `updateOne()` rechazado es un problema de **autorización**. Algunos comandos (`ping`, `hello`, `buildInfo`) responden sin autenticarse, así que sirven para probar la capa de conexión.

Otros códigos que conviene reconocer: **11000** (`DuplicateKey`), **121** (`DocumentValidationFailure`) y **10107** (`NotWritablePrimary`, se escribió en un secundario).

## 8.22 Autenticación

**Orden correcto para activarla:**

1. **Crear el administrador.** Si la autenticación ya está activa y no hay usuarios, la **excepción de localhost** permite crear el primero solo desde el mismo servidor.
2. **Activar** `security.authorization: enabled` en `mongod.conf`.
3. **Reiniciar** el servicio.
4. **Verificar el rechazo**: sin credenciales, `find()` responde `Command find requires authentication`.

```javascript
db.getSiblingDB("admin").createUser({
  user: "adminLab",
  pwd: passwordPrompt(),          // la clave se pide por teclado: no queda en el script ni en el historial
  roles: [{ role: "userAdminAnyDatabase", db: "admin" }, { role: "readWriteAnyDatabase", db: "admin" }]
})
```

| Concepto | Detalle |
| :--- | :--- |
| Sin `authorization: enabled` | Cualquiera ejecuta cualquier cosa, **aunque existan usuarios** |
| Base de autenticación | Cada usuario pertenece a la base donde se creó. Se conecta con `--authenticationDatabase <esa base>` |
| `Authentication failed` | Es **deliberadamente ambiguo**: no distingue usuario inexistente, clave incorrecta o base equivocada |
| Mecanismos | SCRAM-SHA-256 por defecto; también x.509; LDAP y Kerberos son de la edición Enterprise |
| Claves | Nunca en el script ni en una captura: `passwordPrompt()`, `-p` sin valor o un archivo de configuración con permisos 600 |

## 8.23 Autorización: RBAC

Un **privilegio** es un **recurso** (base, colección o clúster) más un conjunto de **acciones** (`find`, `insert`, `update`, `createIndex`...). Un **rol** agrupa privilegios, y un usuario recibe roles.

| Rol integrado | Permite | No permite / Cuidado |
| :--- | :--- | :--- |
| `read` | Consultar (`find`, `listCollections`, `listIndexes`) | Insertar, modificar o borrar |
| `readWrite` | Lo anterior más escribir, crear colecciones e índices | Administrar usuarios |
| `dbAdmin` | Tareas de esquema, índices y estadísticas | Leer datos de negocio |
| `userAdmin` | Crear usuarios y roles **en esa base** | |
| `dbOwner` | `readWrite` + `dbAdmin` + `userAdmin` | Es el objetivo típico de una escalada |
| `userAdminAnyDatabase` | Administrar usuarios de cualquier base | No lee datos, pero **puede concederse cualquier rol**: en la práctica es un superusuario |
| `clusterMonitor` | Observar el servidor | |
| `backup` | Leer todo lo necesario para `mongodump` | |
| `restore` | Escribir lo necesario para `mongorestore` | **Amplio**: en el laboratorio permitió insertar documentos y crear usuarios |
| `root` | Todo | |

**Respaldo y restauración, en usuarios separados.** El usuario de respaldo trabaja todos los días de forma automática; el de restauración se usa en emergencias. Un único usuario con los dos roles convertiría a la tarea programada en una cuenta casi administrativa.

**Cómo se prueba el mínimo privilegio:**

| Prueba | Ejemplo | Resultado esperado |
| :--- | :--- | :--- |
| Positiva | El lector hace `find()` | Funciona |
| Negativa | El lector hace `updateOne()` | `not authorized`, **por la razón correcta** |
| Escalada | El operador intenta `grantRolesToUser(..., ["dbOwner"])` | Rechazado |
| Aislamiento | El operador escribe en otra base | Rechazado |

| Tema | MySQL | PostgreSQL | MongoDB |
| :--- | :--- | :--- | :--- |
| Identidad | `'usuario'@'host'` | Rol con `LOGIN` + `pg_hba.conf` | Usuario **dentro de una base** |
| Permisos por objeto | `GRANT ... ON base.tabla` | `GRANT ... ON tabla` | Privilegio = recurso + acciones |
| Ver permisos | `SHOW GRANTS` | `\du`, `\dp` | `getUser`, `connectionStatus({ showPrivileges: true })` |
| Error de permiso | `ERROR 1142 ... denied` | `permission denied for table` | `not authorized on <db>` (código 13) |

## 8.24 Red: exposición de la instancia

- `net.bindIp: 0.0.0.0` hace escuchar en todas las interfaces. Aunque haya autenticación, expone el puerto 27017 a toda la red, habilita ataques de fuerza bruta contra las credenciales y, sin TLS, deja viajar los datos en claro.
- Lo correcto es escuchar solo en las interfaces necesarias y **filtrar con el firewall** la subred que debe llegar.
- Cambiar el puerto no protege: solo esconde el servicio.

Las defensas se **suman** en capas, y ninguna reemplaza a otra:

```text
Red (bindIp + firewall) → Autenticación → Autorización (RBAC) → TLS → Cifrado en reposo y auditoría
```

La auditoría y el cifrado en reposo del propio motor son de la edición Enterprise; en Community se cifra a nivel del disco o del sistema operativo.

## 8.25 TLS

**Qué aporta:** confidencialidad (nadie lee lo que viaja), integridad (nadie lo altera) y **autenticación del servidor** (el cliente sabe con quién habla). No reemplaza a la autenticación de usuarios.

| Pieza | Para qué |
| :--- | :--- |
| Autoridad certificante (`ca.crt`) | Firma los certificados; el cliente confía en ella con `--tlsCAFile` |
| Certificado del servidor | Su nombre (SAN) debe coincidir con el que usa el cliente para conectarse |
| Clave privada (`.pem`) | Con permisos 600 y dueño `mongodb` |

| Modo (`net.tls.mode`) | Comportamiento |
| :--- | :--- |
| `disabled` (por defecto) | Sin TLS |
| `allowTLS` / `preferTLS` | Acepta las dos formas: sirve para migrar |
| `requireTLS` | Rechaza toda conexión sin cifrar |

**TLS de servidor frente a TLS mutuo:** con `allowConnectionsWithoutCertificates: true`, el cliente solo necesita confiar en la CA. Sin esa opción, el servidor exige también un **certificado de cliente** firmado por la CA (`--tlsCertificateKeyFile`): es **TLS mutuo**, que verifica quién se conecta.

| Error | Causa |
| :--- | :--- |
| `self-signed certificate in certificate chain` | Falta `--tlsCAFile` en el cliente |
| *Hostname mismatch* | El nombre usado no está en el SAN del certificado |
| `certificate has expired` | Certificado vencido |

| | MySQL | PostgreSQL | MongoDB |
| :--- | :--- | :--- | :--- |
| Activar | `ssl-ca`, `ssl-cert`, `ssl-key` | `ssl = on` | `net.tls.*` |
| Obligar | `require_secure_transport = ON` | `hostssl` en `pg_hba.conf` | `mode: requireTLS` |

## 8.26 Respaldo y recuperación

| Estrategia | Herramienta | Ventaja | Límite |
| :--- | :--- | :--- | :--- |
| **Lógico** | `mongodump` / `mongorestore` | Portable entre versiones y servidores; restaura por base o colección | Lento con mucho volumen; sin `--oplog` no es consistente entre colecciones |
| **Físico** | Copia de archivos con el servicio detenido, o snapshot con `fsyncLock` | Rápido | Misma versión; hay que detener o congelar escrituras |
| **Administrado** | Percona Backup for MongoDB, Ops Manager, Atlas | Programado, con recuperación a un punto en el tiempo | Infraestructura o costo adicional |
| `mongoexport` | JSON o CSV | Intercambio de datos | **No es un respaldo**: pierde tipos BSON e índices |

**Qué contiene un volcado:** por cada colección, un `.bson` con los documentos y un `.metadata.json` con las definiciones de índices, que se **reconstruyen** al restaurar. También un `prelude.json` con datos del servidor. Los usuarios **no** se incluyen salvo con `--dumpDbUsersAndRoles`.

| Opción de `mongorestore` | Para qué |
| :--- | :--- |
| `--nsInclude 'base.coleccion'` | Restaurar solo una parte |
| `--nsFrom 'base.*' --nsTo 'base_restore.*'` | **Restaurar con otro nombre**, sin pisar el original |
| `--dryRun` | Ver qué haría, sin hacerlo |
| `--drop` | Borra cada colección antes de restaurarla: **destructivo** |

> Por defecto `mongorestore` **no sobrescribe**: los `_id` que ya existen fallan con `E11000 duplicate key`. Las opciones `--db` y `--collection` están obsoletas; se usan los espacios de nombres.

### Cómo se valida una recuperación

| Nivel | Qué se compara | Qué demuestra |
| :--- | :--- | :--- |
| Recuentos | `countDocuments()` en origen y copia | Que **hay** datos |
| Contenido | Algunos documentos completos, o los mismos `_id` | Que son **los mismos** datos |
| Huella | `dbHash`, `sha256` de una exportación ordenada | Igualdad completa |
| Índices y validador | `getIndexes()`, `getCollectionInfos()` | Que la estructura volvió |
| Funcional | La misma consulta de negocio en las dos bases | Que la aplicación funcionaría |

**Buenas prácticas:** registrar el recuento justo antes del respaldo, restaurar **en otro lugar**, aplicar la regla **3-2-1** (tres copias, dos medios, una fuera del sitio) y **medir** el tiempo de restauración. El RTO se **mide**; el RPO lo fija la **frecuencia** del respaldo. La recuperación a un punto en el tiempo con el oplog (`--oplog` al respaldar y `--oplogReplay` al restaurar) requiere un **replica set**.

## 8.27 Diagnosticar "puedo leer pero no modificar"

1. **Conexión:** funciona, porque `find()` responde.
2. **Autenticación:** funciona, porque el motor aceptó el usuario.
3. **Autorización:** falla. `db.runCommand({ connectionStatus: 1, showPrivileges: true })` muestra los roles y acciones efectivos: el usuario tiene `read` y le falta `update`.
4. **Solución:** `grantRolesToUser("usuario", [{ role: "readWrite", db: "logistica" }])`, aplicando mínimo privilegio. Los privilegios nuevos rigen en las **conexiones nuevas**.

## Preguntas de repaso · Unidad 8

1. ¿Cuáles son las tres preguntas de diseño de la clase (lecturas, cambios, crecimiento) y por qué evitan "tablas convertidas a JSON"?
2. ¿Qué tipos agrega BSON respecto de JSON y para qué sirve cada uno? ¿Por qué no conviene apoyar reglas de negocio en el `ObjectId`?
3. ¿Por qué "esquema flexible ≠ ausencia de diseño"? ¿Qué herramienta del motor lo controla?
4. ¿Por qué los ítems de un pedido se embeben como una "foto" del momento de compra, y por qué el cliente se referencia?
5. Clasificá por cardinalidad y decidí: teléfonos de un cliente, pedidos de un cliente, telemetría de un dispositivo.
6. ¿Qué es el antipatrón "SQL traducido 1:1"? ¿Cuándo conviene la duplicación controlada?
7. Resolvé el microdesafío: perfil de usuario, catálogo e IoT. ¿Embed, referencia o colección separada?
8. ¿Qué hay que hacer antes de un `deleteMany` según la práctica segura?
9. ¿Qué cuatro valores de `explain("executionStats")` hay que comparar antes y después de un índice?
10. En el *pipeline* de ventas por producto, ¿qué hace cada etapa y por qué `$match` va primero?
11. ¿Qué es atómico en MongoDB sin transacciones? ¿Qué requieren las transacciones multidocumento?
12. ¿Qué diferencia hay entre un replica set y un sharded cluster? ¿Qué hacen `mongos` y los config servers?
13. ¿Cuáles son los cuatro mínimos de seguridad de la clase?
14. ¿Qué embeberías y qué referenciarías en un envío con paquetes y eventos de seguimiento? Justificá con cardinalidad y crecimiento.
15. ¿Por qué `{ "paquetes.fragil": true, "paquetes.peso_kg": { $gt: 10 } }` puede devolver envíos que no tienen ningún paquete frágil y pesado?
16. Con `ruta` por igualdad y `fecha_despacho` por rango, ¿en qué orden van los campos del índice y por qué?
17. Un `explain` muestra `COLLSCAN`, 200.000 documentos examinados y 811 devueltos. ¿Qué concluís?
18. ¿En qué orden se activa la autenticación y qué pasa si se activa antes de crear el administrador?
19. ¿Por qué `userAdminAnyDatabase` equivale en la práctica a un superusuario?
20. ¿Qué agrega el TLS mutuo al TLS de servidor?
21. ¿Por qué `mongorestore` sobre la misma colección da `E11000`, y cuál es la forma segura de probar un respaldo?
22. ¿Por qué hay que verificar los documentos existentes antes de aplicar un validador con `collMod`?

---

# Unidad 9 · Redis, Cassandra, Neo4j y CAP

La unidad sigue la **clase 9** de la cátedra (*Comparar: tres modelos, tres necesidades, una decisión fundamentada*). Las secciones 9.1 a 9.10 recorren la clase en su orden: primero **experimentar** con cada motor y después **explicar la distribución**. Cada motor se complementa con lo que se comprobó en la primera actividad. Desde la 9.11 viene la **profundización** con la segunda actividad: cómo se decide y se defiende una arquitectura políglota (OmniMarket).

## 9.1 La pregunta de la unidad

> *¿Qué motor elegirías y por qué?*

Un mismo sistema de comercio electrónico tiene tres necesidades muy distintas:

| Sesiones | Eventos | Relaciones |
| :--- | :--- | :--- |
| ¿Cómo mantener carritos y sesiones **que caducan**? | ¿Cómo registrar **millones de acciones** por usuario y fecha? | ¿Cómo explorar productos relacionados y **recomendaciones**? |

**Objetivo de la clase:** decidir **a partir de evidencia, no por popularidad**.

| Experimentar | Comparar | Justificar |
| :--- | :--- | :--- |
| Ejecutar operaciones concretas en Redis, Cassandra y Neo4j | Contrastar patrones de acceso, datos y límites de cada modelo | Explicar replicación, particiones de red y compromisos CAP |

### Tres modelos, tres preguntas

No son sustitutos perfectos: cada uno responde una pregunta distinta.

| Redis | Cassandra | Neo4j |
| :--- | :--- | :--- |
| ¿Qué dato recupero **inmediatamente por una clave**? | ¿Qué consultas **escalan** sobre grandes volúmenes distribuidos? | ¿Qué **conexiones** necesito recorrer y descubrir? |

## 9.2 Redis: clave-valor en memoria

**La clave determina el acceso.** Redis es, esencialmente, una base **en memoria**: no consulta por contenido ni por relaciones.

| Clave | Estructuras | Tiempo |
| :--- | :--- | :--- |
| `session:ana` → estado de la sesión | *Strings*, *hashes*, *sets*, *sorted sets* y listas | **TTL** para datos temporales: expiración automática |

> *Una sesión de usuario debe vencer sola y leerse en milisegundos miles de veces por segundo. En SQL habría que guardar la fecha de vencimiento y borrar con un proceso programado. En Redis, la clave vence sola.*

### Experimentar con `redis-cli`

```text
SET session:ana activa EX 120        → OK         (crea la clave con 120 s de vida)
GET session:ana                      → "activa"
TTL session:ana                      → 117        (segundos que le quedan)
HSET carrito:ana sku A10 cantidad 2  → 2          (campos nuevos creados)
HGETALL carrito:ana                  → sku, A10, cantidad, 2
```

**Para interpretar:** después de expirar, `GET session:ana` devuelve `(nil)` y `TTL` devuelve `-2`.

| Valor de `TTL` | Significa |
| :--- | :--- |
| Número positivo | Segundos que faltan para que venza |
| `-1` | La clave existe pero **no tiene** vencimiento |
| `-2` | La clave **no existe** (por ejemplo, ya venció) |

### Elegir una estructura: no todo es un *string*

| Estructura | Para qué (clase) |
| :--- | :--- |
| **Hash** | Atributos de un carrito o un perfil pequeño |
| **Set** | Miembros únicos: productos favoritos |
| **Sorted set** | Ranking ordenado por puntuación |

```text
ZADD ranking 10 ana 20 luis 15 eva
ZREVRANGE ranking 0 2 WITHSCORES     → luis 20, eva 15, ana 10
SADD favoritos:ana A10 B22
SMEMBERS favoritos:ana               → A10, B22 (sin orden garantizado)
EXPIRE favoritos:ana 60
```

**Para interpretar:** el *set* no tiene orden ni repetidos; el *sorted set* ordena por puntaje. Y si Redis se reinicia **sin persistencia**, se pierde **todo**: vive en memoria.

**Lo que se comprobó en la actividad**, estructura por estructura:

| Estructura | Ejemplo | Comandos | Retornos que conviene entender |
| :--- | :--- | :--- | :--- |
| `STRING` | `sesion:U01` | `SET`, `GET`, `DEL`, `EXISTS` | `SET` pisa el valor anterior; `DEL` devuelve cuántas claves borró; `EXISTS`, 1 o 0 |
| `HASH` | `carrito:U01` (producto → cantidad) | `HSET`, `HGETALL`, `HINCRBY`, `HDEL`, `HLEN` | **`HSET` devuelve la cantidad de campos nuevos**: 0 si solo actualizó uno existente |
| `SET` | `favoritos:U01` | `SADD`, `SISMEMBER`, `SREM` | Sin repetidos; `SADD`/`SREM` devuelven 1 si cambiaron algo |
| `SORTED SET` | `ranking_productos` | `ZADD`, `ZINCRBY`, `ZRANGE ... REV WITHSCORES` | Cada miembro tiene un puntaje que lo ordena. `ZREVRANGE` está obsoleto desde la versión 6.2 |
| `LIST` | Una cola de tareas | `LPUSH`, `RPOP` | Orden de inserción |

**Nombres de clave `tipo:id`** (`sesion:U01`, `carrito:U01`): ordenan el espacio de claves y permiten **restringir permisos por patrón** en una ACL (`~sesion:*`).

### Persistencia y límites

Rendimiento no significa ausencia de compromisos:

| RDB | AOF | Límites |
| :--- | :--- | :--- |
| *Snapshots* periódicos: recuperación con **posible pérdida reciente** | Registro de operaciones: durabilidad **según la configuración** | RAM, política de expulsión, replicación y operación **deben diseñarse** |

**Respaldo con RDB:** `BGSAVE` (en segundo plano; `SAVE` **bloquea** el servidor) → confirmar que terminó con `LASTSAVE` o `INFO persistence` → ubicar el archivo con `CONFIG GET dir` y `CONFIG GET dbfilename` → copiarlo → restaurarlo en **otra instancia** y comparar las claves. Redis escribe la foto nueva en un archivo temporal y recién al terminar reemplaza a `dump.rdb`: si se copia antes, se lleva la foto anterior.

### Memoria llena: política de expulsión

| Política | Comportamiento | Para qué |
| :--- | :--- | :--- |
| `allkeys-lru` | Expulsa las claves menos usadas | Una **caché**: todo se puede recalcular |
| `volatile-ttl` | Expulsa primero las que están por vencer, **solo entre las que tienen vencimiento** | Mezcla de datos con y sin vencimiento |
| `noeviction` | Rechaza las escrituras | Datos que no deben desaparecer en silencio |

Lo expulsado **se pierde**. Redis no debe ser la **única** fuente de un dato que no se puede reconstruir.

### Arquitectura

Distribución no es una propiedad de todas las instalaciones:

| Instancia única | Réplica | Cluster |
| :--- | :--- | :--- |
| Simple y suficiente para la práctica inicial | Puede atender lecturas; replicación **habitualmente asíncrona** | Distribuye las claves por ***slots*** (16.384); requiere configuración explícita |

- **Réplica** (habitualmente asíncrona), **Sentinel** (vigila y conmuta automáticamente) y **Cluster** (reparte las claves en 16.384 *slots*). Con replicación asíncrona, una conmutación puede perder las últimas escrituras.
- **Cada comando es atómico.** `MULTI`/`EXEC` ejecuta un bloque en secuencia sin otros comandos intercalados, pero **no tiene retroceso**: si un comando falla al ejecutarse, los demás se aplican igual. `WATCH` hace abortar el `EXEC` si una clave vigilada cambió (control optimista). Para lógica condicional atómica se usa un script **Lua**.

### ACL: qué puede hacer cada usuario

```text
ACL SETUSER app_user on >clave ~sesion:* ~carrito:* +@read +@write -@dangerous +ping
```

| Regla | Significado |
| :--- | :--- |
| `on` / `off` | Usuario activo o inactivo |
| `>clave` | Su contraseña (en los informes, siempre un marcador) |
| `~patrón` | Claves que puede tocar |
| `+@categoría` / `-@categoría` | Permite o quita una categoría de comandos |
| `+comando` | Permite un comando puntual |

Un comando no permitido responde **`NOPERM`**. Tres trampas que se comprobaron en el laboratorio:

- **Los patrones de claves no limitan los comandos que afectan a toda la base.** `FLUSHALL` y `FLUSHDB` están en `@write` y no reciben claves: un usuario con `+@read +@write` vació la base completa. Se corrige con **`-@dangerous`**, que quita `FLUSHALL`, `FLUSHDB`, `KEYS`, `CONFIG` y otros.
- **El usuario `default`** existe sin contraseña y con acceso total. Una conexión sin `AUTH` lo usa y saltea la ACL de `app_user`: hay que protegerlo.
- **Las ACL viven en memoria.** Para que sobrevivan a un reinicio se guardan en un archivo de ACL o con `CONFIG REWRITE`.

## 9.3 Cassandra: *wide-column*, pensar primero en la consulta

> *Treinta millones de eventos de navegación por día, que solo se agregan, y una consulta principal: "el historial reciente de un usuario". Cassandra está hecha para eso, a cambio de no permitir consultas arbitrarias.*

Cassandra es una base **distribuida, sin nodo maestro**, pensada para **mucha escritura** y alta disponibilidad.

| Partición | Orden | Consulta |
| :--- | :--- | :--- |
| La ***partition key*** determina la ubicación lógica del dato | Las ***clustering columns*** organizan las filas **dentro** de una partición | El esquema se diseña **para consultas concretas**, no para `JOIN` arbitrarios |

### Tabla orientada a la consulta

```sql
CREATE KEYSPACE IF NOT EXISTS sgdb2026
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
USE sgdb2026;

CREATE TABLE eventos (
  usuario   text,
  fecha     timestamp,
  evento_id uuid,
  tipo      text,
  PRIMARY KEY ((usuario), fecha, evento_id)
) WITH CLUSTERING ORDER BY (fecha DESC, evento_id ASC);
```

| Parte | Función |
| :--- | :--- |
| ***Keyspace*** | El contenedor de tablas; define la **estrategia y el factor de replicación** |
| **Clave de partición** `(usuario)` | Decide en qué nodos vive la fila y agrupa todos los eventos del usuario |
| **Columnas de clustering** `fecha, evento_id` | Ordenan las filas dentro de la partición (más recientes primero); `evento_id` desempata dos eventos con la misma fecha |

**Para interpretar:** es un **laboratorio de nodo único**: RF = 1 no demuestra tolerancia a fallas. La consulta natural **comienza por `usuario`**. Cuidado con las **particiones que crecen sin límite** (un usuario con años de eventos).

### Escribir y leer de acuerdo con la clave

```sql
INSERT INTO eventos (usuario, fecha, evento_id, tipo)
VALUES ('ana', toTimestamp(now()), uuid(), 'click');

SELECT * FROM eventos WHERE usuario = 'ana' LIMIT 10;
```

- **Siempre se indica la clave de partición**: así Cassandra va directo a un lugar.
- Los **rangos** y el `ORDER BY` solo valen sobre las **columnas de clustering**, respetando su orden.
- **`LIMIT` toma las primeras filas en el orden de la tabla.** En el laboratorio, con orden descendente, `LIMIT 3` devolvió los tres eventos **más recientes**; con el orden por defecto, los tres **más antiguos**.

**Para interpretar (pregunta de la clase):** ¿por qué una búsqueda global **por tipo** requeriría otro diseño?

```sql
SELECT * FROM eventos_por_usuario WHERE tipo_evento = 'COMPRA';
-- InvalidRequest: code=2200 ... use ALLOW FILTERING
```

`ALLOW FILTERING` solo **obliga** a recorrer todas las particiones: con volumen es lento e impredecible. La solución de Cassandra es la **desnormalización deliberada**: **otra tabla diseñada para esa consulta** (`eventos_por_tipo`, con `tipo_evento` en la partición), y la aplicación **escribe en las dos**.

> **Trampa de cardinalidad:** `tipo_evento` tiene cinco valores. Con volumen real, cinco particiones crecerían sin límite y concentrarían la carga en pocos nodos (*particiones calientes*). Se agrega un **cubo** a la clave de partición: `((tipo_evento, dia), fecha_evento, evento_id)`.

### Escribir y borrar

| Operación | Comportamiento |
| :--- | :--- |
| `INSERT` y `UPDATE` | Son ***upsert***: si la fila no existe, la crean. En el laboratorio, un `UPDATE` sobre una clave inexistente creó una fila sin dar error |
| `DELETE` | Escribe una **lápida** (*tombstone*) que se limpia más tarde; muchas lápidas degradan las lecturas |
| `INSERT ... IF NOT EXISTS` | **Transacción ligera** con Paxos: más lenta, para casos puntuales |
| `USING TTL 86400` | Vencimiento por fila |

**Camino de escritura:** el dato se anota en el *commit log* y en una estructura en memoria (*memtable*), que luego se vuelca a archivos **inmutables (SSTables)** combinados en segundo plano (*compaction*). Por eso la escritura es rápida y sostenida.

**Fechas:** un `timestamp` escrito sin zona horaria se interpreta con la zona del cliente (`cqlsh`) y se muestra en UTC. En una máquina en hora argentina las horas aparecen desplazadas: conviene escribir la zona (`+0000`).

### Distribución física

Un clúster real tiene varios nodos:

| Concepto | Cómo funciona |
| :--- | :--- |
| **Token / partición** | La clave de partición (por ejemplo `usuario = 'ana'`) pasa por una **función *hash*** y se convierte en un **token**. El token determina qué nodos son dueños de ese dato |
| **Replicación** | El **RF** (*replication factor*) define cuántas copias de cada partición se mantienen |
| **Coordinación** | El **coordinador** recibe la operación y contacta a las réplicas. Como **no hay nodo maestro**, no es un nodo fijo: es el nodo al que el cliente le envió **esa** operación, y puede ser distinto en cada consulta |

### Consistencia configurable: RF y CL son decisiones diferentes

| RF = 3 | CL = `ONE` | CL = `QUORUM` |
| :--- | :--- | :--- |
| Tres réplicas de cada partición, en un clúster apropiado | **Basta una** respuesta de réplica para satisfacer la operación | Con RF = 3, requiere **dos** respuestas |

- **RF** se fija en el *keyspace*; el **CL** (*consistency level*) **se elige en cada operación**.
- **`QUORUM`** = mayoría = ⌊RF ÷ 2⌋ + 1.
- **Regla de consistencia fuerte:** si **R + W > RF**, la lectura se cruza con la última escritura. Con RF = 3, `QUORUM` en las dos (2 + 2 = 4 > 3) es fuerte; `ONE` en las dos (1 + 1 = 2) puede leer un valor viejo.

### Advertencia del laboratorio

| Nodo único | Tres nodos | Evidencia |
| :--- | :--- | :--- |
| Permite CQL, particiones y modelado | Necesarios para **observar RF = 3 y caídas de nodos** | **No afirmar tolerancia a fallas sin ensayar un clúster real** |

### Seguridad y respaldo

- Por defecto no exige credenciales (`AllowAllAuthenticator`). Se activa en `cassandra.yaml` con `PasswordAuthenticator` y `CassandraAuthorizer`; el superusuario inicial `cassandra` debe cambiar su clave. Los roles se administran con `CREATE ROLE` y `GRANT SELECT ON KEYSPACE ... TO rol`.
- `nodetool snapshot` crea **enlaces duros** a las SSTables: instantáneo y casi sin espacio extra. Se restaura copiando las SSTables a una tabla con la misma estructura y cargándolas con `nodetool refresh` o `sstableloader`.

## 9.4 Neo4j: las relaciones son elementos de primera clase

> *"Productos que compraron los clientes que sigo, y que yo todavía no compré." En SQL son varios `JOIN` sobre tablas intermedias, y cada salto más los multiplica. En un grafo es un solo patrón.*

| Elemento | Qué es | Ejemplo |
| :--- | :--- | :--- |
| **Nodo** | Una entidad, con una o más **etiquetas** | Persona, producto o categoría: `(:Cliente)`, `(:Producto)` |
| **Relación** | Une dos nodos; tiene **tipo** y **dirección** | `COMPRO`, `SIGUE`, `PERTENECE_A` |
| **Propiedad** | Atributos en nodos **y en relaciones** | `{nombre: 'Ana'}`, `{cantidad: 2}` |

**Equivalencia con el relacional:** etiqueta ≈ tabla, nodo ≈ fila, relación ≈ clave foránea + `JOIN` o tabla intermedia. La diferencia es que en el grafo **las relaciones están guardadas**: recorrerlas no exige buscar por clave en otra estructura, y el costo depende de la **parte del grafo que se explora**, no del tamaño total.

### Crear un grafo (Cypher, Neo4j Browser)

```cypher
CREATE (a:Cliente  {id: 1, nombre: 'Ana'})
CREATE (p:Producto {sku: 'A10', nombre: 'Teclado'})
CREATE (q:Producto {sku: 'B22', nombre: 'Mouse'})
CREATE (a)-[:COMPRO]->(p)
CREATE (a)-[:COMPRO]->(q);
```

**Para interpretar:** los vínculos son **relaciones persistidas**, no listas de identificadores.

### Consultar patrones: recorrido explícito

```cypher
MATCH (c:Cliente)-[:COMPRO]->(p:Producto)
WHERE c.nombre = 'Ana'
RETURN c.nombre, p.nombre;

MATCH (p:Producto)<-[:COMPRO]-(c:Cliente)
RETURN p.nombre, count(c) AS compras;
```

**Para interpretar (pregunta de la clase):** ¿qué aporta recorrer relaciones frente a múltiples `JOIN`? En SQL cada salto es un `JOIN` que busca por clave en otra tabla; en el grafo, el nodo ya **apunta** a sus vecinos.

### Cuándo conviene

El grafo **no reemplaza automáticamente** todo SQL:

| Fortaleza | Costo | Decisión |
| :--- | :--- | :--- |
| Recorridos de relaciones y patrones variables | Modelado, índices, cardinalidad y **supernodos** | Elegir cuando **el valor está en explorar conexiones** |

Un **supernodo** es un nodo con muchísimas relaciones (un producto que compraron millones de clientes): todo recorrido que pase por él tiene que examinar todas sus relaciones, y la ventaja del grafo se pierde.

### Cypher: CRUD por patrones

```cypher
CREATE (c:Cliente {id: 'U99', nombre: 'Prueba'})                         // crea siempre
MERGE  (c:Cliente {id: 'U01'})                                           // busca el patrón completo; lo crea solo si no está
MATCH  (c:Cliente {id: 'U01'}) SET c.ciudad = 'Resistencia'              // modifica
MATCH  (c:Cliente {id: 'U99'}) DETACH DELETE c                           // borra el nodo y sus relaciones
```

- **`CREATE` frente a `MERGE`:** repetir un script con `CREATE` duplica; con `MERGE`, no. `MERGE` vale para el patrón entero: `MERGE (a)-[:SIGUE]->(b)` crea la relación solo si no estaba.
- **`DELETE` de un nodo con relaciones falla**: Neo4j no deja relaciones "colgando". Se borra con `DETACH DELETE`, o borrando antes las relaciones.
- **Restricción de unicidad:** `CREATE CONSTRAINT FOR (c:Cliente) REQUIRE c.id IS UNIQUE`. Además de rechazar duplicados, crea un índice y protege a los `MERGE` concurrentes.

### Carga con `LOAD CSV`

```cypher
LOAD CSV WITH HEADERS FROM 'file:///productos.csv' AS f
MERGE (p:Producto {id: f.producto_id})
SET p.nombre = f.nombre, p.precio = toInteger(f.precio)
```

- Solo lee del **directorio `import`** del servidor (`server.directories.import`): es una medida de seguridad para que una consulta no lea archivos arbitrarios.
- **Todo llega como texto**: sin `toInteger()`, `"1000"` queda antes que `"200"` al ordenar.
- `UNWIND` convierte una lista en filas, para cargar desde un parámetro.

### Consultas de recorrido y duplicados

```cypher
MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(s:Cliente)-[:COMPRO]->(p:Producto)
WHERE NOT (u)-[:COMPRO]->(p)
RETURN p.nombre, count(DISTINCT s) AS seguidos_que_lo_compraron
ORDER BY seguidos_que_lo_compraron DESC
```

Un patrón devuelve **una fila por camino**: si dos clientes seguidos compraron la misma notebook, aparece dos veces. Se corrige con `RETURN DISTINCT` o agregando con `count(DISTINCT s)`, que además sirve para ordenar por relevancia.

### Seguridad en Neo4j Community

- **Hay autenticación:** el usuario inicial `neo4j` tiene la clave vencida y debe cambiarla al primer ingreso (`ALTER CURRENT USER SET PASSWORD FROM ... TO ...` sobre la base `system`).
- **No hay roles ni privilegios:** `SHOW ROLES` o `GRANT` responden que no están soportados en Community. Un usuario nuevo puede escribir todo. Por eso la consigna no exigía RBAC granular: se compensa con una clave robusta, escuchando solo en localhost y con los permisos del sistema operativo.
- Community tampoco tiene **clúster**, **respaldo en caliente** ni varias bases de usuario: son de Enterprise.

### Respaldo y restauración

| Paso | Comando | Detalle |
| :--- | :--- | :--- |
| Volcado | `neo4j-admin database dump neo4j --to-path=...` | **Fuera de línea**: con el servicio activo responde *"The database is in use"* |
| Carga | `neo4j-admin database load neo4j --from-path=... --overwrite-destination=true` | En una **instancia aislada** (otro directorio y otros puertos), para no pisar el servicio |
| Validación | Recuentos de nodos y relaciones, la misma consulta de negocio, `diff` de las salidas | De 0 nodos y 0 relaciones antes de cargar a los mismos recuentos después; contar prueba que **hay** datos, la consulta y el `diff` prueban que son **los mismos** |

## 9.5 Comparación transversal

Mismo comercio, **tres piezas complementarias**:

| Redis | Cassandra | Neo4j |
| :--- | :--- | :--- |
| Carrito y sesión con TTL | Actividad por usuario y período | Afinidades entre clientes y productos |

| Criterio | Redis | Cassandra | Neo4j |
| :--- | :--- | :--- | :--- |
| Modelo | Clave-valor con estructuras | Tabla por consulta: partición + clustering | Grafo de propiedades |
| Mejor para | Sesiones, carritos, rankings, caché, TTL | Historial de eventos, escritura masiva | Relaciones y recorridos |
| Consulta | Comandos por clave | CQL, siempre con la clave de partición | Cypher por patrones |
| Atomicidad | Por comando o script | Por partición | Transacciones completas |
| Seguridad | ACL por usuario | Autenticación y roles (a habilitar) | Autenticación; sin roles en Community |
| Respaldo | RDB o AOF | Snapshot de SSTables | Dump fuera de línea |
| Punto débil | Memoria; sin consultas ad hoc | Sin consultas arbitrarias ni `JOIN` | Supernodos; escala limitada en Community |

## 9.6 ¿Qué pasa con ACID en los motores NoSQL?

¿Los motores NoSQL sacrifican las propiedades ACID para ganar rendimiento y escalabilidad? **No necesariamente.** Cada motor ofrece garantías diferentes según su arquitectura y el **alcance** de sus operaciones.

| Propiedad | Redis | Cassandra | Neo4j | MySQL (referencia) |
| :--- | :--- | :--- | :--- | :--- |
| **Atomicidad** | Comandos atómicos; `MULTI`/`EXEC` **sin rollback** tradicional | Atómica **por partición**; transacciones ligeras con Paxos | Transacciones ACID completas | Transacciones entre tablas |
| **Consistencia** | Depende de las reglas que implemente la aplicación | **Configurable** entre réplicas | Mantiene las restricciones definidas | Restricciones declarativas (PK, FK, `CHECK`) |
| **Aislamiento** | Ejecución secuencial de comandos; sin aislamiento SQL tradicional | Sin aislamiento transaccional general entre particiones | Aislamiento transaccional con bloqueos | Niveles de aislamiento con MVCC |
| **Durabilidad** | Depende de RDB/AOF y su configuración | *Commit log* + SSTables | Registro de transacciones y recuperación | *Redo log* + *binlog* |

> **NoSQL no significa "sin ACID".** Significa que las garantías transaccionales y **su alcance** dependen del motor y del modelo de datos. Un dominio que necesita atomicidad entre varias entidades (pedido, stock y pago) va al motor que la ofrece entre tablas.

**BASE** (*Basically Available, Soft state, Eventual consistency*) es una **actitud de diseño** que prioriza responder siempre y acepta que las copias converjan con el tiempo. No es un producto ni una propiedad de una familia ([7.11](#711-acid-base-y-cap)).

## 9.7 Distribución: conceptos separados

No confundir **técnicas** con **propiedades**:

| Particionado | Replicación | Consistencia |
| :--- | :--- | :--- |
| Distribuir **subconjuntos** de datos entre nodos | Mantener **copias** para tolerancia a fallas y lecturas | Definir qué lecturas y escrituras **se consideran válidas** |

### ¿Qué ocurre si se corta la red?

Dos réplicas del mismo dato dejan de comunicarse:

| Lado A | Lado B | Decisión |
| :--- | :--- | :--- |
| Acepta la escritura `X = 1` | Recibe una lectura de `X`, y quizá una escritura `X = 2` | ¿Responder en los dos lados, o rechazar alguna operación? |

- **Si los dos lados responden**, el sistema sigue **disponible**, pero el lado B lee un valor **viejo** y puede aceptar una escritura que **choca** con la de A. Al reconectarse hay que reconciliar.
- **Si un lado rechaza** (por ejemplo, el que no tiene mayoría), el sistema es **consistente**, pero no está disponible en ese lado mientras dure el corte.

Esa es exactamente la decisión que formaliza CAP.

## 9.8 CAP: formulación correcta

**Bajo una partición de red, aparece un compromiso:**

| Letra | Significado exacto |
| :--- | :--- |
| **C** · Consistencia | Cada lectura ve el **último valor confirmado** o recibe un **error** |
| **A** · Disponibilidad | Cada solicitud a un nodo **no fallado** obtiene **respuesta** |
| **P** · Partición | La red puede **perder mensajes** entre nodos; hay que tolerarlo |

Si la red se particiona, hay que elegir entre devolver **error** (C) o una respuesta **posiblemente desactualizada** (A). Sin particiones se pueden tener las dos.

### Lo que CAP no significa

| No es... | Por qué |
| :--- | :--- |
| **Un menú** | No se "eligen dos de tres" en cualquier momento: la elección ocurre **durante la falla** |
| **ACID** | La **C** de CAP no equivale a la consistencia de restricciones de ACID |
| **Una etiqueta fija** | Un producto puede ofrecer **modos y configuraciones** distintos ("Cassandra es AP" depende del CL) |
| **Algo sobre latencia** | Eso lo agrega **PACELC** |

**PACELC:** si hay **P**artición, se elige entre **A** y **C**; si no (**E**lse), entre **L**atencia y **C**onsistencia. Explica por qué un sistema replicado que espera a una mayoría de réplicas responde más lento aun sin fallas.

> **La "C" de ACID no es la "C" de CAP.** La de ACID es que cada transacción lleve la base de un estado válido a otro, respetando las restricciones. La de CAP es que cada lectura vea la última escritura. Un sistema puede respetar un `CHECK` y, con réplicas asíncronas, devolver un dato viejo.

### Cassandra y CAP: la consistencia depende de la operación

| `ONE` | `QUORUM` | Análisis |
| :--- | :--- | :--- |
| Puede responder con **menos réplicas** disponibles | Requiere **mayoría**; puede **rechazar** durante fallas | Latencia, disponibilidad y frescura dependen de la **configuración y de las fallas** |

Con RF = 3 y una réplica aislada: `ONE` sigue respondiendo (se comporta como A); `QUORUM` funciona mientras dos réplicas se vean, y del lado de la réplica aislada falla (se comporta como C).

### Redis y Neo4j ante fallas

No hay que asignar una etiqueta CAP sin contexto:

| Redis | Neo4j | Regla |
| :--- | :--- | :--- |
| Réplica, Sentinel y Cluster cambian la recuperación y el comportamiento (con réplica asíncrona, una conmutación puede perder las últimas escrituras) | *Standalone* o clúster cambian las garantías y la operación | Evaluar **despliegue, escritura, lectura y partición concreta** |

### Modelos de consistencia y anomalías

| Modelo | Garantiza | Ejemplo |
| :--- | :--- | :--- |
| Fuerte | Toda lectura ve la última escritura | Reserva de stock en MySQL |
| Eventual | Sin más escrituras, las copias convergen | Una recomendación respecto de una compra reciente |
| Leer lo propio | Quien escribe ve lo que escribió | El cliente ve su carrito recién modificado |
| Monótona | No se ve un dato más viejo después de uno más nuevo | Un precio que no "retrocede" |

Las anomalías del Parcial 1 siguen vigentes: lectura sucia, lectura no repetible, fantasma, **actualización perdida** y sesgo de escritura. InnoDB usa **Repeatable Read** por defecto (PostgreSQL, Read Committed).

## 9.9 Matriz de decisión

**Elegir según el patrón de acceso:**

| Criterio | Redis | Cassandra | Neo4j |
| :--- | :--- | :--- | :--- |
| **Acceso** | Clave directa | Rango dentro de una partición | Recorrido de relaciones |
| **Escala** | Memoria y cantidad de claves | Distribución entre nodos | Densidad de relaciones |
| **Operación** | Persistencia, réplicas, backups, seguridad y costos | Ídem | Ídem |

| Redis | Cassandra | Neo4j |
| :--- | :--- | :--- |
| Prioriza el **acceso directo** y las estructuras en memoria | **Diseña por consultas** y distribuye los datos | Hace foco en los **vínculos y recorridos** |

> **Cierre de la clase:** elegir motor **también es elegir costos de operación**.

## 9.10 Las actividades de la unidad

### Actividad 1 · Tres motores, un sistema

| Redis | Cassandra | Neo4j |
| :--- | :--- | :--- |
| Crear una sesión, aplicar TTL y **verificar la expiración** | Crear la tabla, insertar eventos y **consultar por partición** | Crear relaciones y ejecutar **dos recorridos** Cypher |

### Actividad 2 · Batalla de arquitecturas multimodelo (OmniMarket)

Una plataforma de comercio electrónico necesita gestionar clientes y cuentas, catálogo, inventario, pedidos y pagos, carritos y sesiones, navegación y eventos, recomendaciones, marketing y fidelización, y logística. Hay que **diseñar una arquitectura**, seleccionando los modelos adecuados y **justificando cada decisión**.

> **La pregunta de la clase:** ¿existe una única arquitectura correcta para este negocio? No: hay propuestas **mejor o peor justificadas** según los supuestos. Las secciones 9.11 a 9.20 muestran cómo se construye y se defiende una.

**Evidencia mínima de la entrega:**

| Ejecución | Comparación | Defensa |
| :--- | :--- | :--- |
| Capturas o salidas **reales** de los tres motores | Matriz: acceso, ventaja, limitación y caso elegido | ¿Por qué se eligieron esos modelos? |

| Logrado | Parcial | No logrado |
| :--- | :--- | :--- |
| Tres motores operados, evidencia y justificación coherente | Pruebas incompletas o decisiones poco fundamentadas | Sin evidencia verificable |

### Puente hacia la Unidad 10

¿Quién opera todo esto cuando va a producción? **Provisionar** (nodos, capacidad, redes y versiones), **proteger** (backups, seguridad, monitoreo y recuperación) y **delegar** (DBaaS: qué hace el proveedor y qué el equipo).

## 9.11 Persistencia políglota: qué es y por qué

> **Desde acá, profundización con la segunda actividad** (OmniMarket): cómo se analiza, se decide, se integra y se defiende una arquitectura con varios motores.

**Persistencia políglota** es usar **varios motores en un mismo sistema**, cada uno para el tipo de dato y de acceso donde mejor encaja. Existe porque ningún motor es el mejor en todo: el relacional garantiza integridad entre entidades, pero no tiene vencimiento nativo ni escala la escritura masiva horizontalmente; Redis responde en milisegundos, pero no consulta por contenido.

> **El error contrario: más motores no es mejor.** La consigna lo decía así: **"no gana quien usa más tecnologías"**. Cada motor suma operación, respaldo, seguridad, conocimiento e integración ([9.15](#915-el-costo-de-sumar-motores)). La pregunta no es "¿qué motor sirve?", sino **"¿el que tengo no alcanza?"**.

## 9.12 Analizar los requisitos

- **Funcionales:** qué datos y qué operaciones (alta de cliente, reservar stock, historial de un usuario).
- **No funcionales:** cuánto, cuán rápido, con qué garantías (volumen, latencia, integridad, disponibilidad, seguridad). **Los motores se diferencian casi siempre acá.**

### El patrón de acceso ordena todo

Tres preguntas: ¿se accede **por clave**, **por rango**, **por filtro libre** o **recorriendo relaciones**? ¿Predomina la **lectura** o la **escritura**, y las escrituras modifican o solo agregan? ¿Hace falta atomicidad **entre varios datos**?

| Patrón de acceso | Modelo que suele encajar |
| :--- | :--- |
| Clave exacta, latencia mínima y vencimiento | Clave-valor |
| Historial por usuario y fecha con escritura masiva | Columnas anchas |
| Filtros y uniones entre muchas entidades con integridad | Relacional |
| Documento completo de forma variable | Documental |
| Recorridos de 2 o más saltos | Grafos |

### Obligatorio, preferencia y supuestos

- **Obligatorio:** sale del enunciado o de una norma (no vender más de lo disponible, proteger datos personales). **Preferencia:** mejora pero es negociable. La técnica **MoSCoW** (*must, should, could, won't*) ayuda a ordenarlos.
- **Supuestos explícitos:** si el enunciado no da cifras, se declaran con **valor y unidad**, de dónde salen y **qué decisión cambiaría** si fueran otras. Se defiende la decisión **condicionada a los supuestos**.

### Dimensionamiento: cuentas de orden de magnitud (caso OmniMarket)

| Cálculo | Resultado | Lectura |
| :--- | :--- | :--- |
| 30.000.000 eventos ÷ 86.400 s | ≈ 347 por segundo; ≈ 2.800 en el pico (8 veces) | Presiona a un nodo único en escritura |
| 30 M × 365 | ≈ 10.950 M de eventos por año | ≈ 2,2 TB por año (≈ 6,6 TB con tres copias) |
| 100.000 pedidos ÷ 86.400 s | **≈ 1,2 pedidos por segundo** (≈ 40 en el pico) | Un servidor relacional lo resuelve sin dificultad |
| 400.000 sesiones × 2 × 1 KB | ≈ 800 MB | Entra en memoria |

Un supuesto se convierte en dato **midiendo**: `sysbench` y `EXPLAIN ANALYZE` en MySQL, `redis-benchmark`, `cassandra-stress` y `PROFILE` en Neo4j. Si no se midió, se dice.

## 9.13 Los cinco modelos comparados

| | Relacional | Documental | Clave-valor | Columnas anchas | Grafos |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Unidad de dato | Fila | Documento | Valor (estructura) | Fila en una partición | Nodo y relación |
| Mejor patrón | Uniones e integridad | Agregado de forma variable | Clave directa con TTL | Escritura masiva por clave y rango | Recorridos |
| Transacciones | Entre tablas | Entre documentos (costosas) | Por comando o script | Por partición | Completas |
| Escala de escritura | Vertical; particionado | Horizontal (fragmentación) | Memoria; Cluster | **Horizontal nativa** | Limitada en Community |
| Punto débil | Escritura masiva horizontal | Integridad entre entidades | Capacidad y consultas | Consultas ad hoc y uniones | Agregaciones masivas |

Dos límites de MySQL que pesan en la decisión: no tiene un índice general sobre JSON ([7.16](#716-índices-sobre-json-en-detalle)), y **las tablas InnoDB particionadas no admiten claves foráneas**, así que las tablas con integridad referencial no se particionan.

## 9.14 Un método para decidir

Elegir "porque es más rápido" no resiste una pregunta. Un método es **explícito** (se discute criterio por criterio), **repetible** y **sensible** (se ve qué cambia si cambia un supuesto).

**Matriz ponderada:**

1. **Criterios** derivados de los requisitos: integridad (I), flexibilidad de esquema (F), latencia por clave (L), escala de escritura en disco (E), recorridos (R), expiración nativa (T), consultas ad hoc (Q) y lectura por rango ordenado (S).
2. Cada **modelo** recibe una **aptitud** de 0 a 3 por criterio.
3. Cada **dominio** recibe un **peso** de 0 a 3 por criterio.
4. **Puntaje** = Σ (peso × aptitud).

| Dominio | Resultado | Por qué |
| :--- | :--- | :--- |
| Sesiones y carritos | Clave-valor **23**, relacional **13** | La latencia y la expiración tienen peso 3 y el relacional tiene aptitud baja en las dos |
| Catálogo | Relacional **23**, documental **23** | Empate: el puntaje solo no decide |

**Regla de adopción**, fijada **antes** de mirar los resultados: un motor NoSQL se suma solo si **(1)** hay un criterio de peso 3 que el relacional cubre con aptitud 1 o menos, **(2)** el candidato lo cubre con 3 y **(3)** su puntaje supera al relacional. En el catálogo, los criterios de peso 3 son la flexibilidad (el relacional con `JSON` e índices tiene aptitud 2) y las consultas ad hoc (aptitud 3): **queda en el relacional**.

- **Análisis de sensibilidad:** si el peso de las consultas en el catálogo bajara de 3 a 1, el documental ganaría 19 a 17, pero la regla seguiría sin sumarlo. La decisión es **robusta** a ese cambio.
- **Criterio de revisión:** si hubiera que filtrar por atributos impredecibles, sin poder declarar los índices, la aptitud del relacional en flexibilidad bajaría y se reevaluaría.
- **Honestidad:** aptitudes y pesos son una **valoración cualitativa**, no una medición. Sirven para que la discusión sea sobre criterios concretos.

## 9.15 El costo de sumar motores

| Dimensión | Qué implica un motor más |
| :--- | :--- |
| Operación | Instalar, actualizar, dimensionar y vigilar otro sistema |
| Disponibilidad | Replicación y conmutación propias; un modo de falla nuevo |
| Respaldo | Otro procedimiento, con su propio tiempo de restauración |
| Seguridad | Otro modelo de usuarios y permisos |
| Conocimiento | Otro modelo y otro lenguaje de consulta |
| Integración | Otro camino de sincronización, con duplicados, orden y reintentos |
| Consistencia | Más lugares donde un dato puede estar desactualizado |

**La forma de la arquitectura multiplica la integración.** Con *n* motores, en **estrella** (uno central alimenta a los demás) hay **n − 1** caminos de sincronización; en **malla** (todos con todos), **n × (n − 1) ÷ 2**. Con cinco motores, una malla tendría 10; la estrella de OmniMarket, con cuatro, tiene 3.

**Criterio de baja:** cada motor necesita una condición explícita de salida. Por ejemplo: si los eventos bajaran de 2 millones por día, Cassandra se reemplazaría por una tabla particionada en MySQL.

## 9.16 Integrar datos entre motores

**El problema de la escritura doble:** guardar el pedido en MySQL y luego escribirlo en Neo4j desde la aplicación **no es atómico**. Si el proceso cae entre las dos escrituras, los motores quedan inconsistentes y nadie se entera. Una transacción distribuida (*two-phase commit*) no está disponible entre estos motores y, aunque lo estuviera, bloquea y reduce la disponibilidad.

| Patrón | Idea | Cuándo |
| :--- | :--- | :--- |
| **Outbox transaccional** | El evento se guarda en una tabla del mismo motor, **en la misma transacción** del negocio; un proceso aparte lo publica y lo reintenta | Volumen moderado, control total |
| **Captura de cambios (CDC)** | Se lee el registro binario del motor y se publica cada cambio (por ejemplo, con Debezium) | Volumen alto, sin tocar el código |
| **Carga por lote (ETL)** | Extraer y cargar periódicamente | Cuando la latencia no importa |
| **Eventos como fuente** | El registro de eventos es el dato primario | Auditoría total |
| **Saga** | Transacciones locales encadenadas con compensaciones | Procesos largos entre servicios |

### Garantías de entrega e idempotencia

| Garantía | Riesgo |
| :--- | :--- |
| Como máximo una vez | Puede **perder** mensajes |
| Al menos una vez | Puede **duplicar** |
| Exactamente una vez | En la práctica: **al menos una vez + consumidor idempotente** |

Un consumidor es **idempotente** si aplicar el mismo mensaje dos veces deja el mismo resultado que aplicarlo una. En el laboratorio se logró con `MERGE` sobre una clave única de la línea de compra (`linea_id`) y una restricción de unicidad: después de reentregar el mismo pedido, las compras siguieron siendo las mismas.

**Orden por entidad:** cada evento lleva una `version`, y el consumidor aplica solo si es **mayor** que la ya aplicada. Un evento atrasado no pisa a uno nuevo.

**Fallas:** reintentos con espera creciente y una cola de eventos fallidos; **reconciliación** periódica (comparar recuentos y sumas entre la fuente y las proyecciones); **reconstrucción** de los motores derivados desde la fuente.

## 9.17 Duplicación y concurrencia

- **Un dato tiene un único dueño.** Las demás copias son proyecciones que se actualizan por eventos y se pueden reconstruir. La duplicación deliberada (por rendimiento) se acepta; la accidental (procesar dos veces un evento) se evita con idempotencia.
- **Caché:** se mantiene fresca con vencimiento corto **y** con invalidación por evento. Nunca se cachea un dato que exige exactitud inmediata, como el **stock**.

| Estrategia | Idea | Ejemplo |
| :--- | :--- | :--- |
| **Operación atómica del motor** | La modificación completa es una unidad | `HINCRBY`; `UPDATE ... SET x = x + n` |
| **Actualización condicional** | Se aplica solo si la condición sigue siendo cierta | `UPDATE stock ... WHERE disponible >= n` |
| **Bloqueo optimista** | Se escribe solo si la `version` no cambió | `UPDATE ... WHERE id = ? AND version = ?` |
| **Bloqueo pesimista** | Se bloquea la fila mientras se trabaja | `SELECT ... FOR UPDATE`; con `SKIP LOCKED`, varios procesos se reparten la cola |
| **Última escritura gana** | Gana la marca de tiempo mayor | Cassandra por defecto; riesgoso si los relojes difieren |
| **CRDT** | Estructuras que se combinan sin conflicto | Contadores distribuidos |
| **Vigilancia** | El bloque falla si una clave cambió | `WATCH` + `MULTI`/`EXEC`; scripts Lua |

**El experimento de la actualización perdida:** doscientos procesos suman 1 al mismo contador. Con `HINCRBY`, el resultado es **200**. Leyendo con `HGET` y escribiendo con `HSET`, muchos leen el mismo valor y escriben el mismo resultado, y el total queda **muy por debajo de 200**. Es la carrera de lectura-modificación-escritura del Parcial 1. La lección: **delegar la operación crítica al motor** en una sola sentencia atómica.

## 9.18 Datos personales y seguridad

En Argentina, la **Ley 25.326 de Protección de los Datos Personales** fija los principios de finalidad, calidad del dato, consentimiento y seguridad, y los derechos de acceso, rectificación y supresión. Varios motores multiplican los lugares donde puede quedar un dato personal.

| Medida | Aplicación |
| :--- | :--- |
| Minimización | Los motores secundarios guardan solo identificadores, nunca DNI, email o dirección |
| Fuente única | Solo el motor relacional tiene datos personales: un lugar para proteger, auditar y suprimir |
| Supresión | Baja en la fuente y un evento que borra el identificador en las proyecciones |
| Mínimo privilegio | Un usuario por aplicación y por motor, con permisos limitados |
| Auditoría | Tablas de solo inserción para movimientos e historiales |
| Credenciales | Fuera de los scripts y de las capturas |
| Cifrado | En tránsito y en reposo |

## 9.19 Disponibilidad: qué es crítico y qué se reconstruye

- **99,9 %** de disponibilidad son ≈ 8,8 horas de caída por año; **99,95 %**, ≈ 4,4 horas.
- **RPO**: cuántos datos se pueden perder. **RTO**: cuánto se puede tardar en volver.

| Componente | ¿Se puede perder? | Estrategia |
| :--- | :--- | :--- |
| Relacional (pedidos, stock, pagos) | **No** | Réplica con conmutación; respaldo con recuperación a un punto en el tiempo |
| Cassandra (navegación) | Parcialmente | Replicación entre nodos y snapshots |
| Redis (sesiones) | Sí, temporal | Persistencia y réplica para acortar la vuelta; las sesiones se rehacen |
| Neo4j (recomendaciones) | Sí, derivado | Dump periódico y, sobre todo, reconstrucción desde la fuente |

**Degradación elegante:** si cae un motor secundario, el sistema sigue vendiendo con una versión reducida (por ejemplo, mostrar los más vistos en lugar de recomendaciones personalizadas). Solo el motor relacional es indispensable para confirmar un pedido.

## 9.20 Defender una arquitectura

Una respuesta sólida tiene cuatro partes: **afirmación → evidencia → razonamiento → límite**. Reconocer hasta dónde vale la decisión **la fortalece**.

| Falacia | Por qué falla |
| :--- | :--- |
| "NoSQL es más rápido" | Depende del patrón de acceso |
| "Es el más usado" | La popularidad no es un requisito del negocio |
| "Más motores, más preparada" | Cada motor suma costo e integración |
| "Cassandra no tiene consistencia" | Es ajustable por operación |
| "Redis pierde datos" | Depende de RDB, AOF y réplica; y no debe ser la única fuente de lo crítico |
| "CAP: se eligen dos de tres" | Es un compromiso **ante una partición** |
| "Neo4j reemplaza a SQL" | Es mejor para recorridos, no para todo |

**Preguntas que desarman una propuesta rival:** ¿hay una fuente de verdad por dato?, ¿qué pasa si falla la segunda de dos escrituras?, ¿dónde está el stock y cómo evitan sobrevender?, ¿qué dejarían de poder hacer sin cada motor?, ¿qué cifras supusieron?, ¿dónde están los datos personales y cómo se suprimen?

## Preguntas de repaso · Unidad 9

1. ¿Qué pregunta responde cada motor según la clase (Redis, Cassandra, Neo4j)? ¿Qué necesidad del comercio resuelve cada uno?
2. Ejecutaste `SET session:ana activa EX 120`. ¿Qué devuelven `GET` y `TTL` antes y después de que venza?
3. ¿Cuándo usarías un *hash*, un *set* y un *sorted set*? ¿Qué se pierde si Redis se reinicia sin persistencia?
4. ¿Qué diferencia hay entre RDB y AOF? ¿Qué cambia entre instancia única, réplica y cluster?
5. En `PRIMARY KEY ((usuario), fecha, evento_id)`, ¿qué hace cada parte? ¿Por qué el laboratorio con RF = 1 no demuestra tolerancia a fallas?
6. ¿Qué es el token, qué define el RF y quién es el coordinador en Cassandra?
7. Con RF = 3, ¿cuántas respuestas exigen `ONE` y `QUORUM`? ¿Qué combinación de lectura y escritura da consistencia fuerte?
8. ¿Qué aporta recorrer relaciones frente a múltiples `JOIN`? ¿Qué es un supernodo?
9. "NoSQL no tiene ACID": ¿verdadero o falso? Justificá con la tabla de la clase.
10. Se corta la red entre dos réplicas: el lado A escribió `X = 1` y el lado B recibe una lectura. ¿Qué opciones hay y qué propiedad sacrifica cada una?
11. Formulá correctamente CAP y explicá por qué no es un menú, no es ACID y no es una etiqueta fija.
12. Completá la matriz de decisión (acceso, escala, operación) para los tres motores.
13. ¿Qué devuelve `TTL` para una clave sin vencimiento y para una clave que ya venció?
14. ¿Por qué una ACL con `+@read +@write` y patrones de claves no impide `FLUSHALL`? ¿Qué más hay que proteger?
15. En `PRIMARY KEY ((usuario_id), fecha_evento, evento_id)`, ¿qué hace cada parte y qué consultas son eficientes?
16. ¿Por qué `ALLOW FILTERING` no es una solución, y qué riesgo tiene una tabla particionada por `tipo_evento`?
17. Con RF = 3, ¿qué niveles de lectura y escritura dan consistencia fuerte?
18. ¿Por qué un patrón de Cypher puede devolver el mismo producto dos veces?
19. ¿Qué no ofrece Neo4j Community y cómo se compensa?
20. Formulá correctamente el teorema CAP. ¿Qué agrega PACELC?
21. ¿Por qué la escritura doble entre dos motores no es atómica, y qué patrón lo resuelve?
22. ¿Cómo se logra "exactamente una vez" en la práctica?
23. ¿Qué dice la regla de adopción y por qué se fija antes de ver los resultados?
24. ¿Cuántos caminos de sincronización hay con cinco motores en estrella y en malla?

---

# Unidad 10 · Operar como servicio: DBaaS y Cloud

La unidad sigue la **clase 10** de la cátedra (*Operar como servicio: DBaaS, Cloud y el nuevo rol de administración*). Las secciones 10.1 a 10.18 recorren la clase en su orden. El eje de la clase es explícito: **menos consola de proveedor y más decisiones transferibles entre plataformas**. Las secciones 10.19 y 10.20 complementan con las dos resoluciones: la nuestra en **MongoDB Atlas** y la de otro grupo en **Supabase** (PostgreSQL).

## 10.1 La pregunta de la unidad

> *Si el proveedor administra el servidor, los backups y la alta disponibilidad... ¿qué queda por administrar?*

| ¿Quién configura? | ¿Quién protege? | ¿Quién observa? | ¿Quién paga? |
| :--- | :--- | :--- | :--- |

La respuesta profesional está en la **responsabilidad compartida**.

**Objetivo de la clase:** comprender cómo cambia la operación de una base cuando se consume **como servicio**, distinguir las responsabilidades del proveedor y de la organización, y **justificar** decisiones de configuración, seguridad, disponibilidad, observabilidad y costo.

| 1 · Comprender | 2 · Operar | 3 · Decidir |
| :--- | :--- | :--- |
| Cloud, PaaS y DBaaS | Configurar, observar y recuperar | Responsabilidad, costo y riesgo |

> DBaaS **reduce trabajo operativo**; no elimina las decisiones de administración.

**Mapa de la clase:** 1 · Cloud (de servidor a servicio) → 2 · DBaaS (qué gestiona el proveedor) → 3 · Operación (*endpoint*, backup, HA) → 4 · Observabilidad (métricas, logs, alertas) → 5 · Costos (*compute*, *storage*, I/O) → 6 · Nuevo DBA (automatización, gobierno).

## 10.2 De instalar un motor a consumir un servicio

La misma base puede operar bajo modelos diferentes:

| On-premise | IaaS | PaaS / DBaaS | Serverless DB |
| :--- | :--- | :--- | :--- |
| Hardware + SO + SGBD propios | Una VM alquilada + el SGBD | Motor administrado | Capacidad bajo demanda |
| **Máximo control** | Infraestructura alquilada | **Operación compartida** | **Mayor abstracción** |

| Capa | Qué entrega el proveedor | Ejemplo |
| :--- | :--- | :--- |
| **SaaS** | La aplicación completa | Un CRM en la web |
| **PaaS** | Una plataforma para ejecutar o almacenar | **DBaaS** es un PaaS de bases de datos |
| **IaaS** | Máquinas virtuales, red y discos | Una VM en la nube con MySQL instalado a mano |
| **Física** | El hardware en el centro de datos | El servidor *on-premise* |

> A mayor abstracción, **menos infraestructura propia**, pero **no necesariamente menos responsabilidad** sobre los datos.

### Cloud: tres ideas antes de hablar de DBaaS

No confundir **ubicación**, **servicio** y **responsabilidad**:

| Elasticidad | Pago por consumo | Automatización |
| :--- | :--- | :--- |
| Ajustar la capacidad **sin comprar hardware**; manual o automática según el servicio | El costo se desplaza de la compra y la capacidad instalada hacia los **recursos y servicios utilizados** | Aprovisionamiento, métricas, backups, parches y HA expuestos como **capacidades de la plataforma** |

> **Trampa:** cloud **no** significa automáticamente barato, elástico ni altamente disponible: **depende de cómo se configure**.

## 10.3 ¿Qué es DBaaS?

**Database as a Service:** el SGBD se entrega como **capacidad administrada**. Se consume una base mediante un **endpoint** y una API o consola; el proveedor opera gran parte de la infraestructura y del ciclo de vida del motor.

| Provisionar | Conectar | Operar | Escalar |
| :--- | :--- | :--- | :--- |
| Crear la instancia o el clúster | *Endpoint*, red, TLS | Métricas, backup, HA | *Compute*, *storage* |

> **DBaaS es una forma de operar un motor, no un nuevo modelo de datos.** Un PostgreSQL administrado sigue siendo relacional; un MongoDB Atlas sigue siendo documental.

## 10.4 Responsabilidad compartida

El proveedor administra **la plataforma**; la organización sigue administrando **el uso**:

| Responsabilidad | Quién decide u opera |
| :--- | :--- |
| Hardware / centro de datos | **Proveedor** |
| SO y parches de plataforma | **Proveedor** |
| Disponibilidad de la plataforma | **Compartida** |
| Configuración del servicio | **Cliente** |
| Usuarios, roles y privilegios | **Cliente** |
| Modelo, SQL e índices | **Cliente** |
| Datos y su clasificación | **Cliente** |
| Costo y gobierno | **Cliente** |

> **"Managed" no significa "sin dueño":** hay decisiones que el proveedor no puede tomar por nosotros. Si un usuario con permisos de más borra una tabla, el servicio replica el borrado en todas las copias sin dudar.

### ¿Qué desaparece y qué permanece?

Comparado con la VM del curso:

| Trabajo que suele reducirse | Trabajo que permanece |
| :--- | :--- |
| Instalar el SO y el motor | Diseñar datos e índices |
| Gestionar los discos del servidor | Gestionar identidades y privilegios |
| Aplicar parte del *patching* | Configurar los parámetros permitidos |
| Construir mecanismos básicos de HA | Diagnosticar consultas y sesiones |
| Automatizar copias estándar de plataforma | Validar el *restore*, el RPO/RTO y los costos |
| | Definir la arquitectura y el gobierno |

> El foco se desplaza: **de administrar máquinas a administrar niveles de servicio y decisiones**.

## 10.5 Arquitectura DBaaS: qué ve la aplicación

La infraestructura se oculta; **el endpoint se vuelve la frontera visible**:

```text
APP          →  DNS        →  TLS         →  DB       →  DATA     →  OBS
aplicación      endpoint      red segura     DBaaS       storage     métricas y logs
```

> El DBA ya no "entra al servidor" para resolver todo: **observa el servicio** mediante SQL, consola, API, métricas y logs.

## 10.6 Provisionar una base como servicio

Crear una base implica **tomar decisiones antes del primer `CREATE TABLE`**:

| Decisión | Pregunta |
| :--- | :--- |
| **Región** | ¿Dónde vive? (latencia hacia los usuarios, normativa sobre los datos) |
| **Motor / versión** | ¿Qué compatibilidad necesito? |
| **Compute** | ¿Cuánta CPU y RAM? |
| **Storage** | ¿Qué capacidad e IOPS? |
| **Red** | ¿Acceso público o privado? |
| **HA** | ¿Una zona o varias? |

> Provisionar es **diseñar una plataforma operativa**, no solamente "crear una base".

## 10.7 El endpoint y la conectividad

### El endpoint reemplaza a la IP del servidor

```text
postgresql://app@mi-db.proveedor.cloud:5432/ventas
             │   │                     │    └── base lógica
             │   │                     └─────── puerto del motor
             │   └───────────────────────────── endpoint administrado (host)
             └───────────────────────────────── usuario (identidad)
+ TLS (cifrado en tránsito) + timeout (comportamiento del cliente)
```

> La conexión cambia de infraestructura, **no de principios**: la ruta sigue siendo **cliente → red → autenticación → base**. Lo que cambia es quién opera los componentes intermedios.

### Conectividad: público no significa abierto

| Acceso público | Acceso privado | La aplicación |
| :--- | :--- | :--- |
| *Endpoint* alcanzable desde Internet, protegido por **firewall o reglas**, identidad y TLS. Útil en laboratorios; **exige control** | Servicio accesible **dentro de una red virtual** (VPC o VNet). Reduce la exposición y obliga a resolver rutas y DNS | Debe conocer el *endpoint*, la credencial o identidad, el certificado y la política de conexión. **El *pool* de conexiones sigue importando** |

> DBaaS **no elimina los problemas de red**: cambia la topología que hay que diagnosticar.

## 10.8 MySQL y PostgreSQL como servicio

El motor conocido aparece dentro de distintas plataformas:

| Proveedor | Servicios | Foco |
| :--- | :--- | :--- |
| **AWS** | RDS for MySQL / PostgreSQL · Aurora MySQL-Compatible / PostgreSQL-Compatible | Servicio administrado integrado al ecosistema AWS |
| **Microsoft Azure** | Azure Database for MySQL · Azure Database for PostgreSQL | Integración con la red, la identidad, el monitoreo y los servicios de Azure |
| **Google Cloud** | Cloud SQL for MySQL / PostgreSQL · AlloyDB for PostgreSQL | Servicio administrado e integración con GCP |

> No comparar solo **nombres comerciales**: comparar capacidades, límites, operación y costo.

### ¿Sigue siendo PostgreSQL o MySQL?

**Compatibilidad no implica el mismo control que en el servidor propio:**

| Lo que reconocemos | Lo que puede cambiar |
| :--- | :--- |
| SQL y tipos | Extensiones disponibles |
| Tablas, índices y restricciones | **Privilegios de superusuario** |
| Transacciones y aislamiento | Parámetros modificables |
| Planes de ejecución | Acceso al *filesystem* |
| Usuarios y roles (según el servicio) | *Plugins* y componentes |
| *Drivers* y protocolos habituales | Ventanas de mantenimiento |

> Antes de migrar: verificar la compatibilidad **funcional y operativa**, no solamente que "acepte SQL". En las dos resoluciones apareció: en Atlas, `db.createUser()` está bloqueado; en Supabase, el usuario `postgres` **no es superusuario**.

## 10.9 Backup y alta disponibilidad administrados

### Backup administrado: automatizar no es validar

Se retoma la Unidad 6 con una pregunta nueva: **¿quién ejecuta y quién responde?**

| Proveedor | Cliente | Cliente | Ambos |
| :--- | :--- | :--- | :--- |
| **Ejecuta** las copias y la retención según la configuración | **Elige** la política, la retención y las ventanas | **Prueba el *restore*** y valida los datos | **Sostienen** el objetivo de RPO/RTO |

> Un *checkbox* "backup enabled" **no demuestra recuperabilidad**. La evidencia sigue siendo un **restore validado**.

### Alta disponibilidad administrada

El proveedor puede automatizar el mecanismo (un **primario** en la zona A, un **standby** en la zona B, replicación y *failover* gestionados); **el diseño sigue siendo nuestro**. Preguntas del DBA:

- ¿Qué **SLA** ofrece el servicio?
- ¿Qué **RPO/RTO real** necesito?
- ¿Qué pasa con las **conexiones** abiertas durante el *failover*?
- ¿Cómo **pruebo** el *failover*?

> **La HA del servicio no reemplaza al backup ni corrige errores lógicos.** Es el "alta disponibilidad no es backup" del Parcial 1: un `DELETE` equivocado se replica al *standby*.

## 10.10 Patching y mantenimiento

Delegar la ejecución **no elimina la planificación**:

| Proveedor | Cliente | Aplicación |
| :--- | :--- | :--- |
| Mantiene la plataforma y publica versiones y ventanas; puede automatizar parches según la política | Define la ventana, **prueba la compatibilidad**, revisa las extensiones y planifica los cambios de versión | Debe **tolerar** reinicios, *failover* y cambios de *endpoint* o de sesión |

> "Managed" cambia **quién aplica el parche**; no **quién asume el impacto de negocio**.

## 10.11 Observabilidad y performance

### Administrar sin entrar al servidor

La consola reemplaza parte del acceso al sistema operativo, pero hace falta **evidencia**:

| Señal | Qué muestra |
| :--- | :--- |
| **CPU / memoria** | Saturación y capacidad |
| **Conexiones** | El *pool*, los límites y los picos |
| **Latencia / I/O** | Esperas y almacenamiento |
| **SQL** | Las consultas costosas |
| **Logs** | Errores y eventos |
| **Alertas** | Un umbral **más una acción** |

> La pregunta no es "¿qué dashboard existe?", sino **"¿qué decisión puedo tomar con esa señal?"**.

### El proveedor no optimiza nuestro SQL

DBaaS administra la plataforma; **la carga sigue siendo responsabilidad del equipo**:

| SQL | Diseño físico | Capacidad |
| :--- | :--- | :--- |
| Planes, `JOIN`, filtros, ventanas y patrones de acceso | Índices, estadísticas, particiones y distribución disponible | Escalar el cómputo **puede ocultar un problema**: primero medir y diagnosticar |

> La nube permite comprar más recursos rápido; eso **no convierte una consulta mala en un buen diseño**.

## 10.12 Escalar en DBaaS

La elasticidad tiene mecanismos, **límites y costos**:

| Mecanismo | Cómo funciona | Cuidado |
| :--- | :--- | :--- |
| **↑ Vertical** | Más CPU y RAM para la instancia | Simple, pero puede requerir **reinicio o *failover*** y tiene **techo** |
| **→ Réplicas de lectura** | Distribuyen las consultas compatibles | **La aplicación debe saber usarlas** (y tolerar que estén levemente atrasadas) |
| **↕ Serverless / autoscale** | La plataforma ajusta la capacidad | Simplifica los picos, pero exige entender **los límites y el modelo de cobro** |

> Escalar es una **decisión de arquitectura y costo**, no un botón mágico.

## 10.13 El costo también se administra

En DBaaS **cada decisión técnica tiene traducción económica**:

| Componente | Se cobra por |
| :--- | :--- |
| **Compute** | vCPU, RAM y tiempo encendido |
| **Storage** | GB provisionados |
| **I/O** | Operaciones o *throughput* |
| **Backup** | Retención y *snapshots* |
| **Red** | *Egress*: transferencia de salida |
| **HA** | Réplicas y zonas adicionales |

Cada proveedor tiene su **calculadora de precios** (AWS Pricing Calculator, Azure Pricing Calculator, Google Cloud Pricing Calculator). La nueva habilidad del DBA es **correlacionar rendimiento, disponibilidad y costo antes de sobredimensionar**.

### Ejemplo de decisión: "subamos la instancia"

| Síntoma | Respuesta rápida | Decisión del DBA |
| :--- | :--- | :--- |
| CPU alta y latencia creciente | Duplicar el *compute* → baja la latencia, **sube el costo** | **Medir** SQL + I/O + índices y **comparar** el costo de optimizar contra el de escalar |

> **FinOps para bases de datos:** optimizar el **valor**, no minimizar el costo a cualquier precio.

## 10.14 Seguridad en DBaaS: dos planos

La nube agrega capas; **no reemplaza el mínimo privilegio**:

| Identidad cloud | Identidad del motor | Red + cifrado |
| :--- | :--- | :--- |
| **IAM** e identidades de la plataforma: quién puede **crear, modificar o leer la configuración** del servicio | Usuarios, roles y privilegios del motor: siguen controlando **objetos y acciones dentro de la base** | Firewall o red privada, **TLS** y **cifrado en reposo** complementan la autorización |

> **Dos planos:** controlar **quién administra el servicio** y **quién puede usar los datos**. Una identidad de un plano no sirve en el otro: las dos resoluciones lo comprobaron ([10.19](#1019-nuestra-resolución-mongodb-atlas) y [10.20](#1020-otra-resolución-postgresql-en-supabase)).

## 10.15 Migrar a DBaaS y entornos híbridos

### Migrar no es copiar y pegar

La migración combina **compatibilidad, movimiento y corte**:

| 1 · Inventariar | 2 · Evaluar | 3 · Mover | 4 · Validar | 5 · Traspaso | 6 · Observar |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Versiones, extensiones, tamaño | Compatibilidad y límites | *Dump/restore* o replicación | Conteos, SQL, rendimiento | DNS o *endpoint*, ventana de corte | Errores, latencia, costo |

> La migración termina cuando **la operación es estable y verificable**, no cuando finaliza la copia.

### Cloud e híbrido: no todo tiene que mudarse

El mercado tiende a entornos **cloud e híbridos**:

| On-premise | Frontera | Cloud DBaaS |
| :--- | :--- | :--- |
| Sistemas *legacy*, regulación, latencia local, costo hundido | VPN o enlace privado, replicación, ETL/CDC, APIs | Elasticidad, servicio administrado, servicios integrados |

> La arquitectura híbrida exige **administrar también la frontera** entre los dos mundos.

## 10.16 El nuevo rol de administración

**De operar servidores a gobernar una plataforma de datos:**

| Eje | Qué cambia |
| :--- | :--- |
| **Operación** | Menos instalación; más configuración |
| **Performance** | SQL + capacidad + métricas |
| **Seguridad** | IAM + roles + red + secretos |
| **Automatización** | API, CLI, IaC (*infraestructura como código*), *pipelines* |
| **Costos** | Dimensionamiento + consumo |
| **Gobierno** | Políticas, etiquetado (*tagging*), evidencia |

> La competencia clave sigue siendo la misma: **justificar decisiones técnicas según el contexto y la evidencia**.

### ¿Dónde conviene operar?

No hay un ganador universal: cambia el equilibrio entre **control y esfuerzo**.

| Criterio | On-premise | VM / IaaS | DBaaS |
| :--- | :--- | :--- | :--- |
| Control del SO | Alto | Alto | Bajo |
| Instalación y parches | Propios | Propios | Mayormente del proveedor |
| HA y backup | Diseño propio | Diseño propio | Capacidad administrada |
| Elasticidad | Baja o planificada | Media | Alta, según el servicio |
| Compatibilidad | Máxima | Alta | Sujeta a límites |
| Costo | Capacidad + operación (**CapEx**) | Infraestructura + operación (**OpEx**) | Servicio + consumo |
| Foco del DBA | Servidor + motor | VM + motor | **Servicio + datos** |

> Elegir DBaaS es **elegir una frontera de responsabilidad**, no solamente un proveedor.

## 10.17 Portabilidad y estrategia de salida

**Mismo motor no implica comportamiento idéntico:**

| Dependencias | Exportación | Prueba de salida |
| :--- | :--- | :--- |
| Extensiones, versiones, autenticación, automatizaciones y **APIs propietarias** | Asegurar formatos, herramientas y permisos para **extraer datos y esquema** | **Restaurar en otra instancia**, medir tiempos y ejecutar las consultas críticas |

> Preguntar **antes de adoptar**: ¿cómo nos iríamos de esta plataforma? Cuanto más se usan funciones propias del proveedor, mayor es el ***lock-in***. En nuestra resolución, `mongodump` y los drivers estándar mantuvieron la portabilidad.

## 10.18 La actividad: "Tu base deja la VM"

Un desafío grupal para convertir **administración técnica en decisión de arquitectura**:

| Fase 1 · Diagnosticar | Fase 2 · Diseñar | Fase 3 · Defender |
| :--- | :--- | :--- |
| Partir de la VM MySQL o PostgreSQL del curso. **Inventariar** qué administra hoy el grupo: red, motor, backup, seguridad, HA, monitoreo | **Elegir un DBaaS** y definir región, tamaño, *storage*, red, backup/PITR, HA, monitoreo y estrategia de migración | Mostrar la arquitectura **antes → después**. Explicar **3 responsabilidades transferidas, 3 que permanecen y 3 riesgos o costos** |

> No gana el proveedor "más conocido": gana **la propuesta mejor justificada** con evidencia.

**Evidencia mínima:** 1 · arquitectura antes → después; 2 · matriz proveedor / cliente; 3 · configuración (región, red, capacidad); 4 · operación (backup, HA, observabilidad); 5 · costo (los componentes que cobran); 6 · riesgos (3 límites con su mitigación). **Toda afirmación sobre el servicio se acompaña con documentación oficial o evidencia de consola.**

| Criterio | Logrado | Parcial | No logrado |
| :--- | :--- | :--- | :--- |
| DBaaS | Distingue claramente qué se delega y qué permanece | Reconoce la idea pero mezcla responsabilidades | Interpreta DBaaS como **"sin administración"** |
| Arquitectura | Red, capacidad, backup y HA coherentes | Propuesta incompleta o poco conectada al caso | Enumera opciones sin diseñar una solución |
| Operación | Define métricas, *restore* y evidencia verificable | Menciona monitoreo o backup sin validación | **Confía en los *defaults* sin comprobar** |
| Costo / riesgo | Identifica costos, límites y mitigaciones | Reconoce algunos sin priorizar | No considera costo ni *lock-in* |
| Defensa | Justifica con evidencia y responde objeciones | Defensa mayormente descriptiva | No puede explicar las decisiones |

### Cierre: cambiar la pregunta

De **"¿quién administra el servidor?"** a **"¿quién responde por el servicio?"**

| Antes | Ahora | Siempre |
| :--- | :--- | :--- |
| Servidor, SO, instalación, archivos | Servicio, SLA, configuración, identidad, observabilidad, costo | **Datos, SQL, seguridad, continuidad, decisiones** |

> **DBaaS no elimina al DBA: eleva el nivel en el que debe administrar.**

## 10.19 Nuestra resolución: MongoDB Atlas

> **Desde acá, complemento con las resoluciones.** Nuestro grupo llevó la base documental de la Unidad 8 al plan gratuito de MongoDB Atlas (clúster M0). El caso ilustra casi todos los puntos de la clase con un motor NoSQL.

> *En la VM había que instalar el motor, configurar `mongod.conf`, abrir el firewall, crear usuarios con `db.createUser()` y programar los respaldos. En Atlas el clúster aparece en minutos. ¿Desapareció el trabajo del DBA?*

### Responsabilidad compartida, aplicada a Atlas

| Aspecto | Proveedor | Equipo | Compartido |
| :--- | :--- | :--- | :--- |
| Hardware, red física, centro de datos | ✓ | | |
| Sistema operativo y parches | ✓ | | |
| Instalación y versión del motor | ✓ | | |
| Réplicas y conmutación | ✓ | | |
| TLS en tránsito | ✓ | | |
| Quién puede conectarse (lista de IP) | | ✓ | |
| Usuarios y privilegios | | | ✓ (la plataforma los administra, el equipo decide) |
| Modelo de datos e índices | | ✓ | |
| Respaldo y restauración probada | | | ✓ |
| **Los datos** | | **✓ siempre** | |

> **La responsabilidad sobre los datos nunca se delega.** Si un usuario con permisos de más borra una colección, el servicio replica el borrado a los tres nodos sin dudar.

### Cómo se conecta un cliente

```bash
mongosh "mongodb+srv://<cluster>.<id>.mongodb.net/" --apiVersion 1 --username <usuario>
```

**La cadena SRV no tiene IP ni puerto.** El cliente consulta el **DNS**: el registro **SRV** indica los nodos del clúster y el **TXT**, opciones como el nombre del *replica set* y `authSource`. Así el proveedor puede reemplazar nodos sin cambiar la cadena. El clúster gratuito es un *replica set* de tres nodos.

**Tres controles antes de llegar a los datos:**

| Control | Dónde se configura | Si falla, se ve como... |
| :--- | :--- | :--- |
| **Lista de acceso por IP** | *Network Access* | Un ***timeout***: la conexión ni siquiera llega al motor |
| **TLS** | Obligatorio, lo pone el proveedor | Error de certificado (raro, porque viene configurado) |
| **Usuario de base de datos** (SCRAM) | *Database Access* | `Authentication failed` |

> Desde otra red (por ejemplo, del aula), la IP pública cambia y la conexión da *timeout*. Se agrega esa IP (*Add Current IP Address*); **no** se abre `0.0.0.0/0`, que deja la clave como única defensa frente a todo internet.

### Las dos capas de permisos

| Capa | Quién | Roles | Sirve para |
| :--- | :--- | :--- | :--- |
| **Plataforma** (la consola web) | Cuentas de Atlas | *Organization Owner*, *Project Owner*, *Project Read Only*... | Administrar el proyecto, ver configuración y métricas |
| **Motor** (la base) | Usuarios de base de datos | `atlasAdmin`, *read and write*, *read*, o un privilegio sobre una colección | Leer y escribir datos con `mongosh` o un driver |

Una identidad de una capa **no sirve en la otra**: *Project Read Only* no lee documentos, y un usuario de base de datos no entra a la consola.

#### Lo que cambia respecto de la VM

- En la VM los usuarios se creaban con `db.createUser()`. **En Atlas ese comando está bloqueado, incluso para `atlasAdmin`**, igual que `createRole`, `dropUser`, `grantRolesToUser` o `updateUser`. Los usuarios se crean desde la plataforma (*Database Access*) o su API: **el motor hace cumplir los permisos, pero no los administra**.
- No hay acceso a `mongod.conf` ni al sistema operativo.
- Un rechazo de permiso se ve así: `MongoServerError[AtlasError]: user is not allowed to do action [insert] on [base.coleccion]`.

### Respaldo y recuperación en Atlas

**La replicación no es un respaldo.** Las tres copias del clúster protegen contra la caída de un nodo, no contra un error lógico: un borrado se replica en el acto. Es la misma idea del Parcial 1: *la alta disponibilidad no es backup*.

| Opción en el plan gratuito | Detalle |
| :--- | :--- |
| Snapshots administrados | En el plan Free son una **suscripción paga** opcional (un snapshot diario, se conservan 4) que exige un medio de pago. Si la consigna prohíbe registrar tarjetas, no se activan |
| **`mongodump` contra el endpoint** | Funciona y es **portable**: el respaldo queda fuera del proveedor. En Free/Flex no admite `--oplog` ni el volcado de usuarios y roles |
| Restauración | `mongorestore` con `--nsFrom`/`--nsTo` a otra base (por ejemplo `base_restore`), en el mismo clúster o en uno local. Restaurar en Atlas requiere un usuario con `atlasAdmin` |

```bash
mongodump --uri "mongodb+srv://<cluster>.<id>.mongodb.net/" --username <admin> --db tienda --out ~/backup_atlas
mongorestore --uri "mongodb+srv://<cluster>.<id>.mongodb.net/" --username <admin> \
  --nsFrom 'tienda.*' --nsTo 'tienda_restore.*' ~/backup_atlas
```

> **Un respaldo sin restauración probada no es un respaldo.** La consigna lo decía explícitamente: una captura de "backup activado" no prueba nada. Se valida comparando recuentos, valores y los **mismos `_id`**, que prueban que es una copia fiel y no una carga nueva.

### Monitoreo y límites del plan gratuito (M0)

| Aspecto | Plan Free (M0) |
| :--- | :--- |
| Almacenamiento | 512 MB (documentos BSON más índices) |
| Operaciones | 100 por segundo |
| Conexiones | 500 |
| Transferencia | 10 GB de entrada y 10 GB de salida cada 7 días |
| Versión | La fija el proveedor (MongoDB 8.0): no se elige ni se actualiza |
| Topología | *Replica set* fijo de tres nodos; un clúster Free por proyecto |
| Inactividad | Se **pausa** tras 30 días sin conexiones (no se borra) |
| Red | Sin *private endpoints* ni *peering* |
| JavaScript del lado del servidor | No soportado (`$where`, `mapReduce`, `$function`, `$accumulator`) |
| Métricas | Solo conexiones, operaciones, red y tamaño lógico |
| Logs y diagnóstico | Sin descarga de logs, sin panel en tiempo real, sin *Performance Advisor*, sin auditoría |

**Costos y dependencia del proveedor (*lock-in*):** el plan gratuito sirve para aprender y prototipar. En producción, el costo crece con el tamaño del clúster, el respaldo y la transferencia, y cuanto más se usan funciones propias de la plataforma, más cuesta migrar. `mongodump` y los drivers estándar mantienen la **portabilidad**.

### VM frente a DBaaS

| Aspecto | VM propia | DBaaS (Atlas) | Quién lo administra en DBaaS |
| :--- | :--- | :--- | :--- |
| Instalación y sistema operativo | El equipo instala, configura y parchea | Viene listo | Proveedor |
| Conectividad | `bindIp`, firewall, TLS a mano | SRV, lista de IP y TLS obligatorio | Compartida |
| CRUD | `mongosh` | `mongosh` (igual) | Equipo |
| Usuarios y permisos | `db.createUser()` y roles | Consola o API; `createUser` bloqueado | Compartida |
| Respaldo y restauración | `mongodump`, copias de archivos | Snapshots pagos en Free; `mongodump` portable | Compartida |
| Monitoreo | `serverStatus`, logs completos | Cuatro métricas en Free, sin logs | Proveedor (y límites del plan) |
| Costos | Hardware y horas de operación | Gratuito con límites; luego, por uso | Equipo |

### ¿DBaaS eliminó al DBA en nuestro caso?

No: **transforma el rol**. Se delegan la instalación, los parches, las réplicas y el TLS. Quedan el **diseño de datos e índices**, el **mínimo privilegio**, la **red** (lista de IP), la **continuidad** con restauraciones probadas, los **límites del servicio** y los **costos**. En la actividad igual hubo que decidir permisos, red y respaldo, y compensar los límites del plan (sin respaldo administrado gratuito, sin `createUser`, sin logs).

## 10.20 Otra resolución: PostgreSQL en Supabase

Otro grupo resolvió la unidad con **Supabase**, una plataforma que ofrece **PostgreSQL administrado** (17.11 en su instancia) con un plan gratuito de **500 MB**. Los mismos conceptos aparecen con un motor relacional:

| Tema | Qué encontraron |
| :--- | :--- |
| **Conexión** | La conexión directa **falló desde su red**. Usaron el ***pooler*** de conexiones de la plataforma (Supavisor) en **modo sesión**, en el puerto 5432: el *endpoint* no es un servidor sino un intermediario administrado |
| **Verificación** | `SELECT version(), current_database(), current_user, ssl_is_used();` confirmó el motor, la base, la identidad y que la conexión viajaba **cifrada** |
| **Plano de la plataforma** | Roles de la organización: *Owner*, *Administrator*, *Developer* y *Read-only* |
| **Plano del motor** | El RBAC de PostgreSQL (roles y `GRANT`) más ***Row Level Security*** (RLS), que filtra **filas** según el usuario |
| **Superusuario** | El usuario `postgres` que entrega la plataforma **no es `SUPERUSER`**: tiene privilegios delegados, para que un cliente no pueda comprometer el *host* compartido |
| **Mínimo privilegio** | Un rol `auditor_lectura` con `GRANT SELECT`: el `INSERT` y el `DELETE` fueron **rechazados** con `permission denied`. Prueba positiva y negativas, como en la Unidad 8 |
| **Observabilidad** | Panel con CPU y RAM, tamaño de la base y **consultas lentas** |
| **Extra de la plataforma** | Una API REST autogenerada sobre las tablas (PostgREST): cómoda, pero es una dependencia propia del proveedor |

### Atlas frente a Supabase

| | MongoDB Atlas (nuestro grupo) | Supabase (otro grupo) |
| :--- | :--- | :--- |
| Motor | MongoDB 8.0, documental | PostgreSQL 17.11, relacional |
| Conexión | Cadena SRV (`mongodb+srv://`), sin IP ni puerto | *Pooler* administrado en el 5432 |
| Plano de la plataforma | *Organization* y *Project* roles | *Owner*, *Administrator*, *Developer*, *Read-only* |
| Plano del motor | Roles de MongoDB, pero **creados desde la consola**: `db.createUser()` bloqueado | RBAC + RLS de PostgreSQL, administrados con SQL; `postgres` sin `SUPERUSER` |
| Lo que "puede cambiar" (10.8) | Comandos de administración de usuarios | Privilegios de superusuario |
| Plan gratuito | 512 MB | 500 MB |

> **Lo que muestran las dos resoluciones juntas:** cambia el motor y cambia el proveedor, pero la clase se cumple igual: **dos planos de identidad**, un *endpoint* administrado, límites de compatibilidad y la necesidad de **probar** permisos y recuperación en lugar de confiar en los *defaults*.

## Preguntas de repaso · Unidad 10

1. Si el proveedor administra el servidor, los backups y la HA, ¿qué queda por administrar? Respondé con las cuatro preguntas de la clase.
2. Ordená on-premise, IaaS, DBaaS y serverless por abstracción. ¿Más abstracción implica menos responsabilidad sobre los datos?
3. ¿Por qué cloud no significa automáticamente barato, elástico ni altamente disponible?
4. "DBaaS es una forma de operar un motor, no un nuevo modelo de datos": explicá con un ejemplo.
5. Completá la tabla de responsabilidad compartida. ¿Qué es "compartido" y qué es siempre del cliente?
6. ¿Qué seis decisiones se toman al provisionar? Desarmá el *endpoint* `postgresql://app@mi-db.proveedor.cloud:5432/ventas`.
7. ¿Qué diferencia hay entre acceso público y privado? ¿Por qué "público no significa abierto"?
8. ¿Qué puede cambiar en un PostgreSQL o MySQL administrado respecto del servidor propio?
9. En el backup administrado, ¿qué hace el proveedor, qué hace el cliente y qué sostienen ambos? ¿Qué demuestra un *checkbox* "backup enabled"?
10. ¿Por qué la HA administrada no reemplaza al backup?
11. CPU alta y latencia creciente: ¿por qué "subamos la instancia" puede ser una mala decisión? ¿Qué haría un DBA?
12. ¿Cuáles son los dos planos de la seguridad en DBaaS? Da un ejemplo de cada resolución (Atlas y Supabase).
13. ¿Cuáles son los seis pasos de una migración y cuándo termina?
14. ¿Qué tres preguntas de portabilidad conviene hacer antes de adoptar una plataforma?
15. ¿Qué responsabilidades siguen siendo del equipo en DBaaS, y cuál nunca se delega?
16. ¿Por qué la cadena `mongodb+srv://` no tiene IP ni puerto?
17. Desde otra red, `mongosh` da *timeout*. ¿Qué capa falla y cómo se corrige sin abrir todo?
18. ¿Por qué `db.createUser()` falla en Atlas aunque el usuario sea `atlasAdmin`?
19. ¿Puede un miembro con *Project Read Only* leer documentos? ¿Por qué?
20. ¿Por qué tres réplicas no protegen contra un borrado accidental?
21. ¿Cómo se respalda y se valida una recuperación en el plan gratuito sin registrar tarjetas?
22. ¿Qué límites del plan Free condicionan el monitoreo y el respaldo?

---

# Integración: preguntas que cruzan unidades

| Situación | Unidades | Línea de respuesta |
| :--- | :--- | :--- |
| "El catálogo tiene atributos distintos por categoría: pasémoslo a MongoDB." | 7 · 9 | Primero ver si el relacional alcanza: `JSON` con índices (generados, funcionales, multivaluados) en MySQL, o `JSONB` con un `GIN` en PostgreSQL. Con la regla de adopción, un empate no justifica un motor más. Revisar solo si los filtros son impredecibles. |
| "La búsqueda de productos es lenta y no encuentra plurales." | 7 · 9 | `FULLTEXT` de MySQL resuelve palabras y relevancia, pero no raíces ni errores de tipeo; PostgreSQL los resuelve con `spanish` y `pg_trgm`. Facetas o búsqueda semántica piden un buscador alimentado por CDC desde la fuente de verdad. |
| "La consulta en MongoDB examina 200.000 documentos para devolver 800." | 8 · P1 | Falta un índice para ese patrón: compuesto con la regla ESR, verificado con `explain("executionStats")`. Es la misma lógica del prefijo izquierdo. |
| "El lector puede consultar pero no modificar." | 8 · 10 | Diagnóstico por capas: conexión y autenticación funcionan, falla la autorización. En la VM, `grantRolesToUser`; en Atlas, desde *Database Access*. |
| "Tenemos tres réplicas: no hace falta respaldo." | 8 · 10 · P1 | La replicación copia los errores. Hace falta un respaldo en otro momento y otro lugar, con restauración probada. |
| "Guardemos el pedido en MySQL y después en Neo4j." | 9 | Escritura doble no atómica: outbox en la misma transacción, consumidor idempotente con `MERGE` y versión por entidad. |
| "Dos procesos suman al mismo contador y se pierden unidades." | 9 · P1 | Actualización perdida: operación atómica del motor (`HINCRBY`, `UPDATE ... SET x = x + n`) o condición en la escritura. |
| "Cassandra no permite consultar por tipo de evento." | 9 | Una tabla por consulta, con la partición acotada por un cubo (`tipo_evento, dia`). `ALLOW FILTERING` no es la solución. |
| "El stock lo guardamos en Redis para que sea rápido." | 9 | El stock exige atomicidad y no puede perderse: va al motor relacional con una actualización condicional. Redis, si acaso, como caché de lo que tolera estar desactualizado. |
| "En Atlas no podemos ver los logs del incidente." | 10 | Es un límite del plan gratuito: hay que diseñar la evidencia (recuentos, pruebas de permisos) y saber qué cubre cada plan. |

## Errores conceptuales frecuentes

| Afirmación incorrecta | Corrección |
| :--- | :--- |
| "NoSQL es más rápido." | Depende del patrón de acceso. Para uniones e integridad, el relacional es más adecuado. |
| "Esquema flexible significa que no hay que diseñar." | Se diseña igual, desde las consultas, y se puede validar con `$jsonSchema`. |
| "Un índice sobre la columna `JSON` acelera cualquier filtro en MySQL." | No existe tal índice: cada atributo filtrado necesita el suyo. |
| "Con un `GIN` sobre el `JSONB`, cualquier filtro sobre el documento usa el índice." | Solo los operadores de su clase (`@>`, y `?` con `jsonb_ops`). `atributos->>'clave' = 'x'` recorre la tabla. |
| "`json` y `JSONB` son lo mismo en PostgreSQL." | `json` guarda el texto tal cual y no admite un índice `GIN`; el que se consulta e indexa es `JSONB`. |
| "El Full-Text de un relacional no reconoce plurales." | Es un límite del `FULLTEXT` de MySQL. PostgreSQL con la configuración `spanish` reduce a la raíz: `juego` encuentra `juegos`. |
| "Bajé `min_token_size`, así que ya se indexan las siglas." | Hay que reconstruir el índice, y en dos sentencias separadas. |
| "WiredTiger mueve los documentos cuando crecen." | Eso era MMAPv1. El problema actual es el tamaño, la caché y el costo de mantener arreglos grandes. |
| "La notación con punto aplica todas las condiciones al mismo elemento." | Eso lo hace `$elemMatch`. |
| "`userAdminAnyDatabase` es seguro porque no lee datos." | Puede concederse cualquier rol. |
| "`bindIp: 0.0.0.0` no importa si hay autenticación." | Expone el puerto, habilita fuerza bruta y, sin TLS, los datos viajan en claro. |
| "`mongoexport` es un respaldo." | Pierde tipos BSON e índices; el respaldo es `mongodump`. |
| "`MULTI`/`EXEC` revierte si un comando falla." | No hay retroceso: los demás comandos se aplican. |
| "`ALLOW FILTERING` resuelve la consulta." | Solo fuerza un recorrido completo; la solución es otra tabla. |
| "Cassandra es AP." | La consistencia se ajusta por operación: con `QUORUM` en lectura y escritura es fuerte. |
| "CAP: se eligen dos de tres." | Es la elección **ante una partición**; sin particiones se tienen C y A. |
| "La C de CAP es la de ACID." | Una es leer lo último escrito; la otra, respetar restricciones. |
| "Exactamente una vez se configura en la red." | Se logra con al menos una vez + consumidor idempotente. |
| "En DBaaS el proveedor se ocupa de todo." | Los datos, el acceso y la recuperación siguen siendo del equipo. |
| "La replicación de Atlas es un respaldo." | Replica también los borrados. |

---

# Chuleta de comandos por motor

| Tarea | MySQL 9 (JSON y FTS) | MongoDB | Redis | Cassandra | Neo4j |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Conectarse | `mysql -h host -u usr -p` · `mysqlsh` (X Protocol, 33060) | `mongosh "mongodb://host:27017/base" -u usr --authenticationDatabase admin` | `redis-cli -h host --user usr` (clave en `REDISCLI_AUTH`) | `cqlsh host -u usr` | `cypher-shell -a bolt://host:7687 -u usr` |
| Crear | `INSERT` con columna `JSON` | `insertOne`, `insertMany` | `SET`, `HSET`, `SADD`, `ZADD` | `INSERT` (upsert) | `CREATE`, `MERGE` |
| Leer | `doc->>'$.clave'`, `MATCH ... AGAINST` | `find`, `aggregate` | `GET`, `HGETALL`, `SMEMBERS`, `ZRANGE` | `SELECT ... WHERE <partición>` | `MATCH ... RETURN` |
| Modificar | `JSON_SET`, `UPDATE` | `updateOne` con `$set`, `$inc`, `$push` | `SET`, `HINCRBY`, `EXPIRE` | `UPDATE` (upsert) | `SET` |
| Borrar | `DELETE`, `JSON_REMOVE` | `deleteOne`, `deleteMany` | `DEL`, `HDEL`, `SREM` | `DELETE` (lápida) | `DETACH DELETE` |
| Índice | Generado, funcional, multivaluado, `FULLTEXT` | `createIndex({ a: 1, b: 1 })` | (No hay: se accede por clave) | Tabla por consulta | `CREATE CONSTRAINT ... IS UNIQUE`, `CREATE INDEX` |
| Ver el plan | `EXPLAIN ANALYZE` | `explain("executionStats")` | `SLOWLOG GET` | `TRACING ON` | `EXPLAIN`, `PROFILE` |
| Validar forma | `CHECK (JSON_SCHEMA_VALID(...))` | `$jsonSchema` con `collMod` | — | Tipos de columna | Restricciones |
| Usuario y permisos | `CREATE USER`, `GRANT` | `createUser`, `grantRolesToUser` (en Atlas, desde la consola) | `ACL SETUSER` | `CREATE ROLE`, `GRANT` | `ALTER CURRENT USER SET PASSWORD` (sin roles en Community) |
| Ver permisos | `SHOW GRANTS` | `connectionStatus({ showPrivileges: true })` | `ACL GETUSER`, `ACL WHOAMI` | `LIST ROLES` | `SHOW CURRENT USER` |
| Vencimiento | Evento o tarea programada | Índice TTL | `EXPIRE`, `SET ... EX`, `TTL` | `USING TTL` | — |
| Respaldo | `mysqldump`, binlog | `mongodump` | `BGSAVE` → `dump.rdb` | `nodetool snapshot` | `neo4j-admin database dump` (fuera de línea) |
| Restaurar | `mysql < dump.sql`, `mysqlbinlog` | `mongorestore --nsFrom --nsTo` | Otra instancia con el `.rdb` | `nodetool refresh`, `sstableloader` | `neo4j-admin database load` |
| Carga masiva | `LOAD DATA`, `util.importJson` | `mongoimport` | `redis-cli --pipe` | `COPY ... FROM` | `LOAD CSV` |

### Unidad 7: MySQL frente a PostgreSQL

| Tarea | MySQL 9 (`JSON` y `FULLTEXT`) | PostgreSQL (`JSONB` y `tsvector`) |
| :--- | :--- | :--- |
| Leer una clave como texto | `doc->>'$.marca'` | `doc->>'marca'` |
| ¿Contiene este par? | `JSON_CONTAINS(doc, '16', '$.ram_gb')` | `doc @> '{"ram_gb": 16}'` |
| ¿Existe la clave? | `JSON_CONTAINS_PATH(doc, 'one', '$.gpu')` | `doc ? 'gpu'` |
| Modificar / quitar una clave | `JSON_SET`, `JSON_REMOVE` | `jsonb_set`, `doc \|\| '{...}'`, `doc - 'clave'` |
| Elemento de un arreglo | `'gaming' MEMBER OF (tags)` | `tags @> '["gaming"]'` (o `text[]` con `@>`, `&&`) |
| Índice sobre el documento | Uno por atributo: columna generada, funcional o multivaluado | `CREATE INDEX ... USING gin (doc jsonb_path_ops)` |
| Índice para rango sobre una clave | Columna generada + índice | `CREATE INDEX ... (((doc->>'litros')::int))` |
| Validar la forma | `CHECK (JSON_SCHEMA_VALID(...))` | `CHECK (jsonb_typeof(...) = 'array')`, `CHECK (doc ? 'clave')` |
| Índice de texto | `ALTER TABLE t ADD FULLTEXT (descripcion)` | `CREATE INDEX ... USING gin (to_tsvector('spanish', descripcion))` |
| Buscar texto | `MATCH(descripcion) AGAINST('...' IN BOOLEAN MODE)` | `to_tsvector('spanish', descripcion) @@ websearch_to_tsquery('spanish', '...')` |
| Relevancia | El valor de `MATCH ... AGAINST` | `ts_rank`, `ts_rank_cd` |
| Ver la tokenización | `INFORMATION_SCHEMA.INNODB_FT_INDEX_TABLE` | `ts_debug('spanish', '...')` |
| Plan real | `EXPLAIN ANALYZE` | `EXPLAIN (ANALYZE, BUFFERS)` |
| Extensiones y plugins | `SHOW PLUGINS` | `pg_available_extensions`, `CREATE EXTENSION` |

---

# Resoluciones de las actividades

Como en el simulacro del Parcial 1, las preguntas de opción múltiple suelen describir situaciones de las actividades: un filtro sobre una clave JSON que no existe, un `$elemMatch`, un usuario que lee pero no escribe, un `ALLOW FILTERING`, un `MERGE` idempotente o un `createUser` rechazado en Atlas.

Para cada actividad hay:

- **Qué pedía.**
- **Cómo se resolvió**, con la evidencia obtenida.
- **Lo que hay que saber explicar**, con enlaces a la teoría.
- **Errores y mejoras** detectados al revisar la resolución: son los detalles que suelen aparecer como opción incorrecta.

## U7 · Actividad 1: Radar multimodelo

**Qué pedía:** identificar el entorno (motor, versión, puertos, cliente), investigar las capacidades no relacionales del motor asignado en la documentación oficial, clasificarlas (*Core*, *Habilitable*, *Extensión/Plugin/Cliente*, *No disponible*) con su evidencia, y elegir una capacidad avanzada para la segunda fase. Teoría: [7.6](#76-cómo-reaccionan-los-sgbd-relacionales) a [7.13](#713-la-actividad-hasta-dónde-puede-llegar-nuestro-motor-relacional).

Se comparan dos resoluciones: la nuestra en **MySQL 9.7** y la de otro grupo en **PostgreSQL 18.6**.

| Capacidad | MySQL 9.7 | Evidencia (MySQL) | PostgreSQL 18.6 | Evidencia (PostgreSQL) |
| :--- | :--- | :--- | :--- | :--- |
| Documentos JSON | Core | `JSON_VALID`, `JSON_EXTRACT`, `JSON_TYPE` | Core (`JSONB`) | `SELECT '{"item":"sensor","valor":42}'::jsonb;` |
| Índice para documentos o arreglos | Core (multivaluado) | Creación del índice | Core (`GIN`) | `CREATE INDEX ... USING gin (...)` |
| Arreglos | Dentro de JSON | — | Core (`text[]`) | `SELECT ARRAY['tag1','tag2']::text[];` |
| Texto completo | Core / Habilitable | Core para `FULLTEXT`; Habilitable para ajustar el tamaño mínimo o las *stopwords* | Core | `to_tsvector('spanish', ...) @@ to_tsquery('spanish', ...)` |
| Clave-valor | Dentro de JSON | — | Habilitable (`hstore` 1.8) | `pg_available_extensions` con `installed_version` vacío |
| Document Store | Extensión/Plugin/Cliente | `SHOW PLUGINS` con `mysqlx` activo en el puerto 33060; hace falta MySQL Shell | No aplica | — |
| Espacial | Core | `SPATIAL INDEX` con `NOT NULL` y SRID 4326 | No disponible | `pg_available_extensions WHERE name = 'postgis'`: 0 filas |
| Vistas de dualidad JSON | Core | `CREATE JSON DUALITY VIEW` disponible en la 9.7 | No aplica | — |

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| **Capacidad elegida** | Full-Text Search, para buscar por relevancia en las descripciones en lugar de `LIKE '%palabra%'` | `JSONB` con índice `GIN` (`jsonb_path_ops`) y operadores de contención, para filtrar un catálogo de atributos variables sin EAV |
| **Requisito de habilitación** | Core; ajustar la tokenización exige editar el `.cnf` y reiniciar | Core: ni paquetes del sistema operativo ni `CREATE EXTENSION` |

### Lo que hay que saber explicar

- **"Disponible" no alcanza:** la clasificación dice **cómo** se habilita. Que el servidor tenga el X Plugin activo no significa que se pueda usar el Document Store desde el cliente clásico `mysql`. En PostgreSQL pasa lo mismo con `hstore`: el paquete está, pero hasta el `CREATE EXTENSION` la base no lo tiene.
- **La evidencia es una consulta al catálogo o un comando**, no una cita del manual: `SHOW PLUGINS` o `SHOW VARIABLES LIKE 'innodb_ft%'` en MySQL; `pg_available_extensions`, `pg_extension`, `pg_am` o `pg_type` en PostgreSQL.
- **La segunda fase debía ir más allá** de guardar JSON en una columna con `SELECT` simples. Las dos elecciones cumplen: una usa un índice invertido de texto y la otra, un índice invertido sobre documentos.
- **Las dos capacidades elegidas son índices invertidos** ([7.16](#716-índices-sobre-json-en-detalle) y [7.17](#717-full-text-search-el-índice-invertido)): uno indexa palabras y el otro, componentes de un documento.

### Errores y mejoras de la resolución en PostgreSQL

- **El nombre del paquete de PostGIS:** se indicó `postgresql-contrib-postgis`. En Ubuntu, con los repositorios de PostgreSQL, el paquete sigue el patrón `postgresql-<versión>-postgis-3`. Después hace falta `CREATE EXTENSION postgis` en cada base.
- **La consigna pedía el entorno completo:** sistema operativo y cliente, además de la versión. La segunda actividad declara una instalación en Windows (`x86_64-windows`) y el radar se armó pensando en paquetes de Ubuntu (`apt`). **Si cambia el entorno, hay que volver a verificar las capacidades**: lo habilitable depende de qué paquetes trae cada instalación.
- **"Reduce la búsqueda de O(N) a O(log N)"** es una simplificación. Lo que hay que defender es lo que se midió: el cambio de `Seq Scan` a `Bitmap Index Scan` y los bloques leídos.

## U7 · Actividad 2: Catálogo con JSON y búsqueda de texto completo

**Qué pedía:** registrar una línea base, verificar la capacidad elegida en el entorno, implementar un catálogo híbrido (columnas fijas + documento), resolverlo con al menos tres consultas distintas, aplicar una intervención física, comparar planes antes y después, medir el costo y concluir si el relacional extendido alcanza o conviene un motor especializado. Teoría: [7.14](#714-consultar-y-modificar-json-en-los-dos-motores) a [7.21](#721-relacional-extendido-frente-a-nosql-especializado).

Cada grupo trabajó sobre la capacidad que eligió en la actividad 1, con el **mismo dataset** de 20 productos. Por eso se comparan los temas, no los números.

| Fase | MySQL 9.7 (Full-Text Search) | PostgreSQL 18.6 (`JSONB` + `GIN`) |
| :--- | :--- | :--- |
| Habilitación | `innodb_ft_min_token_size = 2` en un `.cnf` propio + reinicio + tabla de *stopwords* en español, porque de fábrica no se indexaban `TV`, `4K` o `HP` | `CREATE EXTENSION btree_gin`; verificación de `GIN` en `pg_am` y de `json`/`jsonb` en `pg_type`; prueba de `@>` sobre un objeto, un arreglo y un arreglo anidado |
| Modelo híbrido | Precio, stock y categoría en columnas; atributos y etiquetas en `JSON` | Tabla `categorias` (rubro, garantía, devolución) con **FK** desde `productos`; `CHECK (precio > 0)` y `CHECK (stock >= 0)`; atributos y etiquetas en `JSONB NOT NULL` |
| Consultas | Rutas JSON; el ultrabook sin la clave `gpu` quedó excluido de un filtro con `<>` | Agregación por rubro con `JOIN`; extracción con `->>` de talles, litros y *no frost*; búsqueda transversal `atributos @> '{"ram_gb": 16}' OR tags @> '["gaming"]'` |
| Índice especializado | Multivaluado `idx_tags_mv`: de `Table scan` (costo 2,25) a `Index lookup` (0,70); índice `FULLTEXT` sobre la descripción | `GIN` con `jsonb_path_ops` sobre `atributos` y `GIN` por defecto sobre `tags` |
| Con 20 filas | Todo por debajo de 2 ms: solo es comparable el plan | El optimizador mantuvo `Seq Scan` (costo 1,25, un bloque); forzado con `enable_seqscan = off`, el índice costaba 12,55 |
| Escala | 200.000 filas: `LIKE '%SKU...%'` costo 22.541 y 0,5–0,6 s; `MATCH` costo 1,10 y 1–5 ms | 20.000 filas: de `Seq Scan` (costo 760, 510 bloques) a `Bitmap Index Scan` (costo 558, 3 bloques de índice), ≈ 2,5 ms |
| Costo | `UPDATE` de 20.000 descripciones: de 0,60 s a 2,83 s; 20.000 entradas en `INNODB_FT_DELETED`; 210.261 términos | Índice de 192 kB, el 4,7 % de la tabla; costo de escritura explicado (`fastupdate`) pero no medido |
| Límites | `juego` → 0, `juegos` → 2, `juego*` → 2, `notebok` → 0 | Validación polimórfica estricta; búsqueda facetada masiva |
| Veredicto | El relacional extendido alcanza para buscar palabras con relevancia; un buscador solo si fuera el producto | El relacional extendido alcanza: ACID y FK en lo estable, `JSONB` en lo variable; MongoDB fragmentaría la consistencia del inventario sin ganancia de escala |

```sql
-- PostgreSQL: la consulta que explota la capacidad y la intervención física
SELECT id, nombre, categoria, atributos->>'ram_gb' AS ram, tags
FROM productos
WHERE atributos @> '{"ram_gb": 16}'::jsonb
   OR tags      @> '["gaming"]'::jsonb;

CREATE INDEX idx_productos_atributos_gin ON productos USING gin (atributos jsonb_path_ops);
CREATE INDEX idx_productos_tags_gin      ON productos USING gin (tags);
ANALYZE productos;
```

Con los dos índices, el plan puede combinar ambas condiciones del `OR` en un **`BitmapOr`**. Si el filtro se escribiera `atributos->>'ram_gb' = '16'`, en cambio, ninguno de los dos índices serviría ([7.16](#716-índices-sobre-json-en-detalle)).

### Lo que hay que saber explicar

- **Por qué se escaló:** con 20 filas, todo tarda menos de 2 ms (MySQL) o entra en un bloque (PostgreSQL); lo único comparable es el plan ([7.20](#720-cómo-medir)).
- **Por qué el optimizador de PostgreSQL rechazó el índice con 20 filas**, y por qué eso no es un error: leer un bloque es más barato que recorrer el índice y después la tabla. Es la misma lección de la Unidad 1 del Parcial 1.
- **Por qué el `ALTER` combinado de MySQL no reconstruyó** el índice y cómo se comprobó ([7.18](#718-tokenización-y-configuración)).
- **El costo del índice invertido** en las escrituras: purga con `OPTIMIZE TABLE` en MySQL, lista pendiente y `VACUUM` en PostgreSQL ([7.17](#717-full-text-search-el-índice-invertido)).
- **`jsonb_path_ops` frente a `jsonb_ops`:** el primero es más chico y rápido para `@>`, pero no sirve para preguntar si existe una clave (`?`).
- **La conclusión es condicionada en los dos casos:** el relacional extendido alcanza para el catálogo; un motor especializado se justifica por una necesidad concreta (raíces y errores de tipeo en MySQL, facetas o búsqueda semántica en los dos).

### Errores y mejoras de la resolución en PostgreSQL

- **La escala se armó copiando 1.000 veces los mismos 20 productos.** Los atributos se repiten exactamente, así que `ram_gb = 16` devuelve el **10 % de la tabla**. Eso explica que el costo bajara solo de 760 a 558. Para medir el efecto del índice conviene generar valores variados y un filtro selectivo.
- **"3 buffers" son solo los del índice:** el `Bitmap Heap Scan` igual tiene que leer las páginas de la tabla donde están las 2.000 filas. Hay que informar el total del plan, no solo el nodo del índice.
- **"`jsonb_path_ops` es hasta un 65 % más compacto" y "tres veces más chico"** son afirmaciones que no se midieron. Para defenderlas hay que crear los dos índices sobre la misma tabla y comparar `pg_relation_size`.
- **`btree_gin` se habilitó pero no se usó:** los dos índices creados son de una sola columna. Tendría sentido en un índice como `(categoria, atributos)`, si las consultas combinaran los dos filtros.
- **El costo de escritura se explicó pero no se midió.** La consigna pedía medirlo: por ejemplo, el tiempo de un lote de `INSERT` o de un `UPDATE` masivo de `atributos`, con y sin el índice.
- **`tags` no tiene una restricción de forma:** nada impide guardar un objeto en lugar de un arreglo. Se resuelve con `CHECK (jsonb_typeof(tags) = 'array')` ([7.15](#715-esquema-híbrido-qué-va-en-columna-y-qué-en-json)).

### Errores y mejoras de la resolución en MySQL

- **La búsqueda en español quedó a mitad de camino:** sin raíces ni tolerancia a errores de tipeo. En el veredicto conviene decir que **PostgreSQL resuelve ambas cosas en el propio motor** (configuración `spanish` y `pg_trgm`), así que el límite es de MySQL y no del modelo relacional ([7.19](#719-modos-de-búsqueda-y-relevancia)).

## U8 · Actividad 1: Modelado documental en un escenario de logística

**Qué pedía:** diseñar colecciones a partir de los patrones de acceso del escenario, cargar al menos 30 documentos representativos, hacer CRUD, resolver cuatro consultas (con filtros sobre arreglos o subdocumentos) y un pipeline de al menos tres etapas, optimizar con un índice y `explain("executionStats")` antes y después, y defender una alternativa descartada. Teoría: [8.1](#81-la-pregunta-de-la-unidad) a [8.19](#819-desafío-mongodb-y-criterios-de-logro).

| Aspecto | Resolución |
| :--- | :--- |
| Modelo | `envios` (15) con paquetes, origen, destino y transportista embebidos; `eventos_seguimiento` (20) referenciados con `envio_id`; `estado_actual` y `minutos_demora` duplicados en el envío |
| CRUD | Alta, lectura, modificación con `$set` y `$push`, y baja de un envío de prueba, verificando cada paso |
| Consultas | Por ruta y rango de fechas (la prioritaria), por subdocumento con `$elemMatch`, por `_id` con su historial (`$lookup`) y un pipeline de demoras por transportista |
| Índice | `{ ruta: 1, fecha_despacho: 1 }` |
| `explain` con 15 documentos | Examinados: de 15 a 3. El tiempo subió (de 7 a 27 ms) porque 25 ms eran de planificación |
| `explain` con 200.000 documentos | De `COLLSCAN` con 200.000 examinados a `IXSCAN` con 811 para 811 devueltos. El orden inverso del índice examinó 1.531 claves |
| Costo | Dos índices secundarios sumaron un 31 % al tiempo de carga |
| Alternativa descartada | Todo en una sola colección con los eventos embebidos: arreglo sin cota |

### Lo que hay que saber explicar

- **Cada decisión de modelado responde a un patrón de acceso** y a una cardinalidad ([8.6](#86-embedding-frente-a-referencing)).
- **`$elemMatch` frente a la notación con punto:** 5 envíos contra 2 ([8.11](#811-operadores-de-consulta-y-arreglos)).
- **La medición engañosa:** con pocos documentos el tiempo no prueba nada; se comparan documentos y claves examinados ([8.13](#813-explain-evidencia-del-plan)).

**Mejoras que surgieron al revisar:** la devolución pidió reforzar la evidencia y verificar los requisitos de carga. Por eso se agregaron la consulta por estado y fecha, el contraste de `$elemMatch` y la prueba de volumen con 200.000 envíos. En el pipeline original faltaba el `$` en algunas referencias a campos, un error que hace que `$group` agrupe por un texto fijo.

## U8 · Actividad 2: Seguridad y respaldo en MongoDB

**Qué pedía:** diagnosticar la instancia (versión, autenticación, red), activar la autenticación con un administrador, crear un lector y un operador sobre la base del grupo y probar lo permitido y lo denegado, revisar la red y explicar o implementar TLS, hacer `mongodump`, borrar de forma controlada una colección de prueba y restaurar en una base alternativa validando recuentos, y diagnosticar el incidente "puede leer pero no modificar". Teoría: [8.20](#820-la-guardia-dba-qué-revisar-al-tomar-una-instancia) a [8.27](#827-diagnosticar-puedo-leer-pero-no-modificar).

| Paso | Resolución | Evidencia |
| :--- | :--- | :--- |
| Diagnóstico | MongoDB 8.0, base del grupo con `envios` y `eventos_seguimiento`, sin usuarios | `bindIp: 0.0.0.0` en el archivo de configuración: expuesta a toda la red |
| Autenticación | Administrador creado, `authorization: enabled`, reinicio | Sin credenciales: `Command find requires authentication` |
| RBAC | Lector con `read` y operador con `readWrite`, solo sobre la base del grupo | El lector lee y no modifica; el operador modifica y no puede crear usuarios |
| Red y TLS | Se pasó a escuchar en `127.0.0.1` y se explicó la configuración `requireTLS` con CA y certificado | En un laboratorio aislado se probó además el TLS mutuo |
| Respaldo | `mongodump` de la base y `mongorestore` con `--nsFrom`/`--nsTo` a `<base>_restore` | Recuentos iguales en origen y copia (16 y 16, 20 y 20) |
| Incidente | Diagnóstico por capas | `not authorized ... to execute command { update: ... }`: falla la autorización |

### Lo que hay que saber explicar

- **Las tres capas** y el código de error de cada una ([8.21](#821-tres-capas-tres-fallas-distintas)).
- **Por qué usuarios separados para respaldo y restauración:** en las pruebas, el rol `restore` permitió insertar documentos y crear usuarios ([8.23](#823-autorización-rbac)).
- **Qué agrega el TLS mutuo** y qué error aparece si el cliente no confía en la CA ([8.25](#825-tls)).
- **Contar no alcanza:** prueba que hay datos, no que son los mismos. Se suma la comparación de contenido, índices y una consulta de negocio ([8.26](#826-respaldo-y-recuperación)).

**Errores y mejoras:** la devolución pidió pruebas más completas de los controles y de la recuperación. Se agregaron pruebas negativas, de escalada y de aislamiento, y la validación del contenido además de los recuentos. Las claves de laboratorio aparecían en claro en las capturas y en los comandos: en un informe se usan `passwordPrompt()`, `-p` sin valor o un marcador.

## U9 · Actividad 1: Redis, Cassandra y Neo4j

**Qué pedía:** con los datos de la cátedra (usuarios, productos y eventos), modelar y operar el mismo dominio en tres motores. En **Redis**, sesiones con vencimiento, carritos, favoritos y un ranking, más ACL y un respaldo RDB. En **Cassandra**, un keyspace y una tabla diseñada por consulta, consultas por partición y rango, upsert, `ALLOW FILTERING` y una tabla desnormalizada, más seguridad y snapshot. En **Neo4j**, nodos y relaciones, CRUD, `LOAD CSV`, restricciones, consultas de uno y dos saltos y una recomendación, más el cambio de la clave inicial y un dump restaurado en un entorno aislado. Teoría: [9.2](#92-redis-clave-valor-en-memoria) a [9.5](#95-comparación-transversal).

| Motor | Qué se resolvió | Lo que mostró la evidencia |
| :--- | :--- | :--- |
| Redis | `STRING` con `EX`, `HASH`, `SET` y `SORTED SET`; ACL para el usuario de la aplicación | `TTL` en `-2` tras vencer; `HSET` devuelve 0 al actualizar; la ACL con `+@write` dejó correr `FLUSHALL` |
| Cassandra | `PRIMARY KEY ((usuario_id), fecha_evento, evento_id)` con orden descendente; tabla `eventos_por_tipo` | `LIMIT 3` cambia según el orden de clustering; un `UPDATE` sobre una clave inexistente creó la fila; la consulta por tipo exige `ALLOW FILTERING` |
| Neo4j | `Cliente`, `Producto`, `COMPRO` y `SIGUE` cargados con `LOAD CSV` y `MERGE`; restricción de unicidad; recomendación por dos saltos | `DELETE` falla con relaciones; la recomendación duplica sin `DISTINCT`; `SHOW ROLES` no está soportado en Community; el dump exige la base detenida |

### Lo que hay que saber explicar

- **El retorno de cada comando de Redis** y por qué conviene verificar con una lectura ([9.2](#92-redis-clave-valor-en-memoria)).
- **Por qué `-@dangerous`** y por qué proteger al usuario `default`.
- **Por qué en Cassandra se diseña una tabla por consulta** y qué riesgo tiene una partición de baja cardinalidad ([9.3](#93-cassandra-wide-column-pensar-primero-en-la-consulta)).
- **Por qué la restauración de Neo4j va a una instancia aislada** y cómo se prueba que los datos son los mismos ([9.4](#94-neo4j-las-relaciones-son-elementos-de-primera-clase)).

**Errores y mejoras:**
- **Instalación:** la consigna pedía Neo4j Community nativo y capturas de terminal, no Neo4j Desktop.
- **Tabla vacía:** crear `eventos_por_tipo` sin cargarla no demuestra nada.
- **Zona horaria:** las fechas sin zona aparecieron desplazadas.
- **Contraseñas:** no pueden figurar en los comandos entregados.

## U9 · Actividad 2: Batalla de arquitecturas (OmniMarket)

**Qué pedía:** proponer y defender ante otro grupo la arquitectura de datos de un comercio electrónico con diez dominios (clientes, catálogo, inventario, ventas y pagos, sesiones y carritos, navegación, recomendaciones, marketing, logística y fidelización). Había que justificar cada motor, incluido el costo de sumarlo ("no gana quien usa más tecnologías"), resolver integración, duplicación, concurrencia, datos personales y disponibilidad, y presentar evidencia ejecutada. Teoría: [9.11](#911-persistencia-políglota-qué-es-y-por-qué) a [9.20](#920-defender-una-arquitectura).

| Decisión | Resolución |
| :--- | :--- |
| Método | Matriz de 8 criterios × 10 dominios con aptitudes y pesos de 0 a 3, y una regla de adopción fijada de antemano |
| Núcleo | **MySQL** para siete dominios: clientes, catálogo (con `JSON` e índices), inventario, ventas y pagos, marketing, logística y fidelización |
| Especializados | **Redis** para sesiones y carritos; **Cassandra** para navegación (solo diseño); **Neo4j** para recomendaciones (dato derivado) |
| Descartado | **MongoDB**: empata en el catálogo, pero sumaría un quinto motor sin cumplir la regla |
| Integración | Estrella con MySQL como fuente de verdad; outbox en la misma transacción del pedido; consumidor idempotente en Neo4j |
| Evidencia ejecutada | Redis y Neo4j en instancias aisladas: carrito → evento → compras en Neo4j → recomendación en Redis; reentrega sin duplicar; evento viejo descartado por versión; `HINCRBY` = 200 frente a `HGET`+`HSET` muy por debajo |
| Verificación de factibilidad | Catálogo de 150.000 productos en MySQL: atributo sin índice ≈ 88 ms, con índice < 1 ms |
| Defensa | Presentación de 8 minutos y objeciones previsibles preparadas con su respuesta |

### Lo que hay que saber explicar

- **Por qué el pedido no sale de MySQL:** ≈ 1,2 pedidos por segundo, y atomicidad entre pedido, stock y pago ([9.12](#912-analizar-los-requisitos)).
- **Por qué Cassandra quedó solo en diseño:** con un nodo no se puede afirmar tolerancia a fallas.
- **Cómo funciona la regla de adopción** en el empate del catálogo, y cuál es su criterio de revisión ([9.14](#914-un-método-para-decidir)).
- **Qué pasa si se cae cada motor:** solo MySQL es indispensable para vender ([9.19](#919-disponibilidad-qué-es-crítico-y-qué-se-reconstruye)).

**Error real del proceso:** la primera versión de la matriz, con siete criterios, dejaba la navegación empatada en 17 puntos entre documental, clave-valor y columnas anchas. Se agregó el criterio de lectura por rango ordenado (S) y se separó la escritura en disco de la latencia. Por eso la regla de adopción se fijó **antes** de mirar el resultado final.

### Otra resolución: PostgreSQL como núcleo

Otro grupo llegó a una arquitectura muy parecida con **PostgreSQL** en el lugar de MySQL. Las diferencias sirven para repasar:

| Decisión | Resolución con MySQL (la nuestra) | Resolución con PostgreSQL |
| :--- | :--- | :--- |
| Núcleo | MySQL para siete dominios | PostgreSQL para clientes, inventario firme, ventas, fidelización, marketing y catálogo (con `JSONB` y `GIN`) |
| Inventario | Reserva y stock en MySQL, con actualización condicional | Reserva temporal en **Redis** y stock firme en PostgreSQL |
| Cassandra | Solo diseño, para la navegación | Navegación y seguimiento logístico |
| MongoDB | Descartado por la regla de adopción | Descartado: el catálogo se resuelve con `JSONB` en el motor existente |
| Integración | Outbox en la misma transacción + consumidor idempotente | Outbox en la misma transacción + CDC (Debezium y Kafka) leyendo el WAL |
| Evidencia | Redis y Neo4j ejecutados; factibilidad del catálogo medida en MySQL | Redis, Cassandra y Neo4j ejecutados; **la parte relacional quedó solo en diseño** |

> Si la reserva vive en Redis y el stock firme en el relacional, hay **dos lugares** que pueden quedar desalineados: hay que explicar qué pasa si Redis se reinicia con reservas pendientes y cómo se reconcilia ([9.17](#917-duplicación-y-concurrencia)).

## U10 · Actividad 1: El motor en la nube (MongoDB Atlas)

**Qué pedía:** elegir un motor de los vistos y usarlo en un servicio cloud gratuito, sin contratar servicios ni registrar tarjetas. Había que crear el clúster y conectarse, hacer CRUD con al menos cinco registros, crear una identidad restringida con una operación permitida y otra rechazada (distinguiendo permisos del motor y de la plataforma), identificar la protección administrada y verificar una recuperación, revisar el monitoreo, completar la matriz VM frente a DBaaS y responder si DBaaS elimina o transforma al DBA. Teoría: [Unidad 10](#unidad-10--operar-como-servicio-dbaas-y-cloud), con el detalle de Atlas en [10.19](#1019-nuestra-resolución-mongodb-atlas).

| Aspecto | Resolución | Evidencia |
| :--- | :--- | :--- |
| Clúster | Atlas M0 en AWS (São Paulo), MongoDB 8.0 | Conexión con `mongosh` y cadena SRV desde una VM Ubuntu |
| CRUD | Cinco productos, lectura, actualización de precio y stock, y una baja | Quedan cuatro productos, con los valores modificados |
| Permisos | Administrador con `atlasAdmin` y un lector con `read` solo sobre la colección de productos | El lector lee; el `insert` del lector y el `createUser` del administrador son rechazados |
| Respaldo | Snapshots pagos en Free: no se activan. `mongodump` desde la VM y `mongorestore` con `--nsFrom`/`--nsTo` a `<base>_restore` en el mismo clúster | Mismos recuentos y mismos `_id` |
| Monitoreo | Las cuatro métricas del plan gratuito | Sin descarga de logs ni panel en tiempo real |

### Lo que hay que saber explicar

- **Las dos capas de permisos** y por qué `createUser` falla en Atlas ([10.19](#las-dos-capas-de-permisos)).
- **Por qué la replicación no es un respaldo** y qué prueba una restauración con los mismos `_id` ([10.19](#respaldo-y-recuperación-en-atlas)).
- **Qué límites del plan condicionan la actividad** ([10.19](#monitoreo-y-límites-del-plan-gratuito-m0)).

**Errores y mejoras:** la primera entrega asignaba al lector un privilegio más amplio que el necesario y se corrigió a `read` sobre la colección. La primera versión del informe omitía el respaldo, porque se creía que tenía que hacerse con la herramienta del proveedor; con `mongodump` y una restauración en otra base se cumple sin pagar. Una captura de la pestaña *Backup* no prueba una recuperación.

---

# Laboratorio integrador

**Objetivo:** integrar los dos bloques en una sola práctica, sobre una **VM Ubuntu Server 24.04 con MySQL 9.7 y MongoDB 8.0** (más un clúster de Atlas como opción para el respaldo). La entrega es un único PDF con enunciados, código, evidencias y notas.

**Bases de datos:**

| Base | Uso |
| :--- | :--- |
| `employees` | ~300.000 empleados y ~2,8 millones de sueldos: rendimiento, bloqueos y recuperación |
| `world_x` | Países y ciudades, incluida una tabla con documentos JSON (`countryinfo`) |
| `zakila-json` | Colecciones `customers`, `films` y `stores` en JSON, para cargar en MySQL y en MongoDB |

## Bloque 1 · Administración y rendimiento relacional (MySQL 9.7)

| Ejercicio | Qué pedía | Cómo se resolvió | Lo que hay que saber explicar |
| :--- | :--- | :--- | :--- |
| **1 · Usuarios** | Un administrador del grupo (`'usr_gXX'@'%'`) que no sea superusuario y un usuario de respaldo local con lo mínimo | El administrador recibe todo **solo sobre las bases del laboratorio**, más `FILE`, `PROCESS`, `RELOAD` y `REPLICATION CLIENT`. El de respaldo, `SELECT`, `SHOW VIEW`, `TRIGGER` y `EVENT` sobre `employees`, más `RELOAD`, `REPLICATION CLIENT`, `PROCESS` y `SHOW_ROUTINE` | Cada privilegio de `mysqldump` tiene un motivo: `RELOAD` para `--flush-logs`, `REPLICATION CLIENT` para `--source-data`. Se prueban los permitidos **y los denegados** (crear un usuario, tocar otra base) |
| **2 · Exportación e importación** | Exportar tres tablas a texto delimitado, crear un esquema traducido al castellano con integridad referencial y cargarlo masivamente | `SELECT ... INTO OUTFILE` en el directorio de `secure_file_priv`; tablas `empleados`, `salarios` y `cargos` con FK; `LOAD DATA` | El servidor solo lee y escribe en `secure_file_priv` (`ERROR 1290`). `LOAD DATA` no acepta la ruta en una variable ni se puede preparar (`ERROR 1295`): el script arma la sentencia. Se cargan primero los padres |
| **3 · Optimización** | Cuatro consultas, índices B-Tree en `last_name` y `salary`, `EXPLAIN ANALYZE` antes y después, y `LIKE 'Engineer%'` frente a `= 'Engineer'` | El mismo archivo antes y después, descartando la primera corrida en frío; `ANALYZE TABLE` tras crear los índices | El apellido pasó de 122 ms a 0,48 ms (197 entradas en lugar de 300.024 filas). El listado completo no mejora: no tiene filtro. Crear un índice sobre 2,84 millones de filas tardó 4,6 s. El costo estimado puede subir aunque el tiempo baje |
| **4 · Programabilidad** | Procedimiento que verifique si un empleado es gerente vigente y un trigger que actualice su cargo al darlo de alta como gerente | "Vigente" es `to_date = '9999-01-01'`; el trigger cierra el cargo anterior y abre el de *Manager* | Con el binlog activo, crear un trigger dio `ERROR 1419`: se habilitó `log_bin_trust_function_creators`, porque un trigger podría dar otro resultado al reproducirse en una réplica o en un PITR |
| **5 · Bloqueos** | Dos sesiones sobre los mismos sueldos, diagnóstico con `data_locks` e `innodb_trx` | La sesión 1 deja la transacción abierta; la 2 queda en `LOCK WAIT` hasta el *timeout* | Leer `data_locks` exige `SELECT` sobre `performance_schema`. Se identifica quién bloquea a quién (`data_lock_waits`) antes de decidir. Es lo mismo que la Unidad 5 |
| **6 · PITR** | Binlogs, evento de rotación cada 10 minutos, respaldo base, cinco cambios, borrado accidental de una tabla y recuperación | `mysqldump --single-transaction --flush-logs --source-data=2 --set-gtid-purged=OFF`; restauración del respaldo y `mysqlbinlog --skip-gtids` hasta justo antes del `DROP` | Ver la trampa de GTID más abajo. La recuperación se valida contra el estado anterior al incidente: las cinco modificaciones están y la tabla volvió |

### Trampas de MySQL 9.7 que aparecieron

| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| El respaldo no se puede restaurar en el mismo servidor (`ERROR 3546`) | `gtid_mode` está **activado por defecto** y el volcado incluye `GTID_PURGED` | `mysqldump --set-gtid-purged=OFF` |
| El binlog se reaplica "bien" pero las operaciones válidas no vuelven | Con GTID, el servidor **descarta en silencio** las transacciones que ya ejecutó | `mysqlbinlog --skip-gtids` (sirve con GTID activado y desactivado) |
| `SHOW MASTER STATUS` da error | Se eliminó | `SHOW BINARY LOG STATUS` |
| `source`, `DELIMITER` o `\G` fallan dentro de un script | El cliente arranca con `--commands` desactivado | `mysql --commands` |
| `SHOW BINLOG EVENTS` denegado | Exige `REPLICATION SLAVE` | Inspeccionar como administrador, y **no restaurar** si no se encontró el punto de corte |
| `mysqldump` falla por políticas de enmascaramiento | No hay permiso para leerlas | `--skip-masking-policies` |
| `EXPLAIN` sale como árbol | `explain_format = TREE` por defecto | `EXPLAIN FORMAT=TRADITIONAL` si se quiere la tabla |

## Bloque 2 · Datos semiestructurados en MySQL (JSON)

| Ejercicio | Qué pedía | Cómo se resolvió | Lo que hay que saber explicar |
| :--- | :--- | :--- | :--- |
| **7 · Importar JSON** | Cargar `customers`, `films` y `stores` con `util.importJson` en tablas con columnas `JSON` | Una tabla por colección, con el documento en `doc` y la clave primaria como **columna generada** desde `doc->>'$._id'` | `util.importJson` es de MySQL Shell y necesita una sesión **X Protocol** (puerto 33060). La columna generada impide documentos repetidos y permite `JOIN` por `id` |
| **8.1 · `JSON_SET`** | Marcar como VIP a los clientes con 40 o más alquileres | `JSON_SET(doc, '$.ClienteVIP', 'SÍ') WHERE JSON_LENGTH(doc, '$.Rentals') >= 40` | `JSON_SET` agrega o reemplaza: la actualización se puede repetir sin efectos raros |
| **8.2 · JSON Schema** | Un `CHECK` con `JSON_SCHEMA_VALID()`, dos inserciones válidas y dos rechazadas | Esquema con campos obligatorios y `ClienteVIP` limitado a "SÍ" o "NO" | Las inválidas dan `ERROR 3819`; `JSON_SCHEMA_VALIDATION_REPORT()` muestra `required` y `enum`. El esquema va literal porque el `CHECK` no admite variables |
| **8.3 · Cruce multimodelo** | Top 10 de películas más alquiladas en América del Sur, cruzando el JSON de clientes con `countryinfo` | `JSON_TABLE` para abrir los alquileres, `JOIN` con el país y con las películas | Es el mismo resultado que el pipeline del Ejercicio 11 en MongoDB |
| **8.4 · Exportar a JSON** | La tabla `city` con el formato `{"Ciudad": "Resistencia", "CodP": "ARG"}` | Desde el cliente (`-N -B -r`), en JSON Lines | `JSON_OBJECT()` reordena las claves, por eso se armó con `CONCAT` y `JSON_QUOTE` (que además escapa comillas) |

## Bloque 3 · Base documental (MongoDB 8.0)

| Ejercicio | Qué pedía | Cómo se resolvió | Lo que hay que saber explicar |
| :--- | :--- | :--- | :--- |
| **9 · Accesos y carga** | Un administrador en `admin`, autenticarse con `mongosh` e importar las tres colecciones en `LabMongoDB` | Administrador creado con `passwordPrompt()`, autenticación activada; `mongoimport --drop` con nombres en castellano (`clientes`, `peliculas`, `tiendas`) | Los archivos son JSON Lines: no llevan `--jsonArray`. La clave se pasa por un archivo de configuración con permisos 600 o se pide por teclado |
| **10.1 · Modelo** | Justificar qué se embebe y qué se referencia | Embebidos: alquileres y pagos en el cliente (26,8 en promedio, documento máximo de 11,5 KB), actores en la película, inventario en la tienda (solo 2 tiendas). Referenciados: la película del alquiler, el país del cliente y de la ciudad | Las decisiones se **midieron** sobre los datos reales. El inventario embebido es grande (2.311 ítems) pero no crece sin control; si crecieran las tiendas, pasaría a su propia colección |
| **10.2 · Colecciones auxiliares** | Importar `ciudades` y `paises` | `ciudades` desde la exportación del 8.4; `paises` desde `countryinfo` | Un país del origen no coincide por una tilde perdida en los datos: se reporta, no se esconde |
| **11 · Pipeline** | Top 10 de América del Sur con `$lookup`, `$unwind`, `$match`, `$group`, `$sort` y `$limit` | `$lookup` del país, `$match` de América del Sur (**antes** de abrir los alquileres: 70 clientes en lugar de 599), `$unwind`, `$group` por película, `$lookup` de las películas agrupadas, orden con desempate por título | **Resultado idéntico al 8.3 de MySQL**, incluido el empate en el corte: los dos modelos responden igual a la misma pregunta |
| **12.1 · Validación** | `$jsonSchema` sobre `tiendas`, dos inserciones válidas y dos rechazadas | Se verificó primero que las tiendas existentes cumplieran; `collMod` con `strict` y `error` | Si no se verifica, `mongorestore` crearía la colección con la regla y rechazaría los propios datos ([8.15](#815-validación-de-esquema)) |
| **12.2 · Respaldo** | `mongodump` y `mongorestore` en Atlas o en una base local `LabMongoDB_Restore` | Restauración local con `--nsFrom`/`--nsTo`; se compararon recuentos, índices, validador y el pipeline del Ejercicio 11 sobre la copia | La validación funcional (la misma consulta de negocio) es la evidencia más fuerte |

## Bloque 4 · Competencias y transparencia

- **Matriz de distribución de roles y coevaluación:** quién hizo qué en cada ejercicio. Se trabajó en duplas por bloque, cada una a cargo de buscar en el manual, ejecutar, verificar y documentar sus ejercicios.
- **Notas de diagnóstico para Operaciones:** una para el incidente de bloqueo (Ejercicio 5) y otra para la restauración PITR (Ejercicio 6), escritas para alguien que no hizo el laboratorio: qué pasó, cómo se detectó, qué se hizo y qué conviene vigilar.
- **Declaración de uso de IA y herramientas:** qué se usó, para qué, y qué se verificó a mano.

### Lo que el laboratorio enseña en conjunto

- **El mismo problema, dos modelos:** el Top 10 de América del Sur salió igual con `JSON_TABLE` en MySQL y con un pipeline en MongoDB. Lo que cambia es dónde vive el `JOIN`.
- **La versión del motor importa:** MySQL 9.7 rompió procedimientos del Parcial 1 (GTID activado por defecto, `SHOW MASTER STATUS` eliminado, el cliente sin `--commands`). Leer el manual de **esa** versión es parte del trabajo.
- **Mínimo privilegio también en el laboratorio:** un administrador del grupo que no es superusuario y un usuario de respaldo que solo lee, con las pruebas de lo que **no** pueden hacer.
- **Ninguna clave en el informe:** se piden por teclado, se leen de un archivo con permisos 600 o se muestran como `********`.

---

## Preguntas tipo simulacro

Las preguntas de opción múltiple de este bloque están en el [preguntero del Parcial 2](preguntas_simulacro_parcial_2.md): 120 preguntas sobre las clases 7 a 10, en el mismo orden que este apunte, con la explicación de cada opción.

| Señal en una opción | Suele indicar |
| :--- | :--- |
| Absolutos: "siempre", "nunca", "el más rápido", "se eligen dos de tres" | Opción incorrecta: casi todo depende del patrón de acceso y de la configuración |
| Argumentos de moda: "es el más usado", "NoSQL es más rápido", "más motores, más preparada" | Opción incorrecta: no son requisitos del negocio |
| "Depende del patrón de acceso" más una verificación (`explain`, recuentos, restaurar y comparar) | Opción correcta típica |
| El mecanismo del propio motor que garantiza la regla (operación atómica, restricción, `MERGE` idempotente) | Opción correcta típica |

---

*Apunte elaborado a partir de las actividades de las Unidades 7 a 10 (2026), del laboratorio integrador y de la documentación oficial de cada motor. Verificá siempre el comportamiento en tu motor y versión: el criterio de la materia sigue siendo **evidencia antes que afirmación**.*
