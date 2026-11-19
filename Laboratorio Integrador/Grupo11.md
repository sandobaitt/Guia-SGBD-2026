<!-- Fuente del entregable. Se exporta como Grupo11.pdf (nombre exacto exigido por la consigna). -->

# Laboratorio Integrador · SGBD 2026

**Universidad Tecnológica Nacional — Facultad Regional Resistencia**  
**Ingeniería en Sistemas de Información · Sistemas de Gestión de Bases de Datos (SGBD)**  
**Opción A: MySQL 9.7 + MongoDB 8.0**

## Grupo 11

**Integrantes presentes:**
- Aguirre Egea, Emiliano
- Ghione, Lucas Emanuel
- Pagno, Agustin Mario
- Sandoval, Lautaro Emanuel

*[CONFIRMAR: dejar solo los integrantes presentes el día del laboratorio]*

**Docentes:** Prof. Ing. A. Fantín · JTP Ing. J.C. Fernández · Aux. Ing. B. Dominguez  
**Fecha:** 17/11/2026

---

# Bloque 1: Administración y rendimiento relacional (MySQL 9.7)

## Ejercicio 1: Cuentas de usuario y seguridad granular

**Enunciado**
> **1.1 Administrador de Grupo:** Crear la cuenta de usuario `usr_gXX` (donde XX es el número de grupo) accesible desde cualquier host (`'usr_gXX'@'%'`). Concederle privilegios para administrar las bases del laboratorio sin usar la cuenta súper-usuario.
>
> **1.2 Usuario de Backup:** Crear el usuario local `usr_backup@localhost` asignándole únicamente los privilegios indispensables para efectuar copias de seguridad de `employees`. Justificar en comentarios la necesidad de cada privilegio.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

## Ejercicio 2: Almacenamiento, exportación e importación masiva

**Enunciado**
> **2.1 Exportación a Texto Delimitado:** Exportar las tablas `employees`, `salaries` y `titles` de la base `employees` a archivos planos delimitados (`mysqldump --tab` o `SELECT INTO OUTFILE`).
>
> **2.2 Definición del Esquema Traducido:** Crear la base `empleados` y definir las tablas `empleados`, `salarios` y `cargos` traduciendo los nombres de atributos al castellano, manteniendo integridad referencial.
>
> **2.3 Carga Masiva:** Importar masivamente los datos desde los archivos delimitados hacia las nuevas tablas mediante `LOAD DATA INFILE` o `mysqlimport`. Registrar tiempo y filas procesadas.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

## Ejercicio 3: Optimización SQL y planes de ejecución (EXPLAIN ANALYZE)

**Enunciado**
> - **3.a Consulta 1 (Histórico):** Listar la información personal completa de los empleados junto con su historial de salarios.
> - **3.b Consulta 2 (Búsqueda por Apellido):** Filtrar empleados cuyo apellido comience con "Gut" (`last_name LIKE 'Gut%'`) o sea igual a "González" (`last_name = 'González'`), ordenando alfabéticamente.
> - **3.c Consulta 3 (Rangos y Vigencia):** Filtrar sueldos en un rango específico vigentes a la fecha actual (`to_date = '9999-01-01'`).
> - **3.d Consulta 4 (Combinación con CTE):** Combinar las condiciones anteriores mediante CTEs (`WITH ... AS`) o subconsultas.
> - **3.e Índices B-Tree:** Crear índices B-Tree en `employees(last_name)` y `salaries(salary)`. Re-ejecutar consultas con `EXPLAIN ANALYZE` y comparar métricas (filas, tiempo ms, costo) antes y después.
> - **3.f Búsqueda de Cargos:** Consultar la tabla `titles` para "Engineer" comparando `LIKE 'Engineer%'` versus `= 'Engineer'`. Evaluar uso de índices.
> - **3.g Resumen Comparativo:** Consolidar métricas en una tabla y redactar informe sintético de rendimiento (máx. 15 renglones).

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

## Ejercicio 4: Programabilidad en el SGBD (procedimientos y triggers)

