# Bitácora Unidad 10 - SGBD · Actividad 1 (De la VM a la nube: operar un SGBD como servicio)

**Grupo:** 11  
**Integrantes:** Aguirre Egea, Emiliano · Ghione, Lucas · Pagno, Agustin · Sandoval, Lautaro Emanuel  
**Archivos de comandos:** `consigna3.js` (CRUD) · `consigna4_accesos.js` (accesos) · `consigna5_backup.txt` (respaldo y recuperación). Ninguno contiene contraseñas.

---

## 1. Identificar el entorno

- **Motor seleccionado:** MongoDB
- **Versión del motor:** 8.0.37
- **Proveedor cloud:** AWS
- **Servicio DBaaS / Plan utilizado:** MongoDB Atlas, tier `M0` Sandbox (gratuito: 512 MB de almacenamiento, RAM y vCPU compartidas, máximo 500 conexiones), sin tarjeta registrada
- **Región del servicio:** São Paulo (`sa-east-1`)

**Por qué elegimos MongoDB Atlas.** Es el motor que usamos en las Unidades 7 y 8 sobre la VM, así que podemos comparar las mismas operaciones (CRUD, usuarios y respaldo) en los dos entornos. Además, Atlas es el servicio del propio fabricante, y el plan Free no pide tarjeta y permite demostrar los cuatro mínimos de la consigna.

*[CAPTURA: vista general del cluster `SGBD-U10-Grupo11` (versión 8.0.37, AWS São Paulo, tier Free, 3 nodos)]*

---

## 2. Provisionar y conectar

Dentro del proyecto `Project 0` creamos el cluster `SGBD-U10-Grupo11` con el plan Free. No instalamos nada: elegimos plan, proveedor y región, y en unos minutos Atlas entregó un *replica set* de **3 nodos** (un primario y dos secundarios, visibles en la vista general). No hay acceso al sistema operativo de esos nodos.

**Endpoint.** Atlas publica un único nombre SRV: `mongodb+srv://sgbd-u10-grupo11.<id>.mongodb.net/`. El cliente resuelve con DNS los tres nodos y se conecta siempre con TLS. Nunca escribimos una IP ni un puerto.

**Límites del plan Free** (documentación del proveedor, ver Fuentes):

| Límite | Valor |
| :--- | :--- |
| Almacenamiento | 0,5 GB (datos sin comprimir más índices) |
| Operaciones | 100 lecturas y escrituras por segundo |
| Conexiones | 500 como máximo |
| Transferencia | 10 GB de entrada y 10 GB de salida cada 7 días |
| Clusters | Uno Free por proyecto. Siempre con 3 nodos; no se elige memoria, disco ni versión |
| Inactividad | Se pausa solo tras 30 días sin conexiones |

**Conexión autenticada.** Antes de conectarnos tuvimos que hacer dos cosas en la plataforma: agregar la IP pública de nuestra VM a **Network Access** y crear el usuario `admin_grupo11` en **Database Access**. Después conectamos con `mongosh` desde la VM Ubuntu. La contraseña se ingresa oculta (`Enter password: ********`) y la cadena se muestra como `<credentials>`.

```bash
mongosh "mongodb+srv://sgbd-u10-grupo11.<id>.mongodb.net/" --apiVersion 1 --username admin_grupo11
```

**Resultado:** conexión establecida con MongoDB 8.0.37 (API versión 1).

*[CAPTURA: conexión de mongosh desde la VM]*

---

## 3. CRUD

Trabajamos sobre la base `practicaU10`, colección `productos`. Los comandos están en `consigna3.js` y son los mismos que usaríamos en la VM. Lo único que cambia es la cadena de conexión.

| Operación | Comando | Resultado |
| :--- | :--- | :--- |
| **Estructura y alta** | `db.productos.insertMany([...])` con 5 productos (`PROD-01` a `PROD-05`); la base y la colección se crean con la primera inserción | `acknowledged: true` y 5 `insertedIds` |
| **Lectura** | `db.productos.find({ disponible: true, precio: { $gte: 50000 } })` | 2 productos: `PROD-01` (850.000) y `PROD-03` (210.000). `PROD-04` no aparece porque en ese momento estaba no disponible |
| **Actualización** | `db.productos.updateOne({ codigo: "PROD-04" }, { $set: { stock: 12, disponible: true, precio: 68000 } })` | `matchedCount: 1, modifiedCount: 1`. `findOne` muestra el teclado con precio 68.000, stock 12 y disponible |
| **Eliminación** | `db.productos.deleteOne({ codigo: "PROD-05" })` | `deletedCount: 1`. `countDocuments()` pasa de 5 a **4** |

