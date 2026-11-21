# Preguntas tipo simulacro · Parcial 2

**Sistemas de Gestión de Bases de Datos 2026 · Bloque temático 2**
80 preguntas de opción múltiple sobre las Unidades 7 a 10, con una sola respuesta correcta en cada una.

---

## Cómo usar este cuestionario

- El formato sigue el del simulacro de la cátedra: una situación concreta, cuatro opciones y una sola correcta. Muchas situaciones salen de las actividades de laboratorio y del laboratorio integrador.
- Cada pregunta indica unidad, **nivel** y tema:
  - **Básica:** un concepto central bien aplicado.
  - **Intermedia:** hay que relacionar dos ideas o descartar distractores plausibles.
  - **Desafío:** las opciones se parecen mucho o hace falta entender el mecanismo, no recordar una definición.
- Respondé antes de abrir **"Ver respuesta"**. Cada explicación dice por qué la opción correcta lo es y por qué fallan las demás.
- La base son las actividades resueltas de las Unidades 7 a 10 (MySQL, MongoDB, Redis, Cassandra, Neo4j y MongoDB Atlas) y su teoría: [Unidad 7](Unidad%207/Actividad%202/explicacion_teorica.md), [Unidad 8 · Actividad 1](Unidad%208/Actividad%201/explicacion_teorica.md), [Unidad 8 · Actividad 2](Unidad%208/Actividad%202/explicacion_teorica.md), [Unidad 9 · Actividad 1](Unidad%209/Actividad%201/explicacion_teorica.md), [Unidad 9 · Actividad 2](Unidad%209/Actividad%202/explicacion_teorica.md) y [Unidad 10](Unidad%2010/Actividad%201/explicacion_teorica.md). Algunas preguntas de nivel Desafío van un poco más allá de lo que se ejecutó (por ejemplo, la 44 sobre `MULTI`/`EXEC`, la 46 sobre la política de memoria de Redis o la 52 sobre `QUORUM`). Están para entender el mecanismo.
- Al final hay una **clave de respuestas** para corregir rápido.

| Unidad | Preguntas | Tema |
| :--- | :--- | :--- |
| U7 | 1 a 17 | El relacional multimodelo: JSON, índices multivaluados y Full-Text Search |
| U8 | 18 a 39 | MongoDB: modelado, consultas, índices, seguridad y respaldo |
| U9 | 40 a 71 | Redis, Cassandra, Neo4j y persistencia políglota |
| U10 | 72 a 80 | Bases de datos como servicio (MongoDB Atlas) |

### Cómo reconocer la opción correcta

| Señal en una opción | Suele indicar |
| :--- | :--- |
| Absolutos: "siempre", "nunca", "el más rápido", "se eligen dos de tres de una vez" | Opción incorrecta: casi todo depende del patrón de acceso y de la configuración |
| Argumentos de moda: "es el más usado", "NoSQL es más rápido", "más motores, más preparada" | Opción incorrecta: no son requisitos del negocio |
| "Depende del patrón de acceso" más una verificación con evidencia (`explain`, recuentos, restaurar y comparar) | Opción correcta típica |
| El mecanismo del propio motor que garantiza la regla (operación atómica, restricción, `MERGE` idempotente) | Opción correcta típica |
| Dos opciones casi iguales | Buscá la palabra que cambia: `$elemMatch` o notación con punto, `CREATE` o `MERGE`, `QUORUM` o `ONE`, `-1` o `-2`, `->` o `->>` |

---

## Unidad 7 · El relacional multimodelo: JSON y búsqueda de texto

**Pregunta 1** · Básica · *Atributos que varían por categoría*

Un catálogo multirubro vende notebooks (RAM, GPU), heladeras (litros, *no frost*) y ropa (talle, material). Cada categoría tiene atributos distintos y aparecen categorías nuevas seguido. ¿Qué diseño recomienda la unidad en MySQL?

- a) Una tabla con una columna por cada atributo posible de todas las categorías, aunque en cada fila la mayoría quede en `NULL`.
- b) Una tabla `(producto_id, atributo, valor)` con todos los valores en `VARCHAR`, para no tener que modificar el esquema nunca.
- c) Columnas tipadas para lo estable (precio, stock, categoría) y una columna `JSON` para lo que varía por categoría.
- d) Una tabla por categoría, que se crea con un `CREATE TABLE` nuevo cada vez que aparece un rubro.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Es el **esquema híbrido**: lo que se filtra, ordena o agrega seguido va en columnas con tipos, restricciones e índices B-Tree, y lo variable va en `JSON` con `CHECK` mínimos (por ejemplo `JSON_TYPE(tags) = 'ARRAY'`). Las otras son los tres antipatrones de la unidad: la tabla ancha llena de `NULL` (a), el modelo EAV sin tipos ni restricciones, que necesita un `JOIN` por cada atributo que se filtra (b), y las migraciones constantes (d).

</details>

**Pregunta 2** · Intermedia · *Multimodelo o persistencia políglota*

¿Qué situación describe una base de datos **multimodelo**?

- a) Usar MySQL para los pedidos, Redis para las sesiones y Neo4j para las recomendaciones, sincronizados entre sí por eventos.
- b) Un mismo motor que maneja varios modelos de datos (relacional, JSON, texto, espacial) con una sola seguridad, respaldo y optimizador.
- c) Un motor NoSQL que acepta consultas SQL mediante un conector externo, de modo que las aplicaciones relacionales no cambian.
- d) Una base relacional con varias réplicas, donde cada réplica guarda los mismos datos con un modelo distinto según quién la consulte.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** MySQL 9 es relacional en su núcleo, pero suma `JSON` nativo, índices multivaluados, Document Store, datos espaciales y Full-Text Search dentro del mismo motor. La opción a es **persistencia políglota**: varios motores, cada uno donde mejor encaja (Unidad 9). Un conector SQL no convierte a un motor en multimodelo (c), y las réplicas guardan los mismos datos con el mismo modelo (d).

</details>

**Pregunta 3** · Básica · *`->` y `->>`*

En MySQL, `SELECT atributos->'$.marca', atributos->>'$.marca' FROM producto WHERE id = 1;` sobre un producto de marca Acme devuelve:

- a) `"Acme"` y `Acme`: `->` devuelve un valor JSON (con sus comillas) y `->>` devuelve ese valor como texto.
- b) `Acme` y `"Acme"`: `->>` agrega las comillas para que el resultado siga siendo un valor JSON válido.
- c) Lo mismo en las dos columnas: `->>` es una forma abreviada de `->` que se mantiene por compatibilidad.
- d) Un error: `->>` solo acepta rutas que apuntan a arreglos, y `$.marca` apunta a una cadena de texto.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** `->` equivale a `JSON_EXTRACT()` y devuelve JSON (por eso las comillas). `->>` equivale a `JSON_UNQUOTE(JSON_EXTRACT())` y devuelve texto, que es lo que conviene para comparar o mostrar. La b invierte los operadores; no son sinónimos (c) y ninguno se limita a arreglos (d).

</details>

**Pregunta 4** · Desafío · *Claves ausentes en un documento JSON*

Hay tres notebooks: una con `"gpu": "integrada"`, otra con `"gpu": "RTX 4060"` y un ultrabook cuyo documento **no tiene** la clave `gpu`. ¿Qué devuelve `WHERE atributos->>'$.gpu' <> 'integrada'`?

- a) La de RTX y el ultrabook: una clave ausente cuenta como distinta de `'integrada'`, así que la condición se cumple.
- b) Las tres, porque cuando la clave falta, `<>` no evalúa la condición y deja pasar la fila sin filtrarla.
- c) Un error de ruta inválida, porque `->>` exige que todos los documentos de la tabla tengan la clave `gpu`.
- d) Solo la de RTX: en el ultrabook la ruta da `NULL`, y `NULL <> 'integrada'` no es verdadero.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Una clave ausente devuelve `NULL`, y cualquier comparación con `NULL` da `NULL` (desconocido), que el `WHERE` descarta. Pasó en la actividad de la Unidad 7. Para incluir el ultrabook hay que pedirlo explícitamente: `... OR atributos->>'$.gpu' IS NULL`, o usar `JSON_CONTAINS_PATH`. No da error (c), y la fila del ultrabook no cumple la condición, así que no aparece (a, b).

</details>

**Pregunta 5** · Intermedia · *Índice multivaluado*

Se crea `CREATE INDEX idx_tags_mv ON producto ((CAST(tags AS CHAR(30) ARRAY)));` sobre un arreglo JSON de etiquetas. ¿Qué condición puede aprovecharlo?

- a) `WHERE tags LIKE '%gaming%'`
- b) `WHERE JSON_LENGTH(tags) > 2`
- c) `WHERE 'gaming' MEMBER OF (tags)`
- d) `WHERE tags->>'$[0]' = 'gaming'`

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El índice multivaluado guarda **una entrada por cada elemento** del arreglo, y el optimizador lo usa con `MEMBER OF()`, `JSON_CONTAINS()` y `JSON_OVERLAPS()`. En la actividad, `'gaming' MEMBER OF (tags)` pasó de `Table scan` a `Index lookup ... using idx_tags_mv`. Las otras condiciones no coinciden con la expresión indexada: buscan texto dentro del JSON (a), calculan una función sobre el arreglo completo (b) o miran solo la primera posición (d).

</details>

**Pregunta 6** · Básica · *B-Tree y búsqueda por subcadena*

¿Por qué un índice B-Tree sobre `descripcion` no ayuda en `WHERE descripcion LIKE '%inalambrico%'`?

- a) Porque sin un prefijo fijo no hay por dónde entrar al árbol ordenado, y se termina recorriendo toda la tabla.
- b) Porque los índices B-Tree solo admiten columnas numéricas o de fecha; para texto, MySQL usa siempre un recorrido completo.
- c) Porque cualquier `LIKE` desactiva los índices de la columna, incluso con un prefijo fijo como `LIKE 'inal%'`.
- d) Porque MySQL deja de usar los índices en columnas de texto de más de 255 caracteres, como suele ser una descripción.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Un B-Tree ordena valores completos: sirve para `=`, rangos y prefijos (`LIKE 'inal%'` se resuelve como rango, por eso c es falsa). Con el comodín al inicio no hay por dónde entrar. El B-Tree indexa texto sin problema (b), y el largo de la columna no es lo que impide usarlo (d). Para buscar palabras dentro del texto existe el **índice invertido** (`FULLTEXT`), que guarda cada término con la lista de documentos donde aparece.

</details>

**Pregunta 7** · Intermedia · *`MATCH` y su índice*

La tabla tiene `FULLTEXT KEY ft_desc (descripcion)`. La consulta `WHERE MATCH(nombre, descripcion) AGAINST('gaming')` falla con `ERROR 1191`. ¿Por qué?

- a) Porque InnoDB no admite índices `FULLTEXT` sobre varias columnas: hay que convertir la tabla a MyISAM.
- b) Porque el modo de lenguaje natural necesita al menos tres palabras en `AGAINST` para calcular la relevancia.
- c) Porque la tabla tiene menos de 50 filas, y el índice no se activa hasta superar ese umbral.
- d) Porque `MATCH()` exige un índice `FULLTEXT` con exactamente las mismas columnas que se le pasan.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Para buscar en `nombre` y `descripcion` juntas hace falta `FULLTEXT (nombre, descripcion)`: el índice sobre una sola columna no sirve para esa combinación. InnoDB admite `FULLTEXT`, también sobre varias columnas (a). Ni la cantidad de palabras (b) ni la de filas (c) producen ese error.