**Enunciado**
> **4.1 Verificación de Gerentes:** Procedimiento almacenado que verifique si un `dept_manager` administra actualmente un departamento. Retornar los empleados asignados y su antigüedad en años.
>
> **4.2 Trigger de Asignación de Cargo:** `TRIGGER` sobre `dept_manager` que al dar de alta un administrador actualice en `dept_emp` y `titles` su cargo a 'Manager'.
>
> **4.3 Estructura de Ayuda Escolar:** Diseñar la tabla `asignaciones_familiares` asociada a `employees` y un procedimiento para calcular el beneficio económico de empleados beneficiarios.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

## Ejercicio 5: Concurrencia y bloqueos (locking)

**Enunciado**
> **5.1 Simulación de Bloqueo:** En Sesión 1, incrementar sueldos en `salaries` en una transacción abierta.  
> **5.2 Retención:** En Sesión 2, modificar los mismos registros para forzar espera de bloqueo.  
> **5.3 Diagnóstico:** Consultar `performance_schema.data_locks` e `information_schema.innodb_trx`.  
> **5.4 Resolución:** Interrumpir la sesión bloqueada.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

## Ejercicio 6: Respaldo y recuperación a un punto en el tiempo (PITR)

**Enunciado**
> **6.1 Binary Logs:** Verificar activación en MySQL 9.7 (`SHOW BINARY LOGS;`).  
> **6.2 Evento:** Evento MySQL para `FLUSH LOGS;` cada 10 min.  
> **6.3 Respaldo Base:** Backup con `mysqldump --single-transaction --flush-logs --source-data=2`.  
> **6.4 Transacciones Intermedias:** 5 modificaciones identificables.  
> **6.5 Pérdida:** Simular eliminación accidental de tabla crítica.  
> **6.6 PITR:** Restaurar dump base y procesar logs con `mysqlbinlog`.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

# Bloque 2: Datos semiestructurados en MySQL 9.7 (JSON)

## Ejercicio 7: Importación de documentos JSON

**Enunciado**
> Cargar `customers.json`, `films.json` y `stores.json` mediante `mysqlsh` (`util.importJson`) en tablas con columnas de tipo nativo JSON.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

## Ejercicio 8: Consultas, JSON Schema y cruce multimodelo

**Enunciado**
> **8.1 Actualización Documental:** Modificar los documentos JSON añadiendo `"ClienteVIP": "SÍ"` a clientes con 40 o más alquileres mediante `JSON_SET()`.
>
> **8.2 Restricción de Esquema:** Definir un CHECK constraint con `JSON_SCHEMA_VALID()`. Documentar 2 inserciones válidas y 2 invalidadas.
>
> **8.3 Cruce Multimodelo:** Consulta que integre la columna JSON de clientes con la tabla relacional `countryinfo` de `world_x`, identificando el Top 10 de películas más alquiladas en América del Sur.
>
> **8.4 Exportación a JSON:** Exportar la tabla relacional `city` a un archivo JSON con formato `{"Ciudad": "Resistencia", "CodP": "ARG"}`.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

# Bloque 3: Base de datos NoSQL documental (MongoDB 8.0)

## Ejercicio 9: Autenticación e importación documental

**Enunciado**
> **9.1 Gestión de Accesos:** Crear usuario administrador en la base `admin` de MongoDB y autenticarse mediante la consola `mongosh`.
>
> **9.2 Carga Masiva:** Importar con `mongoimport` los archivos `customers.json`, `films.json` y `stores.json` en la base `LabMongoDB`.

### 9.1 Gestión de accesos

**Decisiones técnicas.** Creamos el administrador `adminG11` en la base `admin` con la autorización todavía desactivada, y recién después activamos `security.authorization: enabled` y reiniciamos el servidor. Si se activa antes, solo queda la excepción de *localhost* para crear el primer usuario. En lugar del rol `root` le asignamos los roles que el Bloque 3 necesita:

| Rol | Para qué lo necesita en el laboratorio |
| :--- | :--- |
| `userAdminAnyDatabase` | Crear y administrar usuarios y roles |
| `readWriteAnyDatabase` | Cargar y consultar `LabMongoDB` y `LabMongoDB_Restore` (Ej. 9.2, 10, 11) |
| `dbAdminAnyDatabase` | `collMod` con el validador `$jsonSchema` (Ej. 12.1) |
| `clusterMonitor` | Ver la configuración y el estado del servidor (`getCmdLineOpts`, `serverStatus`) |
| `backup` / `restore` | `mongodump` y `mongorestore` (Ej. 12.2) |

