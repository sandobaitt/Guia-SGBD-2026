# Guía Paso a Paso: U9 - Actividad 1 (Laboratorio multimotor: Redis, Cassandra y Neo4j)
**Grupo:** G11 (Escenario: tienda en línea OmniMarket)
**Motores:** Redis (`redis-cli`) · Cassandra (`cqlsh`, `nodetool`) · Neo4j Community 2026.10.1 (`cypher-shell`)
**Archivos:** `neo4j.cypher` (script que pide la consigna) · `evidencias_terminal_neo4j.sh` (sesión guiada para sacar las capturas) · `U9-Datos-*.csv` (datos de la cátedra) · `bitacora_resuelta.md` (informe)

> Las secciones 0 a 5 cubren la **parte C (Neo4j)**. La sección 6 cubre Redis (A) y la 7 Cassandra (B), con lo que ya está hecho y lo que falta (sección 8).
> Se trabaja en la terminal de tu computadora con Neo4j Community instalado de forma nativa (sin Docker, sin Neo4j Desktop).

---

## 0. Qué vas a hacer, en una frase
Cargar en Neo4j los datos de la tienda (clientes, productos, categorías), hacer las operaciones y consultas que pide la consigna, cambiar la contraseña inicial, y probar un respaldo restaurándolo en una copia aislada. El script guiado lo hace **paso a paso** y se detiene para que saques cada captura.

---

## 1. Preparación

### 1.1. Verificar que Neo4j está instalado
```bash
neo4j --version              # debe decir 2026.10.1
cypher-shell --version       # Cypher-Shell 2026.10.1
```

### 1.2. Estar en la carpeta correcta
Tiene que contener `evidencias_terminal_neo4j.sh`, `neo4j.cypher` y los tres CSV:
```bash
cd "Parcial 2/Unidad 9/Actividad 1"
ls
```

### 1.3. Dejar la terminal cómoda para las capturas
- Maximizada o con **140 columnas o más**, para que las tablas no se corten.
- Si una salida no entra en pantalla, achicar la letra con `Ctrl` + `-`.

### 1.4. Qué contraseñas se usan
| Contraseña | Cuándo | Qué hacer |
| :--- | :--- | :--- |
| **La de `sudo`** (tu usuario de la computadora) | Pasos 5, 15 y 16 (y cuando pase mucho tiempo) | Tipearla y Enter; no se ve al escribir |
| **La nueva de Neo4j** | Paso 3 | La elegís vos (mínimo 8 caracteres), con entrada oculta. **Anotala** |

La clave de Neo4j no se guarda en ningún archivo.

### 1.5. Empezar desde cero (solo si hace falta repetir todo)
Neo4j recién instalado tiene usuario `neo4j`, clave `neo4j` (caducada) y ningún dato. Si ya corriste el script y querés repetir **desde el paso 2** con la clave inicial:
```bash
sudo systemctl stop neo4j
sudo rm -rf /var/lib/neo4j/data/databases /var/lib/neo4j/data/transactions /var/lib/neo4j/data/dbms
sudo rm -f /var/lib/neo4j/import/U9-Datos-*.csv
sudo rm -rf /var/backups/neo4j-u9
```
> **Atención:** esto borra los datos de Neo4j **de tu laboratorio**. No tiene nada más. No lo hagas si necesitás conservar algo.

---

## 2. Ejecutar la sesión guiada

```bash
./evidencias_terminal_neo4j.sh
```

El script muestra cada comando en una línea que empieza con `$`, lo ejecuta, y espera `[Enter] para continuar`. **En ese momento sacás la captura**, con el comando y el resultado juntos, y apretás Enter.

Opciones útiles:
| Opción | Para qué |
| :--- | :--- |
| `PASO_DESDE=10 ./evidencias_terminal_neo4j.sh` | Retomar desde un paso (si es mayor que 3 te pide la clave actual de Neo4j) |
| `SIN_PAUSA=1 ./evidencias_terminal_neo4j.sh` | Correr todo sin pausas, para verificar que funciona |

