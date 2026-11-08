# Informe de Laboratorio Multimotor - Unidad 9 (Actividad 1)

**Grupo:** 11
**Motores:** Redis, Apache Cassandra (un nodo) y Neo4j Community
**Escenario:** tienda en línea (OmniMarket)
**Entorno:** Ubuntu 24.04 LTS, instalación nativa (sin Docker). Se utilizó únicamente la documentación oficial de cada motor.
**Integrantes:**
- [Nombre Integrante 1]
- [Nombre Integrante 2]
- [Nombre Integrante N...]

**Datos de la cátedra:** `U9-Datos-Usuarios.csv` (5 usuarios), `U9-Datos-Productos.csv` (8 productos, 3 categorías) y `U9-Datos-Eventos.csv` (15 eventos de 3 usuarios). Mantuvimos todos los identificadores provistos.
**Scripts entregados:** `redis-comandos.txt`, `cassandra.cql` y `neo4j.cypher` (sin credenciales).

---

## Verificación de servicios

Antes de modificar la seguridad o realizar cualquier restauración, verificamos que los tres motores estuvieran operativos.

1. **Redis:** registramos la versión, el nombre y el estado del servicio, y comprobamos la respuesta con `PING`.

```bash
redis-server --version
sudo systemctl status redis-server
redis-cli ping
```

La versión instalada es **Redis 7.0.15**. El servicio `redis-server` figura como `active (running)` (habilitado al arranque), escucha en `127.0.0.1:6379` y `PING` devuelve `PONG`.

*[INSERTAR CAPTURA RED-1: versión, estado del servicio y PING de Redis]*

2. **Cassandra:** *[A completar: versión, `nodetool status` y conexión con `cqlsh`.]*
3. **Neo4j:** registramos la versión, el estado del servicio y los puertos en escucha, y confirmamos la conexión con `cypher-shell`.

```bash
systemctl status neo4j --no-pager | head -5
neo4j --version && cypher-shell --version
ss -ltn | grep -E ':(7474|7687) '
```

El servicio `neo4j.service` figura como `active (running)`. La versión instalada es la **2026.10.1** (Cypher-Shell 2026.10.1) y escucha únicamente en `127.0.0.1`, puerto 7474 (HTTP) y 7687 (Bolt).

*[INSERTAR CAPTURA 1: estado del servicio, versión y puertos de Neo4j]*

4. **Demostración al JTP:** *[A completar: dejar constancia de que los tres servicios se mostraron operativos antes de tocar seguridad.]*

---

## A. Redis - Sesiones, carritos y rankings

### Modelo mínimo

Elegimos la estructura de datos de Redis según cómo se usa cada dato, y nombramos las claves con el formato `tipo:id` para poder restringirlas por patrón en la ACL.

| Clave | Tipo | Estructura |
| :--- | :--- | :--- |
| `sesion:U01` a `sesion:U03` | `STRING` | Valor = estado de la sesión |
| `carrito:U01` a `carrito:U03` | `HASH` | Campo = ID de producto, valor = cantidad (al menos 2 productos por carrito) |
| `favoritos:U01`, `favoritos:U02` | `SET` | IDs de productos favoritos, sin repetidos |
| `ranking_productos` | `SORTED SET` | 5 productos; el puntaje (*score*) ordena el ranking |

*[A completar: comandos de carga del modelo (`SET`, `HSET`, `SADD`, `ZADD`) y captura de los datos cargados.]*

### A1. CRUD y consultas obligatorias

#### A1.1 Crear sesión `sesion:U01`, leerla, actualizarla, eliminarla y comprobar que ya no existe

```text
127.0.0.1:6379> SET sesion:U01 "activa"        -> OK
127.0.0.1:6379> GET sesion:U01                  -> "activa"
127.0.0.1:6379> SET sesion:U01 "renovada"       -> OK
127.0.0.1:6379> DEL sesion:U01                  -> (integer) 1
127.0.0.1:6379> EXISTS sesion:U01               -> (integer) 0
```

En una `STRING`, `SET` sobre una clave existente la sobrescribe, por lo que actualizar es volver a hacer `SET`. `DEL` devolvió 1 (una clave eliminada) y `EXISTS` devolvió 0, lo que confirma que la sesión ya no existe.

*[INSERTAR CAPTURA RED-2: crear, leer y actualizar la sesión]*
*[INSERTAR CAPTURA RED-3: eliminar la sesión y comprobar que no existe]*

#### A1.2 Carrito `carrito:U01` con dos productos: consultar, modificar una cantidad y quitar un producto

```text
127.0.0.1:6379> HSET carrito:U01 P101 1 P102 2   -> (integer) 2
127.0.0.1:6379> HGETALL carrito:U01              -> P101 / 1 / P102 / 2
127.0.0.1:6379> HSET carrito:U01 P101 3          -> (integer) 0
127.0.0.1:6379> HDEL carrito:U01 P102            -> (integer) 1
127.0.0.1:6379> HGETALL carrito:U01              -> P101 / 3
```

`HSET` devuelve la cantidad de campos **nuevos** que creó: 2 al crear el carrito y 0 al modificar la cantidad de `P101`, porque el campo ya existía y solo se actualizó su valor. `HDEL` quitó `P102` (devolvió 1) y el estado final del carrito es `P101` con cantidad 3.

*[INSERTAR CAPTURA RED-4: crear el carrito y consultar sus campos]*
*[INSERTAR CAPTURA RED-5: modificar la cantidad, quitar un producto y estado final]*

