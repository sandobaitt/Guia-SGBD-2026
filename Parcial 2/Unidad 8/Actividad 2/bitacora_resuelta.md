# Bitácora Técnica: U8 - Actividad 2 (Guardia DBA MongoDB)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)  
**Grupo:** G11 — Aguirre Egea, Emiliano · Ghione, Lucas Emanuel · Pagno, Agustin Mario · Sandoval, Lautaro Emanuel  
**Base bajo guardia:** `u8_g11` (la solución de la Actividad 1: `envios` 15 documentos y `eventos_seguimiento` 20 documentos)  
**Motor SGBD:** MongoDB Community 8.0.34 · `mongosh` 2.14 · Database Tools 100.x  
**Scripts:** `solucion_u8_actividad2.sh` (laboratorio completo, comandos de consola) · `solucion_u8_actividad2_mongosh.js` (comandos de `mongosh`, por fases)

> **Procedencia de la evidencia.** Las capturas de la entrega original (`Bitacora Unidad 8 - SGBD.pdf`, `admin.txt`, `restore.txt`) corresponden a la máquina virtual del grupo (`LinuxE`) y siguen siendo válidas. Los bloques marcados **[REFUERZO]** se obtuvieron ejecutando `solucion_u8_actividad2.sh` el 03/11/2026 en un laboratorio local **aislado** (Pop!_OS 24.04, MongoDB 8.0.34, `mongosh` 2.14.1, instancia propia en el puerto 27019, solo en `127.0.0.1`, sin tocar bases compartidas). La corrida final registra **34 pruebas en `[OK]` y ninguna en `[FALLO]`**. Ninguna salida fue escrita a mano.

---

## Devolución del profesor y cómo se atiende

> *"Se presentan procedimientos de administración y una explicación correcta del incidente de autorización. Sin embargo, **faltan pruebas más completas** para demostrar el **funcionamiento de los controles** y la **recuperación**."*

| Área | Qué faltaba en la entrega | Qué se agregó (sección) |
| :--- | :--- | :--- |
| **Controles: autenticación** | Solo se probó `find` sin credenciales. | Contraseña errónea, `ping` sin credenciales, `connectionStatus` (sección 2). |
| **Controles: RBAC** | De la tabla mínima de la consigna faltaba **`insertOne` del lector** (solo se probó `updateOne`); `admin.txt` **no contenía la creación** del lector ni del operador; no se probó escalada ni acceso a otra base. | Matriz de **29 pruebas** con código de error, incluida la escalada de privilegios del operador (sección 3). |
| **Controles: red y TLS** | La bitácora decía `bindIp: 127.0.0.1`, pero el `mongod.conf` de la captura dice `0.0.0.0` y las pruebas se hicieron desde `192.168.1.42`. TLS solo se describió. | Diagnóstico corregido, comprobación de exposición y **TLS implementado y probado** con CA propia (sección 4). |
| **Recuperación** | La validación fue solo de **recuentos** (16 = 16), sin contenido, sin índices y sin la eliminación controlada. | Validación por recuento, contenido documento a documento, `dbHash` e índices; borrado y recuperación de una colección de prueba (sección 5). |
| **Recuperación: 16 documentos** | `envios` tenía **16** documentos en el respaldo y `admin.txt` informaba **15**: no se explicó la diferencia. | Hipótesis y comando de verificación (sección 7). |

---

## 1. Diagnóstico

### 1.1 Lo que muestra la captura original (VM del grupo)

| Dato | Valor |
| :--- | :--- |
| Versión / `uptime` | `8.0.34` / 12.465 s |
| Bases | `admin`, `config`, `local`, `sgbd2026`, `test`, `u8_g11` |
| Colecciones de `u8_g11` | `envios`, `eventos_seguimiento` |
| Usuarios (`show users`) | **ninguno** (`[]`) |
| `/etc/mongod.conf` | `port: 27017`, **`bindIp: 0.0.0.0`** y **sin** bloque `security:` (la captura es previa a activar el acceso) |