### 2.1. Tabla de pasos

La columna **Captura** es el número del marcador `[INSERTAR CAPTURA N]` en `bitacora_resuelta.md`.

| Paso | Qué hace | Qué escribís | Captura | ¿Obligatorio? |
| :---: | :--- | :--- | :---: | :---: |
| 1 | Muestra el servicio, la versión y los puertos | Solo Enter | 1 | Sí |
| 2 | Sin credenciales: denegado. Con `neo4j/neo4j`: clave caducada | Solo Enter | 11 | Sí |
| 3 | Cambia la clave inicial | **La clave nueva** (oculta) y Enter | 12 | Sí |
| 4 | Edición `community` y `SHOW ROLES` / `GRANT ROLE` no soportados | Solo Enter | 13 | Sí |
| 5 | Copia los CSV y carga los datos | Clave de `sudo` si la pide | 2 | Sí |
| 6 | Cuenta nodos por etiqueta y relaciones por tipo | Solo Enter | 3 | Sí |
| 7 | C1.1: crear, consultar y modificar `U99` | Solo Enter | 4 | Sí |
| 8 | C1.1: crear la relación `COMPRO` | Solo Enter | 5 | Sí |
| 9 | C1.1: borrar la relación y el nodo; verificar | Solo Enter | 6 | Sí |
| 10 | C1.2 y C1.3 | Solo Enter | 7 | Sí |
| 11 | C1.4 y C1.5 | Solo Enter | 8 | Sí |
| 12 | C1.6: recomendación para `U01` | Solo Enter | 9 | Sí |
| 13 | C1.6: duplicados con y sin `DISTINCT` | Solo Enter | 10 | Opcional |
| 14 | C2.2: 16 nodos y 25 relaciones | Solo Enter | 14 | Sí |
| 15 | C2.3: el dump con el servicio activo es rechazado | Clave de `sudo` si la pide | 15 | Opcional |
| 16 | C2.3: dump con el servicio detenido, tamaño y `sha256` | Solo Enter | 16 | Sí |
| 17 | C2.3: configuración de la instancia aislada | Solo Enter | 17 | Opcional |
| 18 | C2.3: la aislada está vacía (0 y 0) | Solo Enter | 18 | Sí |
| 19 | C2.3: carga del dump en la aislada | Solo Enter | 19 | Sí |
| 20 | C2.3: aislada con 16 y 25, y una consulta Cypher | Solo Enter | 20 | Sí |
| 21 | C2.3: `diff` entre origen y copia | Solo Enter | 21 | Opcional |

Los pasos 15 a 19 tardan 10 a 20 segundos entre comandos: esperá a que vuelva el prompt, no hace falta tocar nada.

### 2.2. Al terminar
```bash
sudo systemctl stop neo4j        # libera memoria (el servicio queda activo al final del script)
```
La instancia aislada ya la detiene el propio script.

---

## 3. Si querés probar consultas a mano

Con el servicio activo (`sudo systemctl start neo4j`) y después del cambio de clave:
```bash
cypher-shell -u neo4j          # pide la contraseña, sin mostrarla
```
Adentro, cada sentencia termina con `;` y se sale con `:exit`:
```cypher
MATCH (c:Cliente) RETURN c.id, c.nombre;
MATCH (c:Cliente {id: 'U01'})-[:COMPRO]->(p:Producto) RETURN p.nombre;
:exit
```
Para ejecutar un archivo completo (sin credenciales dentro del archivo):
```bash
export NEO4J_PASSWORD='<tu clave>'
cypher-shell -u neo4j -p "$NEO4J_PASSWORD" -f neo4j.cypher
```
> `neo4j.cypher` es el **script entregable**: contiene la carga, el CRUD y las consultas. La contraseña se pasa aparte, nunca dentro del archivo.

---

## 4. Armar el informe

