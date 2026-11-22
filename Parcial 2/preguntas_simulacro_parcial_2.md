# Preguntas tipo simulacro · Parcial 2

**Sistemas de Gestión de Bases de Datos 2026 · Bloque temático 2**
120 preguntas de opción múltiple sobre las Unidades 7 a 10, con una sola respuesta correcta en cada una.

---

## Cómo usar este cuestionario

- El formato sigue el del simulacro de la cátedra: una situación concreta, cuatro opciones y una sola correcta.
- **La base son las clases de la cátedra** (clases 7 a 10 de 2026): sus preguntas disparadoras, conceptos, tablas comparativas, ejemplos de código y criterios de logro. La mayoría de las preguntas sale de ahí y no depende de haber hecho una actividad en particular.
- Algunas preguntas, sobre todo de nivel Desafío, retoman situaciones que aparecieron al resolver las actividades (búsqueda de texto completo, seguridad y respaldo en MongoDB, ACL de Redis, servicios gratuitos en la nube). Están planteadas en forma general, para cualquier grupo.
- Cada pregunta indica unidad, **nivel** y tema:
  - **Básica:** un concepto central bien aplicado.
  - **Intermedia:** hay que relacionar dos ideas o descartar distractores plausibles.
  - **Desafío:** las opciones se parecen mucho o hace falta entender el mecanismo, no recordar una definición.
- Respondé antes de abrir **"Ver respuesta"**. Cada explicación dice por qué la opción correcta lo es y por qué fallan las demás.
- La teoría de cada pregunta está en el [apunte del Parcial 2](apunte_parcial_2.md), que sigue el mismo orden de las clases.
- Al final hay una **clave de respuestas** para corregir rápido.

| Unidad | Preguntas | Tema (clase) |
| :--- | :--- | :--- |
| U7 | 1 a 33 | Cuando el modelo relacional empieza a quedar corto: tensiones, semiestructurados, MySQL 9.7 y PostgreSQL 18 multimodelo, escala, CAP y familias NoSQL |
| U8 | 34 a 63 | MongoDB: documento y BSON, agregados, embeber o referenciar, CRUD, índices, `explain`, *pipeline*, validación, réplicas y seguridad |
| U9 | 64 a 97 | Redis, Cassandra, Neo4j y CAP: tres modelos, ACID en NoSQL, distribución, matriz de decisión y persistencia políglota |
| U10 | 98 a 120 | Operar como servicio: DBaaS, responsabilidad compartida, endpoint, backup y HA, observabilidad, costos, seguridad y migración |

### Cómo reconocer la opción correcta

| Señal en una opción | Suele indicar |
| :--- | :--- |
| Absolutos: "siempre", "nunca", "el más rápido", "se eligen dos de tres de una vez" | Opción incorrecta: casi todo depende del patrón de acceso y de la configuración |
| Argumentos de moda: "es el más usado", "NoSQL es más rápido", "más motores, más preparada", "en la nube es más barato" | Opción incorrecta: no son requisitos del negocio |
| Etiquetas fijas: "SQL = ACID", "NoSQL = BASE", "Cassandra es AP", "DBaaS = sin administración" | Opción incorrecta: la clase las desarma una por una |
| "Depende del patrón de acceso" más una verificación con evidencia (`explain`, recuentos, restaurar y comparar) | Opción correcta típica |
| El mecanismo del propio motor que garantiza la regla (operación atómica, restricción, `MERGE` idempotente) | Opción correcta típica |
| Dos opciones casi iguales | Buscá la palabra que cambia: `$elemMatch` o notación con punto, `CREATE` o `MERGE`, `QUORUM` o `ONE`, `-1` o `-2`, `json` o `jsonb` |

---

## Unidad 7 · Cuando el modelo relacional empieza a quedar corto

**Pregunta 1** · Básica · *Las cinco tensiones*

Un sistema antifraude necesita encontrar qué caminos conectan clientes, cuentas, comercios y direcciones IP. Cada consulta encadena seis o siete `JOIN` y el tiempo crece con cada salto. Según la clase, ¿qué tensión del modelo relacional aparece?

- a) Estructura: la forma de los datos cambia con frecuencia.
- b) Escala: una sola instancia deja de alcanzar para el volumen.
- c) Relaciones: hay recorridos con demasiados `JOIN`.
- d) Jerarquía: los datos llegan naturalmente anidados.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** La clase plantea cinco tensiones: estructura, jerarquía, relaciones, escala y acceso. Cuando el valor está en **recorrer conexiones** y cada salto es un `JOIN` más, la tensión es de **relaciones**, y el modelo que la resuelve mejor es el de grafos. No hay atributos cambiantes (a), el problema no es el volumen (b) ni la forma anidada del dato (d).

</details>

**Pregunta 2** · Básica · *El relacional sigue siendo excelente*

¿Cuál es, según la clase, el punto de partida profesional para pensar la transición hacia NoSQL?

- a) Reemplazar el motor relacional apenas aparece un dato semiestructurado, porque ACID limita la escala y la flexibilidad del esquema.
- b) Preguntarse qué parte del problema representa mejor cada modelo, sin descartar lo que el relacional ya resuelve.
- c) Elegir entre SQL y NoSQL al inicio del proyecto, porque mezclar modelos en un mismo sistema es un antipatrón.
- d) Usar NoSQL para todo lo nuevo y dejar el relacional solo para los sistemas heredados que no se pueden migrar.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La clase insiste en que NoSQL **no invalida** lo aprendido: ACID, integridad, SQL y una operación madura siguen siendo fortalezas. La pregunta no es "SQL contra NoSQL", sino **qué parte del problema representa mejor cada modelo**. Las demás opciones parten de un reemplazo total (a, d) o niegan la persistencia políglota, que la clase presenta como una arquitectura válida (c).

</details>

**Pregunta 3** · Intermedia · *Caso A y caso B*

Dos sistemas tienen columnas opcionales. En el primero, la estructura casi no cambia y lo importante son las relaciones y las reglas entre entidades. En el segundo, cada entidad trae atributos distintos, aparecen atributos nuevos cada semana y el registro se consume completo. ¿Qué concluye la clase?

- a) Los dos deberían migrar a un motor documental, porque ambos tienen columnas que quedan en `NULL`.
- b) Ninguno necesita cambios: los `NULL` y los `ALTER TABLE` frecuentes son el costo normal del modelo relacional.
- c) El primero conviene flexibilizarlo con JSON y el segundo mantenerlo en tablas, porque las reglas exigen documentos.
- d) En el primero el relacional funciona muy bien; en el segundo conviene flexibilizar esa parte del esquema.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Es la distinción entre el **caso A** (esquema estable, dominan las relaciones y las invariantes: el relacional funciona muy bien) y el **caso B** (atributos que cambian por entidad y un agregado que se consume como unidad: conviene flexibilizar). "No todo dato variable exige NoSQL" (a), pero tampoco hay que convivir con migraciones constantes (b). La opción c invierte los casos.

</details>

**Pregunta 4** · Básica · *El modelo EAV*

Para un catálogo con atributos distintos por categoría, alguien propone una tabla `(producto_id, atributo, valor)` con todos los valores en texto. ¿Cuál es el problema principal de ese diseño?

- a) Pierde tipos y restricciones, y cada atributo filtrado exige un `JOIN`.
- b) Obliga a ejecutar un `ALTER TABLE` cada vez que aparece una categoría nueva en el catálogo.
- c) Deja la mayoría de las celdas en `NULL`, porque cada fila tiene una columna por atributo posible.
- d) No se puede indexar, porque los motores relacionales no admiten índices sobre tablas de tres columnas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** El modelo **entidad-atributo-valor** guarda todo como texto (sin tipos ni `CHECK`) y convierte cada filtro en un `JOIN` contra la misma tabla. La opción b describe la tabla por categoría, y la c, la tabla ancha de 80 columnas. La d es falsa: la tabla EAV se puede indexar, el problema es otro.

</details>

**Pregunta 5** · Básica · *Datos semiestructurados*

¿Qué significa que un dato sea **semiestructurado**?

- a) Que no tiene ninguna estructura interna y requiere técnicas de interpretación, como el texto libre o el audio.
- b) Que tiene estructura, pero flexible, anidada o autocontenida, como XML, JSON o un evento.
- c) Que tiene un esquema explícito y estable, con tablas, columnas, tipos y restricciones declaradas.
- d) Que está incompleto: le faltan columnas obligatorias y debe normalizarse antes de guardarse.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La clase distingue tres formas: **estructurados** (esquema explícito y estable, c), **semiestructurados** (estructura presente pero flexible, anidada o autocontenida) y **no estructurados** (texto libre, imagen, audio, a). "Semiestructurado no significa sin estructura". La d no es ninguna de las categorías.

</details>

**Pregunta 6** · Intermedia · *XML*

¿Qué afirmación sobre XML coincide con la clase?

- a) Fue reemplazado por JSON en todos los ámbitos y hoy solo tiene interés histórico.
- b) Es un formato tabular: cada elemento equivale a una columna y cada documento, a una fila.
- c) Es un árbol autodescriptivo que un XSD puede validar, y sigue vigente en integraciones y sistemas heredados.
- d) No admite anidamiento: para representar jerarquías hay que usar atributos con identificadores que apunten a otros elementos del documento.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** XML es el **antecedente importante**: estructura **jerárquica** (elementos anidados y atributos), **autodescriptiva** y **validable** con un esquema **XSD**. La clase aclara que sigue siendo relevante en integraciones empresariales, mensajería y sistemas heredados, así que la a es falsa. La b y la d contradicen su naturaleza de árbol.

</details>

**Pregunta 7** · Intermedia · *JSON es una representación*

Un compañero dice: "Si guardamos JSON, ya somos NoSQL". ¿Qué le respondería la clase?

- a) Tiene razón: guardar JSON convierte a cualquier motor en una base documental, con sus garantías y sus límites.
- b) Tiene razón solo si el motor guarda el JSON en binario, como `jsonb` o BSON.
- c) Se equivoca, porque los motores relacionales no pueden almacenar JSON y deberían usar XML.
- d) Se equivoca: JSON es una representación, no un modelo ni una arquitectura NoSQL.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La clase lo dice textual: **JSON es una representación**; no es por sí mismo un modelo de base de datos ni una arquitectura NoSQL. MySQL y PostgreSQL guardan JSON sin dejar de ser relacionales, y un motor NoSQL puede no usar JSON. El formato interno (b) no cambia eso, y la c es falsa.

</details>

**Pregunta 8** · Intermedia · *Relación frente a agregado*

Al pasar de pensar en **relaciones** a pensar en **agregados**, ¿cuál es la pregunta de diseño que cambia?

- a) Pasa de "¿cómo evito redundancia?" a "¿qué datos se usan juntos y qué hay que preservar?".
- b) Pasa de "¿qué índices necesito?" a "¿qué motor es el más rápido para este volumen?".
- c) Pasa de "¿qué clave primaria uso?" a "¿cómo elimino todas las claves para ganar flexibilidad?".
- d) Pasa de "¿qué tablas uno?" a "¿cómo replico cada tabla en una colección con el mismo nombre?".

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** El relacional reparte el pedido en `CLIENTE`, `PEDIDO`, `ITEM` y `PRODUCTO` y lo reconstruye con `JOIN` y reglas entre tablas. El agregado es **un objeto autocontenido para un patrón de acceso**: la pregunta es qué datos se usan juntos. La d es justamente el antipatrón de traducir tablas 1:1; la b y la c no tienen relación con el agregado.

</details>

**Pregunta 9** · Intermedia · *JSON no resuelve todo*

Una plataforma ya guarda sus atributos variables en JSON, pero ahora necesita repartir varios terabytes de eventos entre muchos nodos y responder con baja latencia en tres continentes. ¿Qué dice la clase?

- a) Con JSON alcanza: al no tener esquema fijo, el motor reparte los documentos entre nodos sin configuración adicional ni decisiones de partición.
- b) JSON ayuda con la estructura, pero no resuelve la distribución ni la escala: esas tensiones piden otros mecanismos.
- c) Hay que volver a columnas tipadas, porque JSON es incompatible con la replicación y el sharding.
- d) Alcanza con agregar un índice `GIN` o una columna generada sobre los atributos más consultados.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** JSON resuelve atributos variables, jerarquía y propiedades opcionales. **No resuelve** distribución, recorridos, caché ni escala: "NoSQL no puede reducirse a guardar JSON". Un índice (d) acelera consultas, no reparte datos; JSON no se distribuye solo (a) ni es incompatible con la replicación (c).

</details>

**Pregunta 10** · Básica · *Multimodelo o persistencia políglota*

¿Qué situación describe una base **multimodelo**?

- a) Un relacional para los pedidos, Redis para las sesiones y Neo4j para las recomendaciones, sincronizados por eventos.
- b) Dos instancias del mismo motor, una para lectura y otra para escritura, con replicación entre ellas.
- c) Un solo motor que soporta varios modelos: tablas, JSON, texto y espacial.
- d) Un motor relacional que guarda imágenes, audio y video en columnas binarias junto a los datos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** **Multimodelo** es **un motor** con varios modelos, como MySQL con `JSON`, Document Store, `FULLTEXT` y Spatial, o PostgreSQL con `jsonb`, arrays, `hstore` y `tsvector`. La a es **persistencia políglota** (varios motores). La b es replicación y la d, almacenamiento de datos no estructurados.

</details>

**Pregunta 11** · Intermedia · *Columna generada sobre JSON*

En MySQL 9.7, la propiedad `marca` dentro de una columna `JSON` se filtra en casi todas las consultas. ¿Qué propone la clase?

- a) Convertir toda la columna `JSON` en texto y crear un índice `FULLTEXT` sobre ella.
- b) Crear una columna generada con `atributos->>'$.marca'` y un índice sobre esa columna.
- c) Crear un índice B-Tree directamente sobre la columna `JSON` completa.
- d) Pasar la propiedad a una tabla EAV, que se puede indexar mejor que un documento.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La propiedad interna se convierte en una **decisión de diseño físico**: `GENERATED ALWAYS AS (atributos->>'$.marca')` y un índice común. Así el optimizador tiene un índice para ese patrón de consulta, con su costo de escritura (conexión con la Unidad 2). MySQL no permite un índice B-Tree sobre la columna `JSON` entera (c); `FULLTEXT` es para buscar palabras (a) y EAV es un antipatrón (d).