**Hallazgo crítico de la guardia.** En el momento del diagnóstico la instancia **no tenía autenticación y escuchaba en todas las interfaces**: cualquier equipo de la red podía leer y modificar todas las bases. Es el escenario que la consigna pide detectar. La bitácora original lo registraba como `bindIp: 127.0.0.1`; la captura (y el hecho de que las pruebas posteriores se hayan hecho desde `192.168.1.42`) muestra lo contrario.

### 1.2 Diagnóstico reproducible **[REFUERZO]** (`FASE=diagnostico`)

```text
version: 8.0.34 · motor: wiredTiger · modo: standalone · conexiones actuales: 4
security.authorization : (no configurado => disabled: cualquier cliente puede operar)
net.port               : 27019
net.bindIp             : 127.0.0.1
net.tls.mode           : (no configurado => disabled: tráfico en texto plano)

Bases: admin, config, local, u8_g11
envios               15 documentos · índices: _id_, ruta_1_fecha_despacho_1, estado_actual_1_fecha_despacho_-1
eventos_seguimiento  20 documentos · índices: _id_, envio_id_1_timestamp_1
Usuarios definidos: admin.system.users 0 · u8_g11 0

$ ps -o pid,user,args -C mongod   ->  mongod --config $LAB/mongod_a.conf   (usuario del SO: sando, no root)
$ ss -ltnp | grep :27019          ->  LISTEN 127.0.0.1:27019
```

`getCmdLineOpts` expone la **configuración efectiva** (no lo que dice un archivo que quizá no se cargó): permite confirmar qué valores tiene realmente el proceso.

---

## 2. Autenticación

El orden importa: **primero se crea el administrador y después se activa el control de acceso** (con el acceso activo y sin usuarios, solo la *excepción de localhost* permite crear el primero).

**Original (VM):** `db.createUser({ user: "adminG11", roles: [userAdminAnyDatabase, readWriteAnyDatabase] })` → `{ ok: 1 }`; `sudo systemctl restart mongod`; `db.envio.find()` → `MongoServerError[Unauthorized]: Command find requires authentication`.

> Nota: la sentencia de la captura dice `db.envio.find()` (sin la *s*, colección inexistente). El rechazo ocurre antes de resolver la colección, así que la prueba es válida, pero conviene escribir `db.envios.find()`.

### 2.1 Activación **[REFUERZO]**

```yaml
# mongod.conf (se agrega)
security:
  authorization: enabled
```

### 2.2 Pruebas de acceso sin credenciales (`ROL=anonimo`) **[REFUERZO]**

| Prueba | Esperado | Obtenido | Detalle |
| :--- | :--- | :--- | :--- |
| `ping` sin credenciales | Permitida | **Permitida** | `{ ok: 1 }`: la **conexión** no exige autenticación |
| `find()` sobre `envios` | Denegada | **Denegada** | `código 13 Unauthorized — Command find requires authentication` |
| `listDatabases` | Denegada | **Denegada** | `código 13 Unauthorized` |
| `insertOne` | Denegada | **Denegada** | `código 13 Unauthorized — Command insert requires authentication` |
| `createUser` | Denegada | **Denegada** | `código 13 Unauthorized` |

### 2.3 Credenciales incorrectas y correctas **[REFUERZO]**

```text
mongosh -u adminG11 -p ******** (clave incorrecta)  ->  MongoServerError: Authentication failed.

mongosh -u adminG11 -p ******** (correcta) -> connectionStatus:
  authenticatedUsers:     [ { user: 'adminG11', db: 'admin' } ]
  authenticatedUserRoles: clusterMonitor, readWriteAnyDatabase, userAdminAnyDatabase (todos en admin)
```

Con el acceso activo, el mismo diagnóstico informa `security.authorization : enabled`.

---