1. Pegar cada captura en su marcador `*[INSERTAR CAPTURA N: ...]*` de `bitacora_resuelta.md` (o del PDF).
2. En la captura 16 completar `[completar tamaño]` y `[completar sha256]` con lo que muestra tu terminal.
3. **Revisar que ninguna captura muestre una contraseña** (ni la de `sudo` ni la de Neo4j).
4. Si descartás un paso opcional (13, 15, 17 o 21), borrar su marcador.
5. Completar los nombres de los integrantes.
6. Verificar que los resultados de tus capturas coincidan con las tablas del informe; si algo difiere, corregir el texto con lo que realmente viste.
7. En C2.1 hay una oración sobre un usuario adicional creado con `CREATE USER` que **el script guiado no ejecuta**: dejarla solo si se prueba, o borrarla.

---

## 5. Problemas frecuentes

| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| `cypher-shell` pide `username:` o `new password:` | Terminal interactiva sin credenciales o con clave caducada | Los comandos del script ya llevan `--non-interactive`; en comandos propios, agregarlo |
| El `LOAD CSV` falla porque no encuentra el archivo `U9-Datos-...csv` | `LOAD CSV` solo lee de `/var/lib/neo4j/import` | `sudo cp U9-Datos-*.csv /var/lib/neo4j/import/` |
| Dump: `The database is in use` | El servicio está activo | Es lo esperado (paso 15); para hacer el dump, `sudo systemctl stop neo4j` |
| La instancia aislada no arranca (puerto ocupado) | Quedó una instancia aislada corriendo | `NEO4J_CONF=$HOME/u9_neo4j_aislada/conf neo4j stop` y repetir el paso |
| En el paso 18 (o en otros) sale `Access denied`, y `origen_antes.txt` / `copia_despues.txt` quedan **vacíos** | La contraseña que recibió el script no es la de Neo4j (o tiene menos de 8 caracteres, y entonces la instancia aislada nunca llegó a recibirla) | Usar la versión actual del script: valida la clave antes de empezar y la vuelve a pedir. Si no te la acordás, ver la fila siguiente |
| No recordás la clave de Neo4j | — | **Sin perder datos:** `sudo systemctl stop neo4j`, agregar la línea `dbms.security.auth_enabled=false` a `/etc/neo4j/neo4j.conf` (`echo 'dbms.security.auth_enabled=false' \| sudo tee -a /etc/neo4j/neo4j.conf`), `sudo systemctl start neo4j`, esperar ~40 s y ejecutar `read -rs NUEVA; cypher-shell --non-interactive -d system "ALTER USER neo4j SET PASSWORD '$NUEVA' CHANGE NOT REQUIRED"`. Después `sudo systemctl stop neo4j`, **quitar la línea** (`sudo sed -i '/^dbms.security.auth_enabled=false$/d' /etc/neo4j/neo4j.conf`) y `sudo systemctl start neo4j`. Mientras la línea esté puesta, Neo4j acepta cualquier conexión sin clave. (Alternativa más larga: empezar desde cero, sección 1.5) |
| Se corta la terminal a mitad | — | `PASO_DESDE=N` con el paso que sigue |
| Poca memoria al levantar Neo4j | Hay otros motores activos | Detener Redis/Cassandra (`sudo systemctl stop redis-server cassandra`) |

---

## 6. Redis (parte A)

### 6.1. Preparación
```bash
redis-server --version               # Redis server v=7.0.15 (o la que haya instalada)
sudo systemctl status redis-server   # debe decir: active (running)
redis-cli ping                       # PONG
redis-cli                            # abre la consola interactiva; se sale con: exit
```
Cada comando de Redis se ejecuta dentro de `redis-cli` (prompt `127.0.0.1:6379>`). Sacá una captura por comando o por grupo de comandos.

