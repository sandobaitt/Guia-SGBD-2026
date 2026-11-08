# Fundamentos Teóricos: U9 - Actividad 1 (Laboratorio multimotor: Redis, Cassandra y Neo4j)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)
**Tópicos:** Redis (estructuras, TTL, ACL, RDB), Cassandra (clave de partición y clustering, consultas eficientes, `ALLOW FILTERING`, snapshots) y, en detalle, Neo4j: bases de datos de grafos, grafo de propiedades, Cypher, CRUD sobre nodos y relaciones, consultas de recorrido y recomendación, `DISTINCT`, restricciones e índices, `LOAD CSV`, seguridad en Community (autenticación sin RBAC), respaldo offline con `neo4j-admin`, restauración en entorno aislado, comparación con otros motores.

> Las secciones 1 a 8 cubren la **parte C (Neo4j)**, la 9 Redis (A) y la 10 Cassandra (B); las secciones 9.6 y 10.7 son teoría de lo que todavía falta hacer.
> Está pensado para quien trabaja con Neo4j por primera vez: empieza por las ideas básicas y termina con preguntas de defensa.

---

## 1. Qué es una base de datos de grafos

Una base **de grafos** guarda los datos como una red: **nodos** (las cosas) unidos por **relaciones** (cómo se vinculan). Es el modelo natural cuando lo importante no es solo *qué* es cada dato sino *cómo se conectan* (quién compró qué, quién sigue a quién, qué pertenece a qué categoría).

### 1.1. Vocabulario mínimo

| Término | Qué es | En esta actividad |
| :--- | :--- | :--- |
| **Nodo** | Una entidad | Un cliente, un producto, una categoría |
| **Etiqueta** (*label*) | El tipo del nodo | `:Cliente`, `:Producto`, `:Categoria` |
| **Relación** | Un vínculo **con tipo y con dirección** entre dos nodos | `COMPRO`, `SIGUE`, `PERTENECE_A` |
| **Propiedad** | Un dato `clave: valor` dentro de un nodo o relación | `{id: 'U01', nombre: 'Ana'}` |
| **Grafo de propiedades** | Nodos y relaciones, ambos con propiedades | El modelo de Neo4j |
| **Cypher** | El lenguaje de consultas de Neo4j | Lo que ejecutamos con `cypher-shell` |

### 1.2. Cómo se dibuja un patrón en Cypher
Cypher se escribe como un dibujo con símbolos:
```cypher
(c:Cliente {id: 'U01'})-[:COMPRO]->(p:Producto)
```
| Símbolo | Significa |
| :--- | :--- |
| `( )` | Un **nodo** |
| `c` | Un nombre (variable) para referirse a él |
| `:Cliente` | Su etiqueta |
| `{id: 'U01'}` | Un filtro por propiedad |
| `-[:COMPRO]->` | Una **relación** `COMPRO` con dirección, de izquierda a derecha |

Se lee: "un cliente `U01` que compró un producto".

### 1.3. Por qué es distinto al modelo relacional
En una base relacional, relacionar tablas se hace con **claves foráneas y `JOIN`**, y cada `JOIN` se calcula al consultar. En un grafo la relación **es un dato almacenado** junto al nodo, y recorrerla no requiere buscar por clave en otra tabla. Por eso las consultas de varios saltos ("los amigos de mis amigos", "lo que compran quienes sigo") se escriben como un único patrón y su costo depende de la parte del grafo que se recorre, no del tamaño total de los datos.

| Relacional | Grafo (Neo4j) |
| :--- | :--- |
| Tabla | Etiqueta (conjunto de nodos con el mismo tipo) |
| Fila | Nodo |
| Columna | Propiedad |
| Clave foránea + `JOIN` | **Relación** almacenada |
| Tabla intermedia (muchos a muchos) | Relación entre nodos, que puede llevar propiedades |

---

## 2. El modelo de la actividad

```
(:Cliente {id, nombre}) -[:COMPRO]-> (:Producto {id, nombre, precio}) -[:PERTENECE_A]-> (:Categoria {nombre})
(:Cliente) -[:SIGUE]-> (:Cliente)
```