*[CAPTURA: base `practicaU10` en la consola (Data Explorer)]*  
*[CAPTURA: insertMany de 5 productos]*  
*[CAPTURA: find de disponibles con precio >= 50.000]*  
*[CAPTURA: updateOne y findOne de PROD-04]*  
*[CAPTURA: deleteOne con `deletedCount: 1` y `countDocuments()` → 4]*

---

## 4. Accesos

### 4.1 Identidad restringida
Creamos el usuario `lector_g11` desde la consola (**Database Access**) con un **privilegio específico**: rol `read` sobre la colección `practicaU10.productos`. No puede escribir, ni leer otras colecciones o bases. Usuarios de base de datos del proyecto:

| Usuario | Autenticación | Rol | Alcance |
| :--- | :--- | :--- | :--- |
| `admin_grupo11` | SCRAM | `atlasAdmin@admin` | Todo el cluster |
| `lector_g11` | SCRAM | `read@practicaU10.productos` | Solo la colección `practicaU10.productos` |

*[CAPTURA: Database Access con los dos usuarios y sus roles]*

Luego nos conectamos con `lector_g11` y ejecutamos las pruebas de `consigna4_accesos.js`:

| Prueba (como `lector_g11`) | Esperado | Obtenido |
| :--- | :---: | :---: |
| `db.productos.find()` | Permitida | **Permitida**: devuelve los 4 productos |
| `db.productos.insertOne({ codigo: "PROD-99", ... })` | Rechazada | **Rechazada**: `MongoServerError[AtlasError]: user is not allowed to do action [insert] on [practicaU10.productos]` |

*[CAPTURA: operación válida (find)]*  
*[CAPTURA: operación inválida (insertOne rechazado)]*

### 4.2 Permisos de la plataforma y permisos del motor
En un entorno DBaaS como MongoDB Atlas, la seguridad se divide en dos planos independientes:

| | Permisos de la plataforma (Atlas) | Permisos del motor (Database Access) |
| :--- | :--- | :--- |
| **¿Qué administra?** | La infraestructura y el proyecto en la consola web o la API: crear y borrar clusters, configurar Network Access, crear usuarios de base de datos, facturación, invitar colaboradores | El acceso a los datos y a las operaciones del motor: consultas CRUD, índices y colecciones |
| **Identidades y roles** | Cuentas de MongoDB Cloud con roles de organización o de proyecto (*Organization Owner*, *Project Owner*, *Project Read Only*) | Usuarios de base de datos autenticados con SCRAM y roles del motor (`atlasAdmin`, `readWrite`, `read`) |
| **Alcance** | Una cuenta de la consola no lee documentos por sí misma; y un usuario de base de datos no puede modificar la configuración del cluster | Un usuario de base de datos solo se conecta con un driver o `mongosh`, desde una IP habilitada, y opera sobre los recursos asignados |

**Diferencia clave con la VM.** En la Unidad 8 creábamos usuarios desde el motor con `db.createUser()`. En Atlas lo intentamos con `admin_grupo11`, que tiene el rol `atlasAdmin`, y el servidor lo **rechazó** *[completar: mensaje de la captura]*. Toda la gestión de identidades está centralizada en la plataforma: el motor **hace cumplir** los permisos, pero ya no **los administra**. El plan Free sí permite RBAC por base de datos (privilegios específicos), así que no hizo falta un control alternativo.

*[CAPTURA: db.createUser() rechazado para admin_grupo11]*

---

## 5. Backup

### 5.1 Protección administrada disponible
Sobre el plan Free comprobamos lo siguiente:
- **Replicación.** Los 3 nodos dan alta disponibilidad: si cae uno, otro pasa a primario. **No es un respaldo:** el `deleteOne` de la consigna 3 se replicó a los tres nodos.
- **Snapshots administrados.** No están incluidos en el plan Free. La pestaña Backup solo ofrece dos opciones pagas: **Purchase Daily Backups** (una suscripción diaria que exige registrar un medio de pago) y **Upgrade cluster for continuous backups** (pasar a un plan pago). La consigna prohíbe registrar tarjetas, así que **no activamos ninguna**.

*[CAPTURA: pestaña Backup del cluster, con las opciones pagas]*

### 5.2 Respaldo lógico
Como el servicio no incluye respaldo administrado, generamos uno lógico con `mongodump` desde la VM contra el endpoint de Atlas (comandos en `consigna5_backup.txt`). La contraseña la pide la herramienta.