### 6.2. Cargar el modelo mínimo (hacerlo ANTES del CRUD)
La consigna pide 3 sesiones `STRING`, 3 carritos `HASH` (al menos 2 productos), 2 `SET` de favoritos y un ranking `SORTED SET` de 5 productos. Conviene cargarlo y capturarlo **antes** de A1, porque A1.1 elimina `sesion:U01` y A1.2 deja `carrito:U01` con un solo producto.
```text
SET sesion:U01 "activa"
SET sesion:U02 "activa"
SET sesion:U03 "activa"
HSET carrito:U01 P101 1 P102 2
HSET carrito:U02 P103 1 P104 2
HSET carrito:U03 P105 1 P106 1
SADD favoritos:U01 P101 P103
SADD favoritos:U02 P102
ZADD ranking_productos 95 P101 90 P105 85 P104 70 P102 60 P103
```
> Los puntajes de P101, P105 y P104 (95, 90, 85) son los que muestra la evidencia del grupo; los otros dos son un ejemplo: usar los que se hayan cargado realmente.

Para ver el ranking completo (así se comprueba que el top 3 es el correcto): `ZREVRANGE ranking_productos 0 -1 WITHSCORES`.

### 6.3. A1: CRUD y consultas

| Ítem | Comandos | Resultado esperado |
| :--- | :--- | :--- |
| A1.1 sesión | `SET sesion:U01 "activa"` · `GET sesion:U01` · `SET sesion:U01 "renovada"` · **`GET sesion:U01`** · `DEL sesion:U01` · `EXISTS sesion:U01` | `OK` · `"activa"` · `OK` · `"renovada"` · `1` · `0` |
| A1.2 carrito | `HSET carrito:U01 P101 1 P102 2` · `HGETALL carrito:U01` · `HSET carrito:U01 P101 3` · `HDEL carrito:U01 P102` · `HGETALL carrito:U01` | `2` · campos · **`0`** (el campo ya existía) · `1` · solo `P101` = `3` |
| A1.3 favoritos | `SADD favoritos:U01 P107` · `SISMEMBER favoritos:U01 P107` · `SREM favoritos:U01 P107` · `SISMEMBER favoritos:U01 P107` | `1` · `1` · `1` · `0` |
| A1.4 ranking | `ZREVRANGE ranking_productos 0 2 WITHSCORES` | P101 95 · P105 90 · P104 85 |
| A1.5 TTL | `SET sesion:temporal "token_temporal_123" EX 30` · `TTL sesion:temporal` · (esperar 30 s) · `TTL sesion:temporal` · `GET sesion:temporal` | `OK` · ~27 a 30 · **`-2`** · `(nil)` |

> El `GET` en negrita después de actualizar la sesión no figuraba en la evidencia del grupo: sin él solo se ve el `OK`, y recién el `GET` muestra que el valor cambió a `"renovada"`.
>
> `TTL`: `-2` = la clave no existe; `-1` = existe pero no tiene vencimiento.

### 6.4. A2.1: ACL de aplicación (sin mostrar la contraseña)
Para que la clave **no aparezca en las capturas**, se guarda en una variable con entrada oculta y se usa la variable en los comandos:
```bash
read -rs CLAVE          # escribir la clave (no se ve) y Enter
redis-cli ACL SETUSER app_user on ">$CLAVE" '~sesion:*' '~carrito:*' '~favoritos:*' '~ranking_*' +@read +@write -@dangerous +ping
REDISCLI_AUTH="$CLAVE" redis-cli --user app_user GET sesion:U02       # autorizado
REDISCLI_AUTH="$CLAVE" redis-cli --user app_user GET usuario:U01      # denegado por clave
REDISCLI_AUTH="$CLAVE" redis-cli --user app_user FLUSHALL             # denegado por comando
```
| Comando | Resultado | Por qué |
| :--- | :--- | :--- |
| `GET sesion:U02` | `"activa"` | La clave está dentro de `~sesion:*` |
| `GET usuario:U01` | `NOPERM ... keys` | La clave no coincide con ningún patrón |
| `FLUSHALL` | `NOPERM ... 'flushall' command` | `-@dangerous` quita los comandos peligrosos |