### 2.1. Decisiones de modelado
- **Compras y seguimientos como relaciones.** Una compra es un vínculo entre un cliente y un producto. Guardarla como una lista dentro de un campo escondería la conexión; como relación se puede recorrer.
- **La categoría como nodo** (no como texto en el producto): permite listar todos los productos de una categoría recorriendo `PERTENECE_A`, y agregar propiedades a la categoría sin tocar los productos.
- **`SIGUE` entre clientes:** es una relación de un nodo con otro del mismo tipo (relación *reflexiva*). La dirección importa: que U01 siga a U02 no implica lo contrario.

### 2.2. Datos de partida
Los CSV de la cátedra aportan 5 clientes, 8 productos y 3 categorías. Las compras de base salen de los eventos `FINALIZAR_COMPRA` del dataset (mantiene coherencia con la parte de Cassandra) y se agregaron compras y seguimientos para llegar a los mínimos: 12 `COMPRO` y 5 `SIGUE`.

---

## 3. Operaciones Cypher (CRUD)

| Operación | Cláusula | Ejemplo | Qué hace |
| :--- | :--- | :--- | :--- |
| **Crear** | `CREATE` | `CREATE (c:Cliente {id:'U99'})` | Siempre crea; si se ejecuta dos veces, duplica |
| **Crear sin duplicar** | `MERGE` | `MERGE (c:Cliente {id:'U01'})` | Busca el patrón completo; si no existe, lo crea |
| **Leer** | `MATCH` + `RETURN` | `MATCH (c:Cliente) RETURN c.nombre` | Encuentra patrones y devuelve datos |
| **Modificar** | `SET` | `MATCH (c:Cliente {id:'U99'}) SET c.nombre='Nuevo'` | Cambia o agrega propiedades |
| **Borrar relación** | `DELETE` | `MATCH (c)-[r:COMPRO]->() DELETE r` | Elimina la relación |
| **Borrar nodo** | `DELETE` | `MATCH (c:Cliente {id:'U99'}) DELETE c` | **Falla** si el nodo tiene relaciones |
| **Borrar nodo y relaciones** | `DETACH DELETE` | `MATCH (c:Cliente {id:'U99'}) DETACH DELETE c` | Elimina el nodo y todas sus relaciones |

### 3.1. Por qué `DELETE` falla si hay relaciones
Una relación no puede quedar "colgando": siempre une dos nodos. Si se intenta borrar un nodo que todavía tiene relaciones, Neo4j lo rechaza para proteger la integridad (en nuestra prueba: `G1001: dependent object error - edges still exist`). Hay dos salidas: borrar primero las relaciones y después el nodo (como pide la consigna), o usar `DETACH DELETE`.

### 3.2. `CREATE` frente a `MERGE`
`CREATE` crea siempre. `MERGE` es "buscar o crear": ejecutarlo dos veces deja una sola copia. Por eso la carga usa `MERGE`: se puede repetir sin duplicar nodos ni relaciones. Se aplica sobre el **patrón entero**, de modo que `MERGE (a)-[:SIGUE]->(b)` crea la relación solo si no existía.

---

## 4. Carga de datos con `LOAD CSV`

```cypher
LOAD CSV WITH HEADERS FROM 'file:///U9-Datos-Usuarios.csv' AS f
MERGE (c:Cliente {id: f.usuario_id}) SET c.nombre = f.nombre;
```
- Lee el CSV fila por fila; cada fila es `f`, y sus columnas se acceden por nombre del encabezado (`f.usuario_id`).
- **Todo llega como texto.** Por eso el precio se convierte con `toInteger(f.precio_ars)` para poder ordenarlo y compararlo como número.
- **Solo lee desde el directorio `import`** del servidor (`server.directories.import`, por defecto `/var/lib/neo4j/import`). Es una medida de seguridad: evita que una consulta lea archivos arbitrarios del sistema. De ahí que haya que copiar los CSV a esa carpeta.
- Las compras y los seguimientos se cargaron con `UNWIND`, que convierte una lista de pares en filas, y `MATCH` + `MERGE` para unir los nodos existentes.

---

## 5. Restricciones e índices

```cypher
CREATE CONSTRAINT cliente_id IF NOT EXISTS FOR (c:Cliente) REQUIRE c.id IS UNIQUE;
```
- Una **restricción de unicidad** impide dos nodos `Cliente` con el mismo `id`. En pruebas de laboratorio, intentar crear otro cliente con `id` repetido falló con "property uniqueness constraint violated".
- Al crearla, Neo4j crea también un **índice** sobre esa propiedad, que acelera los `MATCH` por `id` (en lugar de recorrer todos los clientes).
- Importa para `MERGE`: sin restricción, dos ejecuciones simultáneas podrían crear duplicados.