</details>

**Pregunta 12** · Intermedia · *Las piezas del Document Store*

¿Qué combinación describe correctamente el Document Store de MySQL?

- a) El X Plugin del servidor atiende el X Protocol en el puerto 33060, y los clientes usan la X DevAPI (MySQL Shell o conectores).
- b) El X Protocol reemplaza al protocolo clásico en el puerto 3306, y por eso los clientes SQL dejan de funcionar al activarlo.
- c) La X DevAPI se instala en el servidor y traduce cada documento a una tabla nueva con una columna por campo.
- d) Es un motor separado que se instala aparte de MySQL y sincroniza sus colecciones con las tablas InnoDB.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Cliente → **X DevAPI** (MySQL Shell, conectores) → **X Protocol** (33060) → **X Plugin** en el mismo servidor → colecciones y documentos. El protocolo clásico sigue en el **3306** (b). No es un motor aparte (d), y una colección no crea una columna por campo (c): es una tabla con una columna `JSON`.

</details>

**Pregunta 13** · Desafío · *"MySQL no se convierte en MongoDB"*

¿Qué quiere decir la clase con que el Document Store "no convierte a MySQL en MongoDB"?

- a) Que el Document Store solo admite lecturas: las escrituras documentales siguen haciéndose con SQL sobre las tablas de InnoDB.
- b) Que es otra interfaz sobre el mismo motor, con las garantías ACID del servidor.
- c) Que el Document Store pierde las transacciones, porque los documentos no tienen esquema fijo.
- d) Que hay que migrar los datos a MongoDB para usar colecciones, porque MySQL solo las emula en memoria.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** El Document Store ofrece **CRUD documental sin abandonar las capacidades ACID** del servidor: por dentro, cada colección es una tabla InnoDB. Por eso es una interfaz **adicional**, no otro motor. Admite altas, modificaciones y bajas (`add`, `modify`, `remove`), así que la a es falsa; no pierde transacciones (c) ni vive en memoria (d).

</details>

**Pregunta 14** · Intermedia · *JSON Duality Views*

¿Qué resuelven las **JSON Duality Views** de MySQL 9?

- a) Copian los datos de las tablas a una colección documental aparte y la mantienen sincronizada con un proceso programado que corre cada pocos minutos.
- b) Permiten guardar dos versiones de cada documento JSON para comparar cambios en el tiempo.
- c) Convierten una columna `JSON` en varias columnas relacionales de forma permanente.
- d) Exponen tablas relacionales como documentos JSON jerárquicos, que se leen y se escriben con los dos modelos sin duplicar datos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Los datos viven en **tablas normalizadas** (con PK y FK) y la vista los expone como documentos; con la anotación `WITH (INSERT, UPDATE, DELETE)` también se escribe a través del documento. Por eso la clase dice que unifican la representación relacional y la jerárquica **sin duplicar** los datos, a diferencia de una copia sincronizada (a). La b y la c no describen la característica.

</details>

**Pregunta 15** · Básica · *`json` y `jsonb`*

¿Por qué la documentación de PostgreSQL recomienda `jsonb` para la mayoría de las aplicaciones?

- a) Porque conserva exactamente el texto de entrada, con espacios, orden de claves y claves duplicadas.
- b) Porque es el único de los dos tipos que valida que el contenido sea JSON válido al insertarlo.
- c) Porque guarda una representación binaria descompuesta: se procesa más rápido y admite indexación con `GIN`.
- d) Porque ocupa siempre menos espacio en disco que `json`, aunque a cambio no permite consultar claves internas ni usar operadores.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** `json` guarda una **copia del texto** y lo reprocesa en muchas operaciones; `jsonb` guarda una representación **descompuesta y binaria**, más eficiente, que admite índices `GIN`. La a describe a `json`, no a `jsonb`. Los dos validan el contenido (b), y `jsonb` sí permite consultar claves internas (d).

</details>

**Pregunta 16** · Intermedia · *El índice `GIN`*

¿Qué tiene de distinto un índice `GIN` sobre una columna `jsonb` respecto de un B-Tree sobre una columna común?

- a) Ordena los documentos completos de menor a mayor, y por eso sirve para rangos y `ORDER BY`.
- b) Es un índice invertido: guarda cada componente del documento con la lista de filas donde aparece.
- c) Guarda un resumen de cada página de la tabla, para descartar bloques enteros en un recorrido.
- d) Solo indexa la primera clave de cada documento, como un prefijo izquierdo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** `GIN` (*Generalized Inverted Index*) es un **índice invertido**: "marca → filas", "rojo → filas", "portable → filas". Por eso sirve para buscar claves, valores y **contención** en muchos documentos con un solo índice. "El documento sigue en una fila, pero el acceso ya no se parece a un B-Tree por columna" (a). La c describe un índice BRIN y la d no existe.

</details>

**Pregunta 17** · Desafío · *Operadores que usa el `GIN`*

Existe `CREATE INDEX ON productos USING gin (atributos jsonb_path_ops)`. ¿Qué consulta puede usar ese índice?

- a) `WHERE atributos->>'ram_gb' = '16'`
- b) `WHERE atributos ? 'gpu'`
- c) `WHERE (atributos->>'litros')::int BETWEEN 300 AND 400`
- d) `WHERE atributos @> '{"ram_gb": 16}'`

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** El `GIN` acelera **operadores**, no expresiones: con `jsonb_path_ops` solo atiende `@>`, `@?` y `@@`. La a compara un texto extraído con `->>` y no lo usa. La b (existencia de clave) necesitaría la clase por defecto `jsonb_ops`. Un rango numérico (c) necesita un índice B-Tree de expresión.

</details>

**Pregunta 18** · Intermedia · *La extensibilidad de PostgreSQL*

¿Cómo se acerca PostgreSQL al multimodelo, según la clase?

- a) Con una API documental separada que escucha en otro puerto, para trabajar con colecciones fuera del SQL.
- b) Con tipos, operadores, índices y extensiones integradas al SQL.
- c) Incorporando un motor clave-valor en memoria que reemplaza al almacenamiento en disco.
- d) Convirtiendo cada tabla en un grafo de propiedades cuando se activa una extensión.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** PostgreSQL se extiende **dentro del SQL**: arrays nativos, `hstore` (extensión clave-valor), texto completo con `tsvector` y extensiones como `pg_trgm` o PostGIS. La API documental separada (a) es el camino de MySQL con el Document Store. La c y la d no describen nada de PostgreSQL.

</details>

**Pregunta 19** · Intermedia · *Dos caminos*

¿Cuál de estos pares MySQL 9.7 / PostgreSQL 18 coincide con la tabla "dos caminos" de la clase?

- a) Clave-valor: Document Store con X DevAPI en MySQL; arrays nativos con operadores de contención en PostgreSQL.
- b) Spatial: sin soporte en MySQL; nativo en el núcleo de PostgreSQL.
- c) Índice documental: columnas generadas o índices de expresión en MySQL; `GIN` sobre `jsonb` en PostgreSQL.
- d) API documental: SQL con tipos y extensiones en MySQL; Document Store con X DevAPI y colecciones en PostgreSQL.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** En la tabla, el índice documental es "generadas, expresiones y otros" en MySQL y "`GIN` sobre `jsonb`" en PostgreSQL. Clave-valor es un documento JSON en MySQL y `hstore` en PostgreSQL (a). Spatial es nativo en MySQL y va por tipos y extensiones (PostGIS) en PostgreSQL (b). La d invierte los motores. Lema: "comparar capacidades, no memorizar nombres".

</details>

**Pregunta 20** · Básica · *Escalar vertical u horizontalmente*

¿Qué diferencia hay entre *scale up* y *scale out*?

- a) *Scale up* agrega nodos que comparten los datos; *scale out* agrega CPU y RAM al mismo servidor.
- b) *Scale up* agrega CPU, RAM o disco al mismo servidor; *scale out* agrega nodos que comparten datos y carga.
- c) Son sinónimos: los dos describen la replicación de un servidor primario en varias réplicas.
- d) *Scale up* es exclusivo de los motores NoSQL y *scale out* es exclusivo de los relacionales, porque solo ellos tienen transacciones.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Escalar **verticalmente** es agrandar el mismo servidor; **horizontalmente**, sumar nodos. La segunda opción trae la pregunta nueva de la clase: cómo particionar, replicar y mantener una visión consistente. La a invierte los términos, no son sinónimos (c) y ninguno es exclusivo de una familia (d).

</details>

**Pregunta 21** · Intermedia · *Replicación y sharding*

¿Qué afirmación distingue correctamente replicación y sharding?

- a) En la replicación cada nodo guarda solo una parte de los datos; en el sharding cada nodo guarda una copia completa para tolerar fallas.
- b) La replicación reparte la escritura entre nodos y el sharding solo sirve para respaldos.
- c) La replicación mantiene copias para disponibilidad y lectura; el sharding reparte fragmentos según una clave de partición.
- d) Son alternativas excluyentes: un sistema que usa sharding no puede replicar sus fragmentos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** La **replicación** (primario y réplicas) da disponibilidad, lectura y recuperación; el **sharding** reparte volumen y carga entre fragmentos según una *shard key*. La a los invierte. En la práctica se combinan: cada fragmento suele ser un conjunto replicado (d). La b es falsa en las dos mitades.

</details>

**Pregunta 22** · Desafío · *Una mala shard key*

Una tienda fragmenta sus pedidos por `fecha_pedido` en rangos. ¿Qué riesgo señala la clase?

- a) Ninguno: cualquier campo con muchos valores distintos es una buena clave de partición.
- b) Que los pedidos de un mismo cliente queden en el mismo fragmento y se pierda la integridad referencial.
- c) Que el motor rechace la fragmentación, porque las fechas no se pueden usar como clave.
- d) Que todas las escrituras nuevas caigan en el fragmento de las fechas recientes y concentren el tráfico.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Una *shard key* **mala** concentra el tráfico o complica las consultas. Con una fecha creciente, todo pedido nuevo va al último rango: un fragmento caliente mientras los demás descansan. Tener muchos valores no alcanza (a). La b no es un riesgo del sharding y la c es falsa.

</details>

**Pregunta 23** · Intermedia · *ACID y BASE*

¿Por qué la clase dice que ACID y BASE "no son etiquetas de familias"?

- a) Porque hay motores NoSQL con transacciones fuertes y motores relacionales distribuidos con distintos compromisos de consistencia.
- b) Porque ACID y BASE son sinónimos en la práctica: los dos garantizan consistencia inmediata entre todas las réplicas del sistema.
- c) Porque BASE es una norma ISO que todos los motores deben cumplir, igual que SQL.
- d) Porque los motores relacionales no ofrecen ACID cuando se ejecutan en la nube.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** ACID describe propiedades de **transacciones**; BASE es un **enfoque histórico** de algunos sistemas distribuidos (disponibilidad básica, estado flexible, consistencia eventual). La simplificación "SQL = ACID / NoSQL = BASE" falla: MongoDB o Neo4j tienen transacciones, y hay relacionales distribuidos con consistencia ajustable. La b, la c y la d son falsas.

</details>

**Pregunta 24** · Intermedia · *La decisión de CAP*

Según la clase, ¿cuándo aparece la decisión que plantea el teorema CAP?

- a) Al diseñar el esquema: hay que elegir dos de las tres propiedades antes de crear las tablas, y esa elección ya no se puede cambiar.
- b) Cuando la red separa nodos: responder con datos quizá viejos o rechazar operaciones.
- c) Cuando el motor se queda sin memoria y debe elegir qué claves expulsar.
- d) Solo en los motores relacionales, porque los NoSQL ya eligieron disponibilidad por diseño.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La decisión aparece **en presencia de una partición real** de la red. La pregunta útil de la clase: si dos grupos de nodos no se comunican, ¿respondemos con datos potencialmente desactualizados, o esperamos y rechazamos operaciones para proteger la consistencia? No es un menú previo (a), no tiene que ver con la memoria (c) y no hay una elección fija por familia (d).

</details>

**Pregunta 25** · Intermedia · *Qué significa NoSQL*

¿Cuál de estas afirmaciones sobre NoSQL es correcta según la clase?

- a) Significa "sin SQL": ningún motor NoSQL ofrece un lenguaje de consulta declarativo.
- b) Garantiza que no hay transacciones entre registros, y justamente por eso escala mejor que cualquier motor relacional.
- c) Elimina el diseño: como no hay esquema fijo, el modelo se ajusta solo a las consultas.
- d) Es una familia de sistemas con modelos distintos del relacional, que exige pensar desde el patrón de datos y de acceso.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** NoSQL **no significa** "sin SQL" necesariamente (Cassandra tiene CQL), **no garantiza** que no existan transacciones y **no elimina** el diseño ni los *trade-offs*. Lo que **sí exige** es pensar desde el patrón de datos y de acceso. Las opciones a, b y c son las tres simplificaciones que la clase desarma.

</details>

**Pregunta 26** · Intermedia · *Las cuatro familias*

Un comercio necesita: sesiones que expiran, un catálogo de forma variable, millones de eventos por usuario y detección de fraude por conexiones. ¿Qué asignación hace la clase?

- a) Clave-valor, documental, *wide-column* y grafo, en ese orden.
- b) Documental, clave-valor, grafo y *wide-column*, en ese orden.
- c) Un relacional para todo, porque cuatro motores son siempre demasiados.
- d) *Wide-column* para todo, porque es la única familia que escala horizontalmente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La tabla "un mismo sistema puede tener varios problemas": sesión y carrito → **clave-valor**; catálogo flexible → **documental**; eventos masivos → **wide-column**; fraude y conexiones → **grafo**; y pedidos y pagos se quedan en el **relacional**. La clase no impone un motor único (c, d): la tecnología se elige por patrón, no por moda.

</details>

**Pregunta 27** · Desafío · *Wide-column no es column-store*

¿Qué aclara la clase sobre el modelo *wide-column*?

