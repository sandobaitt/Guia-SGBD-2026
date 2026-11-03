# Fundamentos Teóricos: U8 - Actividad 2 (Guardia DBA MongoDB)

**Asignatura:** Administración de Sistemas de Gestión de Bases de Datos (SGBD)  
**Tópicos:** Guardia DBA, capas de acceso (conexión, autenticación, autorización), SCRAM y excepción de localhost, RBAC y roles integrados, mínimo privilegio, exposición de red (`bindIp`, firewall), TLS y TLS mutuo, respaldo lógico con `mongodump`/`mongorestore`, validación de la recuperación, diagnóstico de errores de acceso.

---

## 1. La guardia DBA: qué se revisa al tomar una instancia

Cuando un DBA recibe una instancia, antes de tocar datos responde cinco preguntas:

| Pregunta | Dónde se mira | Hallazgo grave |
| :--- | :--- | :--- |
| ¿Qué versión y en qué estado está? | `db.version()`, `serverStatus()` | Versión sin soporte |
| ¿Exige **autenticación**? | `getCmdLineOpts().parsed.security` | Sin `authorization: enabled` |
| ¿Quién puede **llegar** a ella? | `net.bindIp`, `ss -ltnp`, firewall | `bindIp: 0.0.0.0` sin restricciones |
| ¿Cómo viaja el tráfico? | `net.tls.mode` | `disabled`: credenciales y datos en texto plano |
| ¿Puedo **recuperar** los datos? | Respaldos y pruebas de restauración | Sin copia o sin restauración probada |

> **Principio.** Una instancia sin autenticación y que escucha en todas las interfaces equivale a una base **pública**. Durante años fue la causa de filtraciones masivas de MongoDB: por eso, desde la versión 3.6 los binarios escuchan por defecto solo en `localhost`.

`getCmdLineOpts` informa la configuración **efectiva** del proceso: es más confiable que leer un archivo que quizá no se cargó o que se editó sin reiniciar.

---

## 2. Tres capas, tres fallos distintos

| Capa | Pregunta | Mecanismo | Cómo falla |
| :--- | :--- | :--- | :--- |
| **1. Conexión** | ¿Llega al socket del servidor? | Red, `bindIp`, puerto, firewall, TLS | `ECONNREFUSED`, *timeout*, error de TLS |
| **2. Autenticación** | ¿Quién es? | SCRAM-SHA-256, x.509, LDAP, Kerberos (las dos últimas, Enterprise) | `Authentication failed` (código 18) |
| **3. Autorización** | ¿Qué puede hacer esa identidad? | RBAC: roles y privilegios | `not authorized on <base> to execute command ...` (código 13) |

Se **diagnostica de abajo hacia arriba**: si el usuario ya ejecuta `find`, la capa 1 y la capa 2 están bien; el problema está en la 3. Que un `ping` funcione sin credenciales no significa nada sobre los datos: ciertos comandos (`ping`, `hello`, `buildInfo`) no exigen autenticación.

---

## 3. Autenticación

### 3.1. Activarla
```yaml
# mongod.conf
security:
  authorization: enabled
```
Sin esa línea, **cualquier cliente puede ejecutar cualquier comando**, aunque existan usuarios creados.

### 3.2. Conceptos clave
| Concepto | Detalle |
| :--- | :--- |
| **Base de autenticación** | Cada usuario **pertenece a una base** (donde se creó). Para entrar hay que indicarla: `--authenticationDatabase u8_g11`. Un usuario de `admin` con `authSource=admin` no es el mismo que uno de `u8_g11` |
| **Mecanismo** | SCRAM-SHA-256 por defecto (también SCRAM-SHA-1 por compatibilidad); la contraseña **no viaja**: se intercambia una prueba derivada |
| **Excepción de localhost** | Con el acceso activo y **sin usuarios**, solo una conexión desde `localhost` puede crear el primero; se cierra al crearlo |
| **Orden correcto** | Crear el administrador → activar `authorization` → reiniciar → verificar el rechazo sin credenciales |
| **Mensaje deliberadamente ambiguo** | `Authentication failed` no distingue "usuario inexistente" de "clave incorrecta" ni de "base equivocada": no revela información al atacante |
| **Claves** | No escribirlas en archivos ni en el historial: `passwordPrompt()` en `mongosh` y `-p` sin valor en la línea de comandos |

