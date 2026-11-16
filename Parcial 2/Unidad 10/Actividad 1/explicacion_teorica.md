# Explicación Teórica: U10 - Actividad 1 (De la VM a la nube)
**Grupo:** G11 · **Motor:** MongoDB · **Servicio:** MongoDB Atlas, plan Free (`M0`)

> Este documento explica los conceptos detrás de la actividad, pensado para quien opera una base como servicio por primera vez. Al final hay preguntas de defensa con respuesta y un glosario.

---

## 1. ¿Qué es DBaaS?

**DBaaS** (*Database as a Service*, base de datos como servicio) es un modelo en el que el proveedor entrega una base de datos **ya funcionando**. El cliente no instala el motor ni administra el servidor: pide un servicio con ciertas características (motor, tamaño, región) y recibe una dirección para conectarse.

Comparado con lo que hicimos en la VM:

| En la VM (Unidad 8) | En DBaaS (esta unidad) |
| :--- | :--- |
| Instalamos Ubuntu, después `mongod` con `apt` | Elegimos "Free, AWS, São Paulo" en un formulario y Atlas entregó MongoDB 8.0.37 |
| Editamos `mongod.conf` (puerto, `bindIp`, autenticación, TLS) | La configuración ya viene hecha y no se puede tocar |
| Un solo servidor: si se cae, la base se cae | Un *replica set* de 3 nodos con conmutación automática |
| Nosotros aplicábamos los parches | El proveedor actualiza el motor cuando quiere (en el plan Free ni siquiera se elige la versión) |

DBaaS es un caso de **PaaS** (plataforma como servicio). En **IaaS** (alquilar una VM en la nube) seguiríamos administrando el sistema operativo y el motor; en DBaaS solo administramos lo que está **dentro** de la base.

---

## 2. El modelo de responsabilidad compartida

En la nube, la pregunta clave no es "¿quién administra?" sino **"¿quién administra qué?"**. Los proveedores lo llaman **modelo de responsabilidad compartida**:

| Capa | VM propia | IaaS (VM en la nube) | DBaaS |
| :--- | :---: | :---: | :---: |
| Hardware, red física, centro de datos | Equipo | Proveedor | Proveedor |
| Sistema operativo y parches | Equipo | Equipo | Proveedor |
| Instalación, versión y configuración del motor | Equipo | Equipo | Proveedor |
| Alta disponibilidad (réplicas, conmutación) | Equipo | Equipo | Proveedor |
| Quién se conecta (red) y con qué identidad | Equipo | Equipo | **Compartida** |
| Modelo de datos, índices, consultas | Equipo | Equipo | **Equipo** |
| Respaldo y **verificación de la recuperación** | Equipo | Equipo | **Compartida** (o del equipo, en el plan Free) |
| Datos y su clasificación (qué es sensible) | Equipo | Equipo | **Equipo** |

La responsabilidad sobre **los datos** nunca se delega. Si un usuario con permisos de más borra una colección, el proveedor replica ese borrado a los tres nodos sin dudarlo: el servicio funcionó correctamente, el error fue nuestro.

---

## 3. Cómo se conecta un cliente a Atlas

### 3.1. La cadena SRV
Atlas entrega una cadena como `mongodb+srv://clusterg11.ab1cd.mongodb.net/`. El prefijo `+srv` significa que el cliente **consulta al DNS** qué servidores forman el cluster (registros SRV) y qué opciones usar (registro TXT, por ejemplo `authSource=admin` y el nombre del *replica set*). Por eso nunca escribimos IP ni puertos: si el proveedor cambia un nodo, actualiza el DNS y los clientes siguen funcionando.

### 3.2. Tres controles antes de llegar a los datos
1. **Red:** la IP de origen tiene que estar en la **lista de acceso** (*Network Access*). Si no está, la conexión ni siquiera llega al motor (se ve como un *timeout*).
2. **Cifrado:** TLS es obligatorio. En la VM lo configuramos a mano en la Unidad 8; acá viene incluido.
3. **Autenticación:** usuario y clave con **SCRAM** (el mecanismo de desafío y respuesta de MongoDB: la clave nunca viaja en texto plano).

Recién después actúa la **autorización**: qué puede hacer ese usuario.

---

## 4. Las dos capas de permisos

Es el punto más importante de la consigna 4.