## 3. RBAC: lector, operador y usuarios de respaldo

Los usuarios se crean **en la base `u8_g11`** con roles **solo sobre `u8_g11`** (mínimo privilegio). Por eso deben autenticarse con `--authenticationDatabase u8_g11`.

```javascript
db.getSiblingDB("u8_g11").createUser({ user: "u8_g11_lector",   pwd: <clave>, roles: [{ role: "read",      db: "u8_g11" }] })
db.getSiblingDB("u8_g11").createUser({ user: "u8_g11_operador", pwd: <clave>, roles: [{ role: "readWrite", db: "u8_g11" }] })
```

### 3.1 Prueba mínima de la consigna **[REFUERZO]**

| Identidad | Acción | Esperado | Obtenido | Error |
| :--- | :--- | :--- | :--- | :--- |
| **Lector** | `find()` | Permitida | **Permitida** | — |
| **Lector** | `insertOne()` | Denegada | **Denegada** | `13 Unauthorized — not authorized on u8_g11 to execute command { insert: "envios", ... }` |
| **Operador** | `updateOne()` | Permitida | **Permitida** | `matchedCount: 1, modifiedCount: 1` |
| **Operador** | `createUser()` | Denegada | **Denegada** | `13 Unauthorized — not authorized on u8_g11 to execute command { createUser: ... }` |

### 3.2 Pruebas ampliadas (lo que pidió el profesor) **[REFUERZO]**

| Identidad | Acción | Resultado |
| :--- | :--- | :--- |
| Lector | `updateOne()`, `deleteOne()`, `drop()` de `envios`, `createIndex()`, `createUser()` | **Denegadas** (código 13) — 8 de 8 pruebas coinciden con lo esperado |
| Lector | leer otra base (`admin.system.users`) | **Denegada** (`not authorized on admin`) |
| Lector | `listDatabases` | Devuelve solo `["u8_g11"]`: no ve las demás bases |
| Operador | `find()`, `updateOne()` (y su reversión con `$unset`), `insertOne()` y `deleteOne()` del documento de prueba | **Permitidas** |
| Operador | `grantRolesToUser("u8_g11_operador", [dbOwner])` (**escalar sus propios privilegios**) | **Denegada** |
| Operador | `getUsers()`, `serverStatus()`, leer `admin.system.users` | **Denegadas** — 10 de 10 pruebas coinciden con lo esperado |
| Operador | recuento final de `envios` | **15**: las pruebas no dejan residuos |

> El lector **no ve** las otras bases: el motor devuelve solo las que su rol alcanza. Es una consecuencia visible del mínimo privilegio.

### 3.3 Usuarios de respaldo y de restauración **[REFUERZO]**

Se crean en `admin` con los roles integrados **`backup`** y **`restore`**, en **usuarios separados**:

| Usuario | Rol | Pruebas |
| :--- | :--- | :--- |
| `u8_g11_respaldo` | `backup` | `find` permitido; `insertOne`, `createUser` y `deleteOne` **denegados** — 4 de 4 |
| `u8_g11_restaurador` | `restore` | `insertOne` y **`createUser` permitidos** (observación) |

**Por qué dos usuarios.** El rol `restore` es **amplio**: para restaurar necesita escribir en cualquier colección y, como se comprobó, también puede **crear usuarios**. El rol `backup` solo lee. Un único usuario con ambos roles convertiría al usuario del respaldo programado (que corre todos los días) en un usuario casi administrador. Se separan: el de `backup` se usa a diario; el de `restore` se habilita **solo durante una recuperación**.

---

## 4. Red y TLS

### 4.1 Evaluación de la exposición