---

## 4. Autorización: RBAC

### 4.1. Modelo
- Un **privilegio** = un **recurso** (base, colección o todo el clúster) + un conjunto de **acciones** (`find`, `insert`, `update`, `remove`, `createIndex`, `createUser`, `dropCollection`, ...).
- Un **rol** agrupa privilegios; un usuario tiene **uno o más roles**; los roles pueden heredar de otros.
- **Mínimo privilegio:** cada usuario recibe los roles justos y solo sobre las bases necesarias.

### 4.2. Roles integrados usados en la actividad
| Rol | Qué otorga | Observaciones |
| :--- | :--- | :--- |
| `read` | `find`, `listCollections`, `listIndexes`, `collStats`, `dbStats`, `dbHash`, `changeStream`, `killCursors`, `planCacheRead` sobre una base | **No** incluye `insert`, `update` ni `remove` (comprobado con `connectionStatus` + `showPrivileges`) |
| `readWrite` | Todo lo de `read` + `insert`, `update`, `remove`, `createCollection`, `createIndex`, `dropCollection`, `dropIndex` | **No** administra usuarios |
| `dbAdmin` / `userAdmin` | Administración de la base / de los usuarios y roles de la base | Se separan a propósito: el que administra datos no administra cuentas |
| `dbOwner` | `readWrite` + `dbAdmin` + `userAdmin` sobre la base | Es el que un operador intentaría concederse en una **escalada** |
| `userAdminAnyDatabase` | Administrar usuarios de **cualquier** base | **No lee ni escribe datos** por sí mismo (por eso el administrador del laboratorio suma `readWriteAnyDatabase`), pero **puede concederse cualquier rol**: en la práctica equivale a un superusuario y se reserva para el DBA |
| `clusterMonitor` | Lectura de métricas (`serverStatus`, etc.) | Para la guardia de diagnóstico, sin poder modificar |
| `backup` | Lectura necesaria para `mongodump` | Solo lectura |
| `restore` | Escritura necesaria para `mongorestore` | **Amplio**: en el laboratorio permitió `insertOne` y `createUser` |
| `root` | Todo | Solo para el superadministrador |

### 4.3. Por qué separar respaldo y restauración
El usuario que respalda trabaja **todos los días y de forma automática**; el que restaura se usa **en emergencias**. Un único usuario con `backup` + `restore` convertiría a la tarea programada en una cuenta casi administrativa. Se separan, y el de `restore` se habilita **solo mientras dura la recuperación**.

### 4.4. Pruebas de autorización
Un control no está demostrado hasta que se prueban **las dos caras**:

| Cara | Qué prueba | Ejemplo |
| :--- | :--- | :--- |
| **Positiva** | Lo que debe poder hacer, funciona | El operador hace `updateOne` |
| **Negativa** | Lo que no debe poder hacer, **falla por la razón correcta** | El lector hace `insertOne` → `Unauthorized` |
| **Escalada** | No puede darse más permisos | El operador intenta `grantRolesToUser(... dbOwner)` → denegado |
| **Aislamiento** | No ve otras bases | `admin.system.users` denegado; `listDatabases` devuelve solo `u8_g11` |

### 4.5. Comparación con los motores de la primera parte
| Tema | MySQL | PostgreSQL | MongoDB |
| :--- | :--- | :--- | :--- |
| Identidad | `'usuario'@'host'` | Rol con `LOGIN` + `pg_hba.conf` | Usuario **dentro de una base** (`authenticationDatabase`) |
| Roles | `CREATE ROLE` + `SET DEFAULT ROLE` | `CREATE ROLE`, herencia automática | Roles integrados y personalizados, activos al autenticarse |
| Permisos por objeto | `GRANT ... ON base.tabla` | `GRANT ... ON tabla` | Privilegio = recurso + acciones |
| Ver los permisos | `SHOW GRANTS` | `\dp`, `\du` | `getUser`, `rolesInfo`, `connectionStatus({showPrivileges:true})` |
| Error de permiso | `ERROR 1142 ... denied` | `permission denied for table` | `not authorized on <db> to execute command` (código 13) |