### 4.1. Permisos de la plataforma
Controlan **la consola de Atlas**: quién puede crear o borrar clusters, cambiar la red, crear usuarios de base de datos o ver la facturación. Se asignan a **personas** (cuentas de Atlas) mediante roles de organización y de proyecto, por ejemplo:

| Rol | Puede |
| :--- | :--- |
| *Organization Owner* | Todo, incluida la facturación |
| *Project Owner* | Administrar el proyecto: clusters, red, usuarios de base de datos |
| *Project Read Only* | Ver la configuración y las métricas, sin cambiar nada |

La **lista de IP** también es un control de plataforma: decide desde dónde se puede llegar al motor.

### 4.2. Permisos del motor
Controlan **las operaciones sobre los datos**. Se asignan a **usuarios de base de datos** (como `admin_grupo11` y `lector_g11`) y los hace cumplir el propio `mongod`, igual que en la VM: `read` permite `find`; un `insert` sin el privilegio `insert` se rechaza con un error de autorización.

### 4.3. Lo que cambia en Atlas
En la VM, el administrador del motor creaba usuarios con `db.createUser()`. En Atlas ese comando está **bloqueado**, aunque lo ejecute un usuario con rol de administrador (lo comprobamos con `admin_grupo11`, que tiene `atlasAdmin`: bitácora §4.2). Los usuarios del motor se crean **desde la plataforma**. El motor sigue **haciendo cumplir** los permisos, pero ya no **los administra**. Es la evidencia más clara de que la gestión de identidades pasó del DBA a la capa de plataforma.

| Pregunta | Respuesta |
| :--- | :--- |
| ¿Quién verifica que `lector_g11` no pueda insertar? | El motor (`mongod`) |
| ¿Dónde se creó `lector_g11`? | En la plataforma (*Database Access*) |
| ¿Un *Project Read Only* puede leer los datos de `practicaU10.productos`? | No por ese rol: ve la consola, pero para leer datos necesita un usuario de base de datos |
| ¿`lector_g11` puede entrar a la consola web? | No: es una identidad del motor, no una cuenta de Atlas |

---

## 5. Respaldo y recuperación en DBaaS

### 5.1. La replicación no es un respaldo
Los 3 nodos tienen **la misma información** en todo momento. Eso protege contra la caída de un servidor (**disponibilidad**), pero no contra un error humano: el `deleteOne` de `PROD-05` se replicó a los tres nodos en milisegundos. Un respaldo, en cambio, es una **copia en otro momento y otro lugar**, que permite volver atrás.

### 5.2. Respaldo administrado (snapshots)
En los planes pagos, Atlas toma **snapshots** (copias físicas del disco) automáticamente y permite restaurarlos con un clic, incluso a un momento exacto. Para el plan Free existe una suscripción opcional y paga: un snapshot diario, conserva los últimos 4 y exige registrar un medio de pago. La consigna prohíbe tarjetas, así que en nuestro caso el respaldo administrado **no está disponible**.

### 5.3. Respaldo lógico con `mongodump`
`mongodump` lee los documentos a través del motor y los guarda en archivos **BSON** (los datos) y **JSON** (los metadatos de la colección, como sus índices). Ventajas:
- Funciona en cualquier plan y en cualquier proveedor: **es portable**. Lo usamos para restaurar en otra base del mismo cluster, y serviría igual para llevar los datos a otro proveedor o a una VM.
- Es el mismo comando que usamos en la VM.

Limitaciones:
- Es una foto del momento: no permite volver a un instante intermedio.
- En el plan Free no se puede usar `--oplog` (la opción que da una copia consistente mientras hay escrituras).
- No incluye los usuarios, porque en Atlas viven en la plataforma.

### 5.4. Un respaldo sin restauración probada no es un respaldo
La consigna lo dice explícitamente: una captura de "backup activado" no prueba nada. Lo que vale es **restaurar y comparar**. Por eso:
1. Generamos el respaldo y verificamos qué tiene adentro (4 documentos en `productos.bson`).
2. Lo restauramos en un **entorno de prueba** separado: otra base del mismo cluster, `practicaU10_restore` (nunca sobre la base original).
3. Comparamos las dos bases con la misma consulta: mismos 4 productos, con los mismos `_id`, precios y stock.