- a) Que es lo mismo que un *column-store* analítico, pensado para agregar columnas enteras en consultas de reportes.
- b) Que guarda cada columna en un archivo distinto del disco y por eso no admite escrituras frecuentes ni inserciones masivas.
- c) Que no es un *column-store* analítico: su diseño gira alrededor de la partición, la distribución y las consultas previstas.
- d) Que es un modelo relacional con más columnas por tabla, sin cambios en la forma de consultar.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El "punto conceptual" de la clase: *wide-column* (Cassandra) **no** es un *column-store* analítico (a). Se diseña desde la **clave de partición** y las consultas previstas, y soporta escritura masiva (b es falsa). Tampoco es "un relacional con más columnas" (d): no tiene `JOIN` ni consultas arbitrarias.

</details>

**Pregunta 28** · Intermedia · *El árbol de decisión*

Un catálogo heterogéneo ya funciona en PostgreSQL. Los atributos variables se guardan en `jsonb` con un índice `GIN` y las consultas responden con el plan esperado. Siguiendo el árbol de decisión de la clase, ¿qué corresponde?

- a) Migrar a un motor documental, porque los atributos variables siempre piden un modelo especializado aunque el plan actual responda bien.
- b) Quedarse en el relacional extendido: la extensión alcanza para el problema.
- c) Agregar un motor de grafos, porque los productos se relacionan con categorías.
- d) Volver a una tabla ancha, porque `jsonb` no forma parte del modelo relacional.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** El árbol: ¿el relacional representa bien? No → ¿alcanza una extensión? **Sí** → `jsonb`, Document Store, Full Text... Solo si la extensión no alcanza se pasa a un modelo especializado (a). La pregunta de cierre de la clase es justamente si se elige tecnología **por moda** o porque el problema lo pide. La c y la d no tienen fundamento.

</details>

**Pregunta 29** · Intermedia · *Los criterios de la actividad*

En la actividad de la unidad, un grupo habilitó una capacidad, mostró una consulta que funciona, pero no explicó qué limitación del relacional resolvía ni qué costo agregaba. ¿Cómo se evalúa?

- a) Logrado: la capacidad funciona y eso es lo que pide la actividad.
- b) Parcial: la capacidad funciona, pero la decisión o la evidencia es incompleta.
- c) No logrado, porque toda actividad sin un motor NoSQL instalado queda desaprobada.
- d) Logrado, siempre que la capacidad sea *Core* y no requiera instalar nada.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La meta no era "hacer funcionar una *feature*", sino justificar **problema, capacidad, evidencia, costo y veredicto**. "La capacidad funciona, pero la decisión o la evidencia es incompleta" es la definición de **parcial**. Logrado exige justificar con evidencia **y costos** (a, d). No hacía falta instalar NoSQL (c).

</details>

**Pregunta 30** · Desafío · *Claves ausentes en un documento*

Tres notebooks: una con `gpu` "integrada", otra con `gpu` "RTX 4060" y un ultrabook sin la clave `gpu`. ¿Qué devuelve `WHERE atributos->>'gpu' <> 'integrada'` (igual en MySQL con `'$.gpu'`)?

- a) Las dos que no tienen GPU integrada: la de RTX y el ultrabook, porque una clave ausente nunca es igual a 'integrada'.
- b) Un error, porque el ultrabook no tiene la clave que se consulta.
- c) Solo la de RTX: en el ultrabook la comparación da `NULL`.
- d) Las tres, porque `<>` ignora las filas con valores ausentes.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Es la **lógica de tres valores** del Parcial 1 aplicada a JSON: la clave ausente da `NULL`, la comparación da "desconocido" y el `WHERE` descarta la fila. Para incluirlo hay que pedirlo (`OR ... IS NULL`, `IS DISTINCT FROM` en PostgreSQL, `<=>` en MySQL). No hay error (b) ni se incluyen las filas sin la clave (a, d).

</details>

**Pregunta 31** · Básica · *Buscar palabras en un texto*

`WHERE descripcion LIKE '%inalambrico%'` recorre toda la tabla aunque exista un índice B-Tree sobre `descripcion`. ¿Por qué un índice invertido de texto completo sí sirve?

- a) Porque el índice invertido guarda cada término con la lista de filas donde aparece, y no depende del comienzo del valor.
- b) Porque el índice invertido ordena las descripciones completas alfabéticamente, igual que un B-Tree pero comprimido en disco.
- c) Porque el B-Tree solo funciona con columnas numéricas y la descripción es texto.
- d) Porque `LIKE` está deshabilitado en las columnas que tienen un índice de texto completo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** El B-Tree ordena **valores completos**: sirve para `=`, rangos y prefijos (`'inal%'`), pero con el comodín al inicio no hay por dónde entrar. El **índice invertido** (`FULLTEXT` en MySQL, `GIN` sobre `tsvector` en PostgreSQL) indexa **cada palabra**. La b describe al B-Tree, la c es falsa (el B-Tree indexa texto) y la d también.

</details>

**Pregunta 32** · Desafío · *Raíces de las palabras*

Se busca `juego` y la descripción del producto dice `juegos`. ¿Qué pasa en cada motor con su búsqueda de texto completo por defecto?

- a) Los dos lo encuentran, porque cualquier índice de texto completo reduce las palabras a su raíz antes de guardarlas en el índice.
- b) MySQL no lo encuentra, porque su `FULLTEXT` no reduce a raíces; PostgreSQL con la configuración `spanish` sí, porque las dos formas quedan como `jueg`.
- c) PostgreSQL no lo encuentra, porque `tsvector` exige la palabra exacta; MySQL sí lo encuentra, porque su colación ignora acentos y plurales.
- d) Ninguno lo encuentra: para eso hay que sumar siempre un buscador externo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** El `FULLTEXT` de InnoDB indexa palabras tal cual (`juego*` lo mitiga en parte). La configuración `spanish` de PostgreSQL aplica un diccionario **Snowball** que reduce a la raíz. La colación de MySQL ignora mayúsculas y acentos, no plurales (c). Por eso, en PostgreSQL, las raíces no justifican un buscador externo (d).

</details>

**Pregunta 33** · Intermedia · *Medir con pocos datos*

Con 20 filas, el plan de PostgreSQL muestra `Seq Scan` aunque existe un `GIN` adecuado. ¿Qué conclusión es correcta?

- a) El índice está mal creado y hay que borrarlo y volver a crearlo.
- b) Hay que dejar `enable_seqscan = off` también en producción, para forzar el uso del índice en todas las consultas futuras.
- c) El `GIN` no sirve para `jsonb` y conviene pasar a un motor documental.
- d) El optimizador acierta; hay que medir con más volumen.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Con muy pocas filas, recorrer la tabla es más barato que usar el índice, y el optimizador lo sabe. `enable_seqscan = off` sirve **solo para la prueba** (b). Por eso las resoluciones escalaron a miles de filas para mostrar el **cambio de plan**. El índice no está mal (a) y la c es falsa.

</details>

---

## Unidad 8 · MongoDB: de guardar JSON a diseñar agregados

**Pregunta 34** · Básica · *Las tres preguntas de diseño*

Para evitar que MongoDB sea "tablas convertidas a JSON", la clase propone empezar con tres preguntas. ¿Cuáles son?

- a) Qué se lee junto, qué cambia junto y qué puede crecer sin límite.
- b) Cuántas tablas tiene el modelo relacional de origen, cuántas claves foráneas tiene y cuántas colecciones hay que crear para cada una.
- c) Qué versión de MongoDB está instalada, cuánta memoria tiene el servidor y cuántos índices se pueden crear.
- d) Qué campos son obligatorios, qué tipos usa cada campo y qué nombres siguen la convención del equipo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** **Lecturas, cambios y crecimiento**: qué se recupera junto, qué cambia junto y qué puede crecer sin límite. Con esas respuestas se decide qué embeber y qué referenciar. La b es justamente la traducción 1:1 que hay que evitar; la c y la d son cuestiones de operación y de validación, no de diseño del agregado.

</details>

**Pregunta 35** · Básica · *Tipos BSON*

Una colección guarda importes de facturas que se suman y se comparan al centavo. ¿Qué tipo BSON corresponde?

- a) `Date`, porque cada importe está asociado a una fecha de facturación y conviene guardarlos juntos en el mismo campo.
- b) `ObjectId`, porque cada importe debe ser único dentro de la colección.
- c) `Array`, porque una factura puede tener varios importes.
- d) `Decimal128`, pensado para montos y cálculos financieros.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** BSON amplía JSON con tipos útiles para una base de datos: `ObjectId` (identificador de 12 bytes), `Date` (momento exacto en UTC), `Decimal128` (128 bits de precisión, para dinero), `Array` y `Object`. Un número de punto flotante común puede acumular errores de redondeo en sumas de dinero. Las demás opciones confunden el tipo con otros rasgos del dato.

</details>

**Pregunta 36** · Intermedia · *`_id` y `ObjectId`*

¿Qué recomienda la clase sobre el `_id` de un documento?

- a) Que siempre lo informe la aplicación, porque MongoDB no puede generarlo.
- b) Que se use la fecha codificada dentro del `ObjectId` como fecha de alta oficial del pedido, porque así no hace falta otro campo.
- c) Que es único y obligatorio, que se genera si no se informa y que no conviene apoyar reglas de negocio en la estructura interna del `ObjectId`.
- d) Que es opcional: los documentos sin `_id` se guardan igual y se identifican por posición.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Todo documento de una colección estándar tiene un `_id` **único**; si no se informa, el driver o MongoDB generan un `ObjectId`. La clase advierte que **no** conviene diseñar reglas de negocio sobre su estructura interna (b): el dato de negocio, como `nroPedido` o la fecha, va en su propio campo. La a y la d son falsas.

</details>

**Pregunta 37** · Intermedia · *Esquema flexible*

¿Qué quiere decir "esquema flexible ≠ ausencia de diseño"?

- a) Que el esquema flexible solo existe en las primeras versiones del sistema y después hay que congelarlo con tablas.
- b) Que los documentos pueden variar, pero la aplicación necesita nombres, tipos y reglas previsibles, y el motor puede validarlos.
- c) Que MongoDB rechaza cualquier documento que no tenga los mismos campos que el primero de la colección.
- d) Que el diseño se puede dejar para después de la primera carga, porque la flexibilidad del esquema corrige sola los nombres y los tipos distintos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Los documentos **pueden variar**, **deben ser coherentes** y **pueden validarse** (`$jsonSchema`). "La flexibilidad sirve para evolucionar; no justifica almacenar cualquier cosa". MongoDB no impone los campos del primer documento (c), el diseño no se posterga (d) ni hay que congelarlo (a).

</details>

**Pregunta 38** · Intermedia · *El agregado como frontera*

Un pedido tiene cabecera, dirección de entrega, ítems y totales, y siempre se muestra y se confirma completo. ¿Qué dice la clase?

- a) Hay que separar cada parte en su colección, porque un documento no debe tener más de un nivel de anidamiento.
- b) Hay que referenciar los ítems, porque cualquier array dentro de un documento es un antipatrón.
- c) Conviene guardar solo la cabecera y calcular los totales en cada lectura con un `$lookup`.
- d) Que, si se lee y persiste como una unidad, el documento puede ser esa frontera.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** "Lo que se lee y cambia junto suele vivir junto": si el pedido se lee y persiste como unidad, **el documento es la frontera del agregado**. Solo si una relación crece o cambia por separado conviene referenciar. Tener arrays no es el problema (b): el problema es que crezcan sin límite. La a y la c no tienen fundamento.

</details>

**Pregunta 39** · Intermedia · *Diseñar desde los patrones de acceso*

¿En qué orden propone la clase diseñar una base documental?

- a) Diseñar el documento, cargar datos de prueba, medir con `explain()` y recién después listar las consultas.
- b) Copiar el diagrama entidad-relación, crear una colección por tabla y agregar índices sobre cada clave foránea.
- c) Listar las consultas, identificar las escrituras, medir la cardinalidad y recién después diseñar el documento.
- d) Elegir los índices, definir el validador y dejar que los documentos tomen la forma que necesite cada inserción.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** "Primero preguntas; después estructura": **consultas** (qué lecturas son frecuentes y críticas), **escrituras** (qué cambia junto), **cardinalidad** (¿uno a pocos o a millones?) y, al final, el **documento** (embeber, referenciar o duplicar). La b es la traducción 1:1 y la a y la d invierten el orden.

</details>

**Pregunta 40** · Intermedia · *La "foto" del momento de compra*

¿Por qué la clase embebe en el pedido la descripción y el precio unitario de cada ítem, en lugar de referenciar solo el producto?

- a) Porque el pedido debe conservar el estado histórico: si el producto cambia de precio, el pedido pasado no cambia.
- b) Porque MongoDB no permite guardar referencias a documentos de otra colección.
- c) Porque embeber siempre ocupa menos espacio que referenciar.
- d) Porque así el precio del catálogo se actualiza solo en todos los pedidos cuando cambia, sin tener que recorrerlos con un `updateMany`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** El ítem es una **"foto" del momento de compra**. Referenciar siempre al producto actual podría alterar la interpretación del pedido pasado (si el teclado sube de precio, el pedido mostraría un total que nunca se cobró). La d describe justamente lo que **no** se quiere. MongoDB sí admite referencias (b), y embeber no siempre ocupa menos (c).

</details>

**Pregunta 41** · Intermedia · *Referenciar al cliente*

En el ejemplo de la clase, el pedido guarda `clienteId` y el cliente vive en su propia colección. ¿Qué lo justifica?

- a) Que el cliente tiene muchos campos, y los documentos con muchos campos anidados no pueden embeberse dentro de otro documento.
- b) Que los datos personales nunca deben guardarse en MongoDB.
- c) Que referenciar garantiza la integridad referencial, como una clave foránea.
- d) Que el cliente tiene vida propia y cambia por separado.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Se referencia lo que **vive y cambia por separado**, tiene alta cardinalidad o lo **comparten** muchos documentos. Si el cliente estuviera copiado en cada pedido, cambiar su email obligaría a actualizar todas las copias. Una referencia en MongoDB **no** es una clave foránea: el motor no garantiza la integridad (c). La a y la b son falsas.

</details>

**Pregunta 42** · Desafío · *Uno a muchísimos*

Un dispositivo IoT envía una medición por segundo durante años. ¿Qué diseño corresponde según la clase?