</details>

**Pregunta 8** · Intermedia · *Términos de dos letras*

Las descripciones dicen "Smart TV 4K", pero `MATCH(descripcion) AGAINST('TV')` no devuelve nada. ¿Cuál es la causa más probable y su solución?

- a) La colación de la columna distingue mayúsculas y minúsculas, así que hay que buscar `'tv'` en minúsculas.
- b) Los términos más cortos que `innodb_ft_min_token_size` (3) no se indexan: hay que bajarlo a 2, reiniciar y reconstruir el índice.
- c) Hay que usar modo booleano, porque el modo de lenguaje natural descarta las siglas escritas en mayúsculas, como `TV`.
- d) El índice `FULLTEXT` se actualiza una vez por día: hay que esperar al proceso nocturno o forzar la actualización con `ANALYZE TABLE`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** `innodb_ft_min_token_size` es de solo lectura: se cambia en el `.cnf`, se reinicia, y **no afecta a los índices existentes** hasta reconstruirlos. Al bajarlo a 2 conviene una lista de *stopwords* en español, para no indexar `el`, `un` o `al`. Con `utf8mb4_0900_ai_ci` la búsqueda no distingue mayúsculas ni acentos (a), el modo no cambia los términos indexados (c) y el índice se actualiza en cada `COMMIT` (d).

</details>

**Pregunta 9** · Desafío · *Reconstruir el índice FULLTEXT*

Después de bajar `innodb_ft_min_token_size` a 2 y reiniciar, se ejecutó `ALTER TABLE producto DROP INDEX ft_desc, ADD FULLTEXT ft_desc (descripcion);`, y `TV` siguió sin aparecer. ¿Qué pasó?

- a) Ningún índice `FULLTEXT` de InnoDB indexa palabras de dos letras: el mínimo de 3 es fijo, aunque la variable acepte otro valor.
- b) Faltó ejecutar `ANALYZE TABLE` después del `ALTER`, que es la sentencia que vuelve a dividir el texto en términos.
- c) Con la misma definición, la forma combinada solo cambia metadatos: hay que hacer `DROP INDEX` y `ADD FULLTEXT` por separado.
- d) El reinicio devolvió la variable a su valor por defecto, porque solo queda fija si se cambia con `SET PERSIST`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Se comprobó en la actividad de la Unidad 7: con `DROP` y `ADD` en la misma sentencia, InnoDB no reconstruye el índice y conserva los términos viejos. En sentencias separadas, el índice se rearma con el nuevo tamaño mínimo. Las palabras de dos letras sí se indexan con la variable en 2 (a); `ANALYZE TABLE` actualiza estadísticas, no términos (b); y la variable es de solo lectura, se fija en el archivo de configuración (d).

</details>

**Pregunta 10** · Intermedia · *Modo booleano*

¿Qué devuelve `MATCH(nombre, descripcion) AGAINST('+gaming -notebook' IN BOOLEAN MODE)`?

- a) Los productos que contienen `gaming` y no contienen `notebook`.
- b) Los productos que contienen `gaming` o `notebook`, ordenados por relevancia.
- c) Los productos que contienen la frase exacta "gaming notebook".
- d) Los productos con palabras que empiezan con `gaming` o con `notebook`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** `+` hace obligatorio un término y `-` lo excluye: en la actividad solo quedó el Monitor Game 32. La frase exacta se pide entre comillas (`"alta frecuencia"`, c) y el prefijo con `*` (`inalambr*`, d). La b describe el modo de lenguaje natural, sin operadores.

</details>

**Pregunta 11** · Intermedia · *Relevancia*

Se busca `notebook gaming RTX` en modo de lenguaje natural. En la colección, `rtx` aparece en un solo producto, mientras que otros términos, como `pulgadas`, aparecen en siete. ¿Por qué el producto con `rtx` queda primero?

- a) Porque InnoDB devuelve primero los productos insertados primero, y el de `rtx` fue de los primeros en cargarse.
- b) Porque las palabras cortas pesan más en la relevancia, y `rtx` es el término más corto de la consulta.
- c) Porque los términos escritos en mayúsculas en la consulta (`RTX`) reciben más peso que los escritos en minúsculas.
- d) Porque la relevancia es una variante de TF-IDF: un término raro en la colección pesa más que uno frecuente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** TF es la frecuencia del término en el documento e IDF, su rareza en la colección. Un término que aparece en un solo producto discrimina mucho más que uno presente en siete. El orden de inserción (a), el largo de la palabra (b) y las mayúsculas (c) no intervienen.

</details>

**Pregunta 12** · Básica · *Lo que el FTS de InnoDB no hace*

Los usuarios buscan `notebok` (con error de tipeo) y `juego` esperando encontrar "juegos". ¿Qué es correcto?

- a) El modo de lenguaje natural de InnoDB corrige errores de tipeo y reconoce plurales, así que basta con no usar modo booleano.
- b) `WITH QUERY EXPANSION` resuelve los errores de tipeo: la segunda pasada encuentra la palabra correcta sin agregar ruido.
- c) InnoDB no tiene *stemming* ni búsqueda difusa: `juego*` cubre el prefijo, y lo demás pide un motor de búsqueda aparte.
- d) Hay que cambiar al parser `ngram`, que está pensado para el español y reconoce variantes de una misma palabra.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** *Stemming*, tolerancia a errores, sinónimos y facetas son lo que justifica Elasticsearch u OpenSearch, normalmente como **proyección de lectura** de MySQL. La expansión de consulta agrega ruido: en la actividad, `espresso` trajo heladeras (b). `ngram` está pensado para idiomas sin separador de palabras, como chino o japonés (d).

</details>

**Pregunta 13** · Desafío · *Costo de escritura con FULLTEXT*

Tras un `UPDATE` de 20.000 descripciones, el tiempo se multiplicó por 4,7 e `INNODB_FT_DELETED` muestra 20.000 doc_id. ¿Qué está pasando?

- a) Cada `UPDATE` se registra como borrado lógico más inserción con un doc_id nuevo; lo viejo se purga con `OPTIMIZE TABLE`.
- b) El índice quedó dañado por el volumen del `UPDATE`, y hay que recrear la tabla completa a partir del último respaldo.
- c) MySQL reescribe el índice `FULLTEXT` entero en cada `UPDATE`, sin importar cuántas filas cambien ni qué columnas toque.
- d) Los doc_id de `INNODB_FT_DELETED` son filas que el `UPDATE` perdió por error y que hay que recuperar desde el binlog.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Así funciona el FTS de InnoDB: el doc_id viejo se marca como borrado y el texto nuevo se vuelve a dividir en términos. Las entradas obsoletas se purgan con `OPTIMIZE TABLE` (activando `innodb_optimize_fulltext_only`), que procesa una cantidad limitada de términos por pasada (`innodb_ft_num_word_optimize`). No hay daño (b) ni filas perdidas (d), y el índice no se reescribe completo (c): el costo es proporcional a lo modificado.

</details>

**Pregunta 14** · Intermedia · *Medir con pocos datos*

Con 20 productos, `LIKE '%gaming%'` y `MATCH ... AGAINST('gaming')` tardan menos de 2 ms. ¿Qué conclusión y qué paso siguiente son correctos?

- a) El índice `FULLTEXT` no aporta nada a esta tabla: conviene eliminarlo para ahorrar el costo extra de las escrituras.
- b) El tiempo es ruido con ese volumen: hay que comparar el plan y las filas leídas, y escalar los datos.
- c) Hay que reiniciar el servidor antes de cada consulta para vaciar la caché, y repetir hasta que aparezca una diferencia.
- d) Conviene usar `EXPLAIN` sin `ANALYZE`, porque `EXPLAIN ANALYZE` ejecuta la consulta y eso altera los tiempos medidos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Con 20 filas todo entra en una o dos páginas que ya están en memoria. Lo que importa es el **cambio de plan** (`Table scan` frente a `Full-text index search`) y el trabajo del motor (`Handler_read_rnd_next`); por eso la actividad escaló a 200.000 filas, donde el costo estimado bajó de 22.541 a 1,10. Reiniciar no reproduce una carga real (c), y `EXPLAIN ANALYZE` es justamente lo que mide tiempos reales (d).

</details>

**Pregunta 15** · Desafío · *JSON en MySQL y JSONB en PostgreSQL*

Un catálogo debe filtrar por muchos atributos dentro de una columna JSON, y algunos no se pueden prever. ¿Qué afirmación es correcta?

- a) En MySQL, un único índice sobre la columna `JSON` acelera los filtros sobre cualquier clave, igual que un `GIN` en PostgreSQL.
- b) PostgreSQL no puede indexar `JSONB`, así que hay que pasar a columnas comunes los atributos por los que se filtra.
- c) Ninguno de los dos motores indexa JSON, de modo que cualquier filtro sobre un atributo del documento recorre toda la tabla.
- d) MySQL necesita un índice por cada atributo filtrado; en PostgreSQL, un único `GIN` sobre `JSONB` cubre cualquier clave.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Es la diferencia que se analizó para el catálogo en la Unidad 9 (Actividad 2): con atributos impredecibles, PostgreSQL tiene ventaja, porque un `GIN` sobre `JSONB` sirve para filtros de contención (`@>`) sobre cualquier clave. En MySQL hay que prever el índice de cada atributo filtrado (columna generada, índice funcional o multivaluado); con 150.000 productos, un atributo sin índice tardó ≈ 88 ms y con índice, menos de 1 ms. La a le atribuye a MySQL un índice general que no tiene, y la b y la c niegan capacidades que sí existen.

</details>

**Pregunta 16** · Intermedia · *Clasificar capacidades (radar multimodelo)*

El radar multimodelo clasificaba cada capacidad como *Core*, *Habilitable*, *Extensión/Plugin/Cliente* o *No disponible*. En MySQL 9.7, `SHOW PLUGINS` muestra `mysqlx` activo (puerto 33060). ¿Cómo se clasifica el Document Store, es decir, trabajar con colecciones mediante X DevAPI?

- a) *Core*: con el plugin activo alcanza, porque el cliente clásico `mysql` ya puede trabajar con colecciones JSON.
- b) *Extensión/Plugin/Cliente*: el servidor lo trae activo, pero hace falta un cliente adicional (MySQL Shell).
- c) *Habilitable*: viene incluido, pero hay que instalarlo con `INSTALL PLUGIN` y reiniciar el servidor.
- d) *No disponible*: el Document Store y X DevAPI solo se incluyen en la edición Enterprise, no en Community.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Para trabajar con colecciones hace falta MySQL Shell (`mysqlsh`) o un conector que hable X Protocol: el cliente clásico `mysql` usa el protocolo clásico (puerto 3306) y no sirve para X DevAPI (a). Desde MySQL 8.0, el plugin `mysqlx` viene compilado y activo (c), y es parte de la edición Community (d). Para comparar: el tipo `JSON` es *Core*, y Full-Text Search es *Core/Habilitable*, porque los índices funcionan de fábrica, pero ajustar `innodb_ft_min_token_size` o las *stopwords* requiere configuración. En el laboratorio integrador, `util.importJson` también exigió una sesión de MySQL Shell por X Protocol.

</details>

**Pregunta 17** · Intermedia · *Validar la forma de un documento en MySQL*