Dos conceptos para la defensa:
- **RPO** (*Recovery Point Objective*): cuántos datos se pueden perder como máximo. Con un `mongodump` diario, hasta 24 horas.
- **RTO** (*Recovery Time Objective*): cuánto tarda la recuperación. Para restaurar 4 documentos, segundos; para 0,5 GB, minutos.

---

## 6. Monitoreo en el plan Free

En la VM teníamos todo: los logs del motor en disco, `db.serverStatus()`, y las herramientas del sistema operativo (`top`, `df`). En Atlas Free:
- El panel de **Metrics** muestra 4 indicadores: conexiones, operaciones, tráfico de red y tamaño lógico.
- **No** se pueden descargar logs, no hay panel en tiempo real ni asesor de rendimiento, y no hay auditoría ni historial de accesos.
- Desde `mongosh` se puede consultar el tamaño de la base (`db.stats()`) y comparar contra la cuota.

Es un caso concreto de responsabilidad compartida: el proveedor **recolecta** las métricas, pero el equipo tiene que **interpretarlas** (por ejemplo, darse cuenta de que se acerca al límite de 0,5 GB).

---

## 7. Costos y límites del plan Free

| Recurso | VM | Atlas Free |
| :--- | :--- | :--- |
| Cómputo | CPU y RAM de la VM, encendida o no | Compartido con otros clientes, sin costo |
| Almacenamiento | El disco de la VM | 0,5 GB (datos más índices) |
| Rendimiento | El que dé la máquina | 100 operaciones por segundo, 500 conexiones |
| Red | La de la red local | 10 GB de entrada y 10 GB de salida cada 7 días |
| Trabajo humano | Instalar, actualizar, respaldar, vigilar | Configurar, respaldar, vigilar el consumo |

En los planes pagos se factura por tamaño de instancia y tiempo encendido, almacenamiento, transferencia y respaldos. Por eso, en DBaaS el DBA también vigila **costos**: un índice innecesario o una consulta que recorre toda la colección se pagan.

**Dependencia del proveedor (*lock-in*).** Las funciones exclusivas del servicio (por ejemplo, el respaldo administrado) atan al proveedor. Un respaldo lógico estándar como `mongodump` permite salir: lo demostramos restaurando fuera de Atlas.

---

## 8. ¿DBaaS elimina al DBA o transforma su rol?

**Lo transforma.** Desaparecen las tareas de **infraestructura** (instalar, parchear, armar réplicas, configurar TLS). Permanecen, y ganan peso, las tareas de **gobierno**:

| Tarea del DBA en DBaaS | Evidencia en esta actividad |
| :--- | :--- |
| Diseñar el modelo y ejecutar las operaciones | CRUD sobre `practicaU10.productos` (bitácora §3) |
| Definir identidades y mínimo privilegio | `lector_g11` solo lee `practicaU10`; el `insertOne` fue rechazado (§4.1) |
| Controlar la red | Solo la IP de nuestra VM en Network Access (§2) |
| Garantizar la continuidad: respaldo **y** prueba de restauración | `mongodump` desde Atlas y `mongorestore` en `practicaU10_restore` (§5) |
| Conocer los límites del servicio y compensarlos | Sin backup gratuito, sin `createUser`, sin logs |
| Vigilar consumo y costos | Tamaño de la base frente a la cuota de 512 MB (vista general y *Metrics*) |

El DBA pasa de **operar servidores** a **gobernar un servicio**.

---

## 9. Preguntas de defensa