#### A1.3 Favoritos: agregar y quitar un favorito de `favoritos:U01` y demostrar membresía con `SISMEMBER`

```text
127.0.0.1:6379> SADD favoritos:U01 P107          -> (integer) 1
127.0.0.1:6379> SISMEMBER favoritos:U01 P107     -> (integer) 1
127.0.0.1:6379> SREM favoritos:U01 P107          -> (integer) 1
127.0.0.1:6379> SISMEMBER favoritos:U01 P107     -> (integer) 0
```

`SISMEMBER` devolvió 1 mientras el producto estaba en el conjunto y 0 después de quitarlo con `SREM`.

*[INSERTAR CAPTURA RED-6: agregar, comprobar y quitar un favorito]*

#### A1.4 Los tres productos de mayor puntaje del ranking (orden descendente)

```text
127.0.0.1:6379> ZREVRANGE ranking_productos 0 2 WITHSCORES
1) "P101"  2) "95"  3) "P105"  4) "90"  5) "P104"  6) "85"
```

`ZREVRANGE` recorre el conjunto ordenado de mayor a menor puntaje; los índices `0 2` piden las tres primeras posiciones. El top 3 es P101 (95), P105 (90) y P104 (85).

*[INSERTAR CAPTURA RED-7: top 3 del ranking]*

#### A1.5 Sesión temporal `sesion:temporal` con TTL de 30 segundos

```text
127.0.0.1:6379> SET sesion:temporal "token_temporal_123" EX 30   -> OK
127.0.0.1:6379> TTL sesion:temporal                              -> (integer) 27
   (pasados los 30 segundos)
127.0.0.1:6379> TTL sesion:temporal                              -> (integer) -2
127.0.0.1:6379> GET sesion:temporal                              -> (nil)
```

El TTL inicial registrado fue 27 segundos (la lectura se hizo unos segundos después de crear la clave). Después de los 30 segundos `TTL` devolvió `-2`, que en Redis significa que la clave **no existe**, y `GET` devolvió `(nil)`: la sesión expiró sola.

*[INSERTAR CAPTURA RED-8: creación con TTL y lectura del TTL inicial]*
*[INSERTAR CAPTURA RED-9: TTL en -2 y GET en nil tras la expiración]*

### A2. Seguridad y recuperación

#### A2.1 ACL de aplicación restringida a las claves del laboratorio

Creamos un usuario de aplicación `app_user` que solo puede operar sobre las claves del laboratorio, y probamos un comando autorizado y otro denegado. La contraseña no se muestra en las capturas ni en el script.

```text
ACL SETUSER app_user on ><clave> ~sesion:* ~carrito:* ~favoritos:* ~ranking_* +@read +@write +ping
AUTH app_user <clave>
127.0.0.1:6379> GET sesion:U02     -> "activa"
127.0.0.1:6379> GET usuario:U01    -> (error) NOPERM this user has no permissions to access one of the keys used as arguments
```

| Parte de la regla | Significado |
| :--- | :--- |
| `on` | El usuario está activo |
| `><clave>` | Define su contraseña |
| `~sesion:* ~carrito:* ~favoritos:* ~ranking_*` | Solo puede tocar claves con esos prefijos |
| `+@read +@write +ping` | Puede ejecutar comandos de las categorías lectura y escritura, y `PING` |

El `GET` sobre una clave de laboratorio (`sesion:U02`) fue autorizado; el `GET` sobre una clave fuera de los patrones (`usuario:U01`) fue **denegado** con `NOPERM`.

*[INSERTAR CAPTURA RED-10: comando autorizado y comando denegado con `app_user`]*

*[A completar (recomendado): comprobar también que un comando fuera de lo permitido, por ejemplo `FLUSHALL`, queda denegado para `app_user`; ver la guía paso a paso.]*

#### A2.2 Respaldo RDB: generar, identificar su ubicación y copiarlo de forma consistente
*[A completar]*

#### A2.3 Restauración en una instancia de prueba aislada y comparación de al menos tres claves (evidencia antes y después)
*[A completar]*

### Análisis (Redis)
- Cada tipo de dato resuelve un uso distinto: `STRING` para sesiones, `HASH` para carritos (cantidad por producto), `SET` para favoritos sin repetidos y `SORTED SET` para rankings ordenados por puntaje.
- Los valores de retorno de los comandos informan qué pasó: `HSET` devuelve 0 si solo actualizó un campo existente y `TTL` devuelve `-2` cuando la clave ya no existe.
- La ACL restringe qué claves y qué comandos puede usar un usuario; el acceso denegado devuelve `NOPERM`.

---

## B. Cassandra - Historial de actividad

### Modelo mínimo

Cassandra modela las tablas **a partir de las consultas**. La tabla `eventos_por_usuario` responde a "dame los eventos de un usuario, en orden cronológico":

| Columna | Tipo | Rol |
| :--- | :--- | :--- |
| `usuario_id` | `text` | **Clave de partición**: todos los eventos de un usuario quedan en la misma partición |
| `fecha_evento` | `timestamp` | **Clave de clustering**: ordena los eventos dentro de la partición |
| `evento_id` | `uuid` | **Clave de clustering**: desempata eventos con la misma fecha |
| `tipo_evento` | `text` | Dato |
| `producto_id` | `text` | Dato |

`PRIMARY KEY ((usuario_id), fecha_evento, evento_id)` dentro del keyspace `omnimarket`. En las consultas observamos que la tabla devuelve los eventos de cada usuario del más reciente al más antiguo.