*(La consigna no exige restricciones; se incluyeron como buena práctica de modelado.)*

---

## 6. Consultas de recorrido

### 6.1. Un salto
`MATCH (c:Cliente {id:'U01'})-[:COMPRO]->(p:Producto) RETURN p.nombre` — productos que compró U01.

### 6.2. Dos saltos (C1.5)
```cypher
MATCH (:Cliente {id:'U01'})-[:SIGUE]->(s:Cliente)-[:COMPRO]->(p:Producto)
RETURN s.nombre, p.nombre
```
"A quién sigue U01 y qué compró cada uno". Es **un solo patrón** con dos relaciones. En SQL requeriría unir cliente, seguimiento, compra y producto.

### 6.3. Recomendación (C1.6)
```cypher
MATCH (u:Cliente {id:'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto)
WHERE NOT (u)-[:COMPRO]->(p)
RETURN DISTINCT p.nombre
```
La idea es **filtrado colaborativo simple**: recomendar lo que compran las personas que sigo y yo todavía no compré.
- `WHERE NOT (u)-[:COMPRO]->(p)` es un **patrón negado**: descarta los productos para los que ya existe la relación `COMPRO` desde `u`.
- Por eso `Mouse` (P102), comprado por Bruno y Carla, **no** se le recomienda a U01: ya lo compró.

### 6.4. Por qué aparecen duplicados y cómo se evitan
El patrón devuelve **una fila por camino**. Si dos seguidos compraron el mismo producto hay dos caminos y el producto sale dos veces. Se resuelve con:
- `DISTINCT`: elimina filas repetidas (igual que en SQL).
- Agrupar: `RETURN p.nombre, count(DISTINCT s)` devuelve cada producto una vez y cuántos seguidos lo compraron, útil para ordenar por relevancia.

Con los datos base no hay productos repetidos entre los seguidos de U01, así que se creó un seguimiento temporal U01→U05 para provocar y mostrar el duplicado (P101 y P108 salían dos veces sin `DISTINCT`).

---

## 7. Seguridad en Neo4j Community

### 7.1. Autenticación
- Neo4j viene con un usuario inicial **`neo4j`** y contraseña **`neo4j`**.
- Esa contraseña inicial está **caducada**: el primer acceso exige cambiarla antes de operar. Con ella se obtiene "credentials expired".
- Sin credenciales, el acceso se deniega.
- El cambio se hace con `ALTER CURRENT USER SET PASSWORD FROM 'vieja' TO 'nueva'` sobre la base `system`. Después de cambiarla, la anterior deja de funcionar.

### 7.2. Por qué Community no exige RBAC granular
**RBAC** (*Role-Based Access Control*) es dar permisos a **roles** (por ejemplo "solo lectura") y asignar los roles a usuarios. En Neo4j:

| Capacidad | Community | Enterprise |
| :--- | :---: | :---: |
| Autenticación con usuario y contraseña | Sí | Sí |
| Roles y privilegios (`GRANT`, `DENY`, `SHOW ROLES`) | **No** | Sí |
| Permisos por base, grafo, etiqueta o propiedad | **No** | Sí |
| Respaldo en caliente (*online backup*) | **No** | Sí |
| Varias bases de datos de usuario, clustering | **No** | Sí |

Lo comprobamos en el motor: en Community, `SHOW ROLES` y `GRANT ROLE` devuelven *"not supported in community edition"*. En nuestras pruebas de laboratorio también observamos que se pueden crear usuarios adicionales con `CREATE USER`, pero sin roles todos tienen acceso completo.

Por eso la consigna no exige RBAC granular en esta edición: el motor no lo ofrece. La protección depende de:
1. una **contraseña robusta** distinta de la inicial,
2. que el servicio **escuche solo en `localhost`** (en nuestro caso `127.0.0.1`),
3. los **permisos del sistema operativo** sobre los archivos y el servicio.

### 7.3. Credenciales en scripts y capturas
La consigna pide que los scripts **no contengan credenciales**. Por eso la contraseña se pasa por variable de entorno o se pide de forma oculta, y en las capturas el comando muestra `<nueva_clave>`.

---

## 8. Respaldo y recuperación