En el laboratorio integrador se agregó a la tabla `customers` la restricción `CHECK (JSON_SCHEMA_VALID('<esquema>', doc))`, con un JSON Schema escrito literal que exige la clave `"Last Name"`. ¿Qué pasa al insertar un documento sin esa clave?

- a) Se inserta igual, porque MySQL solo verifica que el JSON esté bien formado, no qué claves contiene.
- b) Se inserta con una advertencia, y la regla se aplica recién en la próxima reconstrucción de la tabla.
- c) Se rechaza con `ERROR 3819`, y `JSON_SCHEMA_VALIDATION_REPORT()` informa qué regla falló (`required`).
- d) Se rechaza solo si se importa con `util.importJson`; un `INSERT` común no se valida.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Un `CHECK` con `JSON_SCHEMA_VALID()` aplica un JSON Schema a cada fila (el esquema va literal porque un `CHECK` no admite variables). En el laboratorio, las dos inserciones inválidas dieron `ERROR 3819`, y el informe de validación mostró `required` y `enum`. Sin ese `CHECK`, MySQL solo valida que el JSON esté bien formado (a). La regla rige desde que se crea (b) y para cualquier forma de inserción (d).

</details>

---

## Unidad 8 · MongoDB: modelado, consultas, seguridad y respaldo

**Pregunta 18** · Básica · *Diseñar desde los patrones de acceso*

Un equipo lleva su modelo relacional de logística a MongoDB creando una colección por tabla y un `$lookup` por cada `JOIN`. ¿Qué evaluación es correcta?

- a) Es lo recomendado: conserva la normalización, y MongoDB optimiza cada `$lookup` igual que un `JOIN` relacional.
- b) Es correcto, siempre que se declaren claves foráneas entre las colecciones para mantener la integridad referencial.
- c) Es imposible: MongoDB no permite combinar dos colecciones en una misma consulta, ni siquiera en un pipeline.
- d) Es el error típico: el modelo documental parte de las consultas y agrupa en un documento lo que se lee junto.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** El modelo documental parte de los **patrones de acceso**: qué se consulta, con qué filtros y con qué frecuencia; con eso se decide qué embeber y qué referenciar. Traducir tabla por colección da lo peor de los dos modelos. MongoDB no tiene claves foráneas (b; para validar la forma existe `$jsonSchema`), y `$lookup` sí existe (c), pero es menos expresivo que un `JOIN` (a).

</details>

**Pregunta 19** · Intermedia · *Embeber o referenciar*

Un envío tiene de 1 a 4 paquetes, y genera eventos de seguimiento mientras el camión está en ruta (decenas o cientos por envío). ¿Qué modelo es el adecuado?

- a) Embeber los paquetes en el envío y guardar los eventos en otra colección, con `envio_id` como referencia.
- b) Embeber paquetes y eventos en el envío, para leer todo el seguimiento con una sola consulta.
- c) Guardar paquetes y eventos en colecciones separadas, como en el modelo relacional, para no repetir nada.
- d) Embeber los eventos en el envío, que se consultan seguido, y guardar los paquetes en otra colección.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Lo que se lee junto y está **acotado** se embebe: los paquetes nacen y mueren con el envío. Lo que **crece sin cota** se referencia: los eventos embebidos formarían un arreglo ilimitado (b, d). Separar todo (c) obliga a un `$lookup` para algo que siempre se lee con el envío.

</details>

**Pregunta 20** · Desafío · *Arreglo sin cota*

¿Por qué un arreglo embebido que crece sin límite es un problema en MongoDB con WiredTiger?

- a) Porque WiredTiger mueve el documento a otra zona del disco cada vez que crece y deja de entrar en su espacio reservado.
- b) Porque MongoDB rechaza los arreglos de más de 100 elementos, y el `$push` siguiente falla con un error de validación.
- c) Porque se acerca al límite de 16 MB por documento, y cada lectura trae el arreglo entero a la caché.
- d) Porque un campo que es un arreglo no se puede indexar, y las consultas por evento terminan recorriendo la colección.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Mover el documento por falta de espacio era el problema del motor viejo MMAPv1; WiredTiger genera una versión nueva en cada actualización (a). No hay un límite de 100 elementos (b), y los arreglos sí se indexan con índices multiclave (d). Los argumentos actuales son el tamaño máximo, la presión sobre la caché (*working set*) y el costo de mantener arreglos grandes.

</details>

**Pregunta 21** · Intermedia · *Referencia extendida*

En cada envío se copia `transportista: { id, nombre, cuit }` en lugar de guardar solo el `id`. ¿Qué se gana y qué cuesta?

- a) Se gana integridad referencial automática: MongoDB rechaza un envío cuyo transportista no exista en su colección.
- b) Se evita un `$lookup` al calcular demoras por transportista; si cambia un nombre, hay que corregir las copias con `updateMany`.
- c) No cuesta nada: cuando cambia el nombre de un transportista, MongoDB propaga solo el cambio a todas las copias.
- d) Se puede borrar la colección de transportistas, porque todos sus datos ya quedan copiados dentro de los envíos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Es el patrón de **referencia extendida**: se copian los campos más consultados de un dato casi inmutable. El costo es mantener las copias cuando ese dato cambia: no hay propagación automática (c) ni integridad referencial (a). La colección original sigue siendo la fuente de verdad del transportista (d).

</details>

**Pregunta 22** · Desafío · *`$elemMatch`*

Se buscan los envíos con **un paquete** frágil que pese más de 10 kg. `{ "paquetes.fragil": true, "paquetes.peso_kg": { $gt: 10 } }` devuelve 5 envíos y `{ paquetes: { $elemMatch: { fragil: true, peso_kg: { $gt: 10 } } } }` devuelve 2. ¿Cuál es la correcta?

- a) La primera: la notación con punto aplica las dos condiciones al mismo paquete, y `$elemMatch` admite paquetes distintos.
- b) Son equivalentes: devuelven cantidades distintas solo porque una de las dos consultas usa el índice y la otra no.
- c) Ninguna de las dos: para filtrar dentro de un arreglo hace falta un `$unwind` antes del filtro, en un pipeline.
- d) La segunda: `$elemMatch` exige que un mismo paquete cumpla las dos condiciones a la vez.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Con la notación con punto, cada condición puede cumplirla un paquete distinto (a). En el laboratorio, el envío 001 tenía un paquete frágil de 3,2 kg y **otro** de 12,5 kg: la primera consulta lo devuelve aunque ningún paquete sea frágil y pesado a la vez. El índice no cambia el resultado (b), y `find` filtra arreglos sin necesidad de `$unwind` (c).

</details>

**Pregunta 23** · Básica · *Operadores de actualización*

¿Qué operador agrega una etiqueta al arreglo `etiquetas` sin repetirla si ya está?

- a) `$push`
- b) `$set`
- c) `$addToSet`
- d) `$inc`

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** `$addToSet` agrega solo si el valor no existe. `$push` agrega siempre, aunque se repita (a); `$set` reemplaza el valor del campo (b), e `$inc` suma a un número (d).

</details>

**Pregunta 24** · Intermedia · *Atomicidad en MongoDB*

En un `mongod` *standalone*, registrar un evento implica insertarlo en `eventos_seguimiento` y actualizar `estado_actual` en `envios`. ¿Qué es correcto?

- a) Cada operación es atómica por separado, pero no las dos juntas: para eso hacen falta transacciones, que piden un *replica set*.
- b) Las dos operaciones son atómicas juntas, porque MongoDB envuelve automáticamente cada sesión de `mongosh` en una transacción.
- c) Ni siquiera la actualización de un solo documento es atómica cuando modifica varios campos o elementos de un arreglo.
- d) Si las dos escrituras se envían juntas con `insertMany`, quedan dentro de la misma transacción y se confirman a la vez.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La atomicidad por documento es lo que hace atractivo **embeber**: un `updateOne` que toca varios campos y arreglos es indivisible (c es falsa). Para atomicidad entre documentos hacen falta transacciones, que requieren un *replica set* o un clúster fragmentado: en un *standalone* no existen (b). `insertMany` inserta en una sola colección y no es transaccional (d).

</details>

**Pregunta 25** · Intermedia · *Orden de las etapas*

Un pipeline hace `$lookup` de los eventos de cada envío, luego `$unwind`, y recién al final `$match: { estado_actual: "DEMORADO" }`. ¿Qué mejora corresponde?

- a) Ninguna: el optimizador reordena siempre las etapas, así que el orden en que se escriben no cambia el trabajo del motor.
- b) Escribir el `$match` primero: filtra antes del `$lookup`, achica lo que llega a las etapas y puede usar un índice.
- c) Poner un `$sort` al principio del pipeline, porque ordenar los documentos acelera siempre las etapas siguientes.
- d) Reemplazar el `$match` por un segundo `$lookup` filtrado, que descarta los envíos no demorados al unir.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** `$match` al comienzo es la etapa que puede aprovechar un índice y achica lo que reciben las demás: hacer `$lookup` de todos los envíos para descartarlos después es trabajo desperdiciado. No conviene depender de que el optimizador reordene (a). Un `$sort` sin filtro previo ordena todo (c), y un `$lookup` no filtra la colección de origen (d).

</details>

**Pregunta 26** · Desafío · *Regla ESR*

Consulta: `ruta` igual a un valor y `fecha_despacho` en un rango, sobre 200.000 envíos. Con `{ ruta: 1, fecha_despacho: 1 }` se examinan 811 claves para 811 resultados; con `{ fecha_despacho: 1, ruta: 1 }`, 1.531 claves. ¿Por qué?

- a) Porque el segundo índice es en realidad mejor: poner primero el rango descarta más documentos, aunque examine más claves.
- b) Porque los dos índices son equivalentes, y la diferencia en las claves examinadas se debe a lo que había en la caché.
- c) Porque con la igualdad primero, el índice se acota a esa ruta y el rango recorre un tramo contiguo.
- d) Porque MongoDB reordena alfabéticamente los campos de un índice compuesto, y `fecha_despacho` queda antes que `ruta`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Es la regla **ESR**: *Equality*, *Sort*, *Range*. Con la igualdad primero, 811 claves para 811 resultados es el caso ideal; con el rango primero, se recorren las claves de todas las rutas en esas fechas y se descartan las de otras rutas. La a contradice la medición, la b la atribuye a la caché (la cantidad de claves examinadas no depende de ella) y la d es falsa: el orden de los campos lo decide quien crea el índice.

</details>

**Pregunta 27** · Intermedia · *Leer un `explain`*

`explain("executionStats")` muestra `COLLSCAN`, `totalDocsExamined: 200000` y `nReturned: 811`. ¿Qué diagnóstico es correcto?

- a) Es el plan ideal para esa consulta: se examinaron todos los documentos, así que no quedó ninguno sin evaluar.
- b) Los números son solo estimaciones del planificador, porque el modo `executionStats` no ejecuta la consulta.
- c) La colección está fragmentada y necesita compactarse (`compact`) para que el motor deje de recorrerla completa.
- d) El motor lee y descarta casi todos los documentos: falta un índice para ese patrón de consulta.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La relación ideal es `keys ≈ docs ≈ returned`. Leer 200.000 documentos para devolver 811 es trabajo descartado; en el laboratorio, con el índice adecuado, pasó a 811 → 811. `executionStats` **sí ejecuta** la consulta (b; por eso hay que tener cuidado con las escrituras), y compactar no cambia el plan (c).

</details>

**Pregunta 28** · Desafío · *Una medición engañosa*