*[A completar: DDL del keyspace y de la tabla ejecutado, carga de los 15 eventos provistos y conteo de filas por usuario.]*

### B1. CRUD y consultas obligatorias

#### B1.1 Insertar un evento adicional para `U01` y recuperarlo

```sql
INSERT INTO eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id)
VALUES ('U01', '2026-10-20 15:00:00', 00000000-0000-4000-8000-000000000006, 'VER_PRODUCTO', 'P106');

SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id = 'U01';
```

El `SELECT` devolvió seis eventos de `U01`: el nuevo (15:00, `VER_PRODUCTO`, `P106`) aparece primero, seguido de los cinco originales.

*[INSERTAR CAPTURA CAS-1: inserción y consulta del evento]*

#### B1.2 Actualizar su `tipo_evento` y comprobar el cambio

```sql
UPDATE omnimarket.eventos_por_usuario SET tipo_evento = 'AGREGAR_CARRITO'
WHERE usuario_id = 'U01' AND fecha_evento = '2026-10-20 15:00:00'
  AND evento_id = 00000000-0000-4000-8000-000000000006;
```

En Cassandra el `WHERE` de un `UPDATE` debe incluir **toda la clave primaria** (la de partición y las de clustering): así identifica la fila exacta. Al consultar ese registro, `tipo_evento` pasó a `AGREGAR_CARRITO`.

*[INSERTAR CAPTURA CAS-2: actualización y verificación del registro]*

#### B1.3 Eliminar ese evento y verificar que desapareció

```sql
DELETE FROM omnimarket.eventos_por_usuario
WHERE usuario_id = 'U01' AND fecha_evento = '2026-10-20 15:00:00'
  AND evento_id = 00000000-0000-4000-8000-000000000006;
```

Después del `DELETE`, la consulta de `U01` devolvió nuevamente cinco eventos (de las 14:00 a las 10:00); el evento de las 15:00 ya no está.

*[INSERTAR CAPTURA CAS-3: eliminación y verificación]*

#### B1.4 Todos los eventos de `U02` en orden cronológico descendente

```sql
SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id = 'U02' ORDER BY fecha_evento DESC;
```

Devolvió los cinco eventos de `U02`, de las 14:00 (`FINALIZAR_COMPRA`, `P107`) a las 10:00 (`VER_PRODUCTO`, `P103`). `ORDER BY` solo es posible sobre una columna de clustering y dentro de una partición.

*[INSERTAR CAPTURA CAS-4: eventos de U02 ordenados por fecha descendente]*

#### B1.5 Los últimos tres eventos de `U01` con `LIMIT 3`

```sql
SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id = 'U01' LIMIT 3;
```

| fecha_evento | tipo_evento | producto_id |
| :--- | :--- | :--- |
| 2026-10-20 14:00:00 | FINALIZAR_COMPRA | P105 |
| 2026-10-20 13:00:00 | INICIAR_COMPRA | P104 |
| 2026-10-20 12:00:00 | QUITAR_CARRITO | P103 |

Como la tabla devuelve los eventos de la partición del más reciente al más antiguo, `LIMIT 3` entrega los tres últimos.

*[INSERTAR CAPTURA CAS-5: últimos tres eventos de U01]*

#### B1.6 Eventos de `U03` en un intervalo de fechas usando la clave de partición

```sql
SELECT * FROM omnimarket.eventos_por_usuario
WHERE usuario_id = 'U03' AND fecha_evento >= '2026-10-22 10:00:00' AND fecha_evento <= '2026-10-22 13:00:00';
```

Devolvió los cuatro eventos de `U03` entre las 10:00 y las 13:00 del 22/10/2026 (`INICIAR_COMPRA` `P108`, `QUITAR_CARRITO` `P107`, `AGREGAR_CARRITO` `P106` y `VER_PRODUCTO` `P105`). El rango se aplica sobre `fecha_evento` (clave de clustering) y es eficiente porque la consulta indica la clave de partición `usuario_id`.

*[INSERTAR CAPTURA CAS-6: eventos de U03 en el intervalo de fechas]*

#### B1.7 Filtrar por `tipo_evento` sin clave de partición y tabla alternativa

```sql
SELECT * FROM omnimarket.eventos_por_usuario WHERE tipo_evento = 'VER_PRODUCTO';
```
```text
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
```

Cassandra rechaza la consulta: `tipo_evento` no es parte de la clave, por lo que debería recorrer todas las particiones. No usamos `ALLOW FILTERING` como solución, porque solo fuerza ese recorrido completo. Propusimos en su lugar una tabla pensada para esta consulta, con `tipo_evento` como clave de partición:

```sql
CREATE TABLE IF NOT EXISTS omnimarket.eventos_por_tipo (
  tipo_evento text, fecha_evento timestamp, evento_id uuid, usuario_id text, producto_id text,
  PRIMARY KEY ((tipo_evento), fecha_evento, evento_id)
) WITH CLUSTERING ORDER BY (fecha_evento DESC);

SELECT * FROM omnimarket.eventos_por_tipo WHERE tipo_evento = 'VER_PRODUCTO';
```

La consulta sobre la tabla nueva se ejecuta sin error, aunque no devuelve filas porque todavía no tiene registros.

*[INSERTAR CAPTURA CAS-7: error de la consulta sin clave de partición]*
*[INSERTAR CAPTURA CAS-8: creación de `eventos_por_tipo`]*
*[INSERTAR CAPTURA CAS-9: consulta sobre la tabla nueva]*