| Parámetro | VM del grupo (captura) | Laboratorio **[REFUERZO]** |
| :--- | :--- | :--- |
| Puerto | 27017 | 27019 |
| `bindIp` | **`0.0.0.0`** (todas las interfaces) | `127.0.0.1` (solo local) |
| `ss -ltn` | — | `LISTEN 127.0.0.1:27019`; sockets en `0.0.0.0:27019`: **0** |
| Conexión desde la IP de la LAN | **Aceptada** (`192.168.1.42:27017`) | `MongoNetworkError: connect ECONNREFUSED <IP-LAN>:27019` |
| TLS | No configurado (texto plano) | `requireTLS` en la instancia TLS (4.3) |

**Conclusión sobre la VM.** Con la autenticación activada, `bindIp: 0.0.0.0` ya no deja los datos abiertos, pero sí deja **el puerto expuesto** a toda la red, con las credenciales y los datos viajando **sin cifrar**. Lo mínimo: (1) limitar `bindIp` a `127.0.0.1` y a la IP de la interfaz que se necesite (`bindIp: 127.0.0.1,192.168.1.42`); (2) restringir el puerto con firewall a la subred del aula (`sudo ufw allow from 192.168.1.0/24 to any port 27017`); (3) activar TLS cuando haya acceso remoto.

### 4.2 Implementación de TLS **[REFUERZO]**

Se generó una **CA propia** y un certificado de servidor con **SAN** (`localhost` y `127.0.0.1`), y se levantó una instancia con `requireTLS` y autenticación:

```yaml
net:
  port: 27020
  bindIp: 127.0.0.1
  tls:
    mode: requireTLS                 # rechaza cualquier conexión sin TLS
    certificateKeyFile: .../server.pem   # clave privada + certificado del servidor
    CAFile: .../ca.crt                   # CA que valida la cadena
    allowConnectionsWithoutCertificates: true   # TLS de servidor (el cliente no presenta certificado)
security:
  authorization: enabled
```

```text
$ openssl x509 -in server.crt -noout -subject -issuer -dates -ext subjectAltName
  subject=O = UTN FRRe SGBD, CN = localhost
  issuer=O = UTN FRRe SGBD, CN = CA Laboratorio G11
  X509v3 Subject Alternative Name: DNS:localhost, IP Address:127.0.0.1
```

### 4.3 Pruebas de TLS **[REFUERZO]**

| Cliente | Resultado |
| :--- | :--- |
| **Sin TLS** contra el puerto TLS | Rechazado: `MongoServerSelectionError: connection <monitor> to 127.0.0.1:27020 closed` |
| Con TLS pero **sin confiar en la CA** | Rechazado: `MongoNetworkError: self-signed certificate in certificate chain` |
| Con TLS, `--tlsCAFile ca.crt` y credenciales | **Aceptado**: `{ ping: 1, tls_mode: 'requireTLS', bindIp: '127.0.0.1', port: 27020 }` |
| `serverStatus().transportSecurity` | `'1.3': 8` conexiones con TLS 1.3 (ninguna con TLS 1.0, 1.1 ni 1.2) |
| `openssl s_client` | `TLSv1.3`, cifrado `TLS_AES_256_GCM_SHA384`, `Verify return code: 0 (ok)` |

```bash
mongosh --host localhost --port 27020 --tls --tlsCAFile ca.crt -u adminTLS --authenticationDatabase admin -p
```

### 4.4 TLS mutuo (la configuración que proponía la entrega original) **[REFUERZO]**

La entrega proponía `mode: requireTLS` + `certificateKeyFile` + `CAFile`, sin aclarar que, **con `CAFile` y sin `allowConnectionsWithoutCertificates`, el servidor exige también un certificado de cliente**:

| Cliente | Resultado |
| :--- | :--- |
| TLS + CA, **sin** certificado de cliente | Rechazado: `connection <monitor> to 127.0.0.1:27021 closed` |
| TLS + CA + `--tlsCertificateKeyFile cliente.pem` (firmado por la misma CA) | **Aceptado**: `{ ok: 1 }` |