- a) Embeber todas las mediciones en un array dentro del documento del dispositivo, para leerlas de una sola vez.
- b) Guardar solo la última medición y descartar el resto, porque MongoDB no admite series largas.
- c) Una colección separada para las mediciones, preferiblemente con el patrón *bucket* o una colección *time series*.
- d) Un documento por dispositivo con un array de mediciones, que se recorta cuando supera los 16 MB.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Es **uno a muchísimos** (logs, telemetría, historial continuo): hay que evitar los arrays no acotados y **separar** o usar patrones específicos. Es la respuesta del microdesafío de la clase para IoT. La a y la d crean un array sin cota que se acerca al límite de 16 MB. La b pierde datos sin motivo.

</details>

**Pregunta 43** · Desafío · *Por qué un array sin cota es un problema*

¿Qué argumento es correcto contra un array que crece sin límite dentro de un documento?

- a) Se acerca al límite de 16 MB por documento, cada lectura lo trae entero a la caché y mantenerlo y sus índices se encarece.
- b) El motor WiredTiger mueve el documento a otro lugar del disco cada vez que crece, y eso fragmenta la colección.
- c) MongoDB no permite más de 100 elementos en un array, y la escritura número 101 falla con un error de validación del documento.
- d) Los arrays no se pueden indexar, así que cualquier búsqueda dentro de ellos recorre la colección.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Tamaño (16 MB), caché (*working set*) y costo de mantenimiento son los argumentos actuales. La b es una trampa: "mover el documento cuando crece" era un argumento del motor viejo **MMAPv1**, no de WiredTiger. No hay límite de 100 elementos (c), y los arrays se indexan con índices multiclave (d).

</details>

**Pregunta 44** · Intermedia · *Duplicación controlada*

¿Cuándo justifica la clase duplicar un dato en varios documentos?

- a) Siempre: desnormalizar es el objetivo principal del modelo documental, y cuantas más copias haya, menos `$lookup` hacen falta.
- b) Cuando ganar en lectura compensa mantener las copias.
- c) Solo cuando el dato es un `ObjectId`, porque es inmutable.
- d) Nunca: duplicar datos es un error de diseño en cualquier modelo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La clase llama a la desnormalización "una negociación permanente, no un objetivo". **Beneficio:** menos lecturas cruzadas. **Costo:** más espacio y decidir cómo sincronizar. **Regla:** duplicar cuando el beneficio de lectura supera el costo de mantener la consistencia. Ni siempre (a) ni nunca (d); la c no tiene sentido.

</details>

**Pregunta 45** · Intermedia · *SQL traducido 1:1*

Un equipo creó las colecciones `clientes`, `pedidos`, `items`, `productos` y `direcciones`, con referencias entre todas, y cada pantalla encadena varios `$lookup`. ¿Qué diagnóstico hace la clase?

- a) Es el diseño recomendado, porque evita toda duplicación de datos y cada colección queda pequeña y fácil de indexar.
- b) Es correcto si cada colección tiene un validador `$jsonSchema`.
- c) Es el antipatrón "SQL traducido 1:1": reconstruye el agregado como si fueran `JOIN` y no aprovecha el modelo documental.
- d) Es correcto solo si el clúster tiene más de tres nodos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** "Muchas colecciones pequeñas + referencias para todo": si cada lectura obliga a reconstruir el agregado con `$lookup`, no se aprovechó el modelo documental. Se obtiene lo peor de los dos mundos: ni integridad declarativa ni lectura de una sola vez. En los criterios de logro, "traducción 1:1 del relacional" es **no logrado**. La validación (b) y la topología (d) no cambian eso.

</details>

**Pregunta 46** · Intermedia · *Microdesafío: el catálogo*

Para un catálogo con producto, categorías y stock, ¿qué decisión da la clase en el microdesafío?

- a) Híbrida: referenciar las categorías y embeber el stock.
- b) Embeber las categorías completas en cada producto y guardar el stock en otra colección, porque el stock cambia más seguido que las categorías.
- c) Una colección *time series* para el stock, porque cambia con el tiempo.
- d) Referenciar todo, porque el catálogo es una entidad con vida propia.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** El microdesafío resuelve tres casos: **perfil de usuario → embeber**, **catálogo → híbrido** (referenciar categorías + embeber stock) e **IoT → colección separada** (*bucket* o *time series*). La b invierte la lógica; la c confunde un valor que cambia con una serie de mediciones; la d vuelve a la traducción 1:1.

</details>

**Pregunta 47** · Básica · *Herramientas*

¿Qué herramienta usa una aplicación en Python o Node.js para trabajar con MongoDB?

- a) Compass, el cliente gráfico, que la aplicación invoca para cada consulta.
- b) mongosh, la shell interactiva.
- c) `mongodump`, la herramienta de respaldo.
- d) Los *drivers* oficiales, las APIs de cada lenguaje.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** "Mismo motor, distintas interfaces": **mongosh** para comandos y scripts, **Compass** para explorar datos, consultas, índices y *pipelines* en forma gráfica, y los **drivers** (Java, Python, Node.js, C#) para las aplicaciones. `mongodump` es una herramienta de respaldo (c).

</details>

**Pregunta 48** · Básica · *Filtro y proyección*

En `db.pedidos.find({ estado: "nuevo" }, { nroPedido: 1, total: 1, _id: 0 })`, ¿qué hace el segundo argumento?

- a) Ordena el resultado por `nroPedido` y `total` de forma ascendente, y excluye `_id` del ordenamiento.
- b) Agrega los campos `nroPedido` y `total` a los documentos que no los tienen.
- c) Es la proyección: devuelve solo `nroPedido` y `total`, sin `_id`.
- d) Filtra los pedidos cuyo `nroPedido` y `total` valen 1.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El primer argumento es el **filtro** (≈ `WHERE`) y el segundo, la **proyección** (≈ las columnas del `SELECT`); `_id: 0` lo excluye, porque sale por defecto. Ordenar es tarea de `sort()` sobre el cursor (a). La proyección no modifica datos (b) ni filtra (d).

</details>

**Pregunta 49** · Intermedia · *Operadores de actualización*

Al confirmar un pago hay que cambiar el estado, sumar 1 a `intentosPago` y agregar un evento al historial del pedido. ¿Qué escritura corresponde?

- a) Un `updateOne` con `$set`, `$inc` y `$push`.
- b) Un `replaceOne` con el documento completo armado en la aplicación, para no depender de operadores.
- c) Un `deleteOne` seguido de un `insertOne` con el pedido actualizado.
- d) Un `insert()` sobre el mismo `_id`, que reemplaza al documento anterior.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** "Los operadores expresan la intención del cambio": `$set`, `$inc` (atómico, ideal para contadores) y `$push`, en una sola operación sobre un documento, que además es atómica. `replaceOne` (b) pisa todo y pierde cambios concurrentes; borrar e insertar (c) no es atómico; el viejo `insert()` fue reemplazado y no actualiza (d).

</details>

**Pregunta 50** · Intermedia · *Borrar con intención explícita*

Antes de ejecutar `deleteMany({ estado: "cancelado", fecha: { $lt: ISODate("2025-01-01") } })`, ¿qué práctica recomienda la clase?

- a) Desactivar los índices de la colección para que el borrado sea más rápido.
- b) Ejecutar `drop()` sobre la colección y volver a cargar solo los documentos que se quieren conservar.
- c) Cambiar el filtro por `{}` para asegurarse de que no quede ningún documento inconsistente.
- d) Ejecutar el mismo filtro con `find()` o `countDocuments()` y guardar evidencia del conjunto afectado.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La **práctica segura**: comprobar con el mismo filtro qué se va a borrar y dejar evidencia. Las demás opciones son destructivas o arriesgadas: `drop()` (b) y `{}` (c) borran de más, y desactivar índices (a) no tiene relación con la seguridad del borrado.

</details>

**Pregunta 51** · Desafío · *`$elemMatch`*

Se buscan envíos que tengan **algún paquete frágil y de más de 10 kg**. Un envío tiene un paquete frágil de 3 kg y otro no frágil de 12 kg. ¿Qué consulta lo excluye correctamente?

- a) `{ "paquetes.fragil": true, "paquetes.peso_kg": { $gt: 10 } }`
- b) `{ $or: [ { "paquetes.fragil": true }, { "paquetes.peso_kg": { $gt: 10 } } ] }`
- c) `{ paquetes: { $elemMatch: { fragil: true, peso_kg: { $gt: 10 } } } }`
- d) `{ paquetes: { fragil: true, peso_kg: { $gt: 10 } } }`

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** `$elemMatch` exige que **el mismo elemento** cumpla todas las condiciones. Con la notación con punto (a), cada condición puede cumplirla un paquete distinto, y ese envío aparece. La b es todavía más amplia. La d compara contra un subdocumento exacto y no interpreta `$gt` como un operador dentro del arreglo.

</details>

**Pregunta 52** · Intermedia · *Índices con intención*

¿Qué criterio da la clase para crear un índice en MongoDB?

- a) Que una consulta concreta lo justifique.
- b) Crear un índice por cada campo de la colección, por si alguna consulta futura lo necesita, ya que los índices no afectan a las escrituras.
- c) No crear índices secundarios, porque `_id` alcanza para cualquier consulta.
- d) Crear índices solo después de pasar a un clúster fragmentado.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** "El índice debe responder a consultas reales": cada uno se mantiene en cada inserción, borrado y modificación del campo indexado, y compite por la caché. La pregunta de la clase es **qué consulta concreta justifica cada índice**. "Por si acaso" (b) es lo que se desaconseja; `_id` no sirve para filtros por otros campos (c); la d no tiene fundamento.

</details>

**Pregunta 53** · Intermedia · *Leer un `explain`*

`explain("executionStats")` muestra `COLLSCAN`, `totalDocsExamined: 200000` y `nReturned: 811`. ¿Qué se concluye?

- a) La consulta es óptima, porque devolvió todos los documentos pedidos y el plan no muestra ninguna etapa `SORT` en memoria.
- b) No hay un índice útil: recorrió toda la colección para devolver poco.
- c) Hay que aumentar la memoria del servidor, porque la colección no entra en la caché.
- d) El índice existe y se usó, pero está fragmentado.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** `COLLSCAN` es un recorrido completo. Lo ideal es que documentos examinados, claves examinadas y devueltos sean parecidos (`keys ≈ docs ≈ returned`): con el índice adecuado se pasa a `IXSCAN` y se examinan 811 para devolver 811. Con un índice usado, el plan diría `IXSCAN` (d). Más memoria (c) no corrige un plan malo.

</details>

**Pregunta 54** · Desafío · *Regla ESR*

Una consulta filtra `ruta` por igualdad, `fecha_despacho` por rango y ordena por `prioridad`. Siguiendo la regla ESR, ¿qué índice compuesto conviene?

- a) `{ fecha_despacho: 1, ruta: 1, prioridad: 1 }`
- b) `{ prioridad: 1, fecha_despacho: 1, ruta: 1 }`
- c) `{ ruta: 1, prioridad: 1, fecha_despacho: 1 }`
- d) `{ fecha_despacho: 1, prioridad: 1, ruta: 1 }`

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** **ESR**: primero la **igualdad** (*Equality*), después el **ordenamiento** (*Sort*) y al final el **rango** (*Range*). Es la regla del prefijo izquierdo del Parcial 1 con el orden en el medio. Empezar por el rango (a, d) obliga a recorrer las fechas de todas las rutas; empezar por el orden (b) no acota nada.

</details>

**Pregunta 55** · Intermedia · *`$unwind`*

En el *pipeline* de ventas por producto de la clase (`$match` → `$unwind: "$items"` → `$group` por `items.sku` → `$sort`), ¿qué hace `$unwind`?

- a) Abre el array: un documento por ítem.
- b) Elimina los pedidos que no tienen ítems, como un filtro previo al agrupamiento que reemplaza a `$match` en esa posición.
- c) Une la colección de pedidos con la de productos, como un `JOIN`.
- d) Ordena los ítems de cada pedido por importe antes de agruparlos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** `$match` reduce el conjunto, `$unwind` **abre el array**, `$group` calcula métricas y `$sort` ordena. Sin abrir el array, no se podría agrupar por ítem. Es cierto que, sin `preserveNullAndEmptyArrays`, descarta los documentos con el array vacío (b), pero esa no es su función. La unión es `$lookup` (c) y ordenar, `$sort` (d).

</details>

**Pregunta 56** · Intermedia · *El orden de las etapas*

¿Por qué conviene poner `$match` al comienzo de un *pipeline*?

- a) Porque MongoDB rechaza los *pipelines* que no empiezan con `$match`, salvo que el primero sea `$sort` sobre un índice.
- b) Porque `$match` es la única etapa que puede calcular sumas y promedios.
- c) Porque al final del *pipeline* `$match` se ignora.
- d) Porque reduce el conjunto temprano y puede usar un índice.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** "El orden de las etapas puede afectar el trabajo y el rendimiento": filtrar primero evita procesar documentos que se descartarían después, y solo al comienzo `$match` usa un índice. No es obligatorio (a), los cálculos son de `$group` (b), y al final funciona, solo que tarde (c).

</details>

**Pregunta 57** · Intermedia · *Validación en el motor*

Una diapositiva vieja decía que "en MongoDB toda la validación queda en la aplicación". ¿Qué dice la clase actual?

- a) Que es correcto, porque un motor sin esquema fijo no puede rechazar documentos.
- b) Que es incompleta: MongoDB valida en el motor con validadores por colección, como `$jsonSchema`, que exigen campos, tipos y reglas.
- c) Que es correcto solo para MongoDB Atlas; en una instalación propia sí se valida, porque se puede editar `mongod.conf`.
- d) Que la validación existe, pero solo para el campo `_id`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La clase lo aclara expresamente: MongoDB **sí** posee validación en el motor (`db.createCollection` o `collMod` con `validator: { $jsonSchema: ... }`), con campos requeridos, `bsonType` y reglas. Si un documento no cumple, la escritura se rechaza (código 121). La a, la c y la d son falsas.

</details>

**Pregunta 58** · Intermedia · *Atomicidad y transacciones*

¿Qué es atómico en MongoDB sin usar transacciones?