Con 15 documentos, la primera ejecución con índice tardó más milisegundos que sin índice. ¿Qué conclusión es correcta?

- a) No prueba nada: la primera ejecución incluye la planificación, y con 15 documentos el tiempo es ruido.
- b) El índice empeora esa consulta en particular, así que conviene eliminarlo y repetir la medición sin él.
- c) Los índices recién empiezan a servir a partir del millón de documentos; por debajo, siempre agregan costo.
- d) La medición no vale: falta reiniciar el servidor entre las dos ejecuciones para vaciar la caché.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La caché de planes todavía no tenía el plan, y con tan pocos documentos cualquier diferencia es ruido: hay que repetir, comparar el trabajo examinado y probar con volumen. En el laboratorio, los documentos examinados bajaron de 15 a 3; a 200.000 documentos, de 200.000 a 811. No hay un umbral fijo de volumen (c), y reiniciar no hace la medición más representativa (d).

</details>

**Pregunta 29** · Intermedia · *Costo de los índices*

¿Qué afirmación sobre los índices secundarios en MongoDB es correcta?

- a) No tienen costo en las escrituras: MongoDB los actualiza en segundo plano, después de confirmar cada operación.
- b) Un índice compuesto puede incluir varios campos que sean arreglos, siempre que todos tengan la misma cantidad de elementos.
- c) Las escrituras que tocan campos indexados mantienen cada índice, que además ocupa caché; `$indexStats` muestra los no usados.
- d) `$indexStats` también cuenta las ejecuciones de `explain()`, así que sirve para medir cuánto se usa cada índice en las pruebas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Los índices se actualizan dentro de cada escritura, no después (a), y además ocupan espacio y compiten por la caché. En el laboratorio, dos índices secundarios agregaron un 31 % al tiempo de escritura: por eso se crea un índice por **patrón de acceso real**. Un índice compuesto admite un solo campo arreglo (b), y `explain` no incrementa los contadores de `$indexStats` (d).

</details>

**Pregunta 30** · Básica · *`$lookup`*

¿A qué operación de SQL equivale `$lookup` y qué lo acelera?

- a) A un `INNER JOIN`: descarta los documentos sin coincidencias, y lo acelera un índice sobre `localField`.
- b) A un `LEFT OUTER JOIN`; lo acelera un índice sobre `foreignField` en la colección que se une, si lo hay.
- c) A un `UNION ALL`: agrega a la salida los documentos de la otra colección, y no puede usar índices.
- d) A un `CROSS JOIN`: combina cada documento con todos los de la otra colección, recorriendo las dos completas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** `$lookup` agrega a cada documento un arreglo con los documentos coincidentes de la otra colección, que queda vacío si no hay ninguno: por eso equivale a una unión externa izquierda. Para cada documento busca en la colección unida por `foreignField`; sin índice ahí, cada búsqueda recorre la colección completa.

</details>

**Pregunta 31** · Desafío · *Validador `$jsonSchema`*

Antes de aplicar un validador `$jsonSchema` a `tiendas` con `collMod` (`validationLevel: "strict"`, `validationAction: "error"`), se verificó que los documentos existentes cumplieran la regla. ¿Por qué?

- a) Porque `collMod` borra sin avisar los documentos existentes que no cumplen la regla, y se perderían tiendas.
- b) Porque `collMod` revisa todos los documentos existentes y falla por completo si alguno no cumple la regla.
- c) No hacía falta: un validador solo controla las inserciones nuevas, y nunca las actualizaciones ni las restauraciones.
- d) Porque los inválidos seguirían en la colección, y una restauración que crea antes la regla rechazaría esos documentos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** `collMod` no revisa ni borra lo existente (a, b): aplica la regla a las escrituras siguientes, tanto inserciones como actualizaciones (c). Con `strict`, falla toda actualización que deje el documento inválido. Además, `mongorestore` crea primero la colección con el validador y después carga los documentos. Se verifica con `countDocuments({ $nor: [{ $jsonSchema: esquema }] })`, que debe dar 0.

</details>

**Pregunta 32** · Básica · *Tres capas de acceso*

Un usuario ejecuta `find()` sin problemas, pero `updateOne()` falla con `not authorized on logistica to execute command { update: ... }`. ¿En qué capa está el problema?

- a) Conexión: el firewall deja pasar las lecturas pero bloquea las escrituras hacia el puerto 27017.
- b) Autenticación: la contraseña es incorrecta, y el servidor solo lo detecta al intentar escribir.
- c) Autorización: el usuario se autenticó bien, pero su rol (por ejemplo, `read`) no incluye `update`.
- d) Cifrado: el servidor exige TLS para las escrituras, aunque permita lecturas sin cifrar.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Se diagnostica de abajo hacia arriba: si `find` funciona, la conexión y la autenticación están bien. `not authorized ... to execute command` (código 13) es un error de autorización; uno de autenticación sería `Authentication failed` (código 18). Se verifica con `connectionStatus({ showPrivileges: true })`.

</details>

**Pregunta 33** · Intermedia · *Activar la autenticación*

¿Cuál es el orden correcto para activar la autenticación en un `mongod`?

- a) Crear el administrador, activar `security.authorization`, reiniciar y verificar que sin credenciales se rechacen las operaciones.
- b) Activar `authorization`, reiniciar el servicio y después crear el administrador conectándose desde cualquier equipo de la red.
- c) Crear los usuarios alcanza: en cuanto existe el primero, el servidor empieza a exigir credenciales sin tocar la configuración.
- d) Activar TLS en `net.tls`: al cifrar el canal, el servidor empieza a exigir usuario y contraseña en cada conexión.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Sin `authorization: enabled`, cualquier cliente puede ejecutar cualquier comando aunque haya usuarios creados (c). Si se activa antes de crear usuarios, solo una conexión **desde localhost** puede crear el primero (b). TLS cifra el canal, pero no reemplaza la autenticación (d).

</details>

**Pregunta 34** · Intermedia · *Base de autenticación*

`lector_logistica` se creó en la base `logistica`. Al conectarse con `--authenticationDatabase admin` obtiene `Authentication failed`. ¿Por qué?

- a) Porque la contraseña de los usuarios de solo lectura vence a los 30 días y hay que renovarla desde `admin`.
- b) Porque el usuario pertenece a la base donde se creó: hay que autenticarse contra `logistica`.
- c) Porque los usuarios con rol `read` solo pueden autenticarse desde localhost, no desde otro equipo de la red.
- d) Porque los usuarios creados en una base distinta de `admin` solo pueden autenticarse con un certificado TLS.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Para el servidor, un `lector_logistica` en `admin` y otro en `logistica` serían usuarios distintos. `Authentication failed` no distingue entre usuario inexistente, clave incorrecta o base equivocada, para no darle pistas a un atacante. Las opciones a, c y d inventan restricciones que no existen.

</details>

**Pregunta 35** · Desafío · *`userAdminAnyDatabase`*

Proponen darle `userAdminAnyDatabase` al equipo de operaciones "porque no lee ni escribe datos". ¿Qué evaluación es correcta?

- a) Es correcta: sin `read` ni `readWrite` en ninguna base, ese usuario no puede acceder a ningún documento.
- b) Es correcta, siempre que además se le quite el permiso de escribir en la base `admin`, donde están los usuarios.
- c) Es incorrecta porque ese rol incluye la acción `shutdown`, que permite apagar el servidor en cualquier momento.
- d) Es incorrecta: puede concederse cualquier rol a sí mismo, así que en la práctica equivale a un superusuario.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** No lee datos por sí mismo (a), pero quien administra usuarios de cualquier base puede otorgarse `readWriteAnyDatabase` o `root`, y quitarle la escritura en `admin` no lo impide (b). Por eso se reserva para el DBA. Apagar el servidor es una acción de roles como `hostManager`, no de este (c).

</details>

**Pregunta 36** · Intermedia · *Usuarios de respaldo y de restauración*

¿Por qué conviene un usuario con rol `backup` para el respaldo diario y otro, distinto, con rol `restore`?

- a) Porque `restore` es un rol amplio, y la tarea automática que corre cada día solo necesita leer.
- b) Porque MongoDB no permite asignarle a un mismo usuario dos roles integrados que actúan sobre todas las bases.
- c) Porque `mongodump` falla si el usuario que respalda tiene también el rol `restore`, por conflicto de privilegios.
- d) Porque con usuarios separados, `mongodump` y `mongorestore` pueden ejecutarse en paralelo y el respaldo termina antes.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** En el laboratorio, `restore` permitió insertar documentos y crear usuarios. Una cuenta automática que corre todos los días no debería poder hacer eso: es mínimo privilegio, y el usuario de restauración se habilita solo durante una recuperación. Nada impide tener los dos roles (b), `mongodump` solo necesita leer (c) y la separación no tiene que ver con el rendimiento (d).

</details>

**Pregunta 37** · Intermedia · *`bindIp`*

Un compañero dice: "Ya tenemos autenticación, así que `bindIp: 0.0.0.0` no importa". ¿Qué evaluación es correcta?

- a) Es correcta: con la autenticación activa, nadie sin credenciales válidas puede hacer nada, escuche en la interfaz que escuche.
- b) Es correcta, siempre que además se cambie el puerto 27017 por otro que los atacantes no conozcan.
- c) Es incorrecta: expone el puerto a toda la red y deja la contraseña como única barrera.
- d) Es incorrecta porque, con `bindIp: 0.0.0.0`, MongoDB desactiva la autenticación para las conexiones remotas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Las defensas se suman: red, autenticación, autorización y cifrado, y ninguna reemplaza a otra (a). Exponer el puerto habilita ataques de fuerza bruta contra las credenciales, y sin TLS los datos viajan sin cifrar: se limita `bindIp`, se filtra con firewall y se activa TLS. Cambiar el puerto solo esconde el servicio (b), y `0.0.0.0` no desactiva la autenticación, pero amplía quién puede intentarla (d). Desde la versión 3.6, MongoDB escucha por defecto solo en localhost, justamente por las filtraciones masivas.

</details>

**Pregunta 38** · Intermedia · *TLS mutuo*

El servidor tiene `mode: requireTLS` y `CAFile`, sin `allowConnectionsWithoutCertificates`. Un cliente que usa solo `--tls --tlsCAFile ca.crt` ve que la conexión se cierra. ¿Por qué?

- a) Porque el certificado del servidor venció, y el cliente corta la conexión al validar las fechas de vigencia.
- b) Porque es TLS mutuo: el servidor exige también un certificado de cliente firmado por la CA.
- c) Porque `requireTLS` solo acepta conexiones desde localhost, y el cliente se conecta desde otro equipo.
- d) Porque TLS y SCRAM no pueden usarse a la vez: hay que desactivar la autenticación por usuario y contraseña.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Con `allowConnectionsWithoutCertificates: true`, el cliente solo necesita confiar en la CA del servidor. Sin esa opción, el servidor también verifica **quién** se conecta, mediante su certificado (el cliente lo presenta con `--tlsCertificateKeyFile`). Un certificado vencido daría `certificate has expired` (a). `requireTLS` exige cifrado en todas las conexiones, sin importar su origen (c), y TLS convive con SCRAM (d).

</details>

**Pregunta 39** · Desafío · *`mongorestore` sobre datos existentes*

Se restaura un volcado sobre la misma colección, que ya tiene esos documentos: aparecen errores `E11000 duplicate key` y los documentos no se actualizan. ¿Qué es correcto?