> **Por qué `-@dangerous`:** las categorías `+@read +@write` **incluyen `FLUSHALL` y `FLUSHDB`**, y los patrones de claves (`~...`) no los limitan: un usuario con esa ACL puede borrar **todas** las claves de la base, incluso las que no son suyas. Se comprobó en laboratorio. Con `-@dangerous` el usuario sigue leyendo y escribiendo sus claves pero no puede borrar la base ni usar `KEYS` o `CONFIG`.
>
> **Atención:** si la ACL ya creada **no** lleva `-@dangerous`, **no pruebes `FLUSHALL`**: se ejecutaría y vaciaría la base. Primero corregí el usuario con `redis-cli ACL SETUSER app_user -@dangerous` (o recrealo con la línea de arriba) y recién después probá `FLUSHALL`.
>
> El mensaje exacto de `NOPERM` depende de la versión: en Redis 7.0 dice `this user has no permissions to access one of the keys used as arguments`; en la 8.x, `No permissions to access a key`.
> Para el script `redis-comandos.txt` (que no debe llevar credenciales) usar `<clave>` en lugar de la contraseña real.

### 6.5. A2.2 y A2.3: respaldo RDB y restauración aislada
*[Pendiente: generar el RDB, ubicarlo, copiarlo de forma consistente y restaurarlo en una instancia aislada comparando al menos tres claves, con evidencia antes y después.]*

---

## 7. Cassandra (parte B)

### 7.1. Preparación
```bash
sudo systemctl start cassandra       # tarda cerca de 1 minuto en quedar listo
nodetool status                      # el nodo debe figurar como UN (Up/Normal)
cqlsh                                # consola CQL; se sale con: exit
```
Si `cqlsh` da error de conexión, esperar un poco más y repetir. Cassandra consume bastante memoria: no tener Neo4j activo a la vez.

### 7.2. Modelo y carga (pedido por la consigna)
```sql
CREATE KEYSPACE IF NOT EXISTS omnimarket
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE IF NOT EXISTS omnimarket.eventos_por_usuario (
  usuario_id text, fecha_evento timestamp, evento_id uuid, tipo_evento text, producto_id text,
  PRIMARY KEY ((usuario_id), fecha_evento, evento_id)
) WITH CLUSTERING ORDER BY (fecha_evento DESC, evento_id DESC);

COPY omnimarket.eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id)
  FROM '/ruta/completa/U9-Datos-Eventos.csv' WITH HEADER = TRUE;
```
- **Por qué `CLUSTERING ORDER BY ... DESC`:** define el orden físico dentro de cada partición. Con el orden por defecto (ascendente), `LIMIT 3` devuelve los tres eventos **más antiguos**; con `DESC` devuelve los tres **más recientes**, que es lo que pide B1.5. (Comprobado en laboratorio.)
- `COPY` ignora la primera línea (encabezado) con `HEADER = TRUE`. Verificar que quedaron **15 filas**.
- **Zona horaria:** las fechas escritas sin zona (`'2026-10-20 15:00:00'`) se interpretan con la zona horaria del cliente. En una máquina con zona distinta de UTC las horas pueden aparecer desplazadas (en una prueba con zona -03 se vieron corridas varias horas). Comprobar que, tras cargar, los eventos de `U01` van de las 10:00 a las 14:00 como en el CSV; si no, agregar `+0000` en las fechas de las consultas y la carga.

### 7.3. B1: CRUD y consultas