La clave nunca aparece en los comandos ni en las capturas: el script la pide con `passwordPrompt()` (o la toma de una variable de entorno).

**Código y comandos**

Configuración del servidor (`mongod.conf`), primero con la autorización comentada:
```yaml
storage:
  dbPath: /Users/lauti/lab_mongodb_g11/data
systemLog:
  destination: file
  path: /Users/lauti/lab_mongodb_g11/logs/mongod.log
  logAppend: true
net:
  port: 27017
  bindIp: 127.0.0.1
processManagement:
  fork: true
#security:
#  authorization: enabled
```

Script `ej09_1_crear_admin.js`:
```javascript
const admin = db.getSiblingDB("admin");
const clave = process.env.MONGO_ADMIN_PWD || passwordPrompt();

if (admin.getUser("adminG11")) {
  print("El usuario adminG11 ya existe: no se vuelve a crear.");
} else {
  admin.createUser({
    user: "adminG11",
    pwd: clave,
    roles: [
      { role: "userAdminAnyDatabase", db: "admin" },
      { role: "readWriteAnyDatabase", db: "admin" },
      { role: "dbAdminAnyDatabase",   db: "admin" },
      { role: "clusterMonitor",       db: "admin" },
      { role: "backup",               db: "admin" },
      { role: "restore",              db: "admin" }
    ]
  });
  print("Usuario adminG11 creado en la base admin.");
}
printjson(admin.getUser("adminG11", { showPrivileges: false }));
```

Comandos ejecutados:
```bash
mongod --config ~/lab_mongodb_g11/mongod.conf          # sin autorización
mongosh --quiet --file ej09_1_crear_admin.js           # crea adminG11
# activar el control de acceso: descomentar el bloque security en mongod.conf
#   security:
#     authorization: enabled
mongosh --quiet admin --eval 'db.shutdownServer()'
mongod --config ~/lab_mongodb_g11/mongod.conf          # reinicio con autorización
mongosh --quiet --file ej09_1_verificar_auth.js        # prueba sin y con credenciales
# forma interactiva equivalente (pide la clave):
mongosh "mongodb://127.0.0.1:27017" --authenticationDatabase admin -u adminG11
```

Script `ej09_1_verificar_auth.js`:
```javascript
print("--- 1. Conexión SIN autenticar ---");
printjson(db.runCommand({ connectionStatus: 1 }).authInfo);
try {
  db.adminCommand({ listDatabases: 1 });
} catch (e) {
  print("listDatabases sin autenticar -> " + e.codeName + ": " + e.message);
}
print("\n--- 2. Autenticación como adminG11 ---");
const ok = db.getSiblingDB("admin").auth("adminG11", process.env.MONGO_ADMIN_PWD || passwordPrompt());
print("db.auth() -> " + JSON.stringify(ok));
print("\n--- 3. connectionStatus autenticado ---");
printjson(db.runCommand({ connectionStatus: 1 }).authInfo);
print("\n--- 4. Comando administrativo permitido ---");
printjson(db.adminCommand({ listDatabases: 1, nameOnly: true }).databases.map(d => d.name));
```

**Evidencias**

*[INSERTAR CAPTURA 9.1-A: creación de adminG11 con sus 6 roles]*
```text
$ mongosh --quiet --file ej09_1_crear_admin.js
Usuario adminG11 creado en la base admin.
{
  _id: 'admin.adminG11',
  userId: UUID('17ea977b-bee6-427c-b698-690796660e6f'),
  user: 'adminG11',
  db: 'admin',
  roles: [
    {
      role: 'userAdminAnyDatabase',
      db: 'admin'
    },
    {
      role: 'readWriteAnyDatabase',
      db: 'admin'
    },
    {
      role: 'dbAdminAnyDatabase',
      db: 'admin'
    },
    {
      role: 'clusterMonitor',
      db: 'admin'
    },
    {
      role: 'backup',
      db: 'admin'
    },
    {
      role: 'restore',
      db: 'admin'
    }
  ],
  mechanisms: [
    'SCRAM-SHA-1',
    'SCRAM-SHA-256'
  ]
}
```
El usuario queda registrado en la base `admin` con los mecanismos SCRAM. El servidor guarda la clave como *hash* y no en texto plano.