```bash
mongodump --uri "mongodb+srv://sgbd-u10-grupo11.<id>.mongodb.net/" --username admin_grupo11 --db practicaU10 --out ~/backup_u10
```

| Verificación del respaldo | Resultado |
| :--- | :--- |
| Archivos generados | `productos.bson`, `productos.metadata.json` y `prelude.json` |
| Documentos dentro del `.bson` (`bsondump ... \| wc -l`) | *[completar: 4]* |

*[CAPTURA: mongodump y archivos generados]*

### 5.3 Recuperación en un entorno de prueba
Restauramos el respaldo en el **mismo cluster de Atlas**, en otra base (`practicaU10_restore`). Así la prueba de recuperación ocurre en el cloud y no toca la base original:

```bash
mongorestore --uri "mongodb+srv://sgbd-u10-grupo11.<id>.mongodb.net/" --username admin_grupo11 \
  --nsFrom 'practicaU10.*' --nsTo 'practicaU10_restore.*' ~/backup_u10
```

Después ejecutamos la misma consulta en las dos bases:

| Comparación | Base original (`practicaU10`) | Base restaurada (`practicaU10_restore`) |
| :--- | :---: | :---: |
| Productos | *[completar: 4]* | *[completar: 4]* |
| `_id`, código, precio y stock | `PROD-01` a `PROD-04` | *[completar: idénticos]* |
| `PROD-04` | precio 68.000, stock 12 | *[completar]* |
| `PROD-05` | no existe | *[completar: no existe]* |

La recuperación conserva la actualización de la consigna 3 y no incluye el producto eliminado. Además, los **`_id` son los mismos**: es una copia fiel de los datos, no una nueva carga.

**Alcance.** El respaldo lógico es una foto del momento en que se ejecuta. No incluye los usuarios (viven en la plataforma), y en el plan Free no se puede usar `--oplog` para una copia consistente mientras hay escrituras.

*[CAPTURA: mongorestore hacia Atlas]*  
*[CAPTURA: consulta en practicaU10 y en practicaU10_restore, con resultados idénticos (opcional: las dos bases en Data Explorer)]*

---

## 6. Comparar: matriz VM vs. DBaaS

| Aspecto | VM — Administración tradicional | DBaaS — Servicio Cloud (MongoDB Atlas M0) | ¿Quién administra en DBaaS? | Evidencia / Observaciones |
| :--- | :--- | :--- | :--- | :--- |
| **Instalación y SO** | Se aprovisiona una VM con Ubuntu Server, se agregan los repositorios oficiales, se instala `mongodb-org`, se configura `systemd` y se aplican a mano las actualizaciones de seguridad del SO y del motor | Despliegue automatizado del cluster en minutos desde la consola. No hay acceso SSH, terminal del host ni visibilidad del sistema operativo. La versión la fija y actualiza el proveedor | **Proveedor**: aprovisiona la infraestructura, instala el motor, aplica parches y gestiona la disponibilidad de los nodos | Cluster `SGBD-U10-Grupo11` en AWS sin acceso al SO ni a `mongod.conf` |
| **Conectividad** | Se edita `mongod.conf` (`net.bindIp`), se habilita el puerto 27017 en el firewall (`ufw`/`iptables`) y se generan y renuevan los certificados TLS a mano | Endpoint SRV (`mongodb+srv://...`) con TLS obligatorio y un firewall gestionado con lista de IP permitidas (Network Access) | **Compartida**: el proveedor gestiona DNS, puertos y certificados; el equipo decide qué IP están autorizadas | Conexión desde `mongosh` en la VM Ubuntu tras habilitar su IP pública |
| **CRUD** | Comandos MQL estándar ejecutados con `mongosh` | Exactamente los mismos comandos (`insertMany`, `find`, `updateOne`, `deleteOne`), con compatibilidad total | **Equipo**: define el diseño documental, crea índices y ejecuta las operaciones sobre los datos | `consigna3.js` sobre `practicaU10.productos` (5 altas, consulta, actualización y baja) |
| **Permisos / RBAC** | Se activa `security.authorization` en `mongod.conf` y se crean usuarios y roles desde el motor con `db.createUser()` y `db.createRole()` | Separación entre acceso a la plataforma (roles de organización y proyecto) y usuarios de datos (Database Access, SCRAM). `db.createUser()` está bloqueado: los usuarios se crean solo desde la consola, con roles incorporados o privilegios específicos por base | **Compartida**: el proveedor da la autenticación y los mecanismos de roles; el equipo crea los usuarios y aplica mínimo privilegio | `lector_g11` con `read@practicaU10.productos`: lectura aprobada, `insertOne` rechazado. `createUser` rechazado para `atlasAdmin` |
| **Backup / Restore** | El DBA programa `mongodump` (o snapshots de disco de la VM), guarda los archivos y prueba la recuperación | Los planes pagos ofrecen snapshots administrados y restauración a un momento exacto. En el plan Free no hay snapshots incluidos (solo como adicional pago con tarjeta), así que el respaldo es `mongodump` desde fuera | **Equipo** en el plan Free; **Compartida** en planes pagos | Pestaña Backup con opciones pagas; `mongodump` desde Atlas y `mongorestore` en `practicaU10_restore` con datos idénticos |
| **Monitoreo** | Revisión de logs (`/var/log/mongodb/mongod.log`), `db.serverStatus()` o agentes externos (Prometheus/Grafana) | Panel *Metrics* integrado con gráficos de conexiones, operaciones, red y tamaño lógico. En el plan Free no se pueden descargar logs ni usar el panel en tiempo real | **Compartida**: el proveedor recolecta y expone las métricas; el equipo supervisa rendimiento y consumo de cuotas | Picos de operaciones y conexiones en *Metrics* durante las pruebas CRUD |
| **Costos** | Costo fijo por la CPU, RAM y disco de la VM (estén o no en uso), más horas de mantenimiento y parches | Gratuito (sin tarjeta) en `M0`, con cuotas estrictas: 512 MB, RAM y vCPU compartidas, 500 conexiones simultáneas | **Proveedor** fija precios y cuotas; el **equipo** controla que el volumen no supere los 512 MB | Vista general del cluster `M0` con el límite de 512 MB |