- a) Una escritura sobre un único documento, aunque toque varios campos.
- b) Cualquier conjunto de escrituras enviadas en el mismo `insertMany`, sobre cualquier cantidad de documentos.
- c) Nada: toda escritura necesita una transacción multidocumento para ser atómica.
- d) Las escrituras sobre la misma colección, aunque afecten a muchos documentos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** **Documento único:** atómico aunque toque varios campos. **Varios documentos:** existen transacciones multidocumento, pero requieren un replica set o un clúster fragmentado. Por eso "modelar bien puede reducir la necesidad de transacciones": lo que cambia junto, en un documento. Un `insertMany` no es atómico en conjunto (b), ni una colección entera (d).

</details>

**Pregunta 59** · Intermedia · *Replica set y sharded cluster*

¿Qué afirmación es correcta?

- a) En un replica set, `mongos` enruta cada consulta al nodo secundario que tiene el fragmento pedido, y los config servers eligen al primario.
- b) Un sharded cluster tiene un solo nodo, que divide sus datos en archivos por colección.
- c) Los config servers son las réplicas secundarias que atienden las lecturas.
- d) El replica set busca alta disponibilidad con elección automática; el sharded cluster, escalar horizontalmente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Son **dos problemas distintos**: el **replica set** mantiene copias para redundancia y alta disponibilidad, con elección automática ante una falla; el **sharded cluster** distribuye datos entre shards, con `mongos` como enrutador y los **config servers** con los metadatos. `mongos` es del clúster fragmentado, no del replica set (a); la b y la c son falsas.

</details>

**Pregunta 60** · Básica · *Lo mínimo en seguridad*

La clase lista cuatro mínimos que un DBA no puede omitir: autenticación, RBAC, red/TLS y backups. ¿Qué exige en el caso de los backups?

- a) Que se guarden en el mismo servidor, para restaurarlos más rápido.
- b) Que se hagan con `mongoexport`, porque el formato JSON es portable.
- c) Probar la restauración: un backup sin restore probado no alcanza.
- d) Que se activen solo en los clústeres de más de un nodo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** "Backup sin restore probado no alcanza". En el mismo servidor (a) se pierde junto con él; `mongoexport` (b) pierde los tipos BSON y los índices, así que no es un respaldo. Respaldar no depende de la cantidad de nodos (d).

</details>

**Pregunta 61** · Desafío · *Tres capas de acceso*

Un usuario se conecta, ejecuta `find()` sin problemas, pero `updateOne()` responde `not authorized on logistica to execute command`. ¿Qué capa falla?

- a) La autorización: el rol no permite modificar.
- b) La conexión: el firewall deja pasar las lecturas por el puerto 27017, pero bloquea las escrituras que viajan por otro puerto.
- c) La autenticación: la clave es incorrecta para las operaciones de escritura.
- d) El TLS: las escrituras requieren un certificado de cliente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Se diagnostica de abajo hacia arriba: si `find()` funciona, la **conexión** y la **autenticación** están bien. El rechazo es de **autorización** (código 13): un rol como `read` permite consultar pero no modificar. La solución, con mínimo privilegio, es otorgar `readWrite` sobre esa base. Un firewall no distingue lecturas de escrituras (b), y una clave incorrecta impediría todo (c).

</details>

**Pregunta 62** · Intermedia · *Activar la autenticación*

¿En qué orden se activa la autenticación en una instancia propia de MongoDB?

- a) Activar `security.authorization`, reiniciar el servicio y crear después el administrador desde cualquier máquina de la red del laboratorio.
- b) Crear el administrador, activar la autorización, reiniciar y verificar el rechazo.
- c) Activar la autorización sin reiniciar, porque el parámetro se aplica en caliente.
- d) Crear usuarios con `readWrite`, reiniciar y activar la autorización cuando haya un incidente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Primero el administrador, después la configuración, el reinicio y la **verificación del rechazo**. Si la autenticación ya está activa y no hay usuarios, la **excepción de localhost** permite crear el primero, pero solo desde el mismo servidor (no "desde cualquier máquina", a). Sin `authorization: enabled`, cualquiera ejecuta cualquier cosa aunque existan usuarios (d).

</details>

**Pregunta 63** · Desafío · *Probar un respaldo*

`mongorestore` sobre la misma base de origen responde `E11000 duplicate key` en cada documento. ¿Cuál es la forma segura de probar el respaldo?

- a) Repetir la restauración con `--drop`, que borra cada colección antes de restaurarla y así evita el conflicto con los `_id`.
- b) Borrar los índices únicos de la base de origen para que acepte los duplicados.
- c) Restaurar con otro nombre (`--nsFrom 'base.*' --nsTo 'base_restore.*'`) y comparar recuentos, contenido e índices con el original.
- d) Usar `mongoexport` y `mongoimport`, que no controlan los `_id` repetidos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Por defecto `mongorestore` **no sobrescribe**: los `_id` existentes fallan con `E11000`. Lo seguro es restaurar **en otro lugar** y validar: recuentos, los mismos `_id`, índices, validador y una consulta de negocio. `--drop` (a) es destructivo sobre el original; la b rompe la integridad; la d pierde los tipos BSON.

</details>

---

## Unidad 9 · Redis, Cassandra, Neo4j y CAP

**Pregunta 64** · Básica · *Tres modelos, tres preguntas*

Según la clase, ¿qué pregunta responde cada motor?

- a) Redis: ¿qué conexiones necesito recorrer? Cassandra: ¿qué dato recupero por una clave? Neo4j: ¿qué consultas escalan sobre volumen distribuido?
- b) Redis: ¿qué dato recupero por una clave? Cassandra: ¿qué consultas escalan sobre volumen distribuido? Neo4j: ¿qué conexiones recorro?
- c) Los tres responden la misma pregunta con distinta velocidad y distinto costo de licencia, así que se elige el más rápido que entre en el presupuesto.
- d) Redis y Cassandra responden por clave; Neo4j es un relacional con otro lenguaje de consulta.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** "Tres modelos, tres preguntas; no son sustitutos perfectos": **clave** (Redis), **consultas que escalan sobre volumen distribuido** (Cassandra) y **conexiones** (Neo4j). En el comercio de la clase: sesiones que caducan, millones de eventos por usuario y recomendaciones. La a mezcla las preguntas; la c y la d niegan que los modelos sean distintos.

</details>

**Pregunta 65** · Básica · *TTL en Redis*

Se ejecutó `SET session:ana activa EX 120`. Tres minutos después, ¿qué devuelven `GET session:ana` y `TTL session:ana`?

- a) `"activa"` y `0`: la clave sigue, pero sin tiempo restante.
- b) `"activa"` y `-1`: la clave existe sin vencimiento.
- c) `(nil)` y `-2`: la clave ya venció y no existe.
- d) Un error, porque una clave vencida bloquea su nombre hasta un reinicio.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** `EX 120` da 120 segundos de vida; a los tres minutos la clave ya no existe. `TTL` devuelve los segundos restantes si hay vencimiento, `-1` si la clave existe **sin** vencimiento (b) y `-2` si **no existe**. No queda "con 0 segundos" (a) ni bloquea el nombre (d).

</details>

**Pregunta 66** · Intermedia · *Elegir una estructura en Redis*

Hay que mantener un ranking de productos ordenado por cantidad de ventas y consultar los tres primeros. ¿Qué estructura corresponde?

- a) Un *set*, porque no admite repetidos.
- b) Un *string* por producto, ordenado por el nombre de la clave.
- c) Un *hash*, con el producto como campo y las ventas como valor, que se ordena solo.
- d) Un *sorted set*: cada miembro tiene un puntaje que lo ordena.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La clase asocia cada estructura a un uso: **hash** para atributos de un carrito o un perfil, **set** para miembros únicos (favoritos) y **sorted set** para un **ranking por puntuación**. El *set* no tiene orden (a); el *hash* no ordena por valor (c); las claves no se ordenan (b).

</details>

**Pregunta 67** · Intermedia · *Leer un ranking*

Después de `ZADD ranking 10 ana 20 luis 15 eva`, ¿qué devuelve `ZREVRANGE ranking 0 2 WITHSCORES`?

- a) ana 10, eva 15, luis 20.
- b) luis 20, eva 15, ana 10.
- c) ana, luis, eva, en el orden de inserción, sin puntajes.
- d) Solo luis 20, porque el rango 0 2 devuelve un único elemento.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** `ZREVRANGE` recorre de **mayor a menor** puntaje; `0 2` son las posiciones 0, 1 y 2 (tres elementos), y `WITHSCORES` agrega el puntaje. La a es el orden ascendente de `ZRANGE`. Desde Redis 6.2 la forma recomendada es `ZRANGE ranking 0 2 REV WITHSCORES`, con el mismo resultado.

</details>

**Pregunta 68** · Intermedia · *Persistencia en Redis*

¿Qué diferencia hay entre RDB y AOF?

- a) RDB toma *snapshots* periódicos y puede perder lo escrito después del último; AOF registra las operaciones, con una durabilidad que depende de la configuración.
- b) RDB guarda en disco y AOF solo en memoria, por eso AOF se pierde al reiniciar.
- c) Son lo mismo con distinto nombre: los dos copian la memoria a disco en cada escritura.
- d) RDB sirve solo para replicar hacia otros nodos y AOF solo para respaldar en otro servidor; ninguno se usa para recuperar después de un reinicio.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** **RDB**: fotos periódicas, recuperación con posible pérdida reciente. **AOF**: registro de cada escritura, más durable según cómo se configure. Los dos sirven para recuperar después de un reinicio (d). La clase agrega los **límites**: RAM, política de expulsión, replicación y operación deben diseñarse. "Rendimiento no significa ausencia de compromisos".

</details>

**Pregunta 69** · Intermedia · *Arquitecturas de Redis*

¿Qué afirmación sobre las arquitecturas de Redis coincide con la clase?

- a) Toda instalación de Redis es distribuida por defecto: reparte las claves entre los nodos de la red.
- b) La réplica es síncrona: el primario espera a que cada réplica confirme, así que una conmutación nunca pierde escrituras confirmadas.
- c) Instancia única para practicar; réplica para lecturas, habitualmente asíncrona; Cluster reparte claves por *slots*.
- d) Cluster replica todas las claves en todos los nodos, sin repartirlas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** "Distribución no es una propiedad de todas las instalaciones" (a). La réplica es **habitualmente asíncrona** (b es falsa: una conmutación puede perder las últimas escrituras). **Cluster** reparte las claves en 16.384 *slots*, no las copia todas en todos los nodos (d).

</details>

**Pregunta 70** · Desafío · *`MULTI` y `EXEC`*

Dentro de un bloque `MULTI` … `EXEC`, el segundo de tres comandos falla al ejecutarse por operar sobre un tipo equivocado. ¿Qué pasa?

- a) Redis deshace el primer comando y no ejecuta el tercero, como un `ROLLBACK`.
- b) Se aplican el primero y el tercero: el bloque corre en secuencia, sin intercalar otros comandos, pero no tiene *rollback*.
- c) Redis rechaza el bloque entero antes de ejecutarlo, porque valida los tipos de cada clave de antemano y aborta ante el primer error.
- d) El bloque queda pendiente hasta que se ejecute `WATCH`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La tabla de ACID de la clase: en Redis, **comandos atómicos** y transacciones `MULTI`/`EXEC` **sin rollback tradicional**. El bloque se ejecuta sin comandos intercalados, pero un error de ejecución no deshace lo anterior (a). `WATCH` sirve para abortar si una clave vigilada cambió (d). Para lógica condicional atómica se usa un script Lua.

</details>

**Pregunta 71** · Desafío · *Permisos en Redis*

Un usuario de aplicación tiene `~sesion:* ~carrito:* +@read +@write`. ¿Puede vaciar toda la base con `FLUSHALL`?

- a) No: los patrones de claves impiden cualquier comando que no reciba claves dentro de `sesion:*` o de `carrito:*`, incluido `FLUSHALL`.
- b) No, porque `FLUSHALL` solo lo puede ejecutar el usuario `default`.
- c) Sí: `FLUSHALL` está en `@write` y no recibe claves, así que el patrón no lo limita. Hay que quitar `@dangerous`.
- d) Sí, pero solo si Redis corre en modo Cluster.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Los patrones de claves **no limitan** los comandos que afectan a toda la base. `-@dangerous` quita `FLUSHALL`, `FLUSHDB`, `KEYS`, `CONFIG` y otros. Además, el usuario `default` existe sin contraseña y con acceso total si no se lo protege: no es un límite, es otro riesgo (b).

</details>

**Pregunta 72** · Básica · *Partición y clustering*

En `PRIMARY KEY ((usuario), fecha, evento_id)` con `CLUSTERING ORDER BY (fecha DESC, evento_id ASC)`, ¿qué hace cada parte?

- a) `usuario` y `fecha` forman juntas la clave de partición, y `evento_id` funciona como un índice secundario sobre cada partición.
- b) `usuario` es la partición; `fecha` y `evento_id` ordenan dentro de ella.
- c) Las tres columnas forman la partición, y el orden se elige en cada consulta.
- d) `evento_id` es la clave de partición, porque es el único valor único.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Los paréntesis internos marcan la **clave de partición** (`usuario`): determina la ubicación del dato y agrupa todos sus eventos. Las **columnas de clustering** organizan las filas dentro de la partición, acá de la más reciente a la más antigua; `evento_id` desempata dos eventos con la misma fecha. El orden se fija en la tabla, no en cada consulta (c).

</details>

**Pregunta 73** · Intermedia · *Un keyspace de laboratorio*

En el laboratorio se creó un *keyspace* con `SimpleStrategy` y `replication_factor: 1` en un solo nodo. ¿Qué se puede afirmar con esa evidencia?

- a) Que Cassandra tolera la caída de un nodo, porque ninguna escritura falló durante toda la carga de datos del laboratorio.
- b) Que `QUORUM` y `ONE` dan resultados distintos, porque hay replicación.
- c) Que el clúster tiene tres copias de cada partición, como en producción.
- d) Que CQL, particiones y modelado funcionan, no la tolerancia a fallas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La advertencia de la clase: **nodo único** permite CQL, particiones y modelado; **tres nodos** son necesarios para observar RF = 3 y caídas; y "no afirmar tolerancia a fallas sin ensayar un clúster real". Con RF = 1 hay una sola copia: no hay diferencia observable entre niveles de consistencia (b) ni tolerancia a fallas (a).

</details>

**Pregunta 74** · Intermedia · *Consultar por una columna que no es clave*

En la tabla `eventos` particionada por `usuario`, se necesita buscar todos los eventos de tipo `'compra'`. ¿Qué corresponde en Cassandra?