*[INSERTAR CAPTURA 9.1-B: rechazo sin credenciales y autenticación de adminG11]*
```text
$ grep -A1 "^security" ~/lab_mongodb_g11/mongod.conf
security:
  authorization: enabled

$ mongosh --quiet --file ej09_1_verificar_auth.js
--- 1. Conexión SIN autenticar ---
{
  authenticatedUsers: [],
  authenticatedUserRoles: []
}
listDatabases sin autenticar -> Unauthorized: Command listDatabases requires authentication

--- 2. Autenticación como adminG11 ---
db.auth() -> {"ok":1}

--- 3. connectionStatus autenticado ---
{
  authenticatedUsers: [
    {
      user: 'adminG11',
      db: 'admin'
    }
  ],
  authenticatedUserRoles: [
    {
      role: 'backup',
      db: 'admin'
    },
    {
      role: 'clusterMonitor',
      db: 'admin'
    },
    {
      role: 'dbAdminAnyDatabase',
      db: 'admin'
    },
    {
      role: 'readWriteAnyDatabase',
      db: 'admin'
    },
    {
      role: 'restore',
      db: 'admin'
    },
    {
      role: 'userAdminAnyDatabase',
      db: 'admin'
    }
  ]
}

--- 4. Comando administrativo permitido ---
[
  'admin',
  'config',
  'local'
]
```
Con `authorization: enabled`, una conexión anónima ya no puede listar bases (`Unauthorized`). Después de `db.auth()` contra `admin`, la sesión queda identificada como `adminG11` con sus seis roles, y el mismo comando se ejecuta.

### 9.2 Carga masiva

**Decisiones técnicas.**
- Los tres archivos son **JSON Lines** (un documento por línea), por eso no usamos `--jsonArray`.
- Importamos a colecciones con los nombres en castellano que usa la guía (`clientes`, `peliculas`, `tiendas`), porque el Ejercicio 11 y el 12.1 se refieren a ellas así.
- Usamos `--drop` para que la carga sea repetible.
- La clave de `adminG11` se lee de un archivo de opciones de las *Database Tools* (`--config`, con permisos `600`), así no queda en la línea de comandos ni en el historial.

**Código y comandos**

Script `ej09_2_importar.sh`:
```bash
#!/bin/bash
set -euo pipefail
DATOS="${1:?Indicar la carpeta con los archivos JSON}"
CONFIG="${MONGO_TOOLS_CONFIG:-$HOME/lab_mongodb_g11/tools_admin.yaml}"   # YAML "password: ..." (chmod 600)
DB="LabMongoDB"

importar() {   # $1 = archivo, $2 = colección
  echo "=== $1 -> $DB.$2"
  mongoimport --host 127.0.0.1:27017 \
    --username adminG11 --authenticationDatabase admin --config "$CONFIG" \
    --db "$DB" --collection "$2" --drop \
    --file "$DATOS/$1"
  echo
}

time {
  importar customers.json clientes
  importar films.json     peliculas
  importar stores.json    tiendas
}
```

Script de verificación `ej09_2_verificar_carga.js` (fragmento principal):
```javascript
db = db.getSiblingDB("LabMongoDB");   // en un script, "use LabMongoDB" no tiene efecto
["clientes", "peliculas", "tiendas"].forEach(c =>
  print(c.padEnd(10) + db.getCollection(c).countDocuments()));
db.clientes.aggregate([
  { $project: { n: { $size: "$Rentals" } } },
  { $group: { _id: null, clientes: { $sum: 1 }, alquileres: { $sum: "$n" },
              min: { $min: "$n" }, max: { $max: "$n" } } },
  { $project: { _id: 0 } }
]);
db.tiendas.find({}, { _id: 1, City: 1, Country: 1,
  items_inventario: { $size: "$Inventory" }, empleados: { $size: "$Staff" } });
```

**Evidencias**