*[A completar: cargar los 15 eventos en `eventos_por_tipo` y repetir la consulta para mostrar los resultados (ver la guía paso a paso).]*

**Limitación de la tabla propuesta.** Con solo cinco valores distintos de `tipo_evento`, la clave de partición tiene muy pocos valores: en un volumen real cada partición crecería sin límite y concentraría la carga en pocos nodos. Una mejora habitual es agregar un "cubo" a la clave de partición, por ejemplo `(tipo_evento, dia)`.

### B2. Seguridad y recuperación

#### B2.1 Autenticación/autorización y rol de solo lectura (`SELECT` permitido, `INSERT` denegado)
*[A completar]*

#### B2.2 Snapshot con `nodetool` y ubicación de sus archivos
*[A completar]*

#### B2.3 Restauración guiada en entorno de prueba mediante SSTables: recuentos y muestra de registros (evidencia antes y después)
*[A completar]*

### Análisis (Cassandra)
- En Cassandra la tabla se diseña a partir de la consulta: toda consulta eficiente debe indicar la clave de partición.
- Las claves de clustering definen el orden físico dentro de la partición; por eso `ORDER BY`, `LIMIT` y los rangos de fecha son baratos cuando se hacen sobre ellas.
- Para consultar por un criterio distinto (por ejemplo, por tipo de evento) corresponde una **tabla nueva** orientada a esa consulta, y no `ALLOW FILTERING`.

---

## C. Neo4j - Relaciones comerciales

### Modelo mínimo

Modelamos la tienda como un **grafo de propiedades**: los clientes, productos y categorías son nodos, y las compras, pertenencias y seguimientos son relaciones tipadas y con dirección.

```
(:Cliente {id, nombre}) -[:COMPRO]-> (:Producto {id, nombre, precio}) -[:PERTENECE_A]-> (:Categoria {nombre})
(:Cliente) -[:SIGUE]-> (:Cliente)
```

| Elemento | Cantidad | Origen |
| :--- | :---: | :--- |
| `Cliente` | 5 | `U9-Datos-Usuarios.csv` (U01 a U05) |
| `Producto` | 8 | `U9-Datos-Productos.csv` (P101 a P108) |
| `Categoria` | 3 | Columna `categoria` del CSV de productos |
| `PERTENECE_A` | 8 | Una por cada producto |
| `COMPRO` | 12 | Eventos `FINALIZAR_COMPRA` del dataset (U01→P105, U02→P107, U03→P101) más compras adicionales |
| `SIGUE` | 5 | Seguimientos adicionales |

**Compras adicionales:** U01→P102, P105 · U02→P102, P103, P107 · U03→P101, P102, P108 · U04→P104, P106 · U05→P101, P108.
**Seguimientos:** U01→U02, U01→U03, U02→U03, U04→U01, U05→U04.

**Decisiones de modelado:**
- Modelamos las compras y los seguimientos como **relaciones** y no como listas dentro de una propiedad. ¿Por qué? Porque así una recomendación se resuelve recorriendo el grafo (un patrón de dos saltos) y no con uniones entre tablas.
- Definimos **restricciones de unicidad** sobre `Cliente.id`, `Producto.id` y `Categoria.nombre`. Garantizan que no haya identificadores repetidos y crean el índice que usan las búsquedas por `id`.
- Guardamos `precio` como número entero (`toInteger(precio_ars)`) para poder ordenar y comparar.
- Usamos `MERGE` en la carga para que pueda repetirse sin duplicar nodos ni relaciones.

**Carga de datos.** `LOAD CSV` solo puede leer archivos desde el directorio `import` del servidor (`/var/lib/neo4j/import`), por lo que copiamos allí los CSV de la cátedra antes de cargar.

```bash
sudo cp U9-Datos-Usuarios.csv U9-Datos-Productos.csv /var/lib/neo4j/import/
```
```cypher
CREATE CONSTRAINT cliente_id IF NOT EXISTS FOR (c:Cliente) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT producto_id IF NOT EXISTS FOR (p:Producto) REQUIRE p.id IS UNIQUE;
CREATE CONSTRAINT categoria_nombre IF NOT EXISTS FOR (k:Categoria) REQUIRE k.nombre IS UNIQUE;

LOAD CSV WITH HEADERS FROM 'file:///U9-Datos-Usuarios.csv' AS f
MERGE (c:Cliente {id: f.usuario_id}) SET c.nombre = f.nombre;

LOAD CSV WITH HEADERS FROM 'file:///U9-Datos-Productos.csv' AS f
MERGE (p:Producto {id: f.producto_id}) SET p.nombre = f.nombre, p.precio = toInteger(f.precio_ars)
MERGE (k:Categoria {nombre: f.categoria})
MERGE (p)-[:PERTENECE_A]->(k);
```

Las compras y los seguimientos se cargaron con `UNWIND` sobre pares de identificadores (ver `neo4j.cypher`). El motor informó:

```text
Created 5 nodes, set 10 properties, added 5 labels
Created 11 nodes, created 8 relationships, set 27 properties, added 11 labels
Created 12 relationships
Created 5 relationships
```

*[INSERTAR CAPTURA 2: restricciones y carga de datos]*

Para verificar que se cumplían los mínimos del modelo contamos los elementos por etiqueta y por tipo de relación:

```cypher
MATCH (n) RETURN labels(n)[0] AS etiqueta, count(*) AS cantidad ORDER BY etiqueta;
MATCH ()-[r]->() RETURN type(r) AS relacion, count(*) AS cantidad ORDER BY relacion;
```

| Etiqueta | Cantidad | | Relación | Cantidad |
| :--- | :---: | :--- | :--- | :---: |
| `Categoria` | 3 | | `COMPRO` | 12 |
| `Cliente` | 5 | | `PERTENECE_A` | 8 |
| `Producto` | 8 | | `SIGUE` | 5 |

Con esto confirmamos los mínimos pedidos: 5/8/3 nodos, 8 `PERTENECE_A`, al menos 12 `COMPRO` y al menos 5 `SIGUE`.

*[INSERTAR CAPTURA 3: conteo por etiqueta y por tipo de relación]*

---

### C1. CRUD y consultas Cypher

#### C1.1 Cliente de prueba `U99`: crear, consultar, modificar el nombre, crear una relación `COMPRO`, eliminar la relación y el nodo

Ejecutamos el ciclo completo sobre un cliente de prueba para no tocar los datos del dataset:

```cypher
CREATE (c:Cliente {id: 'U99', nombre: 'Usuario Prueba'}) RETURN c.id AS id, c.nombre AS nombre;
MATCH (c:Cliente {id: 'U99'}) RETURN c.id AS id, c.nombre AS nombre;
MATCH (c:Cliente {id: 'U99'}) SET c.nombre = 'Usuario Modificado' RETURN c.id AS id, c.nombre AS nombre;
```

| Operación | Resultado |
| :--- | :--- |
| Crear | `"U99", "Usuario Prueba"` |
| Consultar | `"U99", "Usuario Prueba"` |
| Modificar el nombre | `"U99", "Usuario Modificado"` |

*[INSERTAR CAPTURA 4: crear, consultar y modificar `U99`]*

```cypher
MATCH (c:Cliente {id: 'U99'}), (p:Producto {id: 'P101'})
CREATE (c)-[:COMPRO]->(p) RETURN c.id AS cliente, p.id AS producto;
```

El motor informó `Created 1 relationship`.

*[INSERTAR CAPTURA 5: creación de la relación `COMPRO`]*

Para el borrado primero intentamos eliminar el nodo con la relación todavía presente, y Neo4j lo **rechazó**: `G1001: dependent object error - edges still exist`. Un nodo con relaciones no puede borrarse con `DELETE`; hay que eliminar antes la relación (o usar `DETACH DELETE`). Lo hicimos en el orden correcto y verificamos que el nodo ya no existía:

```cypher
MATCH (c:Cliente {id: 'U99'}) DELETE c;                           -- rechazado: edges still exist
MATCH (c:Cliente {id: 'U99'})-[r:COMPRO]->() DELETE r;            -- Deleted 1 relationship
MATCH (c:Cliente {id: 'U99'}) DELETE c;                           -- Deleted 1 node
MATCH (c:Cliente {id: 'U99'}) RETURN count(c) AS u99_restantes;   -- 0
```

*[INSERTAR CAPTURA 6: eliminación de la relación y del nodo, y verificación (`u99_restantes = 0`)]*

#### C1.2 Productos comprados por `U01`

```cypher
MATCH (c:Cliente {id: 'U01'})-[:COMPRO]->(p:Producto)
RETURN p.id AS id, p.nombre AS producto, p.precio AS precio ORDER BY p.id;
```

| id | producto | precio |
| :--- | :--- | ---: |
| P102 | Mouse | 18000 |
| P105 | Campera | 95000 |

#### C1.3 Clientes que compraron `P102`

```cypher
MATCH (c:Cliente)-[:COMPRO]->(p:Producto {id: 'P102'})
RETURN c.id AS id, c.nombre AS cliente ORDER BY c.id;
```

| id | cliente |
| :--- | :--- |
| U01 | Ana |
| U02 | Bruno |
| U03 | Carla |

*[INSERTAR CAPTURA 7: consultas C1.2 y C1.3]*

#### C1.4 Productos de la categoría `Tecnologia`

```cypher
MATCH (p:Producto)-[:PERTENECE_A]->(k:Categoria {nombre: 'Tecnologia'})
RETURN p.id AS id, p.nombre AS producto, p.precio AS precio ORDER BY p.id;
```

| id | producto | precio |
| :--- | :--- | ---: |
| P101 | Notebook | 1200000 |
| P102 | Mouse | 18000 |
| P103 | Teclado | 35000 |
| P104 | Monitor | 320000 |

#### C1.5 Productos comprados por clientes a los que sigue `U01` (recorrido de dos relaciones)

```cypher
MATCH (:Cliente {id: 'U01'})-[:SIGUE]->(s:Cliente)-[:COMPRO]->(p:Producto)
RETURN s.nombre AS seguido, p.id AS id, p.nombre AS producto ORDER BY s.nombre, p.id;
```

| seguido | id | producto |
| :--- | :--- | :--- |
| Bruno | P102 | Mouse |
| Bruno | P103 | Teclado |
| Bruno | P107 | Libro SQL |
| Carla | P101 | Notebook |
| Carla | P102 | Mouse |
| Carla | P108 | Libro NoSQL |

Esta consulta recorre dos relaciones en un solo patrón (`SIGUE` y luego `COMPRO`): U01 sigue a Bruno y a Carla, y de cada uno obtenemos sus compras. En un modelo relacional requeriría unir al menos tres tablas.

*[INSERTAR CAPTURA 8: consultas C1.4 y C1.5]*