### 8.1. Dump offline
```bash
neo4j-admin database dump neo4j --to-path=/ruta/respaldo
```
- Genera un archivo `neo4j.dump` con la base completa.
- En Community **la base debe estar detenida**: con el servicio activo Neo4j responde *"The database is in use. Stop database 'neo4j' and try again."* Por eso se detiene el servicio, se hace el dump y se vuelve a iniciar.
- El respaldo **en caliente** (sin detener el servicio) es una funcionalidad de Enterprise.
- Es un respaldo **físico** de la base, no una exportación de sentencias: se restaura completo.

### 8.2. Carga en un entorno aislado
```bash
neo4j-admin database load neo4j --from-path=/ruta/respaldo --overwrite-destination=true
```
- Se ejecuta con la instancia **detenida** y reemplaza la base de destino.
- "Entorno aislado" significa **no tocar el servicio compartido**. Lo logramos con una segunda instancia con configuración propia (`NEO4J_CONF`): otro directorio de datos y otros puertos (7688 Bolt, 7475 HTTP).

### 8.3. Cómo se valida una restauración
La consigna exige **una evidencia antes y otra después**: no alcanza con tener el archivo de backup. El procedimiento fue:

| Verificación | Resultado |
| :--- | :--- |
| Origen antes del dump | 16 nodos, 25 relaciones |
| Instancia aislada **antes** de cargar | 0 y 0 (está vacía) |
| Instancia aislada **después** de cargar | 16 y 25 |
| Una consulta de negocio (recomendación C1.6) en la copia | Mismos 4 productos que el origen |
| Comparación completa (nodos y relaciones) con `diff` | Sin diferencias |
| `sha256sum` del `.dump` | Identifica el archivo respaldado |

Contar nodos y relaciones demuestra que *hay* datos; la consulta y el `diff` demuestran que son *los mismos* datos.

---

## 9. Redis (parte A)

### 9.1. Qué es
Redis es un almacén **clave-valor en memoria**: cada dato se guarda bajo una clave y el valor puede ser una estructura (texto, hash, conjunto, conjunto ordenado). Al estar en memoria, las lecturas y escrituras son muy rápidas, por eso se usa para **sesiones, carritos, cachés y rankings**. Opcionalmente guarda copias en disco (persistencia RDB o AOF). No consulta por relaciones ni por contenido: se accede **por clave**.

### 9.2. Estructuras usadas en la actividad

| Estructura | Uso en OmniMarket | Comandos | Retornos que conviene entender |
| :--- | :--- | :--- | :--- |
| `STRING` | Sesión (`sesion:U01`) | `SET`, `GET`, `DEL`, `EXISTS`, `SET ... EX 30` | `SET` pisa el valor anterior; `DEL` devuelve cuántas claves borró; `EXISTS` devuelve 1 o 0 |
| `HASH` | Carrito (`carrito:U01`: producto → cantidad) | `HSET`, `HGETALL`, `HDEL` | **`HSET` devuelve la cantidad de campos nuevos**: 2 al crear dos campos, 0 si solo actualiza uno existente |
| `SET` | Favoritos (`favoritos:U01`) | `SADD`, `SISMEMBER`, `SREM` | Sin repetidos; `SADD`/`SREM` devuelven 1 si cambiaron algo; `SISMEMBER` devuelve 1 o 0 |
| `SORTED SET` | Ranking (`ranking_productos`) | `ZADD`, `ZREVRANGE ... WITHSCORES` | Cada miembro tiene un puntaje que ordena el conjunto; `ZREVRANGE 0 2` toma las tres primeras posiciones de mayor a menor |

> `ZREVRANGE` está marcado como obsoleto desde Redis 6.2 en favor de `ZRANGE ... REV`, pero sigue funcionando y devuelve lo mismo.

### 9.3. Nombres de clave `tipo:id`
Usar prefijos (`sesion:`, `carrito:`, `favoritos:`, `ranking_`) ordena el espacio de claves y permite **restringir permisos por patrón** en una ACL (`~sesion:*`).

### 9.4. Expiración (TTL)
`SET clave valor EX 30` crea la clave con vencimiento a los 30 segundos. `TTL` informa los segundos restantes:
| Valor de `TTL` | Significa |
| :--- | :--- |
| Número positivo | Segundos que faltan para que expire |
| `-1` | La clave existe pero **no tiene** vencimiento |
| `-2` | La clave **no existe** (por ejemplo, ya expiró) |

Es el mecanismo natural para sesiones temporales y tokens.