1. **¿Por qué eligieron MongoDB Atlas?** Es el motor que usamos en las Unidades 7 y 8 sobre la VM, así que comparamos las mismas operaciones en los dos entornos. Además, es el servicio del fabricante y el plan Free no pide tarjeta.
2. **¿Qué es el endpoint y por qué no tiene IP?** Es un nombre SRV: el cliente le pregunta al DNS cuáles son los nodos. Así el proveedor puede reemplazar nodos sin que cambie la cadena de conexión.
3. **¿Cuántos servidores tiene su cluster Free?** Tres, en un *replica set*: uno primario y dos secundarios (vista general del cluster).
4. **¿Cómo demostraron que la conexión es autenticada sin mostrar la clave?** La salida muestra el usuario autenticado y sus roles; la clave se ingresa oculta y los comandos la muestran como `<clave>`.
5. **¿Los comandos CRUD cambiaron respecto de la VM?** No. Son los mismos comandos de `mongosh`; solo cambia la cadena de conexión.
6. **¿Por qué el `updateOne` filtra por `codigo` y no por `_id`?** Porque `codigo` es el identificador de negocio que conocemos; el `_id` lo genera MongoDB. Para que el filtro sea seguro, `codigo` debería tener un índice único (`createIndex({ codigo: 1 }, { unique: true })`), así nunca hay dos productos con el mismo código.
7. **¿Qué diferencia hay entre permisos del motor y de la plataforma?** Los de la plataforma deciden quién administra la consola y desde qué IP se llega; los del motor deciden qué operaciones hace un usuario sobre los datos.
8. **¿Por qué falló `db.createUser()` si el usuario es administrador?** Porque en Atlas la gestión de usuarios está reservada a la plataforma. El administrador del motor puede operar los datos, pero no crear identidades.
9. **¿Qué hicieron cuando el plan no ofreció algo?** Lo documentamos y aplicamos el control más cercano. Por ejemplo, sin respaldo administrado gratuito usamos `mongodump` y probamos la restauración.
10. **¿La replicación de 3 nodos no alcanza como respaldo?** No: replica también los errores. Un borrado accidental desaparece de los tres nodos a la vez.
11. **¿Cómo saben que el respaldo sirve?** Lo restauramos en otro entorno y comparamos documento por documento: mismos `_id`, códigos, precios y stock en Atlas y en la VM.
12. **¿Por qué restauraron en otra base y no sobre la original?** Para que la prueba no pueda dañar los datos de producción: si el respaldo estuviera mal, solo se rompe la copia. Además, se pueden comparar las dos bases lado a lado.
13. **¿Qué no incluye el respaldo lógico?** Los usuarios (viven en la plataforma) y los cambios posteriores al momento del `mongodump`.
14. **¿Qué limitaciones encontraron?** `createUser` bloqueado, sin backup administrado sin tarjeta, sin logs descargables, solo 4 métricas, 0,5 GB y 100 operaciones por segundo.
15. **¿Usarían el plan Free en producción?** No. Sirve para aprender y prototipar: no tiene respaldo incluido, comparte recursos y tiene límites bajos. En producción usaríamos un plan dedicado con snapshots y restauración a un momento exacto.
16. **¿Por qué no habilitaron `0.0.0.0/0`?** Porque abre el cluster a cualquier IP de internet; la clave quedaría como única defensa.
17. **¿DBaaS elimina al DBA?** No, lo transforma: delega la infraestructura y conserva el diseño, la seguridad, la continuidad y los costos.
18. **¿Por qué cambiaron `lector_g11` de *Only read any database* a `read@practicaU10.productos`?** Porque `readAnyDatabase` deja leer **todas** las bases del cluster. Mínimo privilegio es darle solo lo que necesita: leer la colección `productos`.
19. **¿Para qué sirven `--nsFrom` y `--nsTo` en `mongorestore`?** Para restaurar con otro nombre de base (`practicaU10_restore`). Así la prueba de recuperación no pisa ninguna base existente.
20. **¿Por qué el respaldo restaurado tiene los mismos `_id` que en Atlas?** Porque `mongodump` copia los documentos tal cual, incluido su `_id`. Si fuera una nueva carga, MongoDB generaría `_id` distintos: por eso los `_id` iguales prueban que es una copia fiel.

---

## 10. Glosario

| Término | Significado |
| :--- | :--- |
| **DBaaS** | Base de datos ofrecida como servicio administrado |
| **M0 / plan Free** | Nivel gratuito de Atlas, con recursos compartidos y límites fijos |
| **Replica set** | Grupo de servidores MongoDB con los mismos datos; uno es primario |
| **SRV** | Registro DNS que lista los servidores de un servicio |
| **SCRAM** | Mecanismo de autenticación por desafío y respuesta |
| **Network Access / lista de IP** | Control de la plataforma que define desde qué direcciones se puede conectar |
| **Snapshot** | Copia física del almacenamiento en un momento dado |
| **Respaldo lógico** | Copia de los documentos leídos a través del motor (`mongodump`) |
| **RPO / RTO** | Pérdida máxima de datos admitida / tiempo máximo de recuperación |
| **Lock-in** | Dependencia de un proveedor por usar funciones exclusivas suyas |
| **Responsabilidad compartida** | Reparto explícito de tareas entre proveedor y cliente |