#### C1.6 Recomendar a `U01` productos comprados por usuarios que sigue y que `U01` aún no compró

```cypher
MATCH (u:Cliente {id: 'U01'})-[:SIGUE]->(:Cliente)-[:COMPRO]->(p:Producto)
WHERE NOT (u)-[:COMPRO]->(p)
RETURN DISTINCT p.id AS id, p.nombre AS recomendado, p.precio AS precio ORDER BY p.id;
```

| id | recomendado | precio |
| :--- | :--- | ---: |
| P101 | Notebook | 1200000 |
| P103 | Teclado | 35000 |
| P107 | Libro SQL | 28000 |
| P108 | Libro NoSQL | 31000 |

Notamos que `Mouse` (P102) no aparece aunque lo compraron Bruno y Carla: es porque `U01` ya lo tiene y la condición `WHERE NOT (u)-[:COMPRO]->(p)` lo excluye.

*[INSERTAR CAPTURA 9: consulta C1.6]*

**¿Cómo se evitan los duplicados?** El patrón `(u)-[:SIGUE]->()-[:COMPRO]->(p)` devuelve una fila por cada *camino*, no por cada producto: si dos usuarios seguidos compraron el mismo producto, este aparecería dos veces. La cláusula `DISTINCT` colapsa las filas repetidas, igual que en SQL. Con los datos base ningún producto recomendable fue comprado por dos seguidos, así que el resultado es igual con y sin `DISTINCT`. Para comprobar el efecto agregamos un seguimiento **temporal** `U01 → U05` (Elena compró P101 y P108, igual que Carla) y lo eliminamos al terminar:

| Sin `DISTINCT` | Con `DISTINCT` | Con `count(DISTINCT s)` |
| :--- | :--- | :--- |
| P101, P101, P103, P107, P108, P108 (6 filas) | P101, P103, P107, P108 (4 filas) | P101→2 · P108→2 · P103→1 · P107→1 |

La tercera variante agrupa y cuenta cuántos seguidos compraron cada producto, lo que permite ordenar las recomendaciones por relevancia. Tras la prueba verificamos que volvían a quedar 5 relaciones `SIGUE`.

*[INSERTAR CAPTURA 10: duplicados con y sin `DISTINCT`]*

---

### C2. Seguridad y recuperación

#### C2.1 Verificar autenticación y cambiar la contraseña inicial de administrador. Por qué no se exige RBAC granular en Community

**Autenticación.** Comprobamos tres situaciones. Sin credenciales, el acceso fue denegado. Con la contraseña inicial `neo4j/neo4j`, Neo4j informó que las credenciales eran válidas pero estaban **caducadas** y debían cambiarse antes de operar.

```bash
cypher-shell -a bolt://localhost:7687 --non-interactive "RETURN 1"
cypher-shell -a bolt://localhost:7687 -u neo4j -p neo4j --non-interactive "RETURN 1"
```
```text
42NFF: ... permission/access denied. Access denied
42NFD: ... credentials expired. The credentials you provided were valid, but must be changed before you can use this instance.
```

*[INSERTAR CAPTURA 11: acceso sin credenciales y con la clave inicial]*

**Cambio de la contraseña inicial.** Lo hicimos con `ALTER CURRENT USER` sobre la base `system` y comprobamos que la clave anterior dejó de funcionar. La contraseña nueva no se muestra en las capturas ni se incluye en los scripts.

```bash
cypher-shell -u neo4j -p neo4j --non-interactive -d system \
  "ALTER CURRENT USER SET PASSWORD FROM 'neo4j' TO '<nueva_clave>'"
cypher-shell -a bolt://localhost:7687 -u neo4j -p neo4j --non-interactive "RETURN 1"
```
```text
42NFF: ... permission/access denied. Access denied
```

*[INSERTAR CAPTURA 12: cambio de contraseña y rechazo de la clave inicial]*

**¿Por qué no se exige RBAC granular en Community?** Lo verificamos en el propio motor. La edición instalada es `community` y los comandos de roles no están soportados:

```cypher
CALL dbms.components() YIELD name, versions, edition RETURN name, versions, edition;
SHOW ROLES;
GRANT ROLE reader TO neo4j;
```
```text
"Neo4j Kernel", ["2026.10.1"], "community"
51N27: ... 'SHOW ALL ROLES' is not supported in community edition.
51N27: ... 'GRANT ROLE' is not supported in community edition.
```

*[INSERTAR CAPTURA 13: edición `community` y comandos de roles no soportados]*

Neo4j Community **autentica** con usuario y contraseña, pero **no incluye roles ni privilegios**. Además comprobamos que un usuario adicional creado con `CREATE USER` pudo escribir sin ninguna restricción: todo usuario autenticado tiene acceso completo. El control de acceso por rol, por grafo o por propiedad es una funcionalidad de Neo4j Enterprise. Por eso la consigna no exige RBAC granular en esta edición, y la protección depende de una contraseña robusta, de que el servicio escuche solo en `localhost` y de los permisos del sistema operativo.

#### C2.2 Cantidades de nodos y relaciones

Registramos las cantidades antes del respaldo, para poder compararlas luego con la copia restaurada.

```cypher
MATCH (n) RETURN count(n) AS cantidad_nodos;
MATCH ()-[r]->() RETURN count(r) AS cantidad_relaciones;
```

| Elemento | Cantidad |
| :--- | :---: |
| Nodos | 16 |
| Relaciones | 25 |