- a) El volcado está dañado: los `_id` repetidos indican que `mongodump` copió dos veces los mismos documentos.
- b) Falta `--oplogReplay`, la opción que hace que `mongorestore` sobrescriba los documentos que ya existen.
- c) Hay que restaurar con `--noIndexRestore`, porque el error se debe a que los índices del volcado no coinciden con los existentes.
- d) Por defecto `mongorestore` no sobrescribe; para probar, se restaura en otra base con `--nsFrom`/`--nsTo`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Ese comportamiento protege contra pisar datos por error; `--drop` reemplaza la colección, pero es destructivo. La forma segura de probar un respaldo es restaurarlo en una base alternativa y comparar recuentos, contenido e índices. El volcado no está dañado (a): el error es esperable. `--oplogReplay` sirve para la recuperación a un punto en un *replica set* (b), y el problema no son las definiciones de índices, sino los `_id` que ya existen (c).

</details>

---

## Unidad 9 · Redis, Cassandra, Neo4j y persistencia políglota

**Pregunta 40** · Básica · *TTL en Redis*

Se ejecuta `SET sesion:U07 "..." EX 30` y, 35 segundos después, `TTL sesion:U07`. ¿Qué devuelve?

- a) `0`
- b) `-1`
- c) `-2`
- d) `30`

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** `-2` indica que la clave **no existe** (venció). `-1` indicaría que existe pero no tiene vencimiento (b), y un número positivo, los segundos que le faltan. Es el mecanismo natural para sesiones y tokens.

</details>

**Pregunta 41** · Intermedia · *Qué devuelve `HSET`*

`HSET carrito:U01 P103 1 P107 1` devolvió `2`. Después, `HSET carrito:U01 P103 3` devolvió `0`. ¿Qué significa?

- a) `HSET` devuelve la cantidad de campos nuevos: `P103` ya existía, y su valor pasó a 3.
- b) La segunda operación falló y el valor de `P103` quedó en 1: para cambiar un campo existente hay que usar `HINCRBY`.
- c) El hash se reemplazó completo: `HSET` borra los campos anteriores, así que `P107` ya no existe en el carrito.
- d) `HSET` devuelve la cantidad total de campos que quedan en el hash, y el 0 indica que el carrito quedó vacío.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Por eso conviene verificar con `HGETALL` en lugar de interpretar el `0` como un error. La operación se aplicó (b), el hash no se reemplaza (c), y la cantidad de campos la da `HLEN` (d).

</details>

**Pregunta 42** · Desafío · *ACL en Redis*

`ACL SETUSER app_user on >clave ~sesion:* ~carrito:* +@read +@write`. En una prueba, `app_user` ejecutó `FLUSHALL` y vació toda la base. ¿Por qué y cómo se corrige?

- a) Es un error de Redis: los patrones de claves deberían limitar todos los comandos, y hay que actualizar la versión.
- b) Porque `FLUSHALL` pertenece a la categoría `@read`: hay que quitar esa categoría y dejar solo `+@write`.
- c) Porque falta el patrón `~*`: sin él, Redis ignora los demás patrones de claves y no aplica ninguna restricción.
- d) Porque `FLUSHALL` está en `@write` y no recibe claves, así que los patrones no lo frenan: falta `-@dangerous`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Se comprobó en la Unidad 9: los patrones de claves no limitan un comando que afecta a toda la base, y eso no es un error de Redis (a). `-@dangerous` quita `FLUSHALL`, `FLUSHDB`, `KEYS`, `CONFIG` y otros comandos. Además hay que proteger al usuario `default`, que existe sin contraseña y con acceso total: una conexión sin `AUTH` lo usa y saltea la ACL de `app_user`. `FLUSHALL` no es de lectura (b), y `~*` daría acceso a todas las claves (c), lo contrario de lo buscado.

</details>

**Pregunta 43** · Intermedia · *Actualización perdida*

Doscientos procesos suman 1 al mismo campo. Con `HINCRBY` el resultado es 200. Si cada proceso hace `HGET` y después `HSET` con el valor más uno, el resultado es mucho menor. ¿Por qué?

- a) Porque Redis descarta escrituras cuando recibe muchas a la vez sobre la misma clave, para proteger la memoria.
- b) Porque varios procesos leen el mismo valor y escriben el mismo resultado; `HINCRBY` es una sola operación atómica.
- c) Porque `HSET` es más lento que `HINCRBY`, y algunas escrituras vencen por tiempo antes de llegar al servidor.
- d) Porque faltó persistir con `BGSAVE` entre una escritura y otra, y Redis perdió las que estaban solo en memoria.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Es una carrera de lectura-modificación-escritura. Redis no pierde escrituras (a): cada `HSET` se aplica, pero muchos procesos escriben el mismo número. No es un problema de tiempos (c) ni de persistencia (d): ocurre en memoria, entre la lectura y la escritura. La lección del laboratorio es **delegar la operación crítica al motor** en una sola sentencia atómica. Lo mismo vale para el stock en SQL: `UPDATE ... SET x = x - n WHERE ...`.

</details>

**Pregunta 44** · Desafío · *`MULTI` y `EXEC`*

Dentro de un bloque `MULTI`/`EXEC`, uno de los comandos falla al ejecutarse (por ejemplo, un `INCR` sobre una clave que no es numérica). ¿Qué pasa con los demás?

- a) Se ejecutan igual: Redis no tiene retroceso, y el error solo aparece en la respuesta de ese comando dentro del `EXEC`.
- b) Se deshace todo el bloque, igual que con un `ROLLBACK` en una transacción SQL, y `EXEC` devuelve un error.
- c) Se cancelan los comandos que faltaban, pero los que ya se ejecutaron quedan aplicados, como en un `ROLLBACK` parcial.
- d) El bloque queda en una cola del servidor y se reintenta hasta que todos los comandos funcionen sin error.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** `MULTI`/`EXEC` garantiza que los comandos se ejecuten en secuencia, sin otros intercalados, pero un error durante la ejecución no revierte los anteriores (b) ni frena los siguientes (c), y nada se reintenta solo (d). Para detectar cambios concurrentes está `WATCH`, que hace abortar el `EXEC` si una clave vigilada cambió antes (un control optimista); para lógica condicional atómica, un script Lua.

</details>

**Pregunta 45** · Intermedia · *Respaldo RDB*

¿Qué procedimiento de respaldo y restauración con RDB es correcto?

- a) Lanzar `BGSAVE` y copiar `dump.rdb` en el acto, sin esperar: el archivo ya tiene los datos nuevos.
- b) Usar siempre `SAVE` en lugar de `BGSAVE`, porque guarda sin bloquear al servidor y termina antes.
- c) Ejecutar `BGSAVE`, confirmar con `LASTSAVE` que terminó, copiar el archivo y restaurarlo en otra instancia.
- d) No hace falta copiar nada: RDB registra cada escritura en el momento, así que no puede perder datos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Redis escribe la foto nueva en un archivo temporal y recién al terminar reemplaza a `dump.rdb`: si se copia antes, se lleva la foto anterior (a). El fin del guardado se confirma con `LASTSAVE` o `INFO persistence`, el archivo se ubica con `CONFIG GET dir` y `CONFIG GET dbfilename`, y la copia se valida restaurándola en otra instancia. `SAVE` **bloquea** el servidor; `BGSAVE` trabaja en segundo plano (b). RDB es una foto y puede perder lo escrito después de la última; el registro de cada escritura es **AOF** (d).

</details>

**Pregunta 46** · Desafío · *Memoria llena*

Una instancia de Redis se usa como caché de páginas (todo se puede recalcular) y otra guarda carritos que no deberían desaparecer en silencio. ¿Qué política de memoria corresponde?

- a) `noeviction` para las dos: expulsar claves siempre es un error, aunque el dato se pueda recalcular.
- b) `allkeys-lru` para las dos, porque Redis guarda en el disco lo que expulsa y lo recupera si se vuelve a pedir.
- c) `volatile-ttl` para las dos, porque expulsa primero lo que está por vencer y así nunca se pierde nada útil.
- d) `allkeys-lru` en la caché y `noeviction` en los carritos, que deben fallar antes que perder datos en silencio.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La política se elige según si el dato se puede reconstruir. Lo expulsado **se pierde** (b). `noeviction` hace fallar las escrituras cuando se llena la memoria, en lugar de borrar datos en silencio; para una caché sería un problema innecesario (a). `volatile-ttl` solo expulsa claves con vencimiento (c), y no todas lo tienen. En los carritos conviene, además, activar la persistencia y no usar Redis como única fuente de lo que no puede perderse.

</details>

**Pregunta 47** · Básica · *Clave primaria en Cassandra*

En `PRIMARY KEY ((usuario_id), fecha_evento, evento_id)`, ¿qué rol cumple cada parte?

- a) `usuario_id` es la clave de partición; `fecha_evento` y `evento_id` ordenan las filas dentro de ella.
- b) Las tres columnas forman juntas la clave de partición, y Cassandra ordena las particiones por fecha.
- c) `evento_id` es la clave de partición, porque es el único valor que no se repite; las otras dos son índices.
- d) `usuario_id` funciona como índice secundario, y `fecha_evento` es la clave de partición que ubica cada fila.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Los paréntesis internos marcan la partición, y lo que sigue es clustering. `usuario_id` decide dónde vive la fila y agrupa los eventos de un usuario; `fecha_evento` los ordena, y `evento_id` desempata dos eventos con la misma fecha. Con las tres en la partición (b), cada evento quedaría en una partición distinta y no se podría pedir el historial de un usuario. La partición se ubica por el hash de su clave (el *token*), no por la unicidad de una columna (c), y en esa definición no hay índices secundarios (d).

</details>

**Pregunta 48** · Intermedia · *Los últimos eventos*

Con el orden de clustering por defecto (ascendente), `SELECT ... WHERE usuario_id = 'U01' LIMIT 3` devuelve los tres eventos más antiguos. ¿Cómo se obtienen los tres más recientes?

- a) Agregando `ALLOW FILTERING`, para que Cassandra recorra la partición completa y devuelva las filas más nuevas.
- b) Creando un índice secundario sobre `fecha_evento`, porque el orden de clustering no se puede invertir en la consulta.
- c) Pidiendo `ORDER BY fecha_evento DESC`, o definiendo ese orden en `CLUSTERING ORDER BY`.
- d) No se puede: Cassandra devuelve las filas en el orden en que se insertaron, y `LIMIT` toma siempre las primeras.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Dentro de la partición, las filas están ordenadas por las columnas de clustering, y `LIMIT` toma las primeras. Se comprobó en la Unidad 9: con orden descendente devolvió los tres más recientes. `ALLOW FILTERING` no cambia el orden (a), y un índice secundario no es la forma de ordenar (b).

</details>

**Pregunta 49** · Intermedia · *Consulta por una columna que no es clave*

`SELECT * FROM eventos WHERE tipo_evento = 'COMPRA';` responde `InvalidRequest ... use ALLOW FILTERING`. ¿Qué solución propone Cassandra?

- a) Agregar `ALLOW FILTERING`, que resuelve el problema de forma definitiva aunque la tabla crezca a millones de filas.
- b) Crear otra tabla para esa consulta, con `tipo_evento` en la partición, y que la aplicación escriba en las dos.
- c) Hacer un `JOIN` entre la tabla de eventos y una tabla de tipos de evento que tenga `tipo_evento` como clave.
- d) Aumentar el factor de replicación, para que la consulta encuentre los datos en cualquiera de los nodos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** En Cassandra **se diseña una tabla por consulta**, con desnormalización deliberada. `ALLOW FILTERING` solo fuerza a recorrer todas las particiones: con volumen es lento e impredecible (a). No hay `JOIN` (c), y la replicación no cambia cómo se ubican los datos (d).