---

## 5. Red: exposición de la instancia

| Parámetro | Significado | Valor seguro |
| :--- | :--- | :--- |
| `net.port` | Puerto TCP (27017 por defecto) | Cualquiera, pero el firewall debe restringirlo |
| `net.bindIp` | Interfaces en las que escucha | `127.0.0.1` y, solo si hace falta, la IP concreta de la interfaz de acceso. **No** `0.0.0.0` |
| Firewall | Quién puede llegar al puerto | Permitir solo la subred del aula o de la aplicación |

Capas de defensa (ninguna reemplaza a las otras): **red** (bindIp + firewall) → **autenticación** → **autorización** → **cifrado en tránsito (TLS)** → **cifrado en reposo y auditoría** (en la edición Community, el cifrado en reposo se resuelve a nivel de disco o sistema operativo; la auditoría integrada es de la edición Enterprise).

**Cómo comprobar la exposición:** `ss -ltn | grep 27017` muestra la dirección de escucha (`127.0.0.1` frente a `0.0.0.0`); desde **otro equipo**, un intento de conexión confirma si el puerto es alcanzable (`ECONNREFUSED` si no escucha en esa interfaz).

---

## 6. TLS

### 6.1. Qué aporta
| Propiedad | Significado |
| :--- | :--- |
| **Confidencialidad** | Las credenciales y los datos viajan cifrados (sin TLS, `tcpdump` los muestra en claro) |
| **Integridad** | Los mensajes no pueden alterarse en tránsito |
| **Autenticación del servidor** | El cliente verifica que habla con el servidor correcto (cadena de certificados + nombre en el SAN) |

TLS cifra el **canal**; **no reemplaza** la autenticación de usuarios: son controles complementarios.

### 6.2. Piezas
| Pieza | Función |
| :--- | :--- |
| **CA** (autoridad certificante) | Firma los certificados; su certificado público (`ca.crt`) es lo que los clientes deben **confiar** |
| **Certificado del servidor** | Identidad del servidor; debe incluir en el **SAN** (*Subject Alternative Name*) la IP o el nombre con el que se conectan los clientes |
| **Clave privada** | Secreta; en el servidor, junto con el certificado, en un `.pem` con permisos `600` y propietario `mongodb` |
| `CAFile` | CA con la que el servidor valida los certificados que **presentan los clientes** |

### 6.3. Modos (`net.tls.mode`)
| Modo | Comportamiento |
| :--- | :--- |
| `disabled` | Sin TLS (el valor por defecto) |
| `allowTLS` | Acepta ambos tipos de conexión, pero entre servidores usa texto plano |
| `preferTLS` | Acepta ambos y entre servidores usa TLS (útil para migrar) |
| `requireTLS` | **Solo TLS**: cualquier conexión sin cifrar se rechaza |

### 6.4. TLS de servidor frente a TLS mutuo
| Configuración | Qué exige al cliente |
| :--- | :--- |
| `requireTLS` + certificado de servidor + `allowConnectionsWithoutCertificates: true` | Confiar en la CA del servidor (`--tls --tlsCAFile`). No presenta certificado |
| `requireTLS` + `CAFile` **sin** `allowConnectionsWithoutCertificates` | Además, **presentar un certificado de cliente** firmado por la CA (`--tlsCertificateKeyFile`): **TLS mutuo**. Comprobado en el laboratorio: sin certificado de cliente la conexión se cierra |