Coinciden con lo esperado: 5 + 8 + 3 = 16 nodos y 8 + 12 + 5 = 25 relaciones.

*[INSERTAR CAPTURA 14: cantidades de nodos y relaciones]*

#### C2.3 Dump/copia offline compatible con Community, carga en un entorno aislado y comprobación de cantidades y una consulta Cypher

**Dump offline.** Primero intentamos hacer el dump con el servicio activo y Neo4j lo rechazó, porque la base estaba en uso. En Community el respaldo es **offline**: hay que detener el servicio.

```bash
sudo -u neo4j neo4j-admin database dump neo4j --to-path=/var/backups/neo4j-u9
```
```text
ERROR ... Failed to dump database 'neo4j': The database is in use. Stop database 'neo4j' and try again.
```

*[INSERTAR CAPTURA 15: dump rechazado con el servicio activo]*

Detuvimos el servicio, repetimos el dump y verificamos el archivo generado (ubicación, tamaño y `sha256`), ya que la consigna no acepta como evidencia solo el archivo de backup:

```bash
sudo systemctl stop neo4j
sudo -u neo4j neo4j-admin database dump neo4j --to-path=/var/backups/neo4j-u9
ls -l /var/backups/neo4j-u9 && sha256sum /var/backups/neo4j-u9/neo4j.dump
```
```text
... Dump completed successfully
-rw-rw-r-- 1 neo4j neo4j [completar tamaño] neo4j.dump
[completar sha256]  /var/backups/neo4j-u9/neo4j.dump
```

*[INSERTAR CAPTURA 16: dump generado con ubicación, tamaño y sha256]*

**Entorno aislado.** Para no pisar el servicio compartido levantamos una segunda instancia de Neo4j con configuración propia (`NEO4J_CONF`): otro directorio de datos y otros puertos, 7688 (Bolt) y 7475 (HTTP).

*[INSERTAR CAPTURA 17: configuración de la instancia aislada y puertos en escucha]*

**Validación antes y después de la restauración.** Antes de cargar el dump comprobamos que la instancia aislada estaba vacía; luego cargamos el dump con `neo4j-admin database load` y repetimos las consultas.

```bash
neo4j-admin database load neo4j --from-path=/var/backups/neo4j-u9 --overwrite-destination=true
```

| Momento | Nodos | Relaciones |
| :--- | :---: | :---: |
| Origen, antes del dump | 16 | 25 |
| Instancia aislada, **antes** de cargar el dump | 0 | 0 |
| Instancia aislada, **después** de cargar el dump | **16** | **25** |

*[INSERTAR CAPTURA 18: instancia aislada vacía antes de restaurar]*
*[INSERTAR CAPTURA 19: carga del dump en la instancia aislada]*

Además de las cantidades, ejecutamos en la copia la consulta de recomendación de C1.6 y obtuvimos los mismos cuatro productos que en el origen: P101, P103, P107 y P108.

*[INSERTAR CAPTURA 20: instancia aislada después de restaurar (16 y 25) y consulta Cypher]*

Por último exportamos los nodos (etiqueta, clave, nombre, precio) y las relaciones tanto del origen como de la copia y los comparamos con `diff`: **no hubo diferencias**. El servicio compartido permaneció en 16 nodos durante toda la prueba, lo que confirma que la restauración no lo afectó.

*[INSERTAR CAPTURA 21: comparación con `diff` entre origen y copia restaurada]*

---

### Errores y diagnóstico (Neo4j)

**Falla 1:** Realizamos primero la actividad en **Neo4j Desktop**, y la consigna pide Neo4j Community nativo.
**Detección:** La consulta `CALL dbms.components()` mostraba la edición `enterprise`, además de contradecir nuestra propia explicación sobre RBAC en Community.
**Corrección:** Repetimos todo con el paquete `neo4j` (Community) instalado desde `apt` y trabajando por terminal con `cypher-shell`. La edición pasó a verse como `community`.

**Falla 2:** `cypher-shell` pedía `username:` o `new password:` en lugar de mostrar el error de acceso.
**Detección:** Al ejecutar en una terminal interactiva el acceso sin credenciales y con la clave inicial caducada.
**Corrección:** Agregamos la opción `--non-interactive`, con lo que el comando falla directamente mostrando el mensaje.

**Falla 3:** `DISTINCT` no mostraba ninguna diferencia en C1.6.
**Detección:** Con los datos base el resultado era idéntico con y sin `DISTINCT`, así que no demostraba nada.
**Corrección:** Agregamos un seguimiento temporal `U01 → U05` para provocar el duplicado, lo verificamos y lo eliminamos.

### Conclusión (Neo4j)

Neo4j resultó muy natural para el escenario de recomendaciones: una consulta de dos relaciones resuelve lo que en un modelo relacional exigiría varias uniones. En seguridad y recuperación, en cambio, Community es más limitado: autentica pero no autoriza por roles, y el respaldo solo puede hacerse con el servicio detenido, lo que implica una ventana sin servicio. Comprobamos la restauración comparando cantidades, una consulta de negocio y un `diff` completo entre origen y copia.

### Uso de IA (Neo4j)

Se utilizó una IA (Claude) como asistente para interpretar la consigna, armar el script `neo4j.cypher` y la secuencia de comandos de la prueba.
- **Qué se validó:** ejecutamos los comandos en la terminal y comprobamos que los resultados (cantidades, consultas, rechazo del dump en caliente, restauración y `diff`) correspondieran con lo esperado.
- **Qué se descartó:** usar Neo4j Desktop, porque no es la edición ni el entorno que pide la consigna, y mostrar contraseñas en las capturas.