</details>

**Pregunta 50** · Desafío · *Particiones que crecen sin límite*

Se crea `eventos_por_tipo` con `PRIMARY KEY ((tipo_evento), fecha_evento, evento_id)`. Hay cinco tipos y millones de eventos por día. ¿Qué riesgo hay y cómo se mitiga?

- a) Ninguno: con pocas particiones, cada consulta toca un solo nodo y Cassandra responde más rápido.
- b) Se acumulan demasiadas lápidas en cada partición; se mitiga agregando un `TTL` a cada inserción.
- c) Las consultas por tipo exigirán `ALLOW FILTERING`; se mitiga con un índice secundario sobre `tipo_evento`.
- d) Cinco particiones gigantes y calientes en pocos nodos; se mitiga con un cubo, como `((tipo_evento, dia), ...)`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La clave de partición necesita **cardinalidad suficiente** y particiones acotadas. Con cinco valores, cada partición acumula todo el volumen de su tipo, y los nodos dueños se saturan (*particiones calientes*); que cada consulta toque un solo nodo no compensa ese riesgo (a). El cubo por día reparte la carga y acota cada partición. Las lápidas aparecen con los borrados, no por tener pocas particiones (b), y la consulta por tipo indica la partición, así que no necesita `ALLOW FILTERING` (c).

</details>

**Pregunta 51** · Intermedia · *`UPDATE` en Cassandra*

Se ejecuta un `UPDATE` sobre una clave primaria que no existe. ¿Qué pasa?

- a) Se crea la fila, porque en Cassandra tanto `INSERT` como `UPDATE` escriben sin leer antes (*upsert*).
- b) Da un error de clave inexistente, porque `UPDATE` solo modifica filas que ya existen.
- c) No modifica nada y no avisa, igual que un `UPDATE` de SQL que no encuentra filas.
- d) Se convierte en una lápida (*tombstone*) sobre esa clave, que se elimina en la próxima compactación.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Cassandra no lee antes de escribir: las dos operaciones escriben la fila con esa clave. Se vio en la Unidad 9: un `UPDATE` sobre una clave inexistente creó una fila nueva sin dar error. Por eso cada operación se verifica después con un `SELECT`. Las lápidas aparecen con `DELETE`, no con `UPDATE` (d).

</details>

**Pregunta 52** · Desafío · *Consistencia ajustable*

Con factor de replicación 3, las escrituras y las lecturas se hacen con `QUORUM`. ¿Qué es correcto?

- a) `QUORUM` son 3 réplicas, y por eso usar `ONE` en lecturas y escrituras da la misma consistencia con menos latencia.
- b) La consistencia depende solo del factor de replicación: con RF 3, cualquier nivel garantiza leer la última escritura.
- c) `QUORUM` son 2 réplicas, y como lecturas y escrituras suman 2 + 2 > 3, cada lectura ve la última escritura confirmada.
- d) Cassandra tiene un nodo maestro que confirma cada escritura, así que la consistencia no depende del nivel elegido.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** `QUORUM` = ⌊RF ÷ 2⌋ + 1 = 2. La regla es **R + W > RF**; con `ONE` en ambas (1 + 1 = 2) se podría leer un valor viejo (a). El nivel de consistencia se elige **por operación** (b). No hay nodo maestro: el nodo que recibe una operación actúa como coordinador solo para ella (d).

</details>

**Pregunta 53** · Intermedia · *Un solo nodo*

En el laboratorio, Cassandra corre en un solo nodo con factor de replicación 1. ¿Qué se puede afirmar?

- a) Que la base es tolerante a fallas, porque todo lo escrito queda primero en el *commit log* del nodo.
- b) Que el modelo de datos y las consultas funcionan, pero no la tolerancia a fallas ni la diferencia entre niveles.
- c) Que `QUORUM` y `ONE` ya se comportan distinto, porque Cassandra guarda dos copias en el disco del nodo.
- d) Que la replicación funciona, aunque las copias queden repartidas entre los discos del mismo nodo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Para ensayar tolerancia a fallas y niveles de consistencia hace falta un clúster de al menos tres nodos. Con RF = 1 hay una sola copia: si el nodo cae, el dato no está disponible, y todos los niveles se comportan igual. Por eso, en el caso OmniMarket, Cassandra quedó diseñada sin afirmar lo que no se podía ensayar. El *commit log* da durabilidad local, no tolerancia a fallas (a).

</details>

**Pregunta 54** · Básica · *Por qué un grafo*

Para recomendar "lo que compran los clientes que sigo", ¿por qué conviene un grafo?

- a) Porque guarda los datos de forma más compacta que las tablas, y por eso entra más información en memoria.
- b) Porque es el único modelo que permite guardar relaciones entre clientes, como `SIGUE`, sin tablas intermedias.
- c) Porque suma y agrupa todos los datos más rápido que SQL, al no tener que resolver ningún `JOIN`.
- d) Porque las relaciones están guardadas: cada salto las sigue directamente, sin buscar por clave como un `JOIN`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** En SQL, cada salto es un `JOIN` que se calcula al consultar, y la dificultad crece con la profundidad. En el grafo, las relaciones están almacenadas: el costo depende de la parte que se explora y no del tamaño total, y en Cypher dos saltos son un solo patrón. Un relacional también guarda relaciones (b), y la compacidad no es el motivo (a). Las agregaciones masivas sobre todo el conjunto **no** son el punto fuerte de un grafo (c).

</details>

**Pregunta 55** · Intermedia · *`CREATE` y `MERGE`*

El script de carga de clientes se ejecutó dos veces. Con `CREATE` quedaron clientes duplicados; con `MERGE`, no. ¿Qué es correcto?

- a) `CREATE` crea siempre, mientras que `MERGE` busca el patrón completo y solo lo crea si no existe.
- b) `MERGE` también crea, pero sobrescribe todas las propiedades del nodo existente cada vez que se ejecuta.
- c) Los dos crean nodos nuevos; la diferencia es que `MERGE` aplica un `DISTINCT` al devolver los resultados.
- d) `MERGE` solo sirve para relaciones: con nodos se comporta como `MATCH` y nunca crea nada nuevo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Por eso la carga usa `MERGE`: se puede repetir sin duplicar, y una restricción de unicidad rechaza cualquier duplicado que se cuele. Se aplica sobre el patrón entero, sea un nodo o una relación (d): `MERGE (u)-[:SIGUE]->(s)` crea la relación solo si no estaba. No tiene que ver con `DISTINCT` (c), y para cambiar propiedades se usa `SET` u `ON MATCH SET` (b).

</details>

**Pregunta 56** · Básica · *Borrar un nodo*

`MATCH (c:Cliente {id: 'U99'}) DELETE c` falla con un error que indica que todavía existen relaciones. ¿Qué se hace?

- a) Nada: Neo4j no permite borrar nodos con historia, así que hay que marcarlo como inactivo con una propiedad.
- b) Usar `REMOVE c`, que borra el nodo junto con sus relaciones en una sola operación.
- c) Usar `DETACH DELETE c`, que borra el nodo junto con todas sus relaciones, o borrarlas antes.
- d) Pasar a la edición Enterprise, que es la única que permite borrar nodos que todavía tienen relaciones.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Una relación siempre une dos nodos, así que Neo4j no deja que quede "colgando": las relaciones se borran antes o junto con el nodo. Neo4j sí borra nodos (a). `REMOVE` quita propiedades o etiquetas, no nodos (b), y el comportamiento es el mismo en todas las ediciones (d).

</details>

**Pregunta 57** · Desafío · *Duplicados en una recomendación*

`MATCH (u:Cliente {id:'U01'})-[:SIGUE]->(s)-[:COMPRO]->(p) WHERE NOT (u)-[:COMPRO]->(p) RETURN p.nombre` devuelve `Notebook` dos veces. ¿Por qué y cómo se corrige?

- a) Hay dos nodos `Notebook` cargados en la base, y se corrige borrando el duplicado con `DETACH DELETE`.
- b) Hay una fila por cada camino, y dos clientes seguidos la compraron: se corrige con `RETURN DISTINCT`.
- c) `WHERE NOT` evalúa el patrón dos veces y duplica los resultados, así que hay que quitar esa condición.
- d) `MATCH` repite los nodos que encuentra por más de un camino; se corrige reemplazándolo por `MERGE`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Es el comportamiento esperado de un patrón: cada camino es una fila, y la misma notebook aparece por dos caminos, no por dos nodos (a). Para ordenar por relevancia se usa `count(DISTINCT s)`. `WHERE NOT (u)-[:COMPRO]->(p)` es lo que excluye lo que U01 ya compró (c), y `MERGE` crearía datos en lugar de consultarlos (d).

</details>

**Pregunta 58** · Intermedia · *`LOAD CSV`*

`LOAD CSV WITH HEADERS FROM 'file:///productos.csv'` no encuentra el archivo guardado en `/home/usuario/`. Después de copiarlo donde corresponde, `ORDER BY p.precio` pone `"1000"` antes que `"200"`. ¿Qué explica las dos cosas?

- a) `LOAD CSV` lee cualquier ruta del equipo, y el orden falla porque falta un índice sobre la propiedad `precio`.
- b) Para importar un CSV hace falta `neo4j-admin`, y la importación con `LOAD CSV` convierte los números en fechas.
- c) `LOAD CSV` espera archivos JSON por defecto, así que interpretó mal el CSV y todas sus columnas.
- d) Solo lee del directorio `import`, y los valores llegan como texto: hay que convertirlos con `toInteger()`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Restringir la lectura a `import` evita que una consulta lea archivos arbitrarios del sistema. Como todo llega como texto, `"1000"` queda antes que `"200"` en orden alfabético. Un índice no cambia el tipo de un valor (a).

</details>

**Pregunta 59** · Intermedia · *Neo4j Community*

¿Qué afirmación sobre Neo4j Community es correcta?

- a) Sí tiene autenticación, pero no roles con privilegios, ni respaldo en caliente, ni clúster.
- b) Permite crear roles con `GRANT` y `DENY`, igual que Enterprise; solo le falta el clúster.
- c) No tiene autenticación: cualquiera que llegue al puerto 7687 entra sin usuario ni contraseña.
- d) Permite el respaldo en caliente con `neo4j-admin`, sin detener la base, pero no la restauración.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** En Community, `SHOW ROLES` responde que no está soportado en esa edición. Por eso la consigna no exigía RBAC granular en Community: se compensa con una clave robusta, escuchando solo en localhost y con los permisos del sistema operativo. Sí hay autenticación: el usuario inicial `neo4j` debe cambiar su clave en el primer ingreso (c). El respaldo en caliente es de Enterprise (d).

</details>

**Pregunta 60** · Desafío · *Respaldo y restauración en Neo4j*

`neo4j-admin database dump neo4j` con el servicio activo responde "The database is in use". ¿Cuál es el procedimiento correcto?