- a) Otra tabla para esa consulta, con el tipo en la partición.
- b) Agregar `ALLOW FILTERING` al final del `SELECT`, que resuelve la consulta con el mismo costo que una búsqueda por partición.
- c) Hacer un `JOIN` entre `eventos` y una tabla de tipos.
- d) Ninguna: Cassandra no puede devolver eventos de un tipo determinado.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La pregunta de la clase ("¿por qué una búsqueda global por tipo requeriría otro diseño?") apunta a esto: en Cassandra **la tabla se diseña desde la consulta**, y la desnormalización es deliberada. `ALLOW FILTERING` (b) obliga a recorrer todas las particiones. No hay `JOIN` (c). Cuidado: con pocos tipos, la nueva partición crecería sin límite; se agrega un cubo, como `(tipo, dia)`.

</details>

**Pregunta 75** · Intermedia · *Token y coordinador*

¿Cómo encuentra Cassandra los nodos que guardan los eventos de `usuario = 'ana'`, y quién coordina la operación?

- a) Un nodo maestro fijo consulta un índice global de particiones y reenvía la operación al nodo correcto, que la confirma al maestro.
- b) Se recorren todos los nodos hasta encontrar la partición, y el primero que responde coordina.
- c) La clave de partición pasa por una función *hash* que da un token, y el token determina los nodos dueños. Coordina el nodo que recibió esa operación, que puede ser cualquiera.
- d) El cliente elige el nodo por orden alfabético de la clave, y ese nodo es el maestro de la partición.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** **Token:** el *hash* de la clave de partición ubica el dato. **RF:** cuántas copias hay. **Coordinador:** como no hay nodo maestro (a), es el nodo al que el cliente le envió esa operación, y puede ser distinto en cada consulta. No se recorre todo el clúster (b).

</details>

**Pregunta 76** · Desafío · *RF y nivel de consistencia*

Con RF = 3, ¿cuántas réplicas deben responder con `ONE` y con `QUORUM`?

- a) Una y dos.
- b) Una y tres.
- c) Tres y dos.
- d) Una y una, porque `QUORUM` es el valor por defecto de `ONE`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** **RF y CL son decisiones diferentes:** RF = 3 son tres copias; `ONE` se satisface con **una** respuesta; `QUORUM` es la mayoría, ⌊RF ÷ 2⌋ + 1 = **2**. Tres respuestas serían `ALL` (b). El RF se fija en el *keyspace* y el CL se elige en cada operación.

</details>

**Pregunta 77** · Desafío · *Consistencia fuerte en Cassandra*

Con RF = 3, ¿qué combinación de nivel de escritura (W) y de lectura (R) garantiza leer la última escritura confirmada?

- a) W = `ONE` y R = `ONE`, porque cada operación toca una réplica.
- b) W = `QUORUM` y R = `ONE`, porque la escritura ya llegó a la mayoría.
- c) W = `ONE` y R = `QUORUM`, porque la lectura consulta a la mayoría.
- d) W = `QUORUM` y R = `QUORUM`, porque 2 + 2 > 3.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** La regla es **R + W > RF**: los conjuntos de réplicas que escriben y que leen se cruzan en al menos una. 2 + 2 = 4 > 3 la cumple. Con `ONE` y `ONE` (a), 1 + 1 = 2 puede leer una réplica vieja. La b y la c dan 2 + 1 = 3, que no supera a 3.

</details>

**Pregunta 78** · Intermedia · *`UPDATE` en Cassandra*

Se ejecuta un `UPDATE` sobre una clave primaria que no existe en la tabla. ¿Qué pasa?

- a) Da error, porque no hay fila para modificar.
- b) Crea la fila: en Cassandra `INSERT` y `UPDATE` son *upsert*.
- c) No hace nada y devuelve "0 filas afectadas", como en SQL.
- d) Escribe una lápida (*tombstone*) que marca la clave como inexistente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** En Cassandra las escrituras son **upsert**: si la fila no existe, se crea, sin dar error (se comprobó en el laboratorio). Para "insertar solo si no existe" está `INSERT ... IF NOT EXISTS`, una transacción ligera con Paxos, más lenta. Las lápidas (d) las escribe el `DELETE`.

</details>

**Pregunta 79** · Básica · *Por qué un grafo*

¿Qué diferencia de fondo tiene Neo4j frente a un relacional cuando se recorren relaciones?

- a) Neo4j guarda las relaciones como listas de identificadores dentro de cada nodo, como un array JSON que se recorre en cada consulta.
- b) Las relaciones son elementos de primera clase, persistidas con tipo y dirección: recorrerlas no exige buscar por clave en otra estructura.
- c) Neo4j no tiene relaciones: une los nodos en cada consulta comparando sus propiedades.
- d) Es igual que el relacional, pero con otro lenguaje de consulta.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** "Los vínculos son relaciones **persistidas**, no listas de identificadores" (a). Por eso el costo de un recorrido depende de la parte del grafo que se explora y no del tamaño total, mientras que en SQL cada salto es un `JOIN` que busca por clave. La c y la d niegan justamente lo que distingue al modelo.

</details>

**Pregunta 80** · Intermedia · *Leer una consulta Cypher*

¿Qué devuelve `MATCH (p:Producto)<-[:COMPRO]-(c:Cliente) RETURN p.nombre, count(c) AS compras`?

- a) Los clientes que compraron cada producto, uno por fila, sin agrupar.
- b) La cantidad total de productos de la base, contando también los que nadie compró todavía.
- c) Cada producto comprado, con cuántos clientes lo compraron.
- d) Los productos que ningún cliente compró.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** El patrón recorre las relaciones `COMPRO` desde los clientes hacia los productos; `count(c)` agrupa implícitamente por `p.nombre`. Los productos sin compras (d) no cumplen el patrón y no aparecen. Es la segunda consulta de la clase, que muestra lo que aporta **recorrer relaciones** frente a varios `JOIN`.

</details>

**Pregunta 81** · Intermedia · *Supernodos*

¿Qué es un **supernodo** y por qué la clase lo menciona como costo del modelo de grafos?

- a) Un nodo con muchísimas relaciones, caro de atravesar.
- b) Un nodo administrador con permisos sobre todo el grafo, que es un riesgo de seguridad porque cualquier consulta puede pasar por él.
- c) Un nodo con muchas propiedades, que ocupa más espacio en disco.
- d) El servidor principal de un clúster de Neo4j, que concentra las escrituras.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La clase resume el costo de Neo4j: "modelado, índices, cardinalidad y **supernodos**". Un producto que compraron millones de clientes es un supernodo: recorrer a través de él examina todas sus relaciones. Por eso la decisión es "elegir cuando el valor está en explorar conexiones", no reemplazar todo SQL.

</details>

**Pregunta 82** · Intermedia · *`CREATE` y `MERGE`*

Un script de carga de Neo4j se ejecutó dos veces por error. ¿Qué pasa según se haya escrito con `CREATE` o con `MERGE`?

- a) Con los dos se duplican los nodos, porque Neo4j no controla duplicados.
- b) Con los dos queda igual, porque Neo4j detecta los nodos repetidos por sus propiedades.
- c) Con `MERGE` se duplican y con `CREATE` no, porque `CREATE` busca el patrón antes de crear.
- d) Con `CREATE` se duplican; `MERGE` busca el patrón completo y solo lo crea si no existe.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** `CREATE` crea **siempre**; `MERGE` crea solo si el patrón completo no existe, y vale también para relaciones (`MERGE (a)-[:SIGUE]->(b)`). Con una restricción de unicidad (`REQUIRE c.id IS UNIQUE`) además se rechazan los duplicados y se protegen los `MERGE` concurrentes. La c invierte los comandos.

</details>

**Pregunta 83** · Desafío · *Duplicados en un recorrido*

`MATCH (u:Cliente {id:'U01'})-[:SIGUE]->(s)-[:COMPRO]->(p) RETURN p.nombre` muestra dos veces la misma notebook. ¿Por qué?

- a) Porque la notebook está cargada dos veces en la base.
- b) Porque un patrón devuelve una fila por camino: dos clientes seguidos compraron la misma notebook. Se corrige con `DISTINCT` o `count(DISTINCT s)`.
- c) Porque `MATCH` siempre duplica los resultados de los recorridos de dos saltos, y hay que dividir el conteo por la cantidad de saltos.
- d) Porque falta un índice sobre `Producto.nombre`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Hay **dos caminos** distintos que llegan al mismo producto. `RETURN DISTINCT p.nombre` lo muestra una vez, y `count(DISTINCT s)` además dice cuántos seguidos lo compraron, útil para ordenar recomendaciones. No hace falta que el producto esté duplicado (a), y un índice no cambia el resultado (d).

</details>

**Pregunta 84** · Intermedia · *Comparación transversal*

En el comercio de la clase, ¿qué pieza resuelve cada motor?

- a) Redis: afinidades entre clientes y productos. Cassandra: carrito y sesión con vencimiento. Neo4j: actividad por usuario y período.
- b) Redis: actividad por usuario y período. Cassandra: afinidades. Neo4j: carrito con TTL.
- c) Redis: sesión y carrito. Cassandra: actividad. Neo4j: afinidades.
- d) Los tres guardan lo mismo, replicado, para tener alta disponibilidad.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** "Mismo comercio, tres piezas complementarias". El cierre de la clase lo resume: Redis prioriza el **acceso directo** en memoria; Cassandra **diseña por consultas** y distribuye; Neo4j hace foco en los **vínculos y recorridos**. La a y la b mezclan los usos; la d confunde complementar con replicar.

</details>

**Pregunta 85** · Desafío · *ACID en los motores NoSQL*

¿Qué afirmación coincide con la tabla de ACID de la clase?

- a) Cassandra ofrece atomicidad por partición y transacciones ligeras con Paxos, sin aislamiento general entre particiones.
- b) Ningún motor NoSQL ofrece durabilidad: todos guardan los datos solo en memoria.
- c) Redis ofrece transacciones ACID completas con aislamiento por bloqueos, igual que Neo4j, y por eso tiene *rollback* con `MULTI`/`EXEC`.
- d) Neo4j no tiene transacciones, porque los grafos no admiten ACID.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La tabla de la clase: **Redis**, comandos atómicos y `MULTI`/`EXEC` sin rollback, durabilidad según RDB/AOF; **Cassandra**, atomicidad por partición, Paxos, sin aislamiento entre particiones, *commit log* + SSTables; **Neo4j**, transacciones ACID completas con aislamiento por bloqueos (c y d son falsas). "NoSQL no significa sin ACID": las garantías y su **alcance** dependen del motor (b).

</details>

**Pregunta 86** · Intermedia · *Particionado, replicación y consistencia*

La clase pide "no confundir técnicas con propiedades". ¿Qué definición es correcta?

- a) Particionado es mantener copias para tolerar fallas; replicación es repartir subconjuntos de datos entre nodos para escalar la escritura.
- b) Consistencia es una técnica para repartir la carga de escritura entre nodos.
- c) Particionado, replicación y consistencia son tres nombres del sharding.
- d) Particionado reparte subconjuntos de datos; replicación mantiene copias; consistencia define qué lecturas y escrituras se consideran válidas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** **Particionado** y **replicación** son técnicas (repartir y copiar); **consistencia** es una propiedad (qué se considera válido leer y escribir). La a invierte las dos primeras. La b y la c confunden una propiedad con una técnica.

</details>

**Pregunta 87** · Desafío · *Se corta la red*

Dos réplicas dejan de comunicarse. El lado A acepta `X = 1` y el lado B recibe una lectura de `X`. ¿Qué pasa si **los dos lados siguen respondiendo**?

- a) El sistema es consistente y disponible a la vez, porque la partición es temporal y las réplicas se ponen al día cuando vuelve la red.
- b) Sigue disponible, pero B puede devolver un valor viejo y aceptar escrituras que choquen con las de A.
- c) El lado B rechaza la lectura, porque no puede confirmar el último valor.
- d) Las dos réplicas se sincronizan por otra vía y B devuelve `X = 1`.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Es la disyuntiva de la clase: "¿responder en ambos lados o rechazar alguna operación?". Responder en los dos lados prioriza la **disponibilidad** y sacrifica la consistencia; rechazar en B (c) prioriza la **consistencia** y sacrifica la disponibilidad en ese lado. No se pueden tener las dos durante la partición (a), y por definición no hay otra vía de comunicación (d).

</details>

**Pregunta 88** · Básica · *CAP, formulación correcta*

¿Cuál es la formulación correcta del teorema CAP?

- a) Todo sistema distribuido elige, al diseñarse, dos de las tres propiedades y renuncia para siempre a la tercera.
- b) Un sistema distribuido no puede ser consistente si tiene más de tres nodos.
- c) Si la red se particiona, hay que elegir entre devolver un error (consistencia) o una respuesta posiblemente desactualizada (disponibilidad).
- d) La consistencia y la disponibilidad se excluyen siempre, haya o no fallas de red, y por eso todo sistema distribuido debe renunciar a una.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** **C**: cada lectura ve el último valor confirmado o recibe error. **A**: cada solicitud a un nodo no fallado obtiene respuesta. **P**: la red puede perder mensajes. La elección ocurre **durante la partición**; sin particiones se pueden tener C y A (d es falsa). "No es un menú" (a).

</details>

**Pregunta 89** · Intermedia · *La C de ACID y la C de CAP*

¿Qué diferencia hay entre la "C" de ACID y la "C" de CAP?

- a) La de ACID: cada transacción lleva la base de un estado válido a otro. La de CAP: cada lectura ve la última escritura.
- b) Son la misma propiedad, vista desde una sola máquina y desde varias.
- c) La de ACID habla de que las réplicas tengan el mismo valor, y la de CAP habla de restricciones como `CHECK` y claves foráneas.
- d) La de CAP solo existe en los motores relacionales.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La clase lo marca como uno de los malentendidos: "la C de CAP no equivale a la consistencia de restricciones ACID". Un sistema puede respetar un `CHECK` y, con réplicas asíncronas, devolver un dato viejo. La c invierte las definiciones.

</details>

**Pregunta 90** · Intermedia · *Cassandra y CAP*

Con RF = 3, una réplica queda aislada por un corte de red. ¿Qué pasa con las operaciones según su nivel de consistencia?