### 9.5. ACL: usuarios, claves y comandos permitidos
Una **ACL** (*Access Control List*) define qué puede hacer cada usuario:
```text
ACL SETUSER app_user on >clave ~sesion:* ~carrito:* ~favoritos:* ~ranking_* +@read +@write -@dangerous +ping
```
| Regla | Significado |
| :--- | :--- |
| `on` / `off` | Activa / desactiva el usuario |
| `>clave` | Define su contraseña |
| `~patrón` | Claves que puede tocar |
| `+@categoría` / `-@categoría` | Permite / quita una categoría de comandos (`@read`, `@write`, `@dangerous`...) |
| `+comando` | Permite un comando puntual (`+ping`) |

- Si el usuario intenta algo no permitido, Redis responde **`NOPERM`**.
- **Cuidado:** los patrones de claves **no** limitan comandos que afectan a toda la base. La categoría `@write` incluye `FLUSHALL` y `FLUSHDB`; en pruebas de laboratorio un usuario con `+@read +@write` pudo vaciar la base completa. Para restringirlo de verdad se agrega `-@dangerous` (quita `FLUSHALL`, `FLUSHDB`, `KEYS`, `CONFIG`...).
- **El usuario `default`** existe sin contraseña y con acceso total. La ACL de `app_user` solo limita a quien se autentica como `app_user`; una conexión sin `AUTH` sigue siendo `default`. En un entorno real también se restringe o protege ese usuario.
- Las reglas creadas con `ACL SETUSER` están en memoria: para que sobrevivan a un reinicio hay que guardarlas (archivo de ACL o `CONFIG REWRITE`).
- Las contraseñas no deben aparecer en capturas ni en scripts: se usa un marcador (`<clave>`) o una variable.

### 9.6. Respaldo y restauración RDB (pendiente de evidencia)
- **RDB** es una **foto** (*snapshot*) del conjunto de datos en un momento dado, guardada en un archivo (por defecto `dump.rdb`).
- Se genera con `SAVE` (bloquea el servidor) o `BGSAVE` (en segundo plano). La carpeta y el nombre se consultan con `CONFIG GET dir` y `CONFIG GET dbfilename`.
- **Copia consistente:** Redis escribe el RDB en un archivo temporal y lo renombra al terminar, por lo que se copia **después** de que el guardado haya finalizado (se comprueba con `LASTSAVE` o `INFO persistence`).
- **Restauración:** se levanta **otra instancia** (otro puerto y otro directorio) con ese archivo en su directorio de datos y se comparan claves y valores con la original. Así no se sobrescribe el servicio compartido.
- Alternativa: **AOF** registra cada escritura (más durabilidad, archivo más grande); RDB es más compacto pero puede perder lo escrito desde la última foto.

---

## 10. Cassandra (parte B)

### 10.1. Qué es
Apache Cassandra es una base **distribuida, de columnas anchas**, pensada para **mucho volumen de escritura** y alta disponibilidad, sin uniones (*joins*). Su regla de oro: **se diseña la tabla a partir de la consulta**, no al revés. En la actividad se usa un solo nodo.

### 10.2. La clave primaria: partición y clustering
```sql
PRIMARY KEY ((usuario_id), fecha_evento, evento_id)
```
| Parte | Función |
| :--- | :--- |
| **Clave de partición** `usuario_id` | Decide en qué nodo/partición se guarda la fila; todas las filas con el mismo `usuario_id` quedan juntas |
| **Claves de clustering** `fecha_evento`, `evento_id` | Ordenan las filas **dentro** de la partición; `evento_id` desempata fechas iguales |

`WITH CLUSTERING ORDER BY (fecha_evento DESC, ...)` fija el orden físico (en la actividad, del más reciente al más antiguo).

### 10.3. Qué consultas son eficientes
- **Siempre se indica la clave de partición**: así Cassandra va directo a una partición.
- Dentro de la partición se pueden usar **rangos** y `ORDER BY`, **solo sobre columnas de clustering** y respetando su orden (`fecha_evento >= ... AND fecha_evento <= ...`).
- **`LIMIT` toma las primeras filas en el orden de la tabla.** En una prueba de laboratorio con la misma data: con orden descendente `LIMIT 3` devolvió los tres eventos **más recientes**; con orden por defecto (ascendente) devolvió los tres **más antiguos**. Por eso "los últimos tres eventos" requiere clustering descendente (o `ORDER BY ... DESC`).