### 6.5. Errores típicos
| Mensaje del cliente | Causa |
| :--- | :--- |
| `self-signed certificate in certificate chain` | El cliente no tiene la CA (falta `--tlsCAFile`) |
| `Hostname/IP does not match certificate's altnames` | El SAN no incluye el nombre o la IP usados |
| `connection ... closed` / `SSL handshake` | El cliente no usa TLS contra un servidor `requireTLS`, o falta su certificado en TLS mutuo |
| `certificate has expired` | Vencimiento: hay que **rotar** el certificado antes de la fecha |

### 6.6. Comparación
| | MySQL | PostgreSQL | MongoDB |
| :--- | :--- | :--- | :--- |
| Activar | `ssl-ca`, `ssl-cert`, `ssl-key` | `ssl = on`, `ssl_cert_file`, `ssl_key_file` | `net.tls.*` |
| Obligarlo | `require_secure_transport = ON` | `hostssl` en `pg_hba.conf` | `mode: requireTLS` |

---

## 7. Respaldo y recuperación

### 7.1. Estrategias
| Estrategia | Cómo | Ventajas | Límites |
| :--- | :--- | :--- | :--- |
| **Lógico**: `mongodump` / `mongorestore` | Exporta BSON + metadatos de índices | Portable entre versiones, selectivo por base/colección, simple | Más lento en volúmenes grandes; sin `--oplog`, no es consistente entre colecciones |
| **Físico**: copia del directorio de datos | Con el servicio detenido, o con *snapshot* del sistema de archivos (`fsyncLock`) | Rápido para bases grandes | Atado a la versión y a la plataforma |
| **Gestionado**: Percona Backup for MongoDB, Ops Manager, Atlas | Respaldos continuos y recuperación a un punto en el tiempo | PITR, automatización | Infraestructura adicional |
| **JSON/CSV**: `mongoexport` / `mongoimport` | Texto legible | Intercambio con otras herramientas | Pierde tipos (fechas, `Long`) salvo con *Extended JSON*: **no es un respaldo** |

Comparación con la primera parte: `mongodump` equivale a `mysqldump` / `pg_dump` (lógico). La **recuperación a un punto en el tiempo** (U6) usa en MongoDB el **oplog** de un *replica set* (`mongodump --oplog` + `mongorestore --oplogReplay`), lo que en un *standalone* no existe.

### 7.2. Qué contiene un volcado
Por cada colección: `<coleccion>.bson` (los documentos) y `<coleccion>.metadata.json` (las **definiciones** de los índices y las opciones); más `prelude.json`. Los índices **se reconstruyen** al restaurar. Los usuarios **no** se incluyen salvo `--dumpDbUsersAndRoles`.

### 7.3. Opciones de `mongorestore` que conviene dominar
| Opción | Función |
| :--- | :--- |
| `--nsInclude 'base.coleccion'` | Restaura solo lo indicado (patrones con `*`) |
| `--nsFrom` / `--nsTo` | Renombra el espacio de nombres al restaurar (por ejemplo, a `u8_g11_restore`) |
| `--dryRun` | Ensaya sin escribir |
| `--drop` | Borra la colección destino antes de restaurar (**destructivo**) |
| `--db`, `--collection` | Forma antigua, **obsoleta** |
| *Comportamiento por defecto* | **No sobrescribe**: documentos con `_id` existente dan `E11000 duplicate key` |

### 7.4. Cómo se valida una recuperación
Un respaldo **no está probado** hasta que se restaura y se compara. De menor a mayor exigencia:

| Nivel | Cómo | Qué detecta |
| :--- | :--- | :--- |
| 1. Recuento | `countDocuments()` en origen y destino | Documentos que faltan |
| 2. Contenido | Comparar documento a documento (EJSON) | Documentos alterados |
| 3. Hash | `db.runCommand({ dbHash: 1, collections: [...] })` | Diferencias de contenido, de forma resumida |
| 4. Índices | `getIndexes()` | Índices no reconstruidos |
| 5. Integridad del archivo | `sha256sum` de los `.bson` | Corrupción del respaldo |
| 6. Funcional | Ejecutar las consultas de la aplicación sobre la base restaurada | Que el dato sea **útil** |