### 4.5 Procedimiento para la VM real
1. Generar CA, clave y certificado del servidor con **SAN** que incluya la IP o el nombre con el que se conectan los clientes (si el SAN no coincide, la verificación falla).
2. `cat server.key server.crt > /etc/ssl/mongodb.pem`; `chown mongodb:mongodb`; `chmod 600`.
3. En `/etc/mongod.conf`, bajo `net:`, agregar el bloque `tls:` de arriba.
4. `sudo systemctl restart mongod` y revisar el log si no arranca (`/var/log/mongodb/mongod.log`).
5. Distribuir **solo `ca.crt`** a los clientes (nunca la clave privada) y conectar con `--tls --tlsCAFile`.
6. Medir: `db.serverStatus().transportSecurity`.

---

## 5. Backup y restauración

**Reglas de la consigna:** respaldar la base del grupo, verificar los artefactos, eliminar controladamente una colección **de prueba** o restaurar en `u8_g11_restore`, validar conteos y registros, **no borrar la base original**.

### 5.1 Estado previo (recuentos registrados justo antes del dump) **[REFUERZO]**

```text
envios                  15 documentos
eventos_seguimiento     20 documentos
prueba_borrado           9 documentos · md5 3d2175fc860abccd79d1155263db04d6   (copia de envíos Entregados y Demorados, con un índice)
```

### 5.2 `mongodump` con el usuario de respaldo **[REFUERZO]**

```bash
mongodump --host 127.0.0.1:27019 -u u8_g11_respaldo -p ******** --authenticationDatabase admin --db u8_g11 --out $LAB/backup_u8_g11
```
```text
done dumping u8_g11.envios (15 documents)
done dumping u8_g11.eventos_seguimiento (20 documents)
done dumping u8_g11.prueba_borrado (9 documents)
```

### 5.3 Verificación de los artefactos **[REFUERZO]**

| Archivo | Tamaño | Contenido |
| :--- | ---: | :--- |
| `envios.bson` | 9,5 KB | Documentos en formato BSON |
| `envios.metadata.json` | 449 B | **Definición de los índices** (`_id_`, `ruta_1_fecha_despacho_1`, `estado_actual_1_fecha_despacho_-1`) y opciones |
| `eventos_seguimiento.bson` / `.metadata.json` | 5,1 KB / 312 B | Ídem |
| `prueba_borrado.bson` / `.metadata.json` | 5,7 KB / 274 B | Ídem |
| `prelude.json` | 51 B | Versión del formato de volcado |

- `sha256sum` de cada archivo (por ejemplo `envios.bson` = `b97290a9…f356f`) permite detectar corrupción y comprobar que el respaldo no cambió al copiarlo.
- `bsondump envios.bson` muestra los documentos legibles: **15** en `envios.bson`, igual al recuento de la base.
- El volcado **guarda los índices como definición** (no los datos del índice): `mongorestore` los reconstruye.

### 5.4 Restauración en una base alternativa **[REFUERZO]**

```bash
mongorestore --dryRun --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' $LAB/backup_u8_g11     # ensayo: no escribe nada
mongorestore          --nsInclude 'u8_g11.*' --nsFrom 'u8_g11.*' --nsTo 'u8_g11_restore.*' $LAB/backup_u8_g11     # restauración real
```
```text
finished restoring u8_g11_restore.envios (15 documents, 0 failures)
finished restoring u8_g11_restore.prueba_borrado (9 documents, 0 failures)
finished restoring u8_g11_restore.eventos_seguimiento (20 documents, 0 failures)
44 document(s) restored successfully. 0 document(s) failed to restore.
```

> La entrega original usaba `--db u8_g11_restore`: funciona, pero `mongorestore` lo informa como **obsoleto** (`The --db and --collection flags are deprecated`, visible en la captura). Se usa `--nsFrom/--nsTo`.

### 5.5 Validación de la recuperación (`FASE=comparar`) **[REFUERZO]**

Se comparan origen y destino en **cuatro niveles**, no solo el recuento:

| Colección | Documentos (origen / destino) | Documentos distintos o faltantes | `dbHash` (md5) | Índices |
| :--- | :--- | :--- | :--- | :--- |
| `envios` | 15 / 15 | 0 / 0 | `3307f425…cec73` = `3307f425…cec73` | idénticos |
| `eventos_seguimiento` | 20 / 20 | 0 / 0 | `433220da…b89` = `433220da…b89` | idénticos |

`RESULTADO GLOBAL: RECUPERACIÓN VERIFICADA (conteos, contenido, hash e índices)`. La comparación documento a documento serializa cada uno con EJSON y lo compara por `_id`.

**Restaurar sobre un destino con datos no sobrescribe:** repetir el `mongorestore` produce `E11000 duplicate key error` y `0 document(s) restored successfully. 15 document(s) failed to restore`. Para reemplazar se usa `--drop`, con cuidado (borra la colección destino antes).

### 5.6 Incidente controlado: borrar una colección de prueba y recuperarla **[REFUERZO]**

```text
Antes : colecciones = envios, eventos_seguimiento, prueba_borrado
drop(prueba_borrado) -> true
Después: colecciones = envios, eventos_seguimiento            (prueba_borrado existe: false)
```
```bash
mongorestore -u u8_g11_restaurador -p ******** --authenticationDatabase admin --nsInclude 'u8_g11.prueba_borrado' $LAB/backup_u8_g11
```
```text
finished restoring u8_g11.prueba_borrado (9 documents, 0 failures)
Antes del incidente : 9 documentos | md5 3d2175fc860abccd79d1155263db04d6
Después de recuperar: 9 documentos | md5 3d2175fc860abccd79d1155263db04d6 | índices: _id_, estado_actual_1
[OK]    Colección recuperada con el mismo contenido (conteo y md5 idénticos)
```
Se recuperó **solo esa colección** (`--nsInclude`), con sus índices, sin tocar `envios` ni `eventos_seguimiento`. Control final: `envios` 15 · `eventos_seguimiento` 20 · `prueba_borrado` 9.

### 5.7 Alcance y límites de `mongodump`
- Es un respaldo **lógico** de un instante: sin `--oplog` en un *replica set* no permite recuperación a un punto en el tiempo (en un *standalone* no existe el oplog).
- No incluye los **usuarios** salvo que se pida (`--dumpDbUsersAndRoles` con `--db`): una restauración total necesita además el respaldo de las cuentas.
- Un archivo de respaldo **contiene los datos en claro**: debe guardarse con permisos restrictivos y fuera del servidor (regla 3-2-1).
- Un respaldo sin restauración probada no es un respaldo: por eso se restaura y se compara.

---

## 6. Incidente: el usuario puede leer pero no modificar

### 6.1 Diagnóstico por capas (`FASE=incidente`, con `u8_g11_lector`) **[REFUERZO]**

| Capa | Pregunta | Prueba | Resultado |
| :--- | :--- | :--- | :--- |
| **1. Conexión** | ¿Llega al servidor? | `ping`, `hello` | `ping: 1`, `hello_ok: true` → **OK** (no exigen autenticación) |
| **2. Autenticación** | ¿Quién es? | `connectionStatus` | `authenticatedUsers: [{ user: 'u8_g11_lector', db: 'u8_g11' }]`, rol `read@u8_g11` → **OK** |
| **3. Autorización** | ¿Qué puede hacer? | `connectionStatus({ showPrivileges: true })` | Acciones sobre `u8_g11`: `changeStream, collStats, dbHash, dbStats, find, killCursors, listCollections, listIndexes, listSearchIndexes, planCacheRead` → **no incluye `insert`, `update` ni `remove`** |
| Prueba funcional | Misma conexión, lectura y escritura | `find()` / `updateOne()` | `find`: **permitida** · `updateOne`: **denegada**, `código 13 Unauthorized — not authorized on u8_g11 to execute command { update: "envios", ... }` |