*[CAPTURA: pestaña Metrics del cluster durante las pruebas]*

---

## 7. Conclusiones

**Responsabilidades delegadas.** El proveedor asumió por completo el aprovisionamiento de la infraestructura, la instalación y actualización del sistema operativo y del binario de MongoDB, el *replica set* de 3 nodos, el cifrado TLS en tránsito y la resolución DNS del cluster (`mongodb+srv`).

**Responsabilidades que permanecen.** El equipo sigue a cargo del modelado de las colecciones y de la integridad de las operaciones CRUD. También de la seguridad bajo el principio de mínimo privilegio (usuarios en Database Access y filtrado en Network Access) y del **respaldo y su prueba de recuperación**, que en el plan Free hicimos nosotros con `mongodump` y `mongorestore`.

**Limitaciones.** El tier gratuito `M0` impone restricciones concretas:
- Almacenamiento máximo de 512 MB y cómputo compartido, sin garantías de rendimiento.
- Sin snapshots administrados: solo como adicional pago con tarjeta.
- Bloqueo de `db.createUser()` y de otros comandos administrativos desde `mongosh`: las identidades solo se gestionan desde la consola.
- Sin descarga de logs ni panel en tiempo real.

**Diferencias operativas.**
- **CRUD:** el trabajo es transparente respecto de una VM; las consultas sobre `practicaU10.productos` no requieren cambios de sintaxis.
- **Permisos:** el flujo deja de ser imperativo por consola (`db.createUser()`) y pasa a ser declarativo desde la interfaz web de Atlas.
- **Respaldos:** no hay acceso al sistema de archivos del servidor ni snapshots incluidos en `M0`. El respaldo pasa a ser lógico (`mongodump` contra un endpoint en internet), y la restauración hay que probarla en un entorno propio.

**Reflexión final.** El modelo DBaaS no elimina la necesidad de administrar bases de datos, sino que transforma el rol del DBA. Al automatizar las tareas repetitivas de infraestructura (parches del SO, discos, réplicas y certificados), el administrador desplaza su esfuerzo hacia decisiones de mayor impacto: arquitectura de datos, gobierno de accesos y de la red, continuidad (respaldo **y** prueba de recuperación), optimización de consultas e índices, y control de límites y costos en la nube.

---

## Fuentes

- MongoDB Atlas, *Atlas Free Cluster Limits*: https://www.mongodb.com/docs/atlas/reference/free-shared-limitations/
- MongoDB Atlas, *Free Cluster Backups*: https://www.mongodb.com/docs/atlas/backup/cloud-backup/free-cluster-backup/
- MongoDB Atlas, *Unsupported Commands*: https://www.mongodb.com/docs/atlas/unsupported-commands/