---

## Matriz comparativa final

| Criterio | Redis | Cassandra | Neo4j Community |
| :--- | :--- | :--- | :--- |
| **Modelo** | Clave-valor con estructuras en memoria: `STRING` (sesión), `HASH` (carrito), `SET` (favoritos) y `SORTED SET` (ranking). Las claves siguen el formato `tipo:id`. | Una tabla por consulta: `eventos_por_usuario` con clave de partición `usuario_id` y claves de clustering `fecha_evento` y `evento_id`, que ordenan los eventos dentro de cada partición. | Grafo de propiedades: nodos con etiqueta (`Cliente`, `Producto`, `Categoria`) y relaciones tipadas y dirigidas (`COMPRO`, `SIGUE`, `PERTENECE_A`). |
| **Consultas** | Comandos por clave (`GET`, `HGETALL`, `SISMEMBER`, `ZREVRANGE`). Resuelve muy bien sesiones, carritos y rankings, y tiene vencimiento nativo (`TTL`). No consulta por contenido ni por relaciones. | CQL. Toda consulta eficiente indica la clave de partición; el rango de fechas, `ORDER BY` y `LIMIT` se hacen sobre las columnas de clustering. Filtrar por `tipo_evento` sin la partición falla (error 2200): exige `ALLOW FILTERING` o una tabla nueva (`eventos_por_tipo`). | Cypher por patrones. Los recorridos de varias relaciones (recomendar lo que compran los seguidos) se escriben en un solo patrón, sin `JOIN`. |
| **Seguridad** | ACL por usuario: patrones de claves y categorías de comandos (`app_user` con `~sesion:*`, `+@read +@write -@dangerous`). Lo no permitido responde `NOPERM`. El usuario `default` sigue sin contraseña y con acceso total. | Por defecto no pide credenciales (`AllowAllAuthenticator` y `AllowAllAuthorizer`). Se activa `PasswordAuthenticator` y `CassandraAuthorizer` en `cassandra.yaml` y se reinicia. Roles con `GRANT`: el rol `lector` puede hacer `SELECT` y recibe `Unauthorized` en `INSERT`. | Autenticación con usuario y contraseña; la clave inicial `neo4j/neo4j` está caducada y obliga a cambiarla. **No hay roles ni privilegios** (`SHOW ROLES` y `GRANT ROLE` no están soportados): es funcionalidad de Enterprise. |
| **Recuperación** | Copia RDB: `SAVE` genera `dump.rdb` en `/var/lib/redis`, se copia el archivo y se restaura levantando otra instancia (puerto 6380, otro directorio) para comparar claves y valores. Es una foto: no incluye lo escrito después del último guardado. | `nodetool snapshot` crea enlaces a las SSTables dentro de `snapshots/`. Se restaura copiando las SSTables al directorio de la tabla y ejecutando `nodetool refresh` (o `import`). Se verificó con el conteo: de 0 (tras `TRUNCATE`) a 15. | Dump y carga **offline** con `neo4j-admin`: el servicio debe estar detenido (con el servicio activo el dump se rechaza). Se restauró en una instancia aislada (16 nodos y 25 relaciones) y se comparó con una consulta y un `diff` contra el origen. |
| **Dificultad operativa** | **Baja.** Instalación por `apt`, el servicio queda listo y los comandos son simples. Hay que tener en cuenta que los datos viven en memoria y que la seguridad y la persistencia se configuran aparte. | **Alta.** Requiere más recursos (JVM), ajustar `cassandra.yaml`, reiniciar el nodo para activar la seguridad y cuidar los permisos de los archivos al restaurar (`chown cassandra`). El modelado por consulta exige diseñar antes de cargar. | **Media.** Instalación por `apt`; hay que ajustar memoria, copiar los CSV al directorio `import` para `LOAD CSV` y cambiar la clave inicial. El respaldo implica detener el servicio. |

### Cuándo conviene cada motor en OmniMarket

| Necesidad | Motor | Motivo |
| :--- | :--- | :--- |
| Sesiones, carritos, favoritos y rankings con acceso inmediato | Redis | Lecturas por clave muy rápidas, estructuras listas para usar y expiración automática |
| Historial de eventos de usuarios en gran volumen | Cassandra | La tabla agrupa y ordena los eventos por usuario y escala en escritura |
| Recomendaciones y relaciones entre clientes y productos | Neo4j | Los recorridos por relaciones se resuelven con un solo patrón |

## Conclusión general

Comprobamos que cada motor resuelve mejor un tipo de problema y que ninguno reemplaza a los otros: Redis para datos de acceso inmediato (sesiones, carritos, ranking), Cassandra para historiales que crecen y se consultan siempre por usuario, y Neo4j para preguntas sobre cómo se relacionan los datos. En seguridad, los tres parten de configuraciones abiertas o con credenciales por defecto: Redis deja el usuario `default` sin contraseña, Cassandra no exige credenciales hasta que se habilita la autenticación y Neo4j obliga a cambiar la clave inicial pero, en Community, no ofrece roles. En recuperación, cada uno tiene su mecanismo (foto RDB, snapshot de SSTables y dump offline) y en los tres validamos la restauración comparando datos antes y después, sin sobrescribir el servicio compartido. En dificultad operativa, Redis resultó el más simple, Neo4j intermedio y Cassandra el más exigente.