### 10.4. `INSERT`, `UPDATE` y `DELETE`
- Las tres operaciones identifican la fila por la **clave primaria completa** (partición + clustering).
- **`INSERT` y `UPDATE` son *upsert***: si la fila no existe, se crea. En una prueba de laboratorio un `UPDATE` sobre una clave inexistente **creó una fila nueva** sin dar error; por eso hay que verificar con un `SELECT` después de cada operación.
- `DELETE` no borra de inmediato: marca la fila con una *lápida* (*tombstone*) que se limpia más tarde.

### 10.5. Filtrar por una columna que no es clave: `ALLOW FILTERING`
Consultar por `tipo_evento` (que no es parte de la clave) obliga a revisar **todas las particiones**. Cassandra lo rechaza con `InvalidRequest ... code=2200 ... use ALLOW FILTERING`.
- `ALLOW FILTERING` solo **fuerza** ese recorrido completo: con mucho dato es lento e impredecible. No es una solución.
- La solución de Cassandra es la **desnormalización**: una **tabla nueva** diseñada para esa consulta (`eventos_por_tipo`, con `tipo_evento` como clave de partición). El costo es que la aplicación debe **escribir en ambas tablas**.
- **Cuidado con la cardinalidad de la clave de partición:** `tipo_evento` tiene solo cinco valores, por lo que, con volumen real, cada partición crecería sin límite y la carga se concentraría en pocos nodos. Se resuelve con un "cubo" en la clave, por ejemplo `(tipo_evento, dia)`.
- Crear la tabla nueva vacía no demuestra nada: hay que **cargarla** y mostrar el resultado.

### 10.6. Fechas (`timestamp`)
Una fecha escrita sin zona horaria se interpreta con la **zona horaria del cliente** (`cqlsh`), y se muestra en UTC. En una máquina que no está en UTC las horas pueden aparecer desplazadas; conviene comprobar que los datos cargados coincidan con el CSV o escribir las fechas con zona explícita (`+0000`).

### 10.7. Seguridad, snapshot y restauración (pendiente de evidencia)
- **Autenticación y autorización:** por defecto Cassandra no exige credenciales (`AllowAllAuthenticator`). Se activan en `cassandra.yaml` con `PasswordAuthenticator` y `CassandraAuthorizer` y reiniciando el nodo; el superusuario inicial es `cassandra`/`cassandra` y debe cambiarse. Los **roles** permiten crear uno de solo lectura con `GRANT SELECT ON KEYSPACE omnimarket TO rol`.
- **Snapshot:** `nodetool snapshot` crea una copia de las SSTables mediante enlaces duros, dentro de una carpeta `snapshots/` en el directorio de datos de cada tabla; es instantáneo y casi no ocupa espacio adicional.
- **Restauración en un entorno de prueba:** se copian las SSTables del snapshot al directorio de una tabla con la misma estructura y se cargan con `nodetool refresh` o `sstableloader`; luego se comparan recuentos y una muestra de registros con el origen. Las SSTables deben ser compatibles con la versión.

---

## 11. Comparación entre los tres motores

| Criterio | Redis | Cassandra | Neo4j |
| :--- | :--- | :--- | :--- |
| Modelo | Clave-valor con estructuras (`STRING`, `HASH`, `SET`, `SORTED SET`) | Tabla por consulta: clave de partición + clustering | **Grafo de propiedades** |
| Mejor para | Sesiones, carritos, rankings, caché, TTL | Historial de eventos, alto volumen de escritura | **Relaciones y recorridos** (recomendaciones, redes) |
| Consulta | Comandos por clave | CQL, siempre guiada por la clave de partición | **Cypher** por patrones |
| Seguridad | ACL por usuario (claves y categorías de comandos) | Autenticación y roles (a habilitar) | Autenticación; sin roles en Community |
| Respaldo | Foto RDB (o AOF) | Snapshot de SSTables | Dump **offline** con `neo4j-admin` |
| Punto débil | No consulta por relaciones ni por contenido | No admite consultas arbitrarias: hay que diseñar una tabla por consulta | Escala horizontal limitada en Community |

---

## 12. Preguntas de defensa (respuestas breves)