| Ítem | Sentencia | Resultado esperado |
| :--- | :--- | :--- |
| B1.1 | `INSERT INTO omnimarket.eventos_por_usuario (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id) VALUES ('U01','2026-10-20 15:00:00', 00000000-0000-4000-8000-000000000006,'VER_PRODUCTO','P106');` y luego `SELECT * ... WHERE usuario_id='U01';` | 6 eventos; el nuevo primero |
| B1.2 | `UPDATE omnimarket.eventos_por_usuario SET tipo_evento='AGREGAR_CARRITO' WHERE usuario_id='U01' AND fecha_evento='2026-10-20 15:00:00' AND evento_id=00000000-0000-4000-8000-000000000006;` y `SELECT` de esa fila | `AGREGAR_CARRITO` |
| B1.3 | `DELETE FROM omnimarket.eventos_por_usuario WHERE usuario_id='U01' AND fecha_evento='2026-10-20 15:00:00' AND evento_id=00000000-0000-4000-8000-000000000006;` y `SELECT` de `U01` | 5 eventos |
| B1.4 | `SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id='U02' ORDER BY fecha_evento DESC;` | 5 eventos, de 14:00 a 10:00 |
| B1.5 | `SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id='U01' LIMIT 3;` | 14:00, 13:00 y 12:00 |
| B1.6 | `SELECT * FROM omnimarket.eventos_por_usuario WHERE usuario_id='U03' AND fecha_evento >= '2026-10-22 10:00:00' AND fecha_evento <= '2026-10-22 13:00:00';` | 4 eventos |
| B1.7 | `SELECT * FROM omnimarket.eventos_por_usuario WHERE tipo_evento='VER_PRODUCTO';` | `InvalidRequest ... code=2200 ... use ALLOW FILTERING` |

> **Por qué `UPDATE` y `DELETE` piden toda la clave primaria:** en Cassandra la clave primaria identifica la fila exacta. Además, `UPDATE` **crea la fila si no existe** (es un *upsert*): si se equivoca un valor de la clave, no da error, crea un evento nuevo. Por eso conviene verificar con un `SELECT` después de cada operación.

### 7.4. B1.7: tabla alternativa con datos
La consigna pide proponer una tabla para consultar por `tipo_evento`. Crearla vacía muestra que la consulta no da error, pero **no muestra resultados**. Para que sirva como evidencia, cargarla con los mismos 15 eventos:
```sql
CREATE TABLE IF NOT EXISTS omnimarket.eventos_por_tipo (
  tipo_evento text, fecha_evento timestamp, evento_id uuid, usuario_id text, producto_id text,
  PRIMARY KEY ((tipo_evento), fecha_evento, evento_id)
) WITH CLUSTERING ORDER BY (fecha_evento DESC);

COPY omnimarket.eventos_por_tipo (usuario_id, fecha_evento, evento_id, tipo_evento, producto_id)
  FROM '/ruta/completa/U9-Datos-Eventos.csv' WITH HEADER = TRUE;

SELECT * FROM omnimarket.eventos_por_tipo WHERE tipo_evento = 'VER_PRODUCTO';   -- 3 eventos (U03, U02, U01)
```
> En la prueba de laboratorio la tabla se creó sin error con `CLUSTERING ORDER BY (fecha_evento DESC)` (solo la primera columna de clustering) en Cassandra 5.0.9.
> Cassandra no copia datos entre tablas con `INSERT ... SELECT`: en un sistema real la aplicación escribe en **ambas** tablas, o se carga desde el archivo de origen como aquí.

### 7.5. B2: seguridad, snapshot y restauración
*[Pendiente: habilitar autenticación/autorización con supervisión del JTP, rol de solo lectura (`SELECT` permitido e `INSERT` denegado), snapshot con `nodetool` y restauración guiada con SSTables, con evidencia antes y después.]*

---

## 8. Partes pendientes (resumen)

| Motor | Falta |
| :--- | :--- |
| Redis | Carga del modelo (comandos y captura), A2.2 respaldo RDB y A2.3 restauración aislada; comprobar `FLUSHALL` denegado en A2.1 |
| Cassandra | Verificación del servicio (versión, `nodetool status`, `cqlsh`), DDL y carga de los 15 eventos, B1.7 con datos, y todo B2 |
| General | Demostración de los tres servicios al JTP; `redis-comandos.txt` sin contraseñas y `cassandra.cql`; completar la matriz y la conclusión |