*[INSERTAR CAPTURA 9.2-A: salida de mongoimport para las tres colecciones]*
```text
$ ./ej09_2_importar.sh ../archivos_lab/zakila-json/zakila-json
=== customers.json -> LabMongoDB.clientes
2026-11-17T18:41:59.146-0300	connected to: mongodb://127.0.0.1:27017/
2026-11-17T18:41:59.147-0300	dropping: `LabMongoDB.clientes`
2026-11-17T18:41:59.533-0300	599 document(s) imported successfully. 0 document(s) failed to import.

=== films.json -> LabMongoDB.peliculas
2026-11-17T18:41:59.585-0300	connected to: mongodb://127.0.0.1:27017/
2026-11-17T18:41:59.586-0300	dropping: `LabMongoDB.peliculas`
2026-11-17T18:41:59.690-0300	1000 document(s) imported successfully. 0 document(s) failed to import.

=== stores.json -> LabMongoDB.tiendas
2026-11-17T18:41:59.738-0300	connected to: mongodb://127.0.0.1:27017/
2026-11-17T18:41:59.739-0300	dropping: `LabMongoDB.tiendas`
2026-11-17T18:41:59.799-0300	2 document(s) imported successfully. 0 document(s) failed to import.


real	0m0.875s
user	0m1.152s
sys	0m0.223s
```
Se importaron los 1601 documentos sin fallas en 0,88 s. El usuario se autenticó con `adminG11` sin escribir la clave en el comando.

*[INSERTAR CAPTURA 9.2-B: verificación de la carga en LabMongoDB]*
```text
$ mongosh "mongodb://127.0.0.1:27017" --quiet --file ej09_2_verificar_carga.js
Base: LabMongoDB
Colecciones: ["clientes","peliculas","tiendas"]

--- Documentos por colección (esperado: 599 / 1000 / 2) ---
clientes  599
peliculas 1000
tiendas   2

--- Arreglos anidados (alquileres por cliente, inventario por tienda) ---
{
  clientes: 599,
  alquileres: 16044,
  min: 12,
  max: 46
}
[
  {
    _id: 1,
    City: 'Lethbridge',
    Country: 'Canada',
    items_inventario: 2270,
    empleados: 1
  },
  {
    _id: 2,
    City: 'Woodridge',
    Country: 'Australia',
    items_inventario: 2311,
    empleados: 1
  }
]

--- Muestra: un cliente (primer alquiler) y una película ---
{
  _id: 1,
  City: 'Sasebo',
  Country: 'Japan',
  'First Name': 'MARY',
  'Last Name': 'SMITH',
  Rentals: [
    {
      'Film Title': 'MUSKETEERS WAIT',
      Payments: [
        {
          Amount: 5.989999771118164,
          'Payment Date': '2005-06-15 00:54:12.0',
          'Payment Id': 3
        }
      ],
      'Rental Date': '2005-06-15 00:54:12.0',
      'Return Date': '2005-06-23 02:42:12.0',
      filmId: 611,
      rentalId: 1185,
      staffId: 2
    }
  ]
}
{
  _id: 1,
  Category: 'Documentary',
  Description: 'A Epic Drama of a Feminist And a Mad Scientist who must Battle a Teacher in The Canadian Rockies',
  Length: '86',
  Rating: 'PG',
  'Rental Duration': '6',
  'Replacement Cost': '20.99',
  'Special Features': 'Deleted Scenes,Behind the Scenes',
  Title: 'ACADEMY DINOSAUR'
}
```
Los recuentos coinciden con las líneas de cada archivo (599 / 1000 / 2). Los arreglos anidados también llegaron completos: 16.044 alquileres dentro de los clientes (entre 12 y 46 por cliente) y 2270 / 2311 ítems de inventario por tienda. Este es el insumo del modelado del Ejercicio 10.

**Nota aclaratoria.**
- **Entorno:** la VM del grupo no fue alcanzable desde la red del laboratorio (la PC y la VM quedaron en subredes distintas). Por eso el Bloque 3 se resolvió en una instancia local de **MongoDB 7.0.14** (macOS 13.7.8, `mongosh` 2.4.0, `mongoimport` 100.20.0). MongoDB 8.0 Community no está soportado en esa versión de macOS según la matriz oficial de plataformas. Los comandos usados (`createUser`, `authorization`, `mongoimport`) tienen la misma sintaxis en la serie 8.0.
- **Archivos:** los datos están en formato JSON Lines y tienen nombres de campo con espacios (`"First Name"`, `"Film Title"`). En las consultas se acceden entre comillas.
- **Tipos de datos:** fechas, `Length` y `Replacement Cost` se importan como texto, no como fecha o número. Esto se tiene en cuenta en el `$jsonSchema` del Ejercicio 12.1.