- a) Las dos fallan siempre, porque Cassandra es un sistema CP.
- b) Las dos responden siempre, porque Cassandra es un sistema AP.
- c) `ONE` puede seguir respondiendo con las réplicas que quedan; `QUORUM` exige mayoría y puede rechazar operaciones.
- d) `QUORUM` responde más rápido que `ONE` durante la falla, porque consulta más réplicas en paralelo y toma la primera respuesta que llega.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** "La consistencia depende de la operación": latencia, disponibilidad y frescura dependen de la configuración y de las fallas. Por eso no corresponde ponerle a Cassandra una **etiqueta fija** de CP o AP (a, b): el mismo clúster se comporta distinto según el CL de cada operación.

</details>

**Pregunta 91** · Intermedia · *Redis y Neo4j ante fallas*

¿Qué regla da la clase para analizar Redis y Neo4j frente a CAP?

- a) Redis es siempre CP y Neo4j siempre AP, sin importar cómo se instalen.
- b) Los dos garantizan consistencia y disponibilidad al mismo tiempo durante una partición, porque sus réplicas confirman cada escritura antes de responder.
- c) CAP no se aplica a ninguno de los dos, porque no son motores distribuidos.
- d) No asignar una etiqueta sin contexto: hay que evaluar el despliegue (*standalone*, réplica, Sentinel, clúster), la escritura, la lectura y la partición concreta.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** En Redis, réplica, Sentinel y Cluster cambian la recuperación y el comportamiento; en Neo4j, *standalone* o clúster cambian las garantías. La regla: evaluar **despliegue, escritura, lectura y partición concreta**. La a pone etiquetas fijas; la c ignora que pueden distribuirse; la b contradice CAP.

</details>

**Pregunta 92** · Intermedia · *PACELC*

¿Qué agrega PACELC a CAP?

- a) Que sin partición hay que elegir entre latencia y consistencia.
- b) Que la partición se puede evitar agregando más nodos y enlaces de red redundantes entre ellos.
- c) Que la consistencia eventual garantiza latencia cero.
- d) Que los sistemas con particiones no pueden ser consistentes nunca.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Si hay **P**artición, se elige entre **A** y **C**; si no (**E**lse), entre **L**atencia y **C**onsistencia. Explica por qué un sistema que espera a una mayoría de réplicas responde más lento aun sin fallas: es el costo de `QUORUM`.

</details>

**Pregunta 93** · Intermedia · *Matriz de decisión*

La clase propone elegir motor con tres criterios. ¿Cuáles son?

- a) Popularidad del motor en el mercado, precio de licencia y cantidad de tutoriales y cursos disponibles para el equipo.
- b) Lenguaje de consulta, sintaxis y herramienta gráfica.
- c) Acceso (clave, rango por partición o recorrido), escala (memoria, distribución o densidad) y operación.
- d) Velocidad de lectura, velocidad de escritura y velocidad de instalación.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** "Elegir según el patrón de acceso": **acceso**, **escala** y **operación**. El objetivo de la clase es "decidir a partir de evidencia, no por popularidad" (a). El cierre lo resume: elegir motor también es **elegir costos de operación**.

</details>

**Pregunta 94** · Básica · *"No gana quien usa más tecnologías"*

En la batalla de arquitecturas, un grupo propone seis motores distintos para el comercio. ¿Qué objeción es la más sólida?

- a) Ninguna: más motores hacen la arquitectura más preparada para el futuro, porque cada dato queda en el motor más rápido para él.
- b) Que cada motor suma operación, respaldo, seguridad, conocimiento e integración, y hay que justificar que el que ya se tiene no alcanza.
- c) Que seis motores no pueden convivir en una misma red.
- d) Que solo se permiten motores de una misma familia en un sistema.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La pregunta de la actividad es si existe una única arquitectura correcta. No existe, pero cada motor tiene un **costo**: operarlo, respaldarlo, asegurarlo, conocerlo e **integrarlo** con los demás. La pregunta no es "¿qué motor sirve?", sino "¿el que tengo no alcanza?". La a es la falacia "más motores, más preparada".

</details>

**Pregunta 95** · Intermedia · *Dónde va lo transaccional*

Pedido, descuento de stock y registro del pago deben confirmarse juntos o no confirmarse. ¿Dónde conviene resolverlo?

- a) En Redis, porque responde en milisegundos y `MULTI`/`EXEC` agrupa los comandos del pedido, el stock y el pago.
- b) En Cassandra, porque la escritura masiva es su fortaleza.
- c) En Neo4j, porque el pedido relaciona clientes y productos.
- d) En el motor relacional, con una transacción entre tablas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** "Lo que importa es el alcance de la garantía": un dominio que necesita atomicidad **entre varias entidades** va al motor que la ofrece entre tablas. Redis no tiene rollback (a); Cassandra es atómica por partición (b). En la clase 7, pedidos y pagos son el ejemplo del relacional.

</details>

**Pregunta 96** · Desafío · *Escritura doble*

Una aplicación guarda el pedido en MySQL y después lo escribe en Neo4j para las recomendaciones. ¿Qué problema tiene y qué patrón lo resuelve?

- a) No tiene problema: si la segunda escritura falla, la aplicación muestra un error y el usuario reintenta.
- b) Las dos escrituras no son atómicas entre sí. Se resuelve con un outbox transaccional: el evento se guarda en la misma transacción del pedido y un proceso lo publica y reintenta.
- c) Neo4j no puede recibir datos de MySQL, así que hay que cargarlo a mano.
- d) Se resuelve con un *two-phase commit* entre MySQL y Neo4j, que garantiza la atomicidad y no afecta la disponibilidad de ninguno de los dos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Si el proceso cae entre las dos escrituras, los motores quedan inconsistentes y nadie se entera. El **outbox** guarda el evento en la misma transacción del negocio, y el consumidor en Neo4j se hace **idempotente** (`MERGE` sobre una clave única). Un *two-phase commit* (d) no está disponible entre estos motores y, aunque lo estuviera, bloquea y reduce la disponibilidad.

</details>

**Pregunta 97** · Desafío · *Actualización perdida*

Doscientos procesos suman 1 al mismo contador en Redis. Con `HGET` y luego `HSET` el total queda muy por debajo de 200. ¿Qué lo corrige?

- a) Ejecutar los procesos más rápido, para que no se superpongan.
- b) Leer el contador dos veces antes de escribirlo.
- c) Usar `HINCRBY`, que suma en una sola operación atómica del motor.
- d) Activar AOF con `appendfsync always`, para que ninguna escritura del contador se pierda.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Es la **actualización perdida** del Parcial 1: muchos procesos leen el mismo valor y escriben el mismo resultado. La lección es **delegar la operación crítica al motor** en una sola sentencia atómica (`HINCRBY`, o `UPDATE ... SET x = x + 1` en SQL). AOF (d) da durabilidad, no evita la carrera; leer dos veces (b) tampoco.

</details>

---

## Unidad 10 · Operar como servicio: DBaaS y Cloud

**Pregunta 98** · Básica · *¿Qué queda por administrar?*

Si el proveedor administra el servidor, los backups y la alta disponibilidad, ¿qué queda por administrar según la clase?

- a) Configurar, proteger, observar y pagar.
- b) Nada: el servicio administrado reemplaza toda la tarea del DBA, porque el proveedor también diseña los datos y los índices.
- c) Solo el pago de la factura mensual del proveedor.
- d) Solo la instalación del sistema operativo de la instancia.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** La pregunta disparadora de la clase se desarma en cuatro: **¿quién configura? ¿quién protege? ¿quién observa? ¿quién paga?** "DBaaS reduce trabajo operativo; no elimina las decisiones de administración". El sistema operativo (d) es justamente lo que el proveedor sí opera.

</details>

**Pregunta 99** · Básica · *Abstracción y responsabilidad*

Al pasar de on-premise a IaaS, a DBaaS y a serverless, ¿qué ocurre según la clase?

- a) Desaparece toda responsabilidad sobre los datos al llegar a DBaaS.
- b) Aumenta el control del sistema operativo en cada paso.
- c) El costo baja siempre en cada paso, porque se paga solo lo que se usa y desaparece la inversión en hardware propio.
- d) Más abstracción y menos infraestructura propia, pero no necesariamente menos responsabilidad sobre los datos.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** On-premise (máximo control) → IaaS (infraestructura alquilada) → PaaS/DBaaS (operación compartida) → serverless (mayor abstracción). "A mayor abstracción, menos infraestructura propia; **no necesariamente menos responsabilidad** sobre los datos". El control del SO baja (b) y el costo depende de la configuración (c).

</details>

**Pregunta 100** · Intermedia · *Las tres ideas de la nube*

¿Qué advertencia hace la clase sobre la elasticidad, el pago por consumo y la automatización?

- a) Que solo existen en los proveedores más grandes.
- b) Que cloud no significa automáticamente barato, elástico ni disponible: depende de cómo se configure.
- c) Que la elasticidad es siempre automática en cualquier servicio, y por eso no requiere decisiones de capacidad ni de costo.
- d) Que el pago por consumo hace imposible estimar el costo de una base.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** **Elasticidad** (ajustar capacidad sin comprar hardware, manual o automática), **pago por consumo** (el costo pasa a los recursos usados) y **automatización** (aprovisionamiento, backups, parches, HA como capacidades de plataforma). Ninguna viene garantizada por estar "en la nube". El costo se estima con las calculadoras de cada proveedor (d).

</details>

**Pregunta 101** · Intermedia · *Qué es DBaaS*

¿Qué afirmación sobre DBaaS es correcta?

- a) Una forma de operar un motor, no un modelo de datos.
- b) Es un modelo de datos nuevo, distinto del relacional y del documental, pensado para aplicaciones que corren en la nube.
- c) Es un motor NoSQL que solo existe en la nube.
- d) Es un tipo de respaldo que copia la base a un proveedor externo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** Se consume la base mediante un **endpoint** y una API o consola; el proveedor opera gran parte de la infraestructura y del ciclo de vida del motor. Un PostgreSQL administrado sigue siendo relacional, y MongoDB Atlas sigue siendo documental. La b y la c confunden la forma de operar con el modelo.

</details>

**Pregunta 102** · Intermedia · *Responsabilidad compartida*

En la tabla de responsabilidad compartida de la clase, ¿cuál de estas tareas es **compartida** entre proveedor y cliente?

- a) Hardware y centro de datos donde corre el servicio.
- b) Usuarios, roles y privilegios.
- c) Modelo de datos, SQL e índices.
- d) La disponibilidad de la plataforma.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** **Proveedor:** hardware y centro de datos (a), SO y parches de plataforma. **Compartida:** disponibilidad de la plataforma. **Cliente:** configuración del servicio, usuarios y privilegios (b), modelo, SQL e índices (c), datos y su clasificación, costo y gobierno. "Managed no significa sin dueño".

</details>

**Pregunta 103** · Intermedia · *Qué desaparece y qué permanece*

Comparado con la VM del curso, ¿qué tarea **permanece** al pasar a DBaaS?

- a) Instalar el sistema operativo y el motor.
- b) Probar el *restore* y los costos.
- c) Gestionar los discos del servidor.
- d) Construir los mecanismos básicos de alta disponibilidad, como la réplica en otra zona y el *failover*.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** **Suele reducirse:** instalar SO y motor (a), gestionar discos (c), parte del *patching*, la HA básica (d) y las copias estándar. **Permanece:** diseñar datos e índices, gestionar identidades, configurar parámetros, diagnosticar consultas, **validar el restore, el RPO/RTO y los costos**, y definir la arquitectura. "De administrar máquinas a administrar niveles de servicio y decisiones".

</details>

**Pregunta 104** · Intermedia · *Lo que ve la aplicación*

En la arquitectura DBaaS de la clase (APP → DNS → TLS → DB → DATA → OBS), ¿cómo trabaja el DBA?

- a) Entra por SSH al servidor del proveedor para revisar los archivos de configuración y los logs del sistema operativo.
- b) Pide al proveedor un acceso físico al centro de datos ante cada incidente.
- c) Observa el servicio mediante SQL, consola, API, métricas y logs.
- d) No puede ver nada del servicio hasta que el proveedor envía un informe mensual.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** "La infraestructura se oculta; el endpoint se vuelve la frontera visible". El DBA ya no "entra al servidor" para resolver todo (a): no hay acceso al sistema operativo. Observa con las herramientas del servicio. La b y la d no describen ningún DBaaS.

</details>

**Pregunta 105** · Intermedia · *Provisionar*

¿Qué decisiones se toman al provisionar una base como servicio, antes del primer `CREATE TABLE`?

- a) Región, motor y versión, cómputo, almacenamiento, red y alta disponibilidad.
- b) Solo el nombre de la base y la contraseña del administrador.
- c) Solo el tamaño del disco, porque lo demás lo decide el proveedor.
- d) El modelo de datos y los índices, porque el proveedor ya fijó la infraestructura.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** **Región** (¿dónde vive?), **motor/versión** (¿qué compatibilidad?), **compute** (¿cuánta CPU y RAM?), **storage** (¿capacidad e IOPS?), **red** (¿pública o privada?) y **HA** (¿una zona o varias?). "Provisionar es diseñar una plataforma operativa, no solamente crear una base". Las demás opciones dejan afuera decisiones que son del cliente.

</details>

**Pregunta 106** · Intermedia · *Anatomía del endpoint*

En `postgresql://app@mi-db.proveedor.cloud:5432/ventas`, ¿qué es cada parte?

- a) `app` es la base, `mi-db.proveedor.cloud` es el usuario de la plataforma, `5432` es el código de la región y `ventas` es el motor elegido.
- b) `app` es el motor, `5432` es la versión y `ventas` es el certificado TLS.
- c) `mi-db.proveedor.cloud` es la IP fija del servidor físico, que no cambia nunca.
- d) `app` el usuario, el host el endpoint, `5432` el puerto y `ventas` la base.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** **Usuario** (identidad), **host** (endpoint administrado), **puerto** del motor y **base lógica**, más TLS y *timeout* como comportamiento del cliente. El endpoint reemplaza a la IP del servidor (c): el proveedor puede cambiar la máquina detrás sin cambiar el nombre. "La conexión cambia de infraestructura, no de principios".

</details>

**Pregunta 107** · Intermedia · *Público no significa abierto*