### 7.5. Buenas prácticas
- Registrar el **recuento inmediatamente antes** del respaldo (un dato de prueba olvidado entra en el volcado).
- Restaurar **en otra base** o en un entorno aparte y comparar; no sobre la original.
- Guardar el respaldo **fuera del servidor**, con permisos restrictivos y regla **3-2-1** (3 copias, 2 medios, 1 fuera del sitio): contiene los datos en claro.
- Medir cuánto tarda la restauración: es el **RTO** real. La frecuencia del respaldo determina el **RPO**.

---

## 8. Diagnóstico de errores de acceso (el incidente)

**Síntoma:** «puedo leer con `find()` pero un `updateOne()` es rechazado».

| Paso | Prueba | Si falla, el problema está en... |
| :--- | :--- | :--- |
| 1 | `ping`, `hello` | **Conexión** (red, firewall, TLS) |
| 2 | `connectionStatus` → `authenticatedUsers` | **Autenticación** (usuario, clave, base de autenticación) |
| 3 | `connectionStatus({ showPrivileges: true })` | **Autorización**: si no hay `update`/`insert`/`remove` sobre el recurso, el rol no alcanza |

| Error | Código | Significado |
| :--- | :---: | :--- |
| `Authentication failed` | 18 | Credenciales o base de autenticación incorrectas |
| `Unauthorized` (*requires authentication*) | 13 | No se autenticó |
| `Unauthorized` (*not authorized on ... to execute command ...*) | 13 | Autenticado, **sin privilegio** |
| `NotWritablePrimary` | 10107 | Se conectó a un secundario |
| `DocumentValidationFailure` | 121 | El documento no cumple el validador de esquema |
| `DuplicateKey` | 11000 | `_id` o clave única repetidos |

**Corrección:** depende de la política. Si el usuario **debe** escribir: `grantRolesToUser` con el rol mínimo y reconexión (los privilegios se aplican a las conexiones nuevas). Si **solo debía leer**: no se cambia el permiso, se corrige la expectativa. Cualquier cambio se **revierte** y se verifica.

---

## 9. Preguntas de defensa (respuestas breves)

- **"¿Por qué `bindIp: 0.0.0.0` es un problema si ya hay autenticación?"** Porque expone el puerto a toda la red: permite ataques de fuerza bruta sobre las credenciales y, sin TLS, la contraseña y los datos viajan en claro. Se limita `bindIp` a las interfaces necesarias, se restringe con firewall y se activa TLS.
- **"El lector puede hacer `ping` sin credenciales, ¿está mal?"** No: `ping` no es una operación sobre datos. Lo que debe rechazarse sin autenticar es `find`, `insert`, `listDatabases`, etc., y se probó.
- **"¿Por qué dos usuarios, uno para respaldar y otro para restaurar?"** Porque `restore` es un rol amplio (en el laboratorio permitió insertar y crear usuarios). El respaldo se ejecuta todos los días con el rol de solo lectura; el de restauración se habilita solo durante una recuperación.
- **"¿Cómo demuestran que la restauración fue correcta?"** Por recuento, contenido documento a documento, `dbHash`, índices y `sha256` del archivo; además se borró una colección de prueba y se recuperó con el mismo `md5` y los mismos índices.
- **"El recuento da 16 y esperaban 15, ¿qué hacen?"** Antes de respaldar se investiga: se buscan documentos de prueba (`find({ _id: { $not: /^ENV-2026-0(0[1-9]|1[0-5])$/ } })`) y se corrige. El respaldo se hace sobre un estado conocido y se registra el recuento inmediatamente antes.
- **"¿Qué cambia con TLS mutuo?"** El servidor además exige un certificado de cliente firmado por la CA; sin él, la conexión se cierra. Es un control extra de **quién** puede conectarse, no solo de cifrado.
- **"¿Qué no cubre `mongodump`?"** La recuperación a un punto en el tiempo (requiere el oplog de un replica set), la consistencia entre colecciones sin `--oplog` y los usuarios (salvo `--dumpDbUsersAndRoles`).