**Diagnóstico.** La conexión y la autenticación son correctas: **falla la autorización**. El rol `read` no incluye las acciones de escritura.

### 6.2 Cómo se distingue un fallo de autenticación **[REFUERZO]**

| Situación | Error |
| :--- | :--- |
| Contraseña incorrecta | `MongoServerError: Authentication failed.` (código 18) |
| Usuario correcto contra la base de autenticación equivocada (`--authenticationDatabase admin` en vez de `u8_g11`) | `MongoServerError: Authentication failed.` (**el mismo mensaje**: el motor no revela si el usuario existe) |
| Autenticado, sin privilegio | `Unauthorized — not authorized on u8_g11 to execute command ...` (código 13) |
| Sin autenticar | `Unauthorized — Command find requires authentication` (código 13) |

Con `Authentication failed` el problema está **antes** de la autorización (credenciales o base de autenticación). Con `not authorized on ... to execute command ...` el usuario **ya está autenticado** y le falta el privilegio.

### 6.3 Otras causas de «puedo leer pero no escribir»
| Causa | Cómo se reconoce |
| :--- | :--- |
| Rol `read` (el caso del laboratorio) | `Unauthorized`, código 13 |
| Rol de escritura, pero **sobre otra base o colección** | `Unauthorized`; en `showPrivileges` el recurso no coincide |
| Rol personalizado con solo `find` | Ídem; se revisa con `rolesInfo` |
| Conexión a un **secundario** de un replica set | `NotWritablePrimary`, código 10107 |
| Documento que no pasa la validación de esquema | `DocumentValidationFailure`, código 121 |
| Clave `_id` repetida | `DuplicateKey`, código 11000 |

### 6.4 Corrección y reversión **[REFUERZO]**
```javascript
db.getSiblingDB("u8_g11").grantRolesToUser("u8_g11_lector", [{ role: "readWrite", db: "u8_g11" }])   // como adminG11
```
Roles antes: `[ read ]` → después: `[ read, readWrite ]`. **Los privilegios se aplican a las conexiones nuevas:** el usuario debe reconectar; con la nueva conexión el `updateOne` **funciona**. Después se revierte con `revokeRolesFromUser` y se comprueba que el `updateOne` vuelve a dar `DENEGADA -> Unauthorized (código 13)`. La decisión de otorgar escritura depende de la política: si solo necesita leer, **no se corrige el permiso, se corrige la expectativa**.

---

## 7. Errores y diagnóstico

| # | Qué se detectó | Cómo | Corrección |
| :--- | :--- | :--- | :--- |
| 1 | `bindIp: 127.0.0.1` en el texto, `0.0.0.0` en la captura del `mongod.conf`; pruebas hechas desde `192.168.1.42`. | Cruce entre texto y capturas. | Sección 1.1: el diagnóstico correcto es **instancia expuesta y sin autenticación**; sección 4.1. |
| 2 | Encabezado de la bitácora: "Motor Asignado: MySQL". | Lectura. | MongoDB Community. |
| 3 | `admin.txt` no tiene la creación de `u8_g11_lector` ni de `u8_g11_operador`, y la prueba `insertOne` no indica con qué identidad se ejecuta. | Cotejo de `admin.txt` con la consigna ("comandos para la creación de usuarios, asignación de permisos y ejecución de las pruebas"). | `solucion_u8_actividad2_mongosh.js`: cada fase indica la identidad. |
| 4 | Contraseñas en texto claro dentro de `admin.txt` y `restore.txt` (`AdminPassword123*`, etc.). | Lectura. La consigna pide no publicar credenciales. | Los scripts reciben las contraseñas por variables de entorno y las muestran como `********`. |
| 5 | `envios` con **16** documentos en el respaldo y **15** en `admin.txt` (“devuelve 15”). | `done dumping u8_g11.envios (16 documents)` frente a `countDocuments() → 15`. | Ver hipótesis abajo. |
| 6 | La validación de la recuperación era solo por recuento. | Lectura de `restore.txt`. | Sección 5.5. |
| 7 | `restore.txt` lista `getIndexes()` pero la bitácora no muestra su salida. | Lectura. | La comparación incluye los índices (5.5). |
| 8 | La prueba de TLS solo estaba descripta, sin cliente que se conecte. | Lectura de la sección 4. | Secciones 4.2 a 4.4. |