- a) Agregar `--force` al comando, que hace el volcado en caliente sin detener la base.
- b) Copiar la carpeta de datos con el servicio en marcha y comprimirla, que equivale a un volcado.
- c) Detener el servicio, volcar, reiniciar, y cargar el volcado en una instancia aislada para comparar.
- d) Exportar a un archivo el resultado de `MATCH (n) RETURN n`, que contiene todos los nodos y relaciones.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Community no ofrece respaldo en caliente: el volcado exige la base detenida, y ninguna opción lo evita (a). Copiar archivos en uso no es consistente (b), y el resultado de una consulta no es un respaldo restaurable: `MATCH (n) RETURN n` ni siquiera trae las relaciones (d). La carga se hace con `neo4j-admin database load` en una instancia aislada, para no pisar el servicio, y se compara antes y después: de 0/0 a los mismos recuentos, la misma consulta de negocio y un `diff` sin diferencias. Contar demuestra que **hay** datos; la consulta y el `diff` demuestran que son **los mismos**.

</details>

**Pregunta 61** · Básica · *"No gana quien usa más tecnologías"*

¿Qué criterio respeta la consigna de la Unidad 9, según la cual "no gana quien usa más tecnologías"?

- a) Sumar un motor especializado en cada dominio, para que cada área tenga la tecnología óptima para su carga.
- b) Sumar un motor solo si el que ya se tiene falla en un requisito crítico que el nuevo sí cubre.
- c) Elegir para cada área el motor más usado del mercado, porque tiene más documentación y más especialistas.
- d) Usar siempre un único motor para todo el sistema, aunque no cumpla alguno de los requisitos obligatorios.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Cada motor suma operación, respaldo, seguridad, conocimiento e integración. La pregunta no es "¿qué motor sirve?" sino "¿el que tengo no alcanza?". La popularidad no es un requisito (c), y forzar un solo motor que incumple lo obligatorio tampoco es válido (d).

</details>

**Pregunta 62** · Intermedia · *Patrón de acceso*

Navegación: 30 millones de eventos por día, que solo se agregan, y la consulta principal es "historial reciente de un usuario por fecha". ¿Qué modelo encaja?

- a) Grafos, porque cada evento relaciona a un usuario con un producto, y eso es una relación entre nodos.
- b) Clave-valor en memoria, porque la navegación necesita la menor latencia posible en cada escritura.
- c) Columnas anchas, con partición por usuario y clustering por fecha, para escribir sin pausa.
- d) Documental, con un arreglo de eventos dentro del documento de cada usuario, ordenado por fecha.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Escritura masiva que solo agrega, más lectura por clave y por rango ordenado, es el caso de Cassandra, con un cubo por día en la partición para acotarla. Once mil millones de eventos por año no entran en memoria (b), y un arreglo por usuario sería un arreglo sin cota (d). Un grafo sirve para recorrer relaciones, no para series de eventos (a).

</details>

**Pregunta 63** · Intermedia · *Dimensionamiento*

OmniMarket recibe 100.000 pedidos por día. El grupo rival dice que una base relacional no lo soporta. ¿Qué cálculo corresponde?

- a) ≈ 1,2 pedidos por segundo (100.000 ÷ 86.400): una carga baja incluso para un solo servidor relacional.
- b) ≈ 115 pedidos por segundo: una carga que solo una base distribuida como Cassandra sostiene en el tiempo.
- c) ≈ 1.157 pedidos por segundo: hay que fragmentar la base relacional en varios servidores desde el inicio.
- d) No se puede estimar nada: sin una prueba de carga, cualquier cifra por segundo es una suposición.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Una cuenta de orden de magnitud basta para descartar el argumento; aun con un pico de 40 por segundo sigue siendo una carga baja, y no hay razón técnica para sacar los pedidos de MySQL. Las opciones b y c multiplican el resultado por 100 y por 1.000. Una prueba de carga sirve para validar el supuesto, pero no impide razonar con él (d).

</details>

**Pregunta 64** · Desafío · *Regla de adopción*

Catálogo: el relacional suma 23 puntos y el documental, 23. La regla dice que se suma un NoSQL solo si (1) hay un criterio de peso 3 que el relacional cubre con aptitud 1 o menos, (2) el candidato lo cubre con 3 y (3) suma más puntos. ¿Qué resultado da?

- a) Gana el documental: la flexibilidad de esquema tiene peso 3 en el catálogo, y es su punto más fuerte.
- b) Se usan los dos motores para el catálogo, uno como copia del otro, para no perder ninguna fortaleza.
- c) No se puede decidir: con un empate, la regla no aplica y la elección queda librada al equipo.
- d) Queda en el relacional: ningún criterio de peso 3 tiene aptitud relacional de 1 o menos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** En el catálogo, los criterios de peso 3 son la flexibilidad y las consultas ad hoc: el relacional cubre la primera con aptitud 2 (`JSON` con índices) y la segunda con 3, y además los puntajes empatan. Fallan las condiciones 1 y 3. La regla se fija **antes** de ver el resultado y concreta el principio de no sumar motores sin necesidad: si no se cumple, incluido el empate, el dominio queda en el motor que ya está (c). La decisión deja un criterio de revisión: si hubiera que filtrar libremente por cualquier atributo, sin indexarlo antes, se reevalúa.

</details>

**Pregunta 65** · Básica · *Teorema CAP*

¿Qué formulación del teorema CAP es correcta?

- a) Cada sistema elige dos de las tres propiedades de una vez y para siempre; por ejemplo, Cassandra es siempre AP.
- b) Durante una partición de red, el sistema elige entre responder con un error o con un dato quizás desactualizado.
- c) CAP compara la latencia con el rendimiento: un sistema distribuido no puede optimizar las dos al mismo tiempo.
- d) La C de CAP es la misma C de ACID: cada transacción debe respetar las restricciones de integridad de la base.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La elección ocurre **durante la falla**: sin particiones, el sistema puede ser consistente y disponible a la vez. No es una etiqueta fija por producto: depende de la configuración (réplicas, nivel de consistencia), por eso a es falsa. CAP no habla de latencia (c; eso lo agrega PACELC), y su C no es la de ACID (d).

</details>

**Pregunta 66** · Intermedia · *La C de ACID y la C de CAP*

¿Qué diferencia hay entre la "C" de ACID y la de CAP?

- a) Ninguna: las dos exigen que todas las réplicas tengan los mismos datos en el mismo momento.
- b) La de ACID se refiere a que las réplicas coincidan, y la de CAP, a que se cumplan las restricciones `CHECK`.
- c) La de ACID es respetar las restricciones; la de CAP, que cada lectura vea la última escritura confirmada.
- d) La de ACID solo existe en las bases relacionales, y la de CAP, solo en las bases NoSQL distribuidas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** La de ACID es que cada transacción lleve la base de un estado válido a otro; la de CAP, que cada lectura vea la última escritura confirmada o reciba un error. Confundirlas es un error frecuente en las defensas. Un sistema puede respetar un `CHECK` (la C de ACID) y, en un clúster con réplicas asíncronas, devolver un dato viejo (no cumple la C de CAP). La b invierte los conceptos, y la d inventa una separación por tipo de motor.

</details>

**Pregunta 67** · Intermedia · *PACELC*

Sin ninguna falla de red, un sistema replicado que espera a una mayoría de réplicas en cada lectura responde más lento. ¿Qué lo explica?

- a) PACELC: cuando no hay partición (*else*), el sistema elige entre menor latencia y más consistencia.
- b) El teorema CAP, que obliga a resignar disponibilidad incluso cuando no hay ninguna partición de red.
- c) El modelo BASE, que prohíbe leer de una sola réplica y obliga a consultar siempre a la mayoría.
- d) La durabilidad de ACID, que obliga a escribir en el disco de cada réplica también durante las lecturas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** CAP solo describe la elección durante una partición (b). PACELC mantiene esa elección ante una partición y agrega el caso normal: esperar más réplicas da datos más actualizados a cambio de latencia. BASE es una actitud de diseño que prioriza la disponibilidad (c), y la durabilidad se refiere a lo confirmado, no a las lecturas (d).

</details>

**Pregunta 68** · Intermedia · *Dónde va lo transaccional*

Confirmar un pedido descuenta stock, registra el pago y acredita puntos: todo o nada. ¿Dónde se ubica y por qué?

- a) En Cassandra, porque garantiza aislamiento entre particiones y restricciones `CHECK` entre tablas distintas.
- b) En Redis, porque `MULTI`/`EXEC` revierte todo el bloque si uno de los comandos falla al ejecutarse.
- c) En Neo4j, porque es la única de las cuatro bases con transacciones ACID completas sobre varias entidades.
- d) En MySQL, que ofrece transacciones ACID entre varias tablas y restricciones declarativas como `CHECK`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** El dominio necesita atomicidad **entre varias entidades** y restricciones como `CHECK`. NoSQL no significa "sin ACID", pero el alcance cambia: Cassandra es atómica por partición, y Redis, por comando o script. Cassandra no tiene restricciones de ese tipo ni aislamiento entre particiones (a), `MULTI`/`EXEC` no tiene retroceso (b), y Neo4j no es la única con ACID: MySQL también lo es (c).

</details>

**Pregunta 69** · Intermedia · *Escritura doble*

La aplicación guarda el pedido en MySQL y, a continuación, lo escribe directamente en Neo4j. El proceso cae entre las dos escrituras. ¿Qué pasa y cómo se evita?

- a) Nada grave: al reiniciarse, Neo4j detecta la escritura que quedó pendiente y la aplica por su cuenta.
- b) Quedan inconsistentes; se evita guardando el evento en una tabla *outbox* dentro de la transacción del pedido.
- c) Se evita con una transacción distribuida (*two-phase commit*), disponible entre cualquier par de motores.
- d) Se evita invirtiendo el orden: primero se escribe en Neo4j y, si sale bien, después en MySQL.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Dos escrituras a motores distintos no son atómicas, y la falla pasa inadvertida: Neo4j no sabe nada de una escritura que nunca recibió (a). Con el *outbox*, un proceso aparte publica el evento y lo reintenta hasta aplicarlo. Invertir el orden solo cambia qué motor queda desactualizado (d). El *two-phase commit* no está disponible entre estos motores y, aunque lo estuviera, bloquea y reduce la disponibilidad (c). Con volumen alto, la evolución del outbox es la captura de cambios (CDC) del binlog.

</details>

**Pregunta 70** · Desafío · *Entrega "al menos una vez"*

El relay entrega los eventos "al menos una vez", y el mismo `PEDIDO_CONFIRMADO` llega dos veces al consumidor de Neo4j. ¿Cómo se evita duplicar la compra?

- a) Con un consumidor idempotente: `MERGE` sobre `linea_id`, protegido por una restricción de unicidad.
- b) Configurando la red y el relay para que garanticen la entrega "exactamente una vez" de cada evento.
- c) Usando `CREATE` en lugar de `MERGE`, para que la segunda inserción falle y avise del duplicado.
- d) Desactivando los reintentos del relay, para que cada evento se entregue como máximo una vez.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** **Al menos una vez más un consumidor idempotente** equivale, en la práctica, a "exactamente una vez"; la red sola no puede garantizarlo (b). El laboratorio lo mostró: después de la reentrega, las compras siguieron en 4. Una `version` por entidad, además, descarta los eventos viejos que llegan tarde. Desactivar los reintentos (d) puede **perder** eventos. Con `CREATE`, la segunda entrega duplica la compra o, si hay una restricción, termina en un error que el relay trataría como falla y volvería a intentar (c).

</details>

**Pregunta 71** · Intermedia · *Caminos de sincronización*

Con cinco motores, ¿cuántos caminos de sincronización hay en una arquitectura en estrella y cuántos en una malla?