---

## Ejercicio 10: Modelado documental e importación de apoyo

**Enunciado**
> **10.1 Diseño de Esquema:** Modelo documental justificando anidamiento (*embedding*) vs referencias (*referencing*).
>
> **10.2 Colecciones Auxiliares:** Importar JSONs de ciudades y paises a `LabMongoDB`.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

## Ejercicio 11: Pipeline de agregación complejo

**Enunciado**
> Aggregation Pipeline (`$lookup`, `$unwind`, `$match`, `$group`, `$sort`, `$limit`) para el Top 10 de películas más alquiladas en América del Sur vinculando clientes, peliculas y paises.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

## Ejercicio 12: Validación de esquemas y backup cloud

**Enunciado**
> **12.1 Esquema de Validación:** Regla de validación `$jsonSchema` sobre tiendas (2 inserciones válidas, 2 rechazadas).
>
> **12.2 Respaldo Cloud:** Respaldo con `mongodump` y restauración con `mongorestore` en MongoDB Atlas o base local `LabMongoDB_Restore`.

**Código y comandos**  
*[PENDIENTE]*

**Evidencias**  
*[PENDIENTE]*

---

# Bloque 4: Competencias CGSPA y transparencia tecnológica

## 4.1 Matriz de distribución de roles y coevaluación (Capacidad 5.1)

**Enunciado**
> Completar la matriz indicando qué integrante lideró o colaboró en cada función clave durante las 4 horas de trabajo. Incluir un breve texto (máx. 5 líneas) explicando cómo el grupo resolvió eventuales desacuerdos técnicos.

| Función / dimensión técnica | Integrante que lanza / lidera | Integrante colaborador | Evidencia / entregable |
| :--- | :--- | :--- | :--- |
| Navegación de fuentes oficiales | *[COMPLETAR]* | *[COMPLETAR]* | Comandos y sintaxis verificada |
| Operación técnica en VM Ubuntu | *[COMPLETAR]* | *[COMPLETAR]* | Capturas de terminal y scripts SQL/Bash |
| Verificación y análisis de métricas | *[COMPLETAR]* | *[COMPLETAR]* | Planes `EXPLAIN` y logs de auditoría |
| Documentación y redacción final | *[COMPLETAR]* | *[COMPLETAR]* | Consolidación del PDF `Grupo11.pdf` |

**Resolución de desacuerdos técnicos (máx. 5 líneas):**  
*[PENDIENTE]*

---

## 4.2 Notas de diagnóstico para el equipo de Operaciones / DBA (Capacidad 6.1)

**Enunciado**
> Redactar en formato de nota técnica profesional la incidencia producida en el Ejercicio 5 (Bloqueos) y en el Ejercicio 6 (Restauración PITR): a) Causa raíz, b) Solución técnica aplicada, c) Recomendaciones de prevención.

### Nota 1: Incidencia de bloqueo (Ejercicio 5)
- **a) Causa raíz:** *[PENDIENTE]*
- **b) Solución técnica aplicada:** *[PENDIENTE]*
- **c) Recomendaciones de prevención:** *[PENDIENTE]*

### Nota 2: Restauración PITR (Ejercicio 6)
- **a) Causa raíz:** *[PENDIENTE]*
- **b) Solución técnica aplicada:** *[PENDIENTE]*
- **c) Recomendaciones de prevención:** *[PENDIENTE]*

---

## 4.3 Declaración de transparencia de herramientas de apoyo e IA

**Enunciado**
> - **Tareas en las que se utilizó asistencia tecnológica:** (ej. depuración de sintaxis SQL, optimización de comandos bash, estructuración del informe).
> - **Caso de Verificación y Corrección:** Describa al menos un caso donde una sugerencia técnica o comando requirió corrección respecto a la versión oficial del motor, explicando cómo se detectó y validó con la documentación.

**Tareas con asistencia tecnológica:**
- Estructuración del informe y de los scripts del Bloque 3 (Ejercicio 9).
- *[COMPLETAR con el resto de los ejercicios]*

**Caso de verificación y corrección:**  
*[PENDIENTE]*