**Sobre los 16 documentos (hipótesis, a verificar en la VM).** Entre la carga (15) y el respaldo (16) alguien insertó un documento. En el laboratorio se reprodujo exactamente esa situación: en una primera corrida, la prueba `insertOne` de un usuario con el rol `restore` **tuvo éxito** (el rol es amplio, 3.3) y dejó `ENV-TEST-RESPALDO`; `envios` llegó a 16 y lo detectó el recuento previo al dump. En la VM puede haber pasado algo equivalente (por ejemplo, una prueba de inserción ejecutada con el operador o el administrador). Se identifica con:

```javascript
db.getSiblingDB("u8_g11").envios.find({ _id: { $not: /^ENV-2026-0(0[1-9]|1[0-5])$/ } })
```
Si aparece un documento de prueba, se elimina antes de repetir el respaldo, y siempre se **registra el recuento inmediatamente antes del `mongodump`**.

**Correspondencia con los archivos de la entrega**

| Archivo pedido | Contenido | Equivale a |
| :--- | :--- | :--- |
| `admin.txt` | Solo comandos de `mongosh` (usuarios, permisos, pruebas) | Fases `crear_admin`, `rbac`, `pruebas`, `incidente` de `solucion_u8_actividad2_mongosh.js` |
| `restore.txt` | Comandos de consola, conteos antes y después, verificación | Secciones 5 de `solucion_u8_actividad2.sh` y fase `comparar` |
| `bitacora.pdf` | Pasos, salidas, fecha, entorno y conclusiones | Esta bitácora con capturas propias |

---

## 8. Uso de IA

Se utilizó Claude Code como asistente para **revisar la entrega** frente a la consigna y a la devolución del profesor, **escribir** los scripts y **ejecutarlos** en un laboratorio local aislado, de donde sale toda la evidencia **[REFUERZO]**. Qué se validó: cada resultado citado proviene de la ejecución real del script (la corrida final registra 34 pruebas en `[OK]`); las pruebas que no coincidieron con lo esperado se analizaron en lugar de ocultarse (el rol `restore` permitió `insertOne` y `createUser`, lo que llevó a separar los usuarios de respaldo y de restauración); la afirmación sobre TLS mutuo se comprobó con un servidor de prueba antes de incluirla. Qué se descartó: documentar TLS solo como teoría cuando el laboratorio permite implementarlo, y validar la recuperación solo con recuentos.

## 9. Aprendizajes

- **Conexión, autenticación y autorización son capas distintas** y cada una se prueba y falla de manera distinta; `ping` funciona sin credenciales y `Authentication failed` no revela si el usuario existe.
- El **mínimo privilegio** se demuestra con pruebas negativas, incluida la **escalada** (un operador no puede otorgarse roles). Los roles integrados no son todos "chicos": `restore` es casi administrativo.
- Una instancia con `bindIp: 0.0.0.0` y sin autenticación está **abierta a la red**: el primer hallazgo de una guardia.
- **TLS** requiere CA, certificado con SAN correcto y distribución de la CA; con `CAFile` y sin `allowConnectionsWithoutCertificates` el servidor exige certificado de cliente.
- Un respaldo se valida por **contenido, hash e índices**, no solo por recuento, y se prueba **restaurando** (en otra base o una colección de prueba) antes de necesitarlo.
- Registrar el **recuento justo antes del respaldo** permite detectar datos de prueba que se colaron.