- a) Estrella 10, malla 4.
- b) Estrella 4, malla 10.
- c) Cinco en las dos formas.
- d) Estrella 5, malla 25.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** En estrella son n − 1 caminos, y en malla, n × (n − 1) ÷ 2; la d cuenta n y n × n. Por eso OmniMarket centraliza la fuente de verdad en MySQL y proyecta desde ahí: con cuatro motores en estrella hay 3 caminos. Cada camino es un punto donde pueden aparecer duplicados, desorden y reintentos.

</details>

---

## Unidad 10 · Bases de datos como servicio (MongoDB Atlas)

**Pregunta 72** · Básica · *Responsabilidad compartida*

En MongoDB Atlas, ¿qué sigue siendo responsabilidad del equipo?

- a) Instalar el motor, elegir y aplicar las versiones nuevas, y mantener al día los parches del sistema operativo.
- b) Mantener el hardware, el almacenamiento y la red física del centro de datos donde corre el clúster.
- c) Nada: el proveedor se ocupa de todo, incluidos los datos, sus permisos y sus respaldos.
- d) El modelo de datos, los permisos, la lista de IP y la prueba de restauración de los respaldos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Es el **modelo de responsabilidad compartida**: el proveedor opera la infraestructura (sistema operativo, instalación, versiones, réplicas, TLS) y el equipo gobierna lo que está dentro de la base. La responsabilidad sobre los datos nunca se delega (c): si un usuario con permisos de más borra una colección, el servicio replica el borrado sin dudar.

</details>

**Pregunta 73** · Intermedia · *Crear usuarios en Atlas*

En Atlas, `db.getSiblingDB("admin").createUser(...)` ejecutado con un usuario `atlasAdmin` es rechazado. ¿Por qué?

- a) Porque `atlasAdmin` tiene menos privilegios que `root`: hay que reconectarse con un usuario que tenga el rol `root`.
- b) Porque en Atlas los usuarios de la base se crean desde la plataforma (*Database Access* o la API), no con comandos.
- c) Porque el plan gratuito permite un solo usuario de base de datos, y ese lugar ya lo ocupa el administrador.
- d) Porque falta activar `security.authorization` en el `mongod.conf` del clúster antes de crear usuarios.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** El motor hace cumplir los permisos, pero no los administra: el comando está bloqueado incluso para `atlasAdmin`, el rol más alto que se le puede dar a un usuario de base de datos (a). Es la diferencia más clara con la VM: en la Unidad 8 los usuarios se creaban con `db.createUser()`. En Atlas no hay acceso a `mongod.conf` (d), y el plan Free admite varios usuarios: en la actividad se usaron un administrador y un usuario de solo lectura (c).

</details>

**Pregunta 74** · Intermedia · *Permisos de la plataforma y del motor*

A un compañero se lo invita al proyecto con el rol *Project Read Only*. ¿Puede leer los documentos de `tienda.productos` desde `mongosh`?

- a) No: ese rol es de la plataforma; para leer datos necesita un usuario de base de datos con lectura.
- b) Sí: un rol de solo lectura en el proyecto incluye leer todas las bases y colecciones de sus clústeres.
- c) Sí, siempre que se conecte desde una IP habilitada en la lista de acceso y use su cuenta de Atlas.
- d) Solo en los planes pagos se separan esos permisos; en el plan Free, todos los miembros leen los datos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** *Project Read Only* sirve para ver la configuración y las métricas del proyecto. Son dos capas: las cuentas de la consola web, con roles de organización y de proyecto, y los usuarios de base de datos, que se autentican con SCRAM contra el motor. Una identidad de una capa no sirve en la otra: un usuario de base de datos tampoco puede entrar a la consola. La IP habilitada (c) es una condición de red, no un permiso.

</details>

**Pregunta 75** · Intermedia · *Conectarse desde otra red*

Desde casa, `mongosh` se conectaba a Atlas; en el aula, se queda esperando hasta dar *timeout*. ¿Cuál es la causa y la corrección adecuada?

- a) El clúster se eliminó por inactividad, y hay que crearlo de nuevo y volver a cargar los datos.
- b) La cadena SRV solo se resuelve en redes domésticas; en otras redes hay que usar la IP fija del nodo primario.
- c) La IP pública de la red cambió: hay que agregarla a la lista de acceso del proyecto, sin abrir `0.0.0.0/0`.
- d) Atlas dejó de aceptar `mongosh` 2.x en el plan Free, y hay que usar una versión anterior del cliente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Se agrega en *Network Access*, por ejemplo con *Add Current IP Address*. La lista de IP es el primer control: si la IP no está, la conexión ni siquiera llega al motor, y se ve como un *timeout*, no como un error de credenciales. `0.0.0.0/0` abriría el clúster a cualquier dirección de internet y dejaría la clave como única defensa. Un clúster Free inactivo se **pausa** a los 30 días, no se elimina (a); la cadena SRV funciona en cualquier red con DNS (b), y la versión de `mongosh` no tiene que ver (d).

</details>

**Pregunta 76** · Básica · *La cadena SRV*

¿Por qué la cadena `mongodb+srv://<cluster>.<id>.mongodb.net/` no tiene IP ni puerto?

- a) Porque Atlas usa un único servidor con una dirección fija, y el nombre del clúster ya equivale a esa IP.
- b) Porque la conexión pasa por un proxy HTTP del proveedor, que reenvía cada consulta al nodo que corresponda.
- c) Porque solo funciona dentro de una VPN del proveedor, que asigna la IP y el puerto al conectarse.
- d) Porque el cliente obtiene los nodos y las opciones de conexión consultando registros SRV y TXT en el DNS.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Los registros SRV indican los nodos, y el TXT, opciones como el *replica set* y `authSource`. Así el proveedor puede reemplazar nodos sin cambiar la cadena. El clúster Free es un *replica set* de tres nodos: con SRV, el cliente los descubre y se conecta con TLS, que en Atlas es obligatorio. Las otras opciones describen arquitecturas que Atlas no usa.

</details>

**Pregunta 77** · Intermedia · *La replicación no es un respaldo*

Un usuario borra un producto por error en un clúster de tres nodos. Alguien dice: "Tenemos tres copias, lo recuperamos de un secundario". ¿Qué evaluación es correcta?

- a) Es correcta: alcanza con promover un secundario a primario antes de que reciba el borrado.
- b) Es incorrecta: el borrado ya se replicó a los tres nodos, y para volver atrás hace falta un respaldo.
- c) Es correcta, porque en Atlas los secundarios aplican los cambios con una hora de retraso, como margen.
- d) Es correcta, porque Atlas conserva los documentos borrados durante 30 días en una papelera del clúster.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La replicación da disponibilidad ante la caída de un nodo; para volver atrás hace falta un respaldo, que es una copia en otro momento y otro lugar. Es la misma idea de la Unidad 6: la alta disponibilidad protege contra fallas físicas, no contra errores lógicos. Los secundarios replican casi al instante, así que no hay a cuál promover a tiempo (a, c), y Atlas no conserva los documentos borrados (d).

</details>

**Pregunta 78** · Desafío · *Respaldo en el plan Free*

La consigna pide identificar la protección administrada, generar un respaldo lógico y verificar una recuperación, sin registrar tarjetas. ¿Qué enfoque es correcto?

- a) Sin activar los snapshots pagos: `mongodump`, restauración en otra base y comparación de recuentos y `_id`.
- b) Activar los snapshots en la pestaña Backup y entregar una captura que muestre el respaldo activado.
- c) Documentar la limitación: el plan Free no permite `mongodump`, así que no hay forma de probar una recuperación.
- d) Pasar el clúster por un rato a un plan pago, tomar un snapshot y volver al plan Free antes de que se facture.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Los snapshots administrados del plan Free son una suscripción paga que exige un medio de pago, así que no se activan. El `mongodump` se hace contra el endpoint, y la restauración, en otro espacio de nombres (`--nsFrom`/`--nsTo`). La consigna aclaraba que una captura de "backup activado" no prueba una restauración (b). `mongodump` sí funciona en el plan Free (c), y pasar a un plan pago rompe la condición de no registrar tarjetas (d). Que los `_id` coincidan prueba que es una copia fiel y no una nueva carga.

</details>

**Pregunta 79** · Intermedia · *Límites del plan Free*

¿Qué afirmación sobre el plan Free (M0) de Atlas es correcta?

- a) Se puede elegir la versión de MongoDB, descargar los logs del servidor y usar el panel de rendimiento en tiempo real.
- b) No tiene límite de almacenamiento: el plan solo limita la cantidad de operaciones por segundo y de conexiones.
- c) Tiene 512 MB de almacenamiento, 100 operaciones por segundo y 500 conexiones, y la versión la fija el proveedor.
- d) Admite JavaScript del lado del servidor (`$where`, `mapReduce`) y políticas de respaldo personalizadas sin costo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Son los límites de la documentación oficial de Atlas, consultada en la Unidad 10. La versión no se elige, no se pueden descargar los logs ni usar el panel en tiempo real, y las métricas se reducen a conexiones, operaciones, red y tamaño lógico (a). El almacenamiento también está limitado (b), y el JavaScript del lado del servidor no está soportado (d). Además, un clúster Free se pausa tras 30 días sin conexiones.

</details>

**Pregunta 80** · Intermedia · *¿DBaaS elimina al DBA?*

¿Qué conclusión respalda mejor la evidencia de la Unidad 10?

- a) DBaaS elimina al DBA: el proveedor se ocupa de la instalación, las réplicas, la seguridad y los respaldos.
- b) El trabajo del DBA es el mismo que en la VM: solo cambia dónde está el servidor y quién paga el hardware.
- c) El DBA solo hace falta para escribir consultas, porque la seguridad y los respaldos los resuelve la plataforma.
- d) DBaaS transforma el rol: se delega la infraestructura, pero quedan los datos, el acceso, la continuidad y los costos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Se delegan la instalación, los parches, las réplicas y el TLS, pero quedan el diseño de datos, el mínimo privilegio, la red, la continuidad con restauraciones probadas, los límites del servicio y los costos. En la actividad igual hubo que decidir permisos (un lector con `read`), red (la lista de IP), estructura y respaldo con su verificación, y compensar los límites del plan: sin respaldo administrado gratuito, sin `createUser` y sin logs. Las otras opciones ignoran esa evidencia.

</details>

---

## Clave de respuestas

| Unidad | Respuestas |
| :--- | :--- |
| U7 | 1 c · 2 b · 3 a · 4 d · 5 c · 6 a · 7 d · 8 b · 9 c · 10 a · 11 d · 12 c · 13 a · 14 b · 15 d · 16 b · 17 c |
| U8 | 18 d · 19 a · 20 c · 21 b · 22 d · 23 c · 24 a · 25 b · 26 c · 27 d · 28 a · 29 c · 30 b · 31 d · 32 c · 33 a · 34 b · 35 d · 36 a · 37 c · 38 b · 39 d |
| U9 | 40 c · 41 a · 42 d · 43 b · 44 a · 45 c · 46 d · 47 a · 48 c · 49 b · 50 d · 51 a · 52 c · 53 b · 54 d · 55 a · 56 c · 57 b · 58 d · 59 a · 60 c · 61 b · 62 c · 63 a · 64 d · 65 b · 66 c · 67 a · 68 d · 69 b · 70 a · 71 b |
| U10 | 72 d · 73 b · 74 a · 75 c · 76 d · 77 b · 78 a · 79 c · 80 d |