Una base con acceso público funciona desde la casa de un integrante, pero desde la red de la facultad la conexión da *timeout*. ¿Qué es lo más probable y cómo se corrige?

- a) La clave es incorrecta desde esa red, porque el proveedor asocia cada contraseña a la red desde la que se creó el usuario.
- b) La regla de red (lista de IP o firewall) no incluye la IP pública de la facultad; se agrega esa IP, sin abrir el acceso a todo internet.
- c) El motor está caído; hay que reiniciar el servicio desde la consola.
- d) Falta TLS; hay que desactivarlo para conectarse desde redes públicas.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** Un *timeout* indica que la conexión **ni siquiera llega** al motor: es la capa de red. Una clave incorrecta daría `Authentication failed` (a). "Público no significa abierto": el endpoint alcanzable desde internet se protege con reglas, identidad y TLS. Abrir `0.0.0.0/0` dejaría la clave como única defensa.

</details>

**Pregunta 108** · Intermedia · *¿Sigue siendo PostgreSQL?*

Un equipo migra a un PostgreSQL administrado y descubre que el usuario `postgres` que entrega la plataforma no es `SUPERUSER`. ¿Cómo lo explica la clase?

- a) Es esperable: se mantiene el SQL, pero pueden cambiar el superusuario, las extensiones y los parámetros.
- b) Es un error de configuración del proveedor que hay que reclamar.
- c) Significa que no es PostgreSQL, sino otro motor que imita su sintaxis.
- d) Impide crear roles y tablas, así que el servicio no sirve para producción y hay que volver a un servidor propio con acceso total.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** "Compatibilidad no implica control idéntico al servidor propio". Se mantienen SQL, tipos, índices, transacciones y planes; **puede cambiar** el superusuario, las extensiones, los parámetros, el acceso al sistema de archivos y las ventanas de mantenimiento. Así se evita que un cliente comprometa el host compartido. Los roles y las tablas se siguen creando con privilegios delegados (d).

</details>

**Pregunta 109** · Desafío · *Backup administrado*

En el backup administrado, ¿quién hace qué según la clase?

- a) El proveedor hace todo, incluida la validación de los datos restaurados, y entrega un certificado de recuperabilidad en cada copia.
- b) El cliente ejecuta las copias a mano, porque el proveedor solo guarda los archivos.
- c) El proveedor elige la política de retención y el cliente ejecuta las copias.
- d) El proveedor ejecuta las copias según la configuración; el cliente elige la política y prueba el *restore*; los dos sostienen el RPO/RTO.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** **Proveedor:** ejecuta copias y retención según la configuración. **Cliente:** elige política, retención y ventanas, y **prueba el restore**. **Ambos:** sostienen el RPO/RTO. "Un checkbox *backup enabled* no demuestra recuperabilidad. La evidencia sigue siendo un restore validado". La c invierte los papeles.

</details>

**Pregunta 110** · Intermedia · *HA no es backup*

Un servicio con réplica en otra zona y *failover* automático recibe un `DELETE` sin `WHERE`. ¿Qué pasa?

- a) El *failover* detecta el error y conmuta a la réplica, que todavía tiene los datos.
- b) El borrado se replica al *standby*: la HA protege contra caídas, no contra errores lógicos.
- c) La réplica rechaza el borrado porque no tiene `WHERE`.
- d) El proveedor revierte la operación automáticamente, porque deshacer errores de los usuarios es parte del servicio administrado.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** "La HA del servicio no reemplaza al backup ni corrige errores lógicos". Es el "alta disponibilidad no es backup" del Parcial 1: la réplica copia lo que hace el primario, incluidos los errores. Las preguntas del DBA ante la HA administrada: qué SLA ofrece, qué RPO/RTO necesito, qué pasa con las conexiones y cómo pruebo el *failover*.

</details>

**Pregunta 111** · Intermedia · *Patching administrado*

¿Qué significa que "managed cambia quién aplica el parche, no quién asume el impacto"?

- a) Que el cliente debe aplicar los parches a mano aunque el servicio sea administrado.
- b) Que los parches nunca reinician la base en un servicio administrado.
- c) Que el proveedor aplica los parches según la política, pero el cliente define la ventana, prueba la compatibilidad, y la aplicación debe tolerar reinicios y *failover*.
- d) Que el proveedor se hace cargo de cualquier pérdida de negocio causada por un parche, porque lo aplicó sin consultar al cliente.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** **Proveedor:** mantiene la plataforma y publica versiones y ventanas. **Cliente:** define la ventana, prueba compatibilidad, revisa extensiones y planifica cambios de versión. **Aplicación:** tolera reinicios, *failover* y cambios de sesión. Los parches sí pueden reiniciar (b), y el impacto de negocio sigue siendo del equipo (d).

</details>

**Pregunta 112** · Intermedia · *Observabilidad*

La consola del servicio muestra CPU, memoria, conexiones, latencia, I/O, consultas costosas, logs y alertas. ¿Qué pregunta propone la clase frente a esas señales?

- a) "¿Qué decisión puedo tomar con esta señal?"
- b) "¿Qué dashboard tiene más gráficos?"
- c) "¿Cuántas métricas ofrece este proveedor frente a otro?"
- d) "¿Cómo desactivo las alertas para no recibir notificaciones?"

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** "La pregunta no es qué dashboard existe, sino **qué decisión puedo tomar con esa señal**". Una alerta es **un umbral más una acción**. La consola reemplaza parte del acceso al SO, pero hace falta evidencia; y los planes gratuitos suelen limitar las métricas y los logs disponibles.

</details>

**Pregunta 113** · Desafío · *"Subamos la instancia"*

La CPU está alta y la latencia crece. Alguien propone duplicar el cómputo. ¿Qué haría un DBA según la clase?

- a) Duplicar el cómputo enseguida, porque en la nube escalar es inmediato, no tiene techo y no cambia el costo mensual.
- b) Reducir el cómputo a la mitad para bajar el costo, aunque suba la latencia.
- c) Migrar a otro proveedor, porque el actual no optimiza el SQL.
- d) Medir SQL, I/O e índices y comparar optimizar con escalar.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Duplicar el cómputo baja la latencia, pero **sube el costo** y puede ocultar un problema. "El proveedor no optimiza nuestro SQL", y comprar recursos no convierte una consulta mala en un buen diseño. **FinOps** para bases: optimizar el valor, no minimizar el costo a cualquier precio (b).

</details>

**Pregunta 114** · Intermedia · *Réplicas de lectura*

¿Qué condición pone la clase para que las réplicas de lectura de un DBaaS sirvan?

- a) Que las réplicas estén en la misma zona que el primario.
- b) Que la aplicación sepa usarlas: distribuyen las consultas compatibles, no las escrituras.
- c) Que se desactive el primario, para que las réplicas reciban toda la carga.
- d) Que el plan sea serverless, porque solo esos planes admiten réplicas de lectura.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** "Escalar es una decisión de arquitectura y costo, no un botón mágico". **Vertical:** más CPU y RAM, con reinicio y techo. **Lecturas:** réplicas que la aplicación debe saber usar. **Serverless/autoscale:** simplifica picos, pero hay que entender límites y modelo de cobro.

</details>

**Pregunta 115** · Intermedia · *Componentes del costo*

Un reporte descarga todos los días varios GB desde la base en la nube hacia una oficina. ¿Qué componente del costo crece?

- a) El cómputo, porque cada descarga suma vCPU a la instancia.
- b) El *storage*, porque cada descarga duplica los GB provisionados.
- c) La red: la transferencia de salida (*egress*).
- d) La HA, porque cada descarga crea una réplica nueva.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** Los componentes de la clase: **compute** (vCPU, RAM, tiempo), **storage** (GB provisionados), **I/O** (operaciones), **backup** (retención, *snapshots*), **red** (*egress*) y **HA** (réplicas, zonas). "En DBaaS cada decisión técnica puede tener traducción económica".

</details>

**Pregunta 116** · Intermedia · *Seguridad en dos planos*

Un integrante tiene un rol de solo lectura en la consola del proveedor, pero no tiene usuario de base de datos. ¿Puede leer los datos de las colecciones o tablas?

- a) No: la identidad de la plataforma controla quién administra o ve el servicio, y la del motor controla quién usa los datos. Son planos distintos.
- b) Sí, porque el rol de solo lectura de la consola incluye leer todos los datos de las bases del proyecto desde el explorador web.
- c) Sí, siempre que se conecte desde una IP permitida.
- d) No, porque en DBaaS nadie puede leer datos, salvo el proveedor.

<details>
<summary>Ver respuesta</summary>

**Respuesta: a.** **Identidad cloud** (IAM, roles de la plataforma): quién crea, modifica o lee la configuración del servicio. **Identidad del motor:** quién accede a objetos y acciones dentro de la base. Una identidad de un plano **no sirve en el otro**: un rol de solo lectura del proyecto no lee documentos, y un usuario de base de datos no entra a la consola. La red (c) es una tercera capa, no un permiso.

</details>

**Pregunta 117** · Intermedia · *Cuándo termina una migración*

Según la clase, ¿cuándo termina la migración de una base a DBaaS?

- a) Cuando termina de copiarse el último dato al servicio nuevo y el recuento de filas coincide con el del origen.
- b) Cuando el proveedor confirma que la instancia está creada.
- c) Cuando se borra la base de origen.
- d) Cuando la operación es estable y verificable: validada, con el traspaso hecho y observando errores, latencia y costo.

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** Los seis pasos: **inventariar** (versiones, extensiones, tamaño), **evaluar** (compatibilidad, límites), **mover** (*dump/restore* o replicación), **validar** (conteos, SQL, rendimiento), **traspaso** (DNS o endpoint, ventana) y **observar** (errores, latencia, costo). "La migración termina cuando la operación es estable y verificable, no cuando finaliza la copia" (a).

</details>

**Pregunta 118** · Intermedia · *Dónde conviene operar*

En la tabla comparativa de la clase, ¿qué combinación corresponde a DBaaS?

- a) Control del SO alto, instalación y parches propios, costo en CapEx.
- b) Control del SO bajo, parches del proveedor, compatibilidad con límites y foco en el servicio y los datos.
- c) Elasticidad baja y planificada, compatibilidad máxima con el motor original y foco del DBA en el servidor y el motor.
- d) Control del SO alto, elasticidad media y foco en la VM y el motor.

<details>
<summary>Ver respuesta</summary>

**Respuesta: b.** La a y la c describen on-premise (CapEx, máximo control y compatibilidad); la d describe VM/IaaS (OpEx). "No hay un ganador universal: cambia el equilibrio entre control y esfuerzo". **Elegir DBaaS es elegir una frontera de responsabilidad**, no solamente un proveedor.

</details>

**Pregunta 119** · Intermedia · *Estrategia de salida*

¿Qué propone la clase para no quedar atado a una plataforma (*lock-in*)?

- a) Usar todas las funciones propietarias del proveedor, porque así se aprovecha mejor el servicio y se reduce el costo de operarlo.
- b) No usar nunca un servicio administrado.
- c) Revisar las dependencias propietarias, asegurar herramientas y permisos para exportar datos y esquema, y probar la salida restaurando en otra instancia.
- d) Pedir al proveedor un contrato que prohíba subir los precios.

<details>
<summary>Ver respuesta</summary>

**Respuesta: c.** **Dependencias** (extensiones, versiones, autenticación, APIs propietarias), **exportación** (formatos, herramientas, permisos) y **prueba de salida** (restaurar en otra instancia, medir tiempos, ejecutar las consultas críticas). La pregunta antes de adoptar: "¿cómo nos iríamos de esta plataforma?". Cuanto más se usan funciones propias (a), mayor es el *lock-in*.

</details>

**Pregunta 120** · Básica · *¿DBaaS elimina al DBA?*

¿Qué conclusión da la clase sobre el rol del DBA en DBaaS?

- a) Desaparece: el proveedor se ocupa de todo.
- b) Se reduce a pagar la factura, abrir tickets de soporte y aprobar las ventanas de mantenimiento que propone el proveedor.
- c) No cambia: hace las mismas tareas que en el servidor propio.
- d) Se eleva: pasa de operar servidores a gobernar una plataforma de datos (configuración, seguridad, automatización, costos y gobierno).

<details>
<summary>Ver respuesta</summary>

**Respuesta: d.** "DBaaS no elimina al DBA: **eleva el nivel** en el que debe administrar". La pregunta cambia de "¿quién administra el servidor?" a "¿quién responde por el servicio?". **Siempre** siguen siendo del equipo los datos, el SQL, la seguridad, la continuidad y las decisiones. En los criterios de la actividad, interpretar DBaaS como "sin administración" (a) es **no logrado**.

</details>

---

## Clave de respuestas

| Unidad | Respuestas |
| :--- | :--- |
| U7 | 1 c · 2 b · 3 d · 4 a · 5 b · 6 c · 7 d · 8 a · 9 b · 10 c · 11 b · 12 a · 13 b · 14 d · 15 c · 16 b · 17 d · 18 b · 19 c · 20 b · 21 c · 22 d · 23 a · 24 b · 25 d · 26 a · 27 c · 28 b · 29 b · 30 c · 31 a · 32 b · 33 d |
| U8 | 34 a · 35 d · 36 c · 37 b · 38 d · 39 c · 40 a · 41 d · 42 c · 43 a · 44 b · 45 c · 46 a · 47 d · 48 c · 49 a · 50 d · 51 c · 52 a · 53 b · 54 c · 55 a · 56 d · 57 b · 58 a · 59 d · 60 c · 61 a · 62 b · 63 c |
| U9 | 64 b · 65 c · 66 d · 67 b · 68 a · 69 c · 70 b · 71 c · 72 b · 73 d · 74 a · 75 c · 76 a · 77 d · 78 b · 79 b · 80 c · 81 a · 82 d · 83 b · 84 c · 85 a · 86 d · 87 b · 88 c · 89 a · 90 c · 91 d · 92 a · 93 c · 94 b · 95 d · 96 b · 97 c |
| U10 | 98 a · 99 d · 100 b · 101 a · 102 d · 103 b · 104 c · 105 a · 106 d · 107 b · 108 a · 109 d · 110 b · 111 c · 112 a · 113 d · 114 b · 115 c · 116 a · 117 d · 118 b · 119 c · 120 d |