### Neo4j
1. **¿Qué es un grafo de propiedades?** Nodos con etiquetas y propiedades unidos por relaciones con tipo, dirección y propiedades.
2. **¿Por qué las compras son relaciones y no una lista?** Porque como relación se pueden recorrer; una recomendación pasa a ser un patrón y no una unión.
3. **¿Qué diferencia hay entre `CREATE` y `MERGE`?** `CREATE` siempre crea; `MERGE` busca el patrón y solo lo crea si no existe, por lo que no duplica.
4. **¿Por qué `DELETE` falla en un nodo con relaciones?** Una relación no puede quedar sin uno de sus extremos. Se borran primero las relaciones o se usa `DETACH DELETE`.
5. **¿Cómo funciona la recomendación?** Recorre `SIGUE` y `COMPRO` hasta los productos de mis seguidos y excluye con `WHERE NOT` los que ya compré.
6. **¿Para qué sirve `DISTINCT` ahí?** El patrón devuelve una fila por camino; si dos seguidos compraron lo mismo, el producto se repetiría. `DISTINCT` lo colapsa.
7. **¿Por qué hay que cambiar la contraseña inicial?** Porque `neo4j/neo4j` es pública y viene caducada: Neo4j obliga a cambiarla antes de operar.
8. **¿Por qué Community no tiene RBAC granular?** Roles y privilegios son una funcionalidad de Enterprise. En Community solo hay autenticación; la protección depende de la clave, del acceso por red y del sistema operativo.
9. **¿Por qué el dump es offline?** Porque Community no ofrece respaldo en caliente: la base debe estar detenida para copiarla de forma consistente.
10. **¿Cómo se sabe que la restauración funcionó?** Con evidencia antes y después: la copia aislada estaba vacía (0/0), luego tuvo 16/25, devolvió la misma consulta que el origen y el `diff` no mostró diferencias.
11. **¿Por qué se restaura en una instancia aparte?** Para no sobrescribir el servicio compartido; las pruebas destructivas se hacen solo en entornos de laboratorio.
12. **¿Por qué `LOAD CSV` exige copiar los archivos a `import`?** Es una medida de seguridad: el servidor solo lee archivos de un directorio acotado.

### Redis
13. **¿Por qué `HSET` devolvió 0 al modificar la cantidad?** Devuelve la cantidad de campos *nuevos*; el campo ya existía, así que solo se actualizó su valor.
14. **¿Qué significa `TTL` igual a `-2`?** Que la clave no existe (por ejemplo, ya expiró). `-1` significa que existe sin vencimiento.
15. **¿Por qué una ACL con `+@read +@write` no alcanza para "restringir a claves del laboratorio"?** Porque los patrones de claves no limitan comandos como `FLUSHALL`, que está en `@write` y vacía toda la base. Se agrega `-@dangerous`.
16. **¿Qué pasa con el usuario `default`?** Sigue sin contraseña y con acceso total: la ACL de `app_user` solo limita a quien se autentica con él.
17. **¿Cómo se respalda y se restaura con RDB?** `BGSAVE` genera el `dump.rdb`; se copia cuando el guardado terminó y se restaura levantando otra instancia con ese archivo, comparando claves y valores con la original.

### Cassandra
18. **¿Por qué `UPDATE` y `DELETE` piden toda la clave primaria?** Porque la clave primaria (partición + clustering) identifica la fila exacta; además `UPDATE` es un *upsert*: si la clave no existe, crea una fila nueva.
19. **¿Por qué `LIMIT 3` devuelve los tres últimos eventos?** Porque la tabla guarda cada partición en orden descendente por `fecha_evento` y `LIMIT` toma las primeras filas en ese orden. Con orden ascendente devolvería las tres más antiguas.
20. **¿Por qué no se usa `ALLOW FILTERING`?** Solo fuerza un recorrido de todas las particiones: es lento e impredecible con volumen. Se crea una tabla pensada para esa consulta.
21. **¿Qué limitación tiene `eventos_por_tipo`?** `tipo_evento` tiene pocos valores: las particiones crecerían sin límite y concentrarían la carga. Se mitiga con un cubo en la clave, por ejemplo `(tipo_evento, dia)`.
22. **¿Por qué la consulta por rango de fechas es eficiente?** Porque indica la clave de partición y el rango recae sobre una columna de clustering, que está ordenada dentro de la partición.

---

## 13. Partes pendientes

| Motor | Falta |
| :--- | :--- |
| Redis | Respaldo RDB y restauración en instancia aislada (con evidencia antes y después) |
| Cassandra | Autenticación y rol de solo lectura, snapshot y restauración con SSTables (con evidencia antes y después) |
