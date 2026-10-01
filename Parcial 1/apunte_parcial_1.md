# Apunte guiado · Parcial 1 · Sistemas de Gestión de Bases de Datos (2026)

**Bloque temático 1: Administración de bases de datos relacionales**
Unidades 1 a 6 · Enfoque multiplataforma (MySQL/InnoDB y PostgreSQL)

---

## Cómo usar este apunte

La materia no evalúa sintaxis memorizada: evalúa **criterio**. Casi todas las preguntas se pueden responder con el mismo esquema:

> **Problema → decisión técnica → evidencia → costo o límite.**

Por eso cada tema está organizado así:

1. **Idea central**: qué problema resuelve el concepto.
2. **Tablas comparativas**: las alternativas y cuándo conviene cada una.
3. **Ejemplos en MySQL y PostgreSQL**: la sintaxis cambia, el razonamiento no.
4. **Soluciones alternativas y trampas frecuentes**: lo que suele aparecer en una defensa.
5. **Preguntas de repaso** al final de cada unidad.

> **Regla de oro de la cátedra:** una configuración no está bien porque "funciona", está bien cuando puede **demostrarse con evidencia** (un plan, una medición, un error esperado, un conteo antes y después).

### Índice

- [Unidad 1 · Arquitectura de motores de bases de datos](#unidad-1--arquitectura-de-motores-de-bases-de-datos)
- [Unidad 2 · Diseño físico y rendimiento](#unidad-2--diseño-físico-y-rendimiento)
- [Unidad 3 · SQL avanzado](#unidad-3--sql-avanzado)
- [Unidad 4 · Programabilidad y evolución del esquema](#unidad-4--programabilidad-y-evolución-del-esquema)
- [Unidad 5 · Conectividad, transacciones y concurrencia](#unidad-5--conectividad-transacciones-y-concurrencia)
- [Unidad 6 · Seguridad, backup, réplica y alta disponibilidad](#unidad-6--seguridad-backup-réplica-y-alta-disponibilidad)
- [Integración: preguntas que cruzan unidades](#integración-preguntas-que-cruzan-unidades)
- [Chuleta de comandos MySQL vs PostgreSQL](#chuleta-de-comandos-mysql-vs-postgresql)
- [Resoluciones de las actividades: MySQL y PostgreSQL](#resoluciones-de-las-actividades-mysql-y-postgresql)

### El hilo conductor del bloque

| Unidad | Pregunta que responde | Idea que no hay que perder |
| :--- | :--- | :--- |
| 1 · Arquitectura | ¿Qué pasa dentro del motor cuando llega una consulta? | Distintos motores, **mismos problemas de ingeniería**. |
| 2 · Diseño físico | ¿Cómo hago que una consulta correcta también sea rápida? | Toda decisión física responde a una **carga** y se **mide**. |
| 3 · SQL avanzado | ¿Cómo expreso un requerimiento complejo sin perder la semántica? | Primero decidir **qué filas deben sobrevivir**, después la sintaxis. |
| 4 · Programabilidad | ¿Dónde pongo una regla de negocio y cómo evoluciono la base? | El **mecanismo más simple** que garantice la regla. |
| 5 · Concurrencia | ¿Qué pasa cuando dos usuarios tocan el mismo dato? | Distinguir **lentitud, espera y deadlock**. |
| 6 · Seguridad y continuidad | ¿Cómo protejo, recupero y mantengo el servicio? | **Backup no es HA**, y un backup sin restore probado es una promesa. |

---

# Unidad 1 · Arquitectura de motores de bases de datos

## 1.1 Tres términos que no se deben confundir

| Término | Qué es | Ejemplo |
| :--- | :--- | :--- |
| **Base de datos (BD)** | Conjunto persistente y organizado de datos con un fin determinado. Es un concepto **lógico**. | Los datos de clientes, cuentas y movimientos de un banco. |
| **Sistema de base de datos** | Todo lo que da soporte a una o más BD: hardware, software, datos, usuarios y procesos. | Servidor + MySQL + aplicación + DBA + usuarios. |
| **SGBD / DBMS** | El **software** que gestiona definición, manipulación, seguridad, concurrencia, transacciones, recuperación y acceso eficiente. | MySQL, PostgreSQL, SQL Server, Oracle. |

Un DBMS no es "un lugar donde guardar datos": **decide cómo protegerlos, recuperarlos y accederlos eficientemente**.

### DBMS frente a sistema de archivos

| Aspecto | Sistema de archivos | DBMS |
| :--- | :--- | :--- |
| Estructura | El programa conoce el formato exacto del archivo. | El catálogo describe la estructura y los programas la consultan. |
| Integridad | Queda del lado de cada aplicación. | Centralizada (PK, FK, CHECK, triggers). |
| Concurrencia | Difícil: bloqueo de archivo completo o nada. | Transacciones, locks y MVCC. |
| Recuperación | Manual. | Logs, checkpoints, backup y restore. |
| Redundancia | Alta (cada app tiene sus archivos). | Menor: datos integrados y compartidos. |
| Independencia | Cambiar el formato rompe los programas. | Independencia lógica y física. |

## 1.2 Componentes y actores

- **Datos**: integrados, persistentes y compartidos.
- **Hardware**: CPU, memoria, discos y red. En la nube parte de esto lo opera el proveedor, pero **las decisiones técnicas no desaparecen**.
- **Software**: el DBMS, las utilidades, los drivers y las herramientas.
- **Usuarios**:

| Rol | Mirada sobre la base |
| :--- | :--- |
| **DA** (administrador de datos) | Políticas de datos, gobierno, decisiones estratégicas. |
| **DBA** | Operación, seguridad, rendimiento, backups y disponibilidad. **Es la mirada de la materia.** |
| **Desarrollador** | Aplicaciones, consultas, APIs y migraciones. |
| **Analista / usuario final** | Consume e interpreta información. |

## 1.3 Familias de lenguaje SQL

| Familia | Sentencias | Para qué | Quién debería usarla en producción |
| :--- | :--- | :--- | :--- |
| **DDL** | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` | Definir estructuras. | DBA o scripts de migración, **nunca la app en tiempo de ejecución**. |
| **DML** | `SELECT`, `INSERT`, `UPDATE`, `DELETE` | Consultar y manipular datos. | Aplicación y usuarios, según su rol. |
| **DCL** | `GRANT`, `REVOKE` | Administrar permisos. | DBA. |
| **TCL** | `COMMIT`, `ROLLBACK`, `SAVEPOINT` | Controlar transacciones. | Aplicación y DBA. |

> Esta tabla vuelve a aparecer en la Unidad 6: el **mínimo privilegio** se diseña sobre estas familias.

## 1.4 Arquitectura ANSI/SPARC: tres niveles

| Nivel | Qué describe | Ejemplo |
| :--- | :--- | :--- |
| **Externo** (vistas) | Cómo ve los datos cada usuario o aplicación. | Una vista que oculta el sueldo a un analista. |
| **Conceptual** (lógico) | El modelo común de la organización: entidades, relaciones, restricciones. | Tablas `cliente`, `cuenta`, `movimiento` con sus PK y FK. |
| **Interno** (físico) | Cómo se almacena realmente: páginas, índices, archivos, particiones, logs. | InnoDB guarda `cuenta` como un B-tree ordenado por la PK. |

Para el DBA el nivel interno es clave. Para el usuario final debería ser **invisible**.

### Independencia de datos

| Tipo | Qué permite | Ejemplo |
| :--- | :--- | :--- |
| **Lógica** | Cambiar el esquema conceptual sin romper las vistas externas. | Agregar una columna o dividir una tabla y mantener una vista con la forma anterior. |
| **Física** | Cambiar el almacenamiento sin cambiar la visión lógica. | Crear un índice, particionar o mover a otro tablespace: **las consultas siguen iguales**. |

> El ideal: *una decisión física de rendimiento no debería obligar a reprogramar el sistema.* Todo el diseño físico de la Unidad 2 se apoya en la independencia física.

## 1.5 Modelos de datos

| Modelo | Unidad de datos | Fuerte en | Ejemplos |
| :--- | :--- | :--- | :--- |
| Relacional | Tablas, claves, restricciones | Transacciones, integridad, SQL | MySQL, PostgreSQL, Oracle, SQL Server |
| Documental | Documentos JSON/BSON (agregados) | Esquema flexible | MongoDB |
| Clave-valor | Par clave → valor | Acceso muy rápido por clave | Redis |
| Columnar / columna ancha | Columnas o familias de columnas | Lectura masiva, analítica, escala | Cassandra, motores analíticos |
| Grafo | Nodos y aristas | Relaciones y recorridos complejos | Neo4j |

> La selección de motor depende del **caso de uso**, no de la moda.

## 1.6 Arquitectura interna: del SQL al disco

El patrón se repite en todos los motores relacionales, aunque cambien los nombres:

```
Cliente → Parser → Catálogo → Optimizador → Ejecutor → Buffer (RAM) → Storage manager → Datos + Logs (disco)
```

| Componente | Qué hace |
| :--- | :--- |
| **Parser** | Análisis léxico, sintáctico y semántico. Valida que los objetos existan y arma un árbol de consulta. |
| **Catálogo / diccionario** | Aporta metadatos: columnas, tipos, índices, **estadísticas** y permisos. |
| **Optimizador** | Estima costos y elige un **plan**: qué índice usar, orden y tipo de join, si ordenar, si paralelizar. La consulta **no se ejecuta "tal como está escrita"**. |
| **Ejecutor** | Recorre el plan, pide páginas, aplica locks o versiones y devuelve filas. |
| **Buffer / caché** | Mantiene páginas en memoria. El ejecutor **opera sobre páginas en RAM, nunca directamente sobre el disco**. |
| **Storage manager** | Traduce páginas en archivos y administra la E/S. |

### Qué pasa en un `UPDATE` + `COMMIT` (clave para entender recuperación)

1. El ejecutor trae la página a memoria (si no estaba: *miss*, se lee del disco).
2. Registra el cambio en el **búfer de log** (*write-ahead logging*: **el log se escribe antes que el dato**).
3. Modifica la página en RAM, que queda **"sucia"**.
4. Con el `COMMIT`, el motor **fuerza el log a disco** (fsync). Recién ahí responde "OK": eso es **durabilidad**.
5. La página sucia baja al archivo de datos **más tarde**, en segundo plano, con el **checkpoint**.

> **Idea clave:** el `COMMIT` persiste el **log**, no los datos. Si el servidor cae antes del checkpoint, al reiniciar el motor **rehace** (*redo*) desde el log los cambios confirmados y **deshace** (*undo*) los que no llegaron a confirmarse.

**¿Por qué no escribir directamente el dato en el `COMMIT`?** Porque escribir el log es secuencial y pequeño, mientras que escribir páginas es aleatorio y costoso. El log permite responder rápido sin perder durabilidad.

## 1.7 Memoria: el puente entre SQL y disco

| Estructura | Función | MySQL/InnoDB | PostgreSQL |
| :--- | :--- | :--- | :--- |
| Caché de datos | Páginas de datos e índices usadas recientemente. | `innodb_buffer_pool_size` (buffer pool) | `shared_buffers` (+ caché del SO) |
| Memoria de trabajo | Ordenamientos, joins hash, agregaciones. | `sort_buffer_size`, `join_buffer_size`, `tmp_table_size` | `work_mem` |
| Búfer de log | Agrupa cambios antes de escribir el log. | `innodb_log_buffer_size` | `wal_buffers` |
| Caché de planes | Reutiliza planes de sentencias frecuentes. | Limitada (sentencias preparadas) | Planes de sentencias preparadas |

> Oracle habla de SGA/Buffer Cache y SQL Server de Buffer Pool: **mismo patrón, otro nombre**.

Si la memoria de trabajo no alcanza para ordenar, el motor **derrama a disco** (archivos temporales). Es una causa típica de lentitud que se ve en el plan (Unidad 2).

## 1.8 Almacenamiento físico

| Estructura | Qué contiene |
| :--- | :--- |
| **Datos** | Páginas, bloques, extensiones y segmentos organizados en *heap*, *tablespaces* o *datafiles*. |
| **Índices** | B-tree, hash, full-text, espacial y otros. |
| **Logs** | Registro transaccional para durabilidad y recuperación. |
| **Temporales** | Espacio para ordenamientos, hash y resultados intermedios. |

## 1.9 Transacciones y ACID: qué mecanismo sostiene cada propiedad

| Propiedad | Significa | Mecanismo concreto |
| :--- | :--- | :--- |
| **A** · Atomicidad | Todo o nada. | `ROLLBACK` con información de deshacer (undo log en InnoDB; en PostgreSQL las versiones no confirmadas quedan invisibles). |
| **C** · Consistencia | La transacción lleva la base de un estado válido a otro válido. | Constraints (PK, FK, CHECK), triggers y la propia atomicidad. |
| **I** · Aislamiento | Las transacciones concurrentes no se interfieren más de lo permitido. | Locks, MVCC y niveles de aislamiento (Unidad 5). |
| **D** · Durabilidad | Lo confirmado sobrevive a una caída. | Log escrito a disco en el `COMMIT` (redo/WAL) + checkpoints. |

### Logs transaccionales por motor

| Motor | Nombre | Nota |
| :--- | :--- | :--- |
| MySQL/InnoDB | **Redo log** + **undo log** | Aparte existe el **binary log**, que registra los cambios lógicos para réplica y recuperación a un punto en el tiempo (Unidad 6). |
| PostgreSQL | **WAL** (*Write-Ahead Log*) | Sirve para durabilidad, réplica y PITR. No hay undo separado: MVCC guarda versiones en la tabla. |
| SQL Server | Transaction log | |
| Oracle | Redo log + undo | |

> **Patrón común:** antes o junto con la modificación, el motor registra información suficiente para **rehacer o deshacer** el cambio.

## 1.10 Metadatos y catálogo

Los metadatos son **datos sobre los datos**, y cada motor los guarda en tablas que se consultan con SQL. **Sin metadatos no hay optimizador, seguridad ni administración.**

| Motor | Catálogo | Ejemplos |
| :--- | :--- | :--- |
| MySQL | `INFORMATION_SCHEMA` (estándar ANSI) + `performance_schema` + `mysql` | `SHOW TABLES; DESCRIBE cuenta;` · `SELECT table_name, engine FROM information_schema.tables WHERE table_schema = 'banco';` |
| PostgreSQL | `pg_catalog` (`pg_class`, `pg_attribute`...) + `information_schema` | `\dt` · `\d cuenta` · `SELECT relname FROM pg_class WHERE relkind = 'r';` |
| SQL Server | `sys.*` + `INFORMATION_SCHEMA` + `sp_*` | `SELECT name FROM sys.tables; EXEC sp_help 'cuenta';` |
| Oracle | Diccionario `USER_*`, `ALL_*`, `DBA_*` | `SELECT table_name FROM user_tables;` |

## 1.11 Instancia, base de datos y esquema: el mismo término cambia de significado

| Concepto | Idea general | MySQL | PostgreSQL |
| :--- | :--- | :--- | :--- |
| **Instancia** | Proceso o servicio que administra recursos y conexiones. | `mysqld` | El *cluster* (un `postgres` escuchando en un puerto). |
| **Base de datos** | Contenedor lógico de objetos. | **Es sinónimo de esquema.** | Una instancia tiene varias bases, y una conexión es **a una sola base**. |
| **Esquema** | Espacio de nombres de objetos. | `CREATE SCHEMA` = `CREATE DATABASE`. | Namespace **dentro** de una base (`public` por defecto). |

Consecuencias prácticas:
- En MySQL se puede consultar `otra_base.tabla` desde la misma conexión. En PostgreSQL, para cruzar bases hace falta `dblink` o `postgres_fdw`; lo normal es separar con **esquemas**.
- En Oracle el esquema está ligado al usuario; en SQL Server, a la propiedad (*ownership*).

> **Comparar términos antes de comparar comandos.**

## 1.12 Comparación multiplataforma

| Aspecto | MySQL / InnoDB | PostgreSQL |
| :--- | :--- | :--- |
| Organización de la tabla | **Clustered** por la PK: los datos viven en el B-tree de la PK. | **Heap**: filas sin orden; los índices apuntan a la ubicación física. |
| Log | Redo + undo (+ binlog lógico) | WAL |
| Concurrencia | MVCC con undo log + locks de fila, gap y next-key | MVCC con versiones en la tabla (requiere `VACUUM`) + locks |
| Aislamiento por defecto | `REPEATABLE READ` | `READ COMMITTED` |
| DDL | Commit implícito: **no se puede deshacer** con `ROLLBACK`. | **Transaccional**: un `CREATE`/`ALTER` dentro de `BEGIN` se puede revertir. |
| Herramienta gráfica | MySQL Workbench | pgAdmin |
| Fuerte en | Aplicaciones web y servicios transaccionales. | Robustez SQL, extensibilidad, funciones avanzadas. |

## 1.13 Bases de datos en la nube (DBaaS)

| El proveedor administra (en parte) | El equipo **sigue** decidiendo |
| :--- | :--- |
| Hardware, parches, backups automáticos, réplicas, monitoreo básico. | Modelo de datos, consultas, índices, seguridad, costos y continuidad (RPO/RTO). |

Ejemplos: Amazon RDS/Aurora, Azure SQL, Google Cloud SQL. **DBaaS cambia la operación, no elimina la arquitectura.** Hoy lo normal es un modelo **híbrido** (on-premise + nube) según cumplimiento, residencia de datos y costo.

## Preguntas de repaso · Unidad 1

1. Explicá con tus palabras por qué el `COMMIT` puede responder antes de que la página modificada llegue al archivo de datos, sin perder durabilidad.
2. Un compañero dice: "Si el servidor se cae, perdemos lo que estaba en el buffer pool". ¿Qué es cierto y qué no?
3. Dá un ejemplo de independencia física y otro de independencia lógica.
4. ¿Por qué en PostgreSQL no se puede hacer `SELECT` sobre dos bases distintas en la misma consulta, y en MySQL sí?
5. Relacioná cada propiedad ACID con un mecanismo concreto del motor.
6. ¿Qué información del catálogo usa el optimizador para elegir un plan?

---

# Unidad 2 · Diseño físico y rendimiento

## 2.1 Idea central: el diseño empieza por la carga, no por la tabla

> *¿Por qué una consulta correcta se vuelve lenta cuando crecen los datos?* Con 10.000 filas responde en milisegundos; con 50 millones recorre toda la tabla. **Es lógicamente correcta, pero incumple el tiempo objetivo.**

No se optimiza una tabla en abstracto. Antes de crear cualquier estructura hay que conocer:

| Dimensión | Preguntas |
| :--- | :--- |
| **Operaciones** | ¿Qué consultas y transacciones concretas se ejecutan? |
| **Patrones de acceso** | ¿Qué filtros, joins y ordenamientos usan? ¿Cuántas filas devuelven? |
| **Volumen y crecimiento** | Filas, tamaño promedio, altas diarias, retención, distribución de valores (sesgos, nulos). |
| **Frecuencia y criticidad** | ¿Cuántas veces y en qué horario? ¿Qué impacto tiene si no cumple el tiempo? |
| **Concurrencia** | ¿Cuántas ejecuciones compiten por recursos al mismo tiempo? |
| **Escrituras** | ¿Cuántos `INSERT`/`UPDATE`/`DELETE` pagarían el costo de mantener una estructura nueva? |

### Matriz de carga (ejemplo)

| Operación | Acceso | Frecuencia | Filas | Objetivo | Prioridad |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Últimos 20 pedidos de un cliente | `WHERE cliente_id = ? ORDER BY fecha DESC LIMIT 20` | Miles por hora | ~20 | < 50 ms | Muy alta |
| Pendientes por sucursal | `WHERE sucursal_id = ? AND estado = 'PENDIENTE' ORDER BY fecha` | Cientos por hora | < 100 | < 100 ms | Alta |
| Resumen trimestral | `WHERE fecha BETWEEN ... GROUP BY estado` | 1 por día | Miles | < 5 s | Baja |
| Alta de pedidos | `INSERT` | Continua | 1 | < 10 ms | Muy alta |

> **Optimizar una consulta aislada puede degradar el sistema completo.** La matriz obliga a ver lecturas y escrituras juntas.

## 2.2 El motor lee páginas, no filas

- La **página** (o bloque) es la unidad mínima de lectura y escritura: 16 KB en InnoDB y 8 KB en PostgreSQL por defecto.
- Jerarquía: **página → extensión (conjunto de páginas) → segmento/objeto (tabla o índice) → archivo/tablespace**.
- Agrupación de archivos: *tablespaces* (PostgreSQL, Oracle, MySQL), *filegroups* (SQL Server).

**El ancho de la fila multiplica el trabajo:**

```
Tipo de dato → ancho de fila → filas por página → páginas procesadas → E/S y caché
```

Ejemplo: guardar un estado como `VARCHAR(255)` en lugar de `TINYINT` o un `ENUM`, o una fecha como texto, hace que entren menos filas por página. La misma consulta lee más páginas y aprovecha peor la caché. **Menos instrucciones SQL no siempre significa menos E/S.**

## 2.3 Organización de la tabla

| Organización | Cómo guarda las filas | Motores | Consecuencia |
| :--- | :--- | :--- | :--- |
| **Heap** (montón) | Sin orden físico definido. Los índices apuntan a la ubicación física de la fila. | PostgreSQL (siempre), SQL Server sin índice clustered | Inserción barata. Los índices son estructuras separadas. |
| **Clustered** | Las filas **forman parte** del índice principal, ordenadas por su clave. | InnoDB (por la PK), SQL Server | Buscar por PK o por rango de PK es muy eficiente. |
| **IOT** (*index-organized table*) | Equivalente al clustered en Oracle. | Oracle | |

### La PK en InnoDB importa más de lo que parece

- Los índices secundarios de InnoDB guardan **el valor de la PK** como puntero. **Una PK ancha agranda todos los índices secundarios.**
- Una PK **secuencial** (autoincremental) inserta siempre al final del árbol. Una PK **aleatoria** (por ejemplo un UUID v4) inserta en cualquier lugar, provoca divisiones de página (*page splits*), fragmenta y empeora la caché.
- Alternativas: `BIGINT AUTO_INCREMENT`, UUID ordenados por tiempo (v7) o guardar el UUID como `BINARY(16)`.
- En PostgreSQL existe el comando `CLUSTER`, que reordena la tabla **una sola vez** según un índice; el orden no se mantiene con las inserciones posteriores.

## 2.4 Índices: la navaja suiza del DBA

Un índice sirve cuando **reduce el acceso necesario**. Puede hacer tres cosas:

| Función | Qué evita | Señal en el plan |
| :--- | :--- | :--- |
| **Localizar** | Recorrer toda la tabla. | `Index lookup`/`range` (MySQL) · `Index Scan`/`Bitmap Heap Scan` (PG) |
| **Ordenar** | Un paso de ordenamiento, porque el índice ya entrega las filas en orden. | Desaparece `Sort`/`Using filesort` |
| **Cubrir** | Volver a la tabla, porque el índice ya tiene todas las columnas pedidas. | `Using index` (MySQL) · `Index Only Scan` (PG) |

> **Crear un índice no garantiza que el optimizador lo use.** Ver [2.8](#28-por-qué-el-optimizador-no-usa-mi-índice).

### Tipos de índice

| Tipo | Sirve para | Motores |
| :--- | :--- | :--- |
| **B-tree** (el más usado) | Igualdad, rangos, prefijos (`LIKE 'abc%'`) y orden. | Todos (tipo por defecto) |
| **Hash** | Solo igualdad. | PostgreSQL; en MySQL, motor `MEMORY` y hash adaptativo interno de InnoDB |
| **Full-text** | Búsqueda de palabras en texto. | MySQL `FULLTEXT`, PG `GIN` + `tsvector` |
| **Espacial** | Geometrías. | MySQL `SPATIAL`, PG `GiST` |
| **GIN / GiST / BRIN** | JSON, arrays, texto (GIN); rangos y geometría (GiST); tablas enormes ordenadas naturalmente, como logs por fecha (BRIN). | PostgreSQL |
| **Bitmap** | Columnas de baja cardinalidad en analítica. | Oracle (PG arma bitmaps **en memoria** durante la ejecución) |

**El tipo de índice debe corresponder al operador y a la carga.**

### Variantes útiles

| Variante | Qué es | MySQL | PostgreSQL |
| :--- | :--- | :--- | :--- |
| **Compuesto** | Varias columnas en un orden. | ✓ | ✓ |
| **De expresión / funcional** | Indexa el resultado de una expresión, como `LOWER(email)`. | ✓ (8.0.13+), o columna generada + índice | ✓ |
| **Parcial** | Indexa solo las filas que cumplen una condición: `WHERE estado = 'PENDIENTE'`. | ✗ | ✓ |
| **Con columnas incluidas** | Agrega columnas solo para cubrir, sin que formen parte de la clave. | ✗ (se agregan a la clave) | `INCLUDE (...)` |
| **Descendente** | Orden `DESC` explícito. | ✓ (8.0+) | ✓ |
| **Invisible** | El optimizador lo ignora pero se sigue manteniendo. Sirve para probar el efecto de sacar un índice sin borrarlo. | ✓ (`ALTER INDEX ... INVISIBLE`) | ✗ |

## 2.5 Índices compuestos: el orden de las columnas importa

Un índice `(A, B, C)` está ordenado primero por A, dentro de cada A por B y dentro de cada B por C, como una guía telefónica ordenada por apellido y después por nombre.

**Regla del prefijo izquierdo:** el índice se puede usar para filtrar por `A`, por `A, B` o por `A, B, C`, pero **no por `B` solo** ni por `C` solo.

**Regla práctica de orden (igualdad → orden/rango):**
1. Primero las columnas comparadas por **igualdad** (`=`).
2. Después la columna del **`ORDER BY`** o del **rango** (`BETWEEN`, `>`, `<`).
3. Una vez que aparece un rango, las columnas siguientes ya no sirven para filtrar con el índice.

### Ejemplo razonado

```sql
SELECT pedido_id, fecha, total
FROM pedido
WHERE cliente_id = 1500
ORDER BY fecha DESC
LIMIT 20;
```

| Índice | ¿Filtra? | ¿Evita el sort? | Resultado |
| :--- | :--- | :--- | :--- |
| Ninguno | ✗ Recorre toda la tabla | ✗ Ordena todas las filas del cliente | Lee cientos de miles de filas y ordena. |
| `(cliente_id)` | ✓ | ✗ Tiene que ordenar las filas del cliente | Mejora mucho, pero sigue ordenando. |
| `(fecha)` | ✗ | ✓ Puede recorrer el índice en orden y filtrar hasta juntar 20 | Depende de cuántos pedidos tenga el cliente: arriesgado. |
| **`(cliente_id, fecha)`** | ✓ | ✓ Lee al revés (*backward scan*) y corta en 20 | **Óptimo:** lee aproximadamente 20 entradas. |
| `(fecha, cliente_id)` | Parcialmente | ✓ | Peor: el prefijo es la fecha y no hay filtro por fecha. |

Para `WHERE sucursal_id = ? AND estado = ? ORDER BY fecha`, el índice natural es `(sucursal_id, estado, fecha)`: **dos igualdades y después el orden**.

> Un índice útil para "cliente + fecha" **no siempre** sirve para "fecha sola".

## 2.6 Selectividad, distribución y estadísticas

- **Selectividad**: qué porcentaje de filas queda después del filtro. Un filtro que deja el 0,01 % es muy selectivo; uno que deja el 60 % no lo es.
- **No hay umbrales universales.** La misma columna puede ser selectiva para un valor y no para otro. Por ejemplo, `estado = 'CANCELADO'` (2 %) frente a `estado = 'ENVIADO'` (75 %).
- Cuando el filtro devuelve una porción grande, **un scan completo puede ser más barato** que ir y volver al índice por cada fila (acceso aleatorio).

El optimizador estima con **estadísticas**:

| Estadística | Qué describe | MySQL | PostgreSQL |
| :--- | :--- | :--- | :--- |
| Cardinalidad básica | Cantidad de valores distintos por índice. | `ANALYZE TABLE t;` | `ANALYZE t;` (también automático con *autovacuum*) |
| Histogramas | Frecuencias y valores dominantes (sesgo). | `ANALYZE TABLE t UPDATE HISTOGRAM ON col WITH 32 BUCKETS;` | Automáticos (lista de valores más comunes + histograma) |
| Correlación entre columnas | Columnas que no son independientes (ciudad y provincia). | ✗ | `CREATE STATISTICS ... (dependencies, ndistinct, mcv)` |

> **Una mala estimación puede producir un mal plan aun con buenos índices.** Señal típica: filas estimadas muy distintas de las reales. Solución: `ANALYZE` **antes** de crear otro índice.

## 2.7 Índices de cobertura y costo oculto de los índices

**Cobertura:** si el índice contiene todas las columnas que pide la consulta, el motor no vuelve a la tabla.

```sql
-- MySQL: cubre si todas las columnas están en el índice
CREATE INDEX idx_cli_fecha_total ON pedido (cliente_id, fecha, total);
-- PostgreSQL: columnas incluidas, que no forman parte de la clave
CREATE INDEX idx_cli_fecha ON pedido (cliente_id, fecha) INCLUDE (total);
```

En PostgreSQL un *Index Only Scan* igual consulta el *visibility map*. Si la tabla tiene muchas páginas sin `VACUUM`, aparecen `Heap Fetches` y la ventaja se pierde.

### Todo índice tiene costo

| Costo | Por qué |
| :--- | :--- |
| **Escritura** | Cada `INSERT`, cada `DELETE` y cada `UPDATE` sobre columnas indexadas debe mantener **cada** índice. |
| **Espacio** | Más páginas en disco y **en la caché**: compiten con los datos. |
| **Log** | Más redo/WAL generado, lo que implica más carga de réplica y de backup. |
| **Concurrencia** | Más estructuras que bloquear. Las claves que concentran las escrituras (*hot spots*) amplifican las esperas. |

**Orden de magnitud típico en laboratorio** (tabla de ~300.000 filas y dos índices compuestos nuevos): las consultas prioritarias pasan de ~100 ms (scan + sort) a menos de 1 ms, y un lote de 10.000 inserciones se vuelve varias veces más lento. **La decisión depende de la prioridad de cada operación**, no de un número aislado.

> Antes de crear un índice: *¿qué mejora, cuánto se usa y qué operación encarece?*

## 2.8 ¿Por qué el optimizador no usa mi índice?

| Causa | Ejemplo | Solución alternativa |
| :--- | :--- | :--- |
| Función sobre la columna | `WHERE YEAR(fecha) = 2026` | Reescribir como rango: `fecha >= '2026-01-01' AND fecha < '2027-01-01'`, o usar un índice funcional. |
| Conversión implícita de tipos | `WHERE dni = 12345678` con `dni VARCHAR` | Comparar con el mismo tipo: `'12345678'`. |
| Comodín al inicio | `LIKE '%perez'` | Índice full-text o trigram (`pg_trgm`) en PG. |
| No se usa el prefijo | Índice `(cliente_id, fecha)` con `WHERE fecha > ...` | Otro índice, o reordenar si la carga lo justifica. |
| Baja selectividad | `WHERE activo = 1` con 95 % de activos | El scan es correcto. En PG, un índice parcial sobre el valor minoritario. |
| Tabla pequeña | 200 filas | El scan es correcto: entra en pocas páginas. |
| `OR` entre columnas distintas | `WHERE a = 1 OR b = 2` | `UNION` de dos consultas indexables, o *index merge* / *bitmap OR*. |
| Estadísticas desactualizadas | Estimado 10 filas, reales 500.000 | `ANALYZE`. |
| Tipo de índice inadecuado | Hash para un rango | B-tree. |

## 2.9 Particionamiento: divide y reinarás

**Idea:** dividir una tabla grande en partes según una clave y una regla.

| Estrategia | Regla | Caso típico |
| :--- | :--- | :--- |
| **Rango** | Intervalos de valores. | Fechas y períodos: una partición por mes. |
| **Lista** | Valores conocidos. | Regiones o categorías. |
| **Hash** | Distribución uniforme. | Repartir carga cuando no hay una clave natural de corte. |

**Beneficios:**
- ***Partition pruning***: el optimizador **descarta particiones** que no pueden contener filas del filtro.
- **Retiro de datos históricos**: eliminar un mes completo con `DROP`/`DETACH PARTITION` es casi instantáneo, frente a un `DELETE` fila por fila que genera log, locks y fragmentación.

**Límites:**
- **No reemplaza al índice**: dentro de la partición que se conserva todavía hay que localizar filas.
- Si la consulta **no filtra por la clave de partición**, se recorren todas las particiones (puede ser peor que sin particionar).
- MySQL: toda clave única (incluida la PK) debe contener las columnas de la partición, y las tablas particionadas **no admiten FK**. PostgreSQL: la PK también debe incluir la clave de partición.

| | Índice | Partición |
| :--- | :--- | :--- |
| Resuelve | **Localizar** filas | **Reducir lo recorrido** y **gestionar el ciclo de vida** del dato |
| Mejor para | Consultas selectivas | Tablas enormes con acceso por período y retención |
| Costo | Escrituras y espacio | Complejidad de diseño y restricciones de claves |

```sql
-- PostgreSQL: particionamiento declarativo por rango
CREATE TABLE movimiento (id bigint, fecha date NOT NULL, importe numeric)
  PARTITION BY RANGE (fecha);
CREATE TABLE movimiento_2026_09 PARTITION OF movimiento
  FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
-- Retirar un período sin DELETE masivo
ALTER TABLE movimiento DETACH PARTITION movimiento_2026_09;

-- MySQL
CREATE TABLE movimiento (id BIGINT, fecha DATE NOT NULL, importe DECIMAL(14,2),
  PRIMARY KEY (id, fecha))
PARTITION BY RANGE (TO_DAYS(fecha)) (
  PARTITION p2026_09 VALUES LESS THAN (TO_DAYS('2026-10-01')),
  PARTITION pmax     VALUES LESS THAN MAXVALUE);
ALTER TABLE movimiento DROP PARTITION p2026_09;
```

## 2.10 Desnormalizar y materializar (con evidencia)

| Técnica | Qué hace | Riesgo o costo | En los motores |
| :--- | :--- | :--- | :--- |
| **Desnormalización** | Duplica datos para evitar joins costosos. | Inconsistencias: hay que definir la fuente de verdad y cómo se sincroniza. | Ambos |
| **Vista materializada** | Persiste el resultado de una consulta. | Queda desactualizada hasta refrescarla. | PG: `CREATE MATERIALIZED VIEW` + `REFRESH`. MySQL no la tiene: tabla resumen + evento o trigger. |
| **Tabla resumen** | Agregados precalculados para reportes. | Mantenimiento. | Ambos |
| **Columna generada** | Precalcula una expresión (e indexable). | Espacio (si se almacena). | MySQL `GENERATED ALWAYS AS ... STORED/VIRTUAL`; PG `GENERATED ALWAYS AS ... STORED` |

> La redundancia controlada es una **excepción**: primero medir, después justificar **cómo se mantendrá la consistencia**.

## 2.11 Leer un plan de ejecución

| Motor | Plan estimado | Plan real (ejecuta la sentencia) |
| :--- | :--- | :--- |
| MySQL | `EXPLAIN` (tabla con `type`, `key`, `rows`, `filtered`, `Extra`) · `EXPLAIN FORMAT=TREE` | `EXPLAIN ANALYZE` (formato árbol con tiempos reales) |
| PostgreSQL | `EXPLAIN` | `EXPLAIN (ANALYZE, BUFFERS)` |

> ⚠️ `EXPLAIN ANALYZE` **ejecuta** la sentencia. Sobre un `UPDATE` o `DELETE`, hacerlo dentro de `BEGIN ... ROLLBACK`.

### Equivalencias entre motores

| Idea | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Lectura completa | `Table scan` · `type = ALL` | `Seq Scan` |
| Acceso por índice | `Index lookup` · `Index range scan` · `type = ref/range` | `Index Scan` · `Bitmap Heap Scan` |
| Filtro posterior al acceso | `Filter` · `filtered` | `Filter` · `Rows Removed by Filter` |
| Join repetitivo | `Nested loop` | `Nested Loop` |
| Cobertura | `Extra: Using index` | `Index Only Scan` + `Heap Fetches` |
| Ordenamiento | `Sort` · `Using filesort` · `Sort_merge_passes` | `Sort Method: quicksort Memory` / `external merge Disk` |
| Estimado vs real | `cost=... rows=...` vs `actual time=... rows=... loops=...` | Ídem |

### Cómo leerlo

1. **De adentro hacia afuera** (de los nodos más profundos hacia la raíz): las filas suben de un nodo al siguiente.
2. Buscar los nodos con **mayor tiempo o costo**.
3. Comparar **filas estimadas vs reales**. Una diferencia grande apunta a un problema de estadísticas.
4. Mirar los **loops**: en MySQL, el tiempo informado es el promedio por loop, así que el costo total es tiempo × loops.
5. Buscar **scans inesperados**, **sorts a disco** y **temporales**.
6. Distinguir **condición de acceso** (`Index Cond`) de **filtro posterior** (`Filter`).

```text
-- MySQL, antes: scan completo + sort
-> Limit: 20 row(s)  (actual time=101..101 rows=15 loops=1)
    -> Sort: pedido.fecha DESC, limit input to 20 row(s) per chunk
        -> Filter: (pedido.cliente_id = 1500)  (actual time=2.6..101 rows=15)
            -> Table scan on pedido  (actual time=0.2..89.8 rows=300000)

-- MySQL, después de (cliente_id, fecha): no hay sort, el índice se recorre al revés
-> Limit: 20 row(s)  (actual time=0.16..0.29 rows=15 loops=1)
    -> Index lookup on pedido using idx_cliente_fecha (cliente_id=1500) (reverse)
```

> **No comparar costos entre motores:** las unidades y los modelos de costo no son equivalentes. Y no concluir que *Scan*, *Nested Loop* o *Sort* son "siempre malos": depende del volumen y de la selectividad.

## 2.12 Protocolo de medición reproducible

1. **Línea de base**: motor, versión, filas, índices existentes y plan inicial.
2. **Hipótesis escrita antes del DDL**: qué debería cambiar en el plan y por qué.
3. **Intervención**: DDL + **estadísticas actualizadas** (`ANALYZE`).
4. **Mismos parámetros** antes y después.
5. **Tres ejecuciones y la mediana** (la mediana resiste valores atípicos, como la primera ejecución con la caché fría).
6. **No reiniciar el servidor ni limpiar cachés** entre pruebas: las condiciones tienen que ser comparables.
7. **Medir el costo de escritura** antes y después.
8. **Veredicto**: mantener, modificar o revertir, e incluir **una alternativa considerada y descartada**.

> Una hipótesis **refutada** también es un buen resultado si se explica por qué el optimizador no usó la estructura.

## 2.13 Antes de cambiar, identificar la causa

| Síntoma (evidencia) | Causa probable | Intervención de menor costo |
| :--- | :--- | :--- |
| Muchas páginas o filas examinadas para pocas devueltas | Falta un camino de acceso | Índice, mejor ubicación de los datos o partición |
| Filas anchas y muchas columnas | `SELECT *`, tipos sobredimensionados | Proyectar solo lo necesario, ajustar tipos, comprimir |
| Estimado ≠ real | Estadísticas viejas o sesgo | `ANALYZE`, histogramas, estadísticas extendidas |
| Sort o temporales en disco | Se ordenan demasiadas filas o falta memoria | Reducir filas antes de ordenar, un índice que entregue el orden, ajustar `work_mem`/`sort_buffer_size` |
| Degradación con el tiempo | Bloat, índices sin uso | `VACUUM` (PG), `OPTIMIZE TABLE` (MySQL), eliminar índices sin uso |

> *No todo problema se resuelve con otro índice.* La mejora prioritaria puede ser estadísticas, SQL, memoria o diseño.

### Caso resuelto: "el ordenamiento que llega al disco"

**Síntoma:** un reporte ordena ~900.000 filas por importe para quedarse con las primeras 1.000. El scan tarda ~2,7 s, pero la consulta total tarda ~11 s, y `Sort_merge_passes` aumenta.
**Diagnóstico:** el ordenamiento no entra en memoria y **derrama a disco** con pasadas de mezcla.

| Alternativa | Mejora | Costo o límite |
| :--- | :--- | :--- |
| Filtrar más antes de ordenar (piso de importe, rango de fechas más chico) | Menos filas llegan al sort | Cambia el alcance del reporte: validar con el negocio. |
| Columna generada `dia = DATE(fecha)` + índice `(dia, importe DESC)`, y filtrar con `dia = '2026-08-09'` | Con **igualdad** sobre `dia`, el índice entrega las filas ya ordenadas por importe y el `LIMIT` corta en 1.000 | Costo en cada escritura, por un reporte aislado. |
| Más memoria de ordenamiento para esa sesión | El sort entra en RAM | Consume memoria por conexión: riesgoso con mucha concurrencia. |
| Tabla resumen o vista materializada | El reporte lee resultados precalculados | Hay que definir cuándo se refresca. |

> ⚠️ **Trampa:** un índice `(fecha, importe DESC)` **no** elimina el sort si `fecha` se filtra por **rango** (`fecha >= ... AND fecha < ...`). El índice ordena primero por fecha y hora, y el importe queda ordenado solo dentro de cada valor exacto de `fecha`. Después de un rango, las columnas siguientes del índice ya no sirven para ordenar (ver [2.5](#25-índices-compuestos-el-orden-de-las-columnas-importa)). Para que sirva hace falta una **igualdad** en la primera columna, como la columna `dia`.

## 2.14 El diseño físico envejece: mantenimiento

| Tarea | MySQL | PostgreSQL | Por qué |
| :--- | :--- | :--- | :--- |
| Actualizar estadísticas | `ANALYZE TABLE t` | `ANALYZE t` (autovacuum) | Cambia la distribución de los datos. |
| Recuperar espacio y versiones muertas | `OPTIMIZE TABLE t` (reconstruye) | `VACUUM` / `VACUUM FULL` | Con MVCC, los `UPDATE` y `DELETE` dejan versiones viejas (bloat). |
| Índices sin uso | `sys.schema_unused_indexes` | `pg_stat_user_indexes` con `idx_scan = 0` | Cuestan en cada escritura sin aportar nada. |
| Tamaño | `information_schema.tables` (`data_length`, `index_length`) | `pg_total_relation_size()` | Seguimiento del crecimiento. |

> Diseñar también es **observar, mantener y retirar** estructuras.

## Preguntas de repaso · Unidad 2

1. Tenés un índice `(sucursal_id, estado, fecha)`. ¿Sirve para `WHERE estado = 'PENDIENTE'`? ¿Y para `WHERE sucursal_id = 3 ORDER BY fecha`? Justificá.
2. ¿Por qué crear un índice puede empeorar el rendimiento global del sistema?
3. El plan estima 12 filas y lee 480.000. ¿Qué hacés primero?
4. ¿En qué casos un *table scan* es la decisión correcta?
5. ¿Qué problema resuelve el particionamiento que un índice no resuelve, y viceversa?
6. ¿Por qué se usan tres ejecuciones y la mediana, y por qué no se limpia la caché entre pruebas?
7. En InnoDB, ¿por qué una PK de tipo UUID aleatorio perjudica a los índices secundarios y a las inserciones?

---

# Unidad 3 · SQL avanzado

## 3.1 Antes de escribir SQL: definir el resultado

"Obtener la última venta de cada cliente" parece claro hasta que aparecen los casos borde:

| Decisión | Pregunta | Impacto en el SQL |
| :--- | :--- | :--- |
| **Cobertura** | ¿Incluimos clientes sin ventas? | `INNER` o `LEFT JOIN` |
| **Empates** | ¿Dos ventas en la misma fecha? | `ROW_NUMBER` (una sola fila) o `RANK` (todas las empatadas) |
| **Desempate** | ¿Qué criterio define una única fila? | `ORDER BY fecha DESC, venta_id DESC` |
| **Salida** | ¿Qué columnas debe conservar el reporte? | Hace falta la **fila completa**, no solo `MAX(fecha)` |

> **Muchas consultas incorrectas son sintácticamente válidas.** SQL avanzado no es "más sintaxis": es elegir la construcción que **preserve la semántica** del resultado.

## 3.2 Orden lógico de evaluación de un `SELECT`

Explica muchos errores frecuentes:

```
1. FROM / JOIN  →  2. WHERE  →  3. GROUP BY  →  4. HAVING  →
5. Funciones de ventana  →  6. SELECT (alias)  →  7. DISTINCT  →  8. ORDER BY  →  9. LIMIT
```

Consecuencias:
- **No se puede filtrar una función de ventana en el `WHERE`** (`WHERE ROW_NUMBER() OVER (...) = 1` da error), porque el `WHERE` se evalúa antes. Hay que envolver la consulta en una **CTE o subconsulta** y filtrar afuera.
- Un alias del `SELECT` no existe todavía en el `WHERE`.
- `HAVING` filtra grupos y `WHERE` filtra filas.

## 3.3 NULL y lógica de tres valores

- Cualquier comparación con `NULL` da **UNKNOWN**, que no es verdadero ni falso. `WHERE col = NULL` nunca devuelve filas: hay que usar `IS NULL` / `IS NOT NULL`.
- `COALESCE(x, valor)` reemplaza nulos, por ejemplo `COALESCE(SUM(total), 0)` para un cliente sin ventas.
- Las funciones de agregación (`SUM`, `AVG`) **ignoran** los nulos. `COUNT(*)` cuenta filas y `COUNT(col)` cuenta los valores no nulos.

> ⚠️ **Trampa clásica:** `WHERE id NOT IN (SELECT cliente_id FROM venta)` **no devuelve nada** si la subconsulta contiene aunque sea un `NULL`. `NOT EXISTS` no tiene este problema.

**Funciones portables:** `COALESCE`, `CONCAT`, `EXTRACT(YEAR FROM fecha)`, `CASE`. Usar SQL estándar cuando resuelve el problema; las funciones propias del motor, solo si aportan valor.

## 3.4 JOIN: decidir qué filas sobreviven

| Operación | Conserva | Ejemplo de uso |
| :--- | :--- | :--- |
| `INNER JOIN` | Solo las filas con pareja en ambas tablas. | Ventas con los datos de su cliente. |
| `LEFT JOIN` | Todas las filas de la izquierda, aunque no tengan pareja (completa con `NULL`). | Todos los clientes con su total, **incluso los que tienen 0**. |
| **Semi-join** (`EXISTS`) | Filas de la izquierda que tienen **al menos una** pareja, **sin duplicarlas**. | Clientes con alguna venta mayor a 100.000. |
| **Anti-join** (`NOT EXISTS`) | Filas de la izquierda **sin** pareja. | Clientes que nunca compraron. |

> ⚠️ **Trampa:** con `LEFT JOIN venta v` y después `WHERE v.fecha >= '2026-01-01'`, los clientes sin ventas desaparecen: el `LEFT` se convirtió en `INNER`. La condición sobre la tabla derecha va en el **`ON`**.

## 3.5 Subconsulta, JOIN o EXISTS

El mismo requerimiento, *"clientes con al menos una venta mayor a 100.000"*, escrito de tres formas:

```sql
-- 1. Subconsulta (IN)
SELECT cliente_id, nombre FROM cliente
WHERE cliente_id IN (SELECT cliente_id FROM venta WHERE total > 100000);

-- 2. JOIN: devuelve un cliente repetido por cada venta que cumple (hace falta DISTINCT)
SELECT DISTINCT c.cliente_id, c.nombre
FROM cliente c JOIN venta v ON v.cliente_id = c.cliente_id
WHERE v.total > 100000;

-- 3. EXISTS: pregunta por existencia, no por cantidad
SELECT c.cliente_id, c.nombre FROM cliente c
WHERE EXISTS (SELECT 1 FROM venta v
              WHERE v.cliente_id = c.cliente_id AND v.total > 100000);
```

| Forma | Natural cuando... | Cuidado |
| :--- | :--- | :--- |
| Subconsulta | La consulta interna produce un conjunto o un valor que alimenta a la externa. | `NOT IN` con nulos. |
| JOIN | Hacen falta **columnas de ambas** tablas. | Multiplica filas (1 a N): puede requerir `DISTINCT` o agregación. |
| EXISTS | Solo importa **si existe** al menos una fila relacionada. | No trae columnas de la tabla interna. |

> Los optimizadores modernos suelen transformar las tres en planes equivalentes (semi-join). La elección se defiende por **intención, legibilidad y evidencia (plan)**, no por mito.

## 3.6 Funciones de ventana: agregar sin perder detalle

`GROUP BY` **reduce** filas: cuatro ventas pasan a ser dos filas, una por cliente. Las funciones de ventana **conservan cada fila** y agregan una columna con un cálculo sobre las filas relacionadas.

> `GROUP BY` resume; `OVER()` agrega contexto analítico a cada fila.

### Anatomía de `OVER()`

```sql
SUM(total) OVER (
    PARTITION BY cliente_id           -- 1. el grupo (se reinicia por cliente)
    ORDER BY fecha, venta_id          -- 2. la secuencia dentro del grupo
    ROWS BETWEEN UNBOUNDED PRECEDING  -- 3. el marco (frame): desde el inicio...
         AND CURRENT ROW              --    ...hasta la fila actual
) AS acumulado
```

| Parte | Define | Si se omite |
| :--- | :--- | :--- |
| `PARTITION BY` | Qué filas forman el grupo. | Toda la consulta es un solo grupo. |
| `ORDER BY` | El orden dentro del grupo. | Sin orden: la función ve toda la partición. |
| `ROWS` / `RANGE` | El marco de filas sobre el que se calcula. | Con `ORDER BY`, el marco por defecto es **`RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`**. |

> ⚠️ **Trampa del marco por defecto:** con `RANGE`, las filas **empatadas** en el `ORDER BY` se suman juntas. Si dos ventas tienen la misma fecha, ambas muestran el mismo acumulado. Solución: `ROWS` + un **segundo criterio de orden** (`venta_id`).

### Familias de funciones de ventana

| Familia | Funciones | Uso típico |
| :--- | :--- | :--- |
| Ranking | `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE(n)` | Top N, posiciones, cuartiles. |
| Agregadas | `SUM`, `AVG`, `COUNT`, `MIN`, `MAX` con `OVER` | Acumulados, promedios móviles, porcentaje sobre el total. |
| Desplazamiento | `LAG`, `LEAD` | Comparar con la fila anterior o la siguiente (variación mes a mes). |
| Valor | `FIRST_VALUE`, `LAST_VALUE` | Primer o último valor del marco. |

### Ranking: elegir qué significa un empate

| Cliente | Total | `ROW_NUMBER` | `RANK` | `DENSE_RANK` |
| :--- | ---: | :---: | :---: | :---: |
| A | 300 | 1 | 1 | 1 |
| B | 200 | 2 | 2 | 2 |
| C | 200 | 3 | 2 | 2 |
| D | 100 | 4 | **4** | **3** |

- `ROW_NUMBER`: siempre números distintos (el empate se rompe arbitrariamente si no hay desempate).
- `RANK`: comparte la posición y **deja huecos**.
- `DENSE_RANK`: comparte la posición **sin huecos**.

> La función correcta depende de la **semántica del ranking**, no de la sintaxis.

### Ejemplos

**Acumulado mensual por cliente, conservando cada venta:**

```sql
SELECT v.venta_id, v.cliente_id, v.fecha, v.total,
       SUM(v.total) OVER (
           PARTITION BY v.cliente_id, EXTRACT(YEAR FROM v.fecha), EXTRACT(MONTH FROM v.fecha)
           ORDER BY v.fecha, v.venta_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS acumulado_mes
FROM venta v;
```

Si la partición es solo `cliente_id`, el acumulado **no se reinicia cada mes**. Si falta la partición, el acumulado de un cliente arranca con el del cliente anterior.

**Variación respecto de la venta anterior:**

```sql
SELECT cliente_id, fecha, total,
       total - LAG(total) OVER (PARTITION BY cliente_id ORDER BY fecha, venta_id) AS variacion
FROM venta;
```

**Porcentaje de cada venta sobre el total del cliente (sin subconsulta):**

```sql
SELECT venta_id, cliente_id, total,
       ROUND(100 * total / SUM(total) OVER (PARTITION BY cliente_id), 2) AS pct
FROM venta;
```

## 3.7 Patrón "la última fila de cada grupo": alternativas

| # | Técnica | Motores | Empates | Comentario |
| :--- | :--- | :--- | :--- | :--- |
| 1 | CTE + `ROW_NUMBER()` y filtro `rn = 1` | Ambos | Una fila (con desempate explícito) | **La más clara y portable.** |
| 2 | CTE + `RANK()` y filtro `rn = 1` | Ambos | Todas las empatadas | Si el negocio quiere ver los empates. |
| 3 | Subconsulta correlacionada con `MAX(fecha)` | Ambos | Todas las empatadas | Puede ejecutar la subconsulta por cada fila. |
| 4 | `JOIN` contra un `GROUP BY cliente_id, MAX(fecha)` | Ambos | Todas las empatadas | Dos pasadas; clásica antes de las ventanas. |
| 5 | `DISTINCT ON (cliente_id) ... ORDER BY cliente_id, fecha DESC` | Solo PG | Una fila | Muy concisa, no portable. |
| 6 | `LATERAL (SELECT ... ORDER BY fecha DESC LIMIT 1)` | Ambos (MySQL 8.0.14+) | Una fila | Excelente con el índice `(cliente_id, fecha)`. |

```sql
WITH ventas_ordenadas AS (
    SELECT c.cliente_id, c.nombre, v.venta_id, v.fecha, v.total,
           ROW_NUMBER() OVER (PARTITION BY c.cliente_id
                              ORDER BY v.fecha DESC, v.venta_id DESC) AS rn
    FROM cliente c
    JOIN venta v ON v.cliente_id = c.cliente_id
)
SELECT * FROM ventas_ordenadas WHERE rn = 1;
```

Para incluir clientes **sin ventas** se usa `LEFT JOIN`: esos clientes aparecen con `rn = 1` y los datos de la venta en `NULL`.

## 3.8 CTE: poner nombre a cada etapa

Una *Common Table Expression* (`WITH nombre AS (...)`) **dura lo que dura la sentencia**: organiza el razonamiento, **no crea una tabla persistente**.

**Ejemplo: totalizar primero y rankear después**

```sql
WITH totales AS (                                   -- Etapa 1: total por cliente
    SELECT c.cliente_id, c.segmento, COALESCE(SUM(v.total), 0) AS total_vendido
    FROM cliente c LEFT JOIN venta v ON v.cliente_id = c.cliente_id
    GROUP BY c.cliente_id, c.segmento
)
SELECT cliente_id, segmento, total_vendido,        -- Etapa 2: ranking por segmento
       DENSE_RANK() OVER (PARTITION BY segmento ORDER BY total_vendido DESC) AS posicion
FROM totales;
```

| | Subconsulta derivada | CTE |
| :--- | :--- | :--- |
| Legibilidad | Anidada, se lee de adentro hacia afuera. | Secuencial, con nombre. |
| Reutilización en la misma consulta | Hay que repetirla. | Se referencia varias veces. |
| Recursividad | ✗ | ✓ (`WITH RECURSIVE`) |
| Rendimiento | El optimizador puede fusionarla. | **Depende del motor**: PostgreSQL 12+ la integra en la consulta (salvo `MATERIALIZED`); MySQL puede fusionarla o materializarla. |

> **No asumir que una CTE "siempre es más rápida":** revisar el plan cuando el rendimiento importa.

## 3.9 CTE recursiva: jerarquías de profundidad desconocida

**Problema:** con self-joins, cada nivel del árbol necesita un `JOIN` más. Si no se conoce la profundidad, no se sabe cuántos escribir.

**Anatomía:**

| Parte | Qué hace |
| :--- | :--- |
| **Ancla** | Filas iniciales, por ejemplo los nodos raíz (`responsable_id IS NULL`). |
| `UNION ALL` | Combina lo ya encontrado con el nivel siguiente. |
| **Paso recursivo** | Busca los hijos de las filas de la iteración anterior (`JOIN` con la propia CTE). |
| **Terminación** | Implícita: termina cuando una iteración **no produce filas nuevas**. |

```sql
WITH RECURSIVE jerarquia AS (
    SELECT cliente_id, nombre, responsable_id, 0 AS nivel,
           CAST(nombre AS CHAR(500)) AS ruta          -- MySQL. En PG: nombre::text
    FROM cliente
    WHERE responsable_id IS NULL                       -- ancla
    UNION ALL
    SELECT c.cliente_id, c.nombre, c.responsable_id, j.nivel + 1,
           CONCAT(j.ruta, ' > ', c.nombre)            -- PG: j.ruta || ' > ' || c.nombre
    FROM cliente c
    JOIN jerarquia j ON c.responsable_id = j.cliente_id  -- paso recursivo
)
SELECT * FROM jerarquia ORDER BY ruta;
```

**Diferencias y cuidados:**
- **MySQL:** el tipo de cada columna lo fija el **ancla**. Si la ruta crece, se trunca o da error: por eso se usa `CAST(... AS CHAR(n))`. La profundidad máxima es `cte_max_recursion_depth`, 1000 por defecto.
- **PostgreSQL:** hace falta que los tipos coincidan (`::text`). Desde la versión 14 existen `SEARCH` y `CYCLE` para ordenar y **detectar ciclos**.
- **Ciclos en los datos** (A es responsable de B y B de A): la recursión no termina. Hay que cortarla con un límite de nivel o controlando la ruta (`WHERE ruta NOT LIKE ...`, o `CYCLE` en PG).
- En el plan de MySQL aparece `Materialize recursive CTE` → `Repeat until convergence`.

**¿Cuándo usarla?**

| Tiene sentido | No necesariamente |
| :--- | :--- |
| Organigramas, categorías y subcategorías, lista de materiales (BOM), dependencias, árboles de permisos, profundidad variable | Profundidad conocida y muy chica (1 o 2 self-joins alcanzan), datos que conviene precalcular |

**Alternativas de modelado de jerarquías:**

| Modelo | Idea | Lectura | Escritura |
| :--- | :--- | :--- | :--- |
| **Lista de adyacencia** (`responsable_id`) | Cada nodo apunta a su padre. | Necesita recursión. | Muy simple. |
| **Camino materializado** (`'/1/4/9/'`) | Guarda la ruta completa. | `LIKE '/1/4/%'` | Mover un subárbol obliga a actualizar muchas filas. |
| **Tabla de cierre** | Una fila por cada par (ancestro, descendiente, distancia). | Muy rápida. | Más espacio y mantenimiento. |

## 3.10 Carga masiva: fila por fila vs por lote

| | 20.000 `INSERT` individuales | Operación por lote |
| :--- | :--- | :--- |
| Interacciones | 20.000 idas y vueltas aplicación → motor | Una o pocas |
| Costo por fila | Alto: red, parseo, commit por fila (con autocommit) | Bajo |
| Herramienta | — | MySQL: `LOAD DATA [LOCAL] INFILE` · PG: `COPY` / `\copy` |

```sql
-- MySQL
LOAD DATA LOCAL INFILE 'ventas.csv' INTO TABLE venta
FIELDS TERMINATED BY ',' IGNORE 1 LINES;
-- PostgreSQL
COPY venta FROM '/ruta/ventas.csv' WITH (FORMAT csv, HEADER true);
```

Otras mejoras: `INSERT` con varias filas por sentencia (`VALUES (...), (...), ...`) y **agrupar en una transacción** en lugar de un commit por fila. Antes de cargar hay que definir formato, tipos, manejo de errores, transacción y **validación posterior** (conteos y sumas).

## Preguntas de repaso · Unidad 3

1. ¿Por qué `WHERE ROW_NUMBER() OVER (...) = 1` da error? ¿Cómo se resuelve?
2. Tenés dos ventas del mismo cliente con la misma fecha. ¿Qué devuelven `ROW_NUMBER`, `RANK` y `DENSE_RANK`? ¿Cuál elegirías para "la última venta" y por qué?
3. ¿Qué diferencia hay entre `ROWS` y `RANGE` en un acumulado?
4. ¿Por qué `NOT IN` puede devolver cero filas, y `NOT EXISTS` no?
5. Escribí "clientes que nunca compraron" de dos formas distintas.
6. ¿Qué pasa si una jerarquía tiene un ciclo y usás una CTE recursiva sin protección?
7. ¿Una CTE es siempre más rápida que una subconsulta? ¿Cómo lo verificarías?

---

# Unidad 4 · Programabilidad y evolución del esquema

## 4.1 ¿Dónde debería vivir la regla de negocio?

| Ubicación | Conviene para | Riesgo |
| :--- | :--- | :--- |
| **Aplicación** | Experiencia de usuario (validar un formulario al instante), reglas propias de un canal. | Se duplica en cada canal. Si alguien entra por consola o por otra app, la saltea. |
| **Capa media / servicios** | Reglas compartidas por varios canales, orquestación de procesos. | ¿Qué pasa si alguien accede por fuera del servicio? |
| **Base de datos** | **Integridad que debe cumplirse siempre**, reglas cercanas al dato. | Acoplamiento al motor, lógica "escondida", portabilidad. |

**Respuesta de defensa típica:** las reglas críticas de integridad, como un saldo que no puede ser negativo, van **en la base como última línea de defensa**, *y además* en la aplicación para dar una buena experiencia de usuario. Es **defensa en profundidad**: la aplicación valida para el usuario y la base garantiza para el sistema.

## 4.2 Mapa de mecanismos: del más simple al más complejo

| Necesidad | Mecanismo | Pregunta guía |
| :--- | :--- | :--- |
| Validar una regla simple sobre una fila | `NOT NULL`, `UNIQUE`, `PK`, `FK`, `CHECK`, `DEFAULT` | ¿Se puede expresar **declarativamente**? |
| Calcular y reutilizar un valor | **Función** almacenada | ¿Se usa **dentro de consultas**? |
| Ejecutar un proceso explícito de varios pasos | **Procedimiento** almacenado | ¿Es una operación que alguien **invoca**? |
| Reaccionar automáticamente a un cambio | **Trigger** | ¿Debe ocurrir **siempre** ante `INSERT`/`UPDATE`/`DELETE`? |
| Cambiar la estructura | **Migración** de esquema | ¿Cómo evoluciono sin perder datos? |

> **Poder hacerlo con un trigger no significa que debamos hacerlo con un trigger.** La regla más simple se implementa con el mecanismo más simple que la garantice.

## 4.3 Integridad declarativa (constraints)

```sql
ALTER TABLE cuenta ADD CONSTRAINT chk_saldo_no_negativo CHECK (saldo >= 0);
ALTER TABLE producto ADD CONSTRAINT chk_precio_positivo CHECK (precio > 0);
```

| Caso | Valor | Resultado esperado |
| :--- | :--- | :--- |
| Válido | `saldo = 1000` | ✓ acepta |
| **Límite** | `saldo = 0` | ✓ acepta (la regla dice "no negativo") |
| Inválido | `saldo = -1` | ✗ rechaza: MySQL `ERROR 3819 Check constraint ... is violated`; PG `violates check constraint` (SQLSTATE 23514) |

**Ventajas frente a un trigger:** lo evalúa el motor de forma nativa, no hay código que mantener, es visible en el catálogo y no se puede "olvidar" en ninguna ruta de escritura.

| Constraint | Garantiza |
| :--- | :--- |
| `PRIMARY KEY` | Identidad única y no nula. |
| `UNIQUE` | No hay duplicados (por ejemplo, `nro_cuenta`). |
| `FOREIGN KEY` | Integridad referencial. Las acciones `ON DELETE RESTRICT/CASCADE/SET NULL` definen qué pasa con los hijos. |
| `CHECK` | Condición sobre la fila (dominio). |
| `NOT NULL` / `DEFAULT` | Presencia y valor inicial. |

> **MySQL:** los `CHECK` se **aplican** recién desde la versión **8.0.16**. En versiones anteriores se aceptaban en la sintaxis pero se ignoraban. Un `CHECK` solo ve **la fila**: no puede consultar otras tablas. Para eso hace falta un trigger o una FK.

> ⚠️ **Un `CHECK` deja pasar `NULL`.** La fila se rechaza solo si la condición da **FALSE**. Con `precio = NULL`, `precio > 0` da UNKNOWN y la fila **se acepta**. Para rechazar nulos hace falta `NOT NULL` en la columna.

## 4.4 Funciones almacenadas

**Semántica: devuelven un valor** y se pueden usar como expresión dentro de un `SELECT`, un `WHERE`, etc.

**Ejemplo: clasificar un cliente por su total anual** (Bronce < 2M, Plata entre 2M y 50M, Oro > 50M). La función **recibe el cliente y el año, y calcula el total ella misma**.

```sql
-- MySQL
DELIMITER //
CREATE FUNCTION clasificar_cliente(p_cliente_id INT, p_anio INT)
RETURNS VARCHAR(10)
NOT DETERMINISTIC READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(14,2);
  SELECT COALESCE(SUM(total), 0) INTO v_total      -- COALESCE: cliente sin ventas → 0 → Bronce
  FROM venta
  WHERE cliente_id = p_cliente_id
    AND fecha >= MAKEDATE(p_anio, 1) AND fecha < MAKEDATE(p_anio + 1, 1);  -- rango: aprovecha índices
  RETURN CASE WHEN v_total > 50000000 THEN 'Oro'
              WHEN v_total >= 2000000 THEN 'Plata'
              ELSE 'Bronce' END;
END //
DELIMITER ;
```

```sql
-- PostgreSQL
CREATE FUNCTION clasificar_cliente(p_cliente_id int, p_anio int)
RETURNS varchar LANGUAGE plpgsql STABLE AS $$
DECLARE v_total numeric;
BEGIN
  SELECT COALESCE(SUM(total), 0) INTO v_total
  FROM venta
  WHERE cliente_id = p_cliente_id
    AND fecha >= make_date(p_anio, 1, 1) AND fecha < make_date(p_anio + 1, 1, 1);
  RETURN CASE WHEN v_total > 50000000 THEN 'Oro'
              WHEN v_total >= 2000000 THEN 'Plata'
              ELSE 'Bronce' END;
END $$;

SELECT nombre, clasificar_cliente(cliente_id, 2026) FROM cliente;
```

**Características que conviene declarar bien:**

| MySQL | PostgreSQL | Significado |
| :--- | :--- | :--- |
| `DETERMINISTIC` | `IMMUTABLE` | Mismos parámetros → siempre el mismo resultado, **sin leer tablas**. |
| `NOT DETERMINISTIC READS SQL DATA` | `STABLE` | Lee tablas: el resultado puede cambiar entre sentencias. |
| `MODIFIES SQL DATA` | `VOLATILE` (por defecto) | Puede tener efectos secundarios. |

> ⚠️ Declarar `DETERMINISTIC` una función que lee tablas "funciona", pero le **miente** al motor y puede dar resultados incorrectos con caché o réplica. En MySQL con binlog activo, si no se declara ninguna característica aparece el **error 1418**.

**Alternativa de rendimiento:** llamar a una función por cada fila ejecuta una consulta interna por fila (problema N+1). Para un reporte masivo suele ser mejor una **CTE que agregue una sola vez + `CASE`**:

```sql
WITH totales AS (
  SELECT cliente_id, SUM(total) AS t FROM venta
  WHERE fecha >= '2026-01-01' AND fecha < '2027-01-01' GROUP BY cliente_id)
SELECT c.nombre,
       CASE WHEN COALESCE(t.t,0) > 50000000 THEN 'Oro'
            WHEN COALESCE(t.t,0) >= 2000000 THEN 'Plata' ELSE 'Bronce' END AS categoria
FROM cliente c LEFT JOIN totales t ON t.cliente_id = c.cliente_id;
```

La función gana en **reutilización y centralización de la regla**; la CTE gana en **rendimiento para lotes grandes**.

## 4.5 Procedimientos almacenados

**Semántica: ejecutar un proceso.** Se invocan explícitamente con `CALL`, pueden tener parámetros `IN`/`OUT`, coordinar varios pasos y modificar datos.

```sql
-- MySQL
DELIMITER //
CREATE PROCEDURE cambiar_estado_pedido(IN p_pedido_id INT, IN p_estado VARCHAR(12))
BEGIN
  UPDATE pedido SET estado = p_estado WHERE pedido_id = p_pedido_id;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido inexistente';
  END IF;
END //
DELIMITER ;
CALL cambiar_estado_pedido(10, 'pagado');
```

```sql
-- PostgreSQL (11+)
CREATE PROCEDURE cambiar_estado_pedido(p_pedido_id int, p_estado varchar)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE pedido SET estado = p_estado WHERE pedido_id = p_pedido_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido % inexistente', p_pedido_id;
  END IF;
END $$;
CALL cambiar_estado_pedido(10, 'pagado');
```

### Función vs procedimiento

| | Función | Procedimiento |
| :--- | :--- | :--- |
| Semántica | **Valor** | **Proceso** |
| Invocación | Dentro de una expresión (`SELECT f(x)`) | `CALL p(x)` |
| Devuelve | Un valor (o una tabla, en PG) | Nada, o parámetros `OUT` |
| Modifica datos | Conviene que no (pequeña y predecible) | Sí, es su uso natural |
| Control de transacción | ✗ | PG: puede hacer `COMMIT` adentro. MySQL: puede usar `START TRANSACTION`/`COMMIT` |

**Conceptos comunes de la programación en el motor:** parámetros, variables locales, `IF`/`CASE`, sentencias SQL, **manejo de errores** (MySQL: `SIGNAL`, `DECLARE ... HANDLER`; PG: `RAISE`, `EXCEPTION WHEN`) y **transacción** (coherencia del proceso).

## 4.6 Triggers: reacción automática

**Evento → condición → acción.** El trigger no se llama: el motor lo ejecuta cuando ocurre el evento, **dentro de la misma transacción** que lo causó. Si el trigger falla, la operación original también falla.

| Evento | `OLD` | `NEW` |
| :--- | :---: | :---: |
| `INSERT` | — | ✓ |
| `UPDATE` | ✓ | ✓ |
| `DELETE` | ✓ | — |

| Momento | Útil para |
| :--- | :--- |
| `BEFORE` | Validar o **transformar** `NEW` antes de persistir, como normalizar un texto o completar un valor. |
| `AFTER` | **Registrar o reaccionar** una vez aplicado el cambio: auditoría. |

### Ejemplo: auditoría de cambios de precio

```sql
-- MySQL: la lógica va dentro del trigger
DELIMITER //
CREATE TRIGGER trg_precio_aud AFTER UPDATE ON producto
FOR EACH ROW
BEGIN
  IF NOT (OLD.precio <=> NEW.precio) THEN          -- <=> compara bien aunque haya NULL
    INSERT INTO auditoria_precio (producto_id, precio_anterior, precio_nuevo)
    VALUES (OLD.producto_id, OLD.precio, NEW.precio);
  END IF;
END //
DELIMITER ;
```

```sql
-- PostgreSQL: el trigger invoca una función de tipo trigger
CREATE FUNCTION fn_precio_aud() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.precio IS DISTINCT FROM NEW.precio THEN
    INSERT INTO auditoria_precio (producto_id, precio_anterior, precio_nuevo)
    VALUES (OLD.producto_id, OLD.precio, NEW.precio);
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_precio_aud AFTER UPDATE ON producto
FOR EACH ROW EXECUTE FUNCTION fn_precio_aud();
```

> ⚠️ `OLD.precio <> NEW.precio` da **UNKNOWN** si alguno de los dos es `NULL`, y el cambio no se audita. Hay que usar `IS DISTINCT FROM` (PG) o `NOT (a <=> b)` (MySQL).

| Diferencia | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Dónde va la lógica | Dentro del trigger | En una función `RETURNS trigger` |
| Nivel | Solo `FOR EACH ROW` | `FOR EACH ROW` y `FOR EACH STATEMENT` (con tablas de transición) |
| Modificar la misma tabla desde su trigger | ✗ (error 1442) | Posible (cuidado con la recursión) |
| Cancelar la operación | `SIGNAL SQLSTATE '45000'` | `RAISE EXCEPTION`, o `RETURN NULL` en un `BEFORE` |

**Riesgos de los triggers:** lógica "invisible" para quien lee la aplicación, efectos en cascada (trigger que dispara otro trigger), costo en cada fila modificada y depuración más difícil. **Uso ideal:** auditoría, mantener datos derivados, reglas que involucran **otras tablas** (lo que un `CHECK` no puede).

## 4.7 Tabla de decisión: ¿qué mecanismo uso?

| Caso | Mecanismo preferido | Por qué no otro |
| :--- | :--- | :--- |
| Saldo ≥ 0 | `CHECK` | Un trigger funcionaría, pero es más complejo, más lento y más fácil de romper. |
| Auditar un cambio de precio | Trigger `AFTER UPDATE` | Tiene que ocurrir siempre, sin que la app lo recuerde, y necesita `OLD`/`NEW`. |
| Clasificar un cliente (Oro/Plata/Bronce) | Función | Devuelve un valor que se reutiliza en consultas. Un procedimiento no se puede usar en un `SELECT`. |
| Transferir dinero (debitar + acreditar + registrar) | Procedimiento + transacción | Es un proceso explícito de varios pasos que debe ser atómico. |
| Estado de un pedido dentro de un conjunto | `CHECK (estado IN (...))`, `ENUM` o FK a una tabla de estados | Ver [4.9](#tres-formas-de-restringir-un-conjunto-de-valores). |
| El total de un pedido = suma de sus ítems | Trigger o cálculo al consultar (vista) | Involucra otra tabla: un `CHECK` no alcanza. |

## 4.8 Sintaxis MySQL vs PostgreSQL (programabilidad)

| Aspecto | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Delimitador del cuerpo | `DELIMITER // ... END //` (cliente) | `$$ ... $$` |
| Lenguaje | SQL/PSM implícito | `LANGUAGE plpgsql` (o `sql`) |
| Lanzar un error | `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '...'` | `RAISE EXCEPTION '...'` |
| Capturar errores | `DECLARE CONTINUE/EXIT HANDLER FOR ...` | `BEGIN ... EXCEPTION WHEN ... THEN ... END` |
| Filas afectadas | `ROW_COUNT()` | `FOUND` / `GET DIAGNOSTICS` |
| Trigger | Cuerpo propio | `EXECUTE FUNCTION f()` |
| Comparación segura con NULL | `<=>` | `IS [NOT] DISTINCT FROM` |
| Reemplazar | `DROP ... IF EXISTS` + `CREATE` | `CREATE OR REPLACE` |

## 4.9 Migraciones: una base de datos también tiene versiones

**Escenario:** la v1 está en producción con datos y hay que liberar la v2 **sin borrar ni recrear la base**. No vale un `DROP DATABASE` + `CREATE` final: hay que **demostrar la evolución**.

### Secuencia segura para una columna nueva (expandir → contraer)

| Paso | Acción | Ejemplo |
| :--- | :--- | :--- |
| 1. **Expandir** | Agregar la estructura sin romper lo existente | `ALTER TABLE pedido ADD COLUMN estado VARCHAR(12) NULL;` |
| 2. **Completar** (*backfill*) | Rellenar los históricos | `UPDATE pedido SET estado = 'pendiente' WHERE estado IS NULL;` |
| 3. **Validar** | Comparar v1 con v2: conteos, sumas, nulos | `SELECT COUNT(*) ... WHERE estado IS NULL;` → 0 |
| 4. **Endurecer** | Agregar las restricciones | `NOT NULL` + `CHECK` |
| 5. **Programar** | Habilitar triggers y funciones nuevos | Auditoría de cambios de estado |

Atajo común: `ADD COLUMN estado ... NOT NULL DEFAULT 'pendiente'` hace los pasos 1, 2 y 4 juntos (los históricos toman el `DEFAULT`). En tablas enormes, la secuencia en pasos evita bloqueos largos.

### Tres formas de restringir un conjunto de valores

| Opción | Ventaja | Desventaja |
| :--- | :--- | :--- |
| `ENUM('pendiente', 'pagado', ...)` (MySQL; en PG, `CREATE TYPE ... AS ENUM`) | Compacto y autodocumentado. | Agregar o quitar un valor requiere DDL. Ordena por posición, no alfabéticamente. Es **integridad de dominio**, no referencial. |
| `VARCHAR` + `CHECK (estado IN (...))` | Portable y claro. | Cambiar la lista requiere DDL. |
| **Tabla de estados + FK** | Los valores son datos: se agregan sin DDL, admiten atributos (descripción, orden, activo). | Un join más (normalmente despreciable). |

> En MySQL sin modo estricto, un valor inválido en un `ENUM` puede guardarse como `''` con una advertencia en lugar de dar error. Con modo estricto da `ERROR 1265 Data truncated`.

## 4.10 Rollback de migraciones: avanzar suele ser seguro, retroceder es destructivo

| Cambio v2 | ¿Se puede revertir sin pérdida? |
| :--- | :--- |
| `CREATE TABLE auditoria` | Sí, pero `DROP TABLE` pierde la auditoría generada en v2. |
| `ADD COLUMN estado` | **No:** `DROP COLUMN estado` destruye los estados cargados durante la v2. |
| `ADD CONSTRAINT CHECK` | Sí (`DROP CONSTRAINT`). |
| Crear un trigger o una función | Sí (`DROP`). |
| Achicar un tipo (`VARCHAR(100)` → `VARCHAR(20)`) | Puede truncar datos. |

**Mitigaciones:**
- **Backup antes** de migrar y antes del rollback.
- Copiar los datos nuevos a una tabla de archivo antes de hacer `DROP COLUMN`.
- Preferir ***forward fix*** (corregir con una v2.1) antes que volver a v1.
- Rollback "blando": dejar la columna, desactivar la lógica y limpiar más tarde.

### DDL transaccional: diferencia clave entre motores

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| `ALTER`/`CREATE` dentro de una transacción | Provoca un **commit implícito**: no se puede deshacer con `ROLLBACK`. | Es **transaccional**: toda la migración puede ir entre `BEGIN ... COMMIT` y revertirse completa si algo falla. |
| Consecuencia | Una migración que falla a la mitad deja la base en un estado intermedio: cada paso debe ser idempotente o tener su reverso. | La migración es "todo o nada" (salvo excepciones como `CREATE INDEX CONCURRENTLY`). |

## 4.11 Scripts versionados y CI/CD

```
V001__modelo_inicial.sql
V002__estado_pedido.sql
V003__auditoria_estado.sql
V004__funcion_total_cliente.sql
```

| Principio | Significa |
| :--- | :--- |
| **Orden** | La versión indica qué cambio va antes. |
| **Trazabilidad** | Cada script explica qué cambió y cuándo (con control de versiones). |
| **Repetibilidad** | El despliegue da el mismo resultado en desarrollo, prueba y producción. |
| **Automatización** | Herramientas como **Flyway** o **Liquibase** registran qué versiones se aplicaron. |

Pipeline típico: *crear la base de prueba → aplicar migraciones → correr las pruebas (válido, inválido, límite, continuidad de datos) → recién entonces desplegar*. **CI/CD no elimina el riesgo: hace repetibles las validaciones y el despliegue.**

### Cómo probar una migración

- **Continuidad:** los datos de v1 siguen existiendo (conteos y sumas iguales antes y después).
- **Nueva funcionalidad:** los estados nuevos funcionan, la auditoría registra cambios.
- **Restricciones:** los datos inválidos se rechazan con el error esperado.
- **Reversibilidad:** el rollback se ejecutó en un entorno de prueba y se documentó qué se pierde.

## Preguntas de repaso · Unidad 4

1. "Una cuenta no puede quedar con saldo negativo": ¿dónde implementarías la regla? ¿Base, aplicación o ambas? Justificá por riesgo y mantenibilidad.
2. ¿Por qué un `CHECK` es preferible a un trigger para validar `saldo >= 0`? ¿Qué regla **no** podría resolver un `CHECK`?
3. ¿Por qué la clasificación de clientes se implementa como función y no como procedimiento?
4. En un trigger de auditoría, ¿qué problema tiene `IF OLD.precio <> NEW.precio`?
5. ¿Qué datos se pierden si hacés rollback de una v2 que agregó una columna `estado`? ¿Cómo lo mitigarías?
6. ¿Qué ventaja tiene PostgreSQL sobre MySQL al ejecutar una migración que falla a la mitad?
7. Compará `ENUM`, `CHECK IN (...)` y tabla de estados con FK.

---

# Unidad 5 · Conectividad, transacciones y concurrencia

## 5.1 Del motor aislado al servidor compartido

> Una base multiusuario no se administra mirando solo SQL: hay que entender **la ruta de conexión, el estado del motor y las interacciones entre sesiones**.

**Una conexión remota es una ruta completa:**

```
Cliente (Workbench / pgAdmin / app) → Red (IP, ruta, firewall) → VM → Puerto → Motor (listener) → Autenticación → Base
```

### Checklist de conexión remota

1. La VM está encendida.
2. El servicio del SGBD está activo (`systemctl status mysql` / `postgresql`).
3. La IP es correcta y alcanzable (`ip addr` en la VM, `ping` desde otra PC).
4. El puerto está abierto (firewall: `ufw allow 3306/tcp` o `5432/tcp`).
5. **El motor escucha en la interfaz externa**, no solo en `127.0.0.1` (`ss -lntp`).
6. El usuario remoto está habilitado para conectarse desde ese origen.
7. La base existe y el usuario tiene permisos sobre ella.
8. El cliente apunta al host, puerto, usuario y base correctos.

### Configuración por motor

| Paso | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Puerto por defecto | 3306 | 5432 |
| Escuchar en la red | `bind-address = 0.0.0.0` en `mysqld.cnf` (reiniciar) | `listen_addresses = '*'` en `postgresql.conf` (reiniciar) |
| Quién puede conectarse | El usuario se define **con el host**: `'alumno'@'%'` o `'alumno'@'192.168.1.%'` | Archivo `pg_hba.conf`: `host  base  usuario  192.168.1.0/24  scram-sha-256` (recargar) |
| Verificar | `sudo ss -lntp \| grep 3306` → `0.0.0.0:3306` | `sudo ss -lntp \| grep 5432` |

### Diagnóstico por mensaje de error

| Síntoma | Capa probable | Qué revisar |
| :--- | :--- | :--- |
| *Connection refused* | El motor no escucha en esa interfaz, o el servicio está caído | `bind-address`/`listen_addresses`, servicio |
| *Timeout* (se queda esperando) | Red o firewall descartan paquetes | IP, ruta, firewall, modo de red de la VM |
| MySQL `1130 Host '...' is not allowed to connect` | El usuario no existe para ese host | `CREATE USER 'u'@'%'` |
| PG `no pg_hba.conf entry for host` | Falta la regla de acceso | `pg_hba.conf` + reload |
| MySQL `1045 Access denied` / PG `password authentication failed` | Credenciales o plugin de autenticación | Usuario y clave |
| MySQL `1049 Unknown database` / PG `database does not exist` | Cadena de conexión | Nombre de la base |

> **Distinguir conectividad de configuración del SGBD:** si `telnet ip 3306` (o `nc -zv ip 3306`) no conecta, el problema es de red o listener, no de usuario.

### Red de la máquina virtual

| Modo (VirtualBox) | Alcanzable desde otras PC | Nota |
| :--- | :--- | :--- |
| **NAT** | ✗ (salvo con **redirección de puertos** host:3306 → VM:3306) | Las otras PC se conectan a la **IP del host**. |
| **Adaptador puente** | ✓ | La VM toma una IP propia de la LAN. Tiene que estar en la misma red que el host. |
| **Solo anfitrión** (*host-only*) | ✗ (solo el host) | Útil para pruebas locales. |
| **Multipass** | Depende de la plataforma | La IP la administra Multipass (`multipass list`). Hay que verificar si es alcanzable desde la LAN. |

## 5.2 Herramientas gráficas: una ventana al motor

| Necesidad | MySQL Workbench | pgAdmin |
| :--- | :--- | :--- |
| Objetos | Navigator → Schemas | Browser (árbol de objetos) |
| Metadatos de una tabla | Table Inspector | Properties / pestaña SQL |
| Usuarios y roles | Administration → Users and Privileges | Login/Group Roles |
| Sesiones | Administration → Client Connections | Dashboard → Server activity |
| Indicadores de rendimiento | Dashboard (tráfico, CPU, buffer pool) | Dashboard (sesiones, transacciones/s, E/S de bloques) |
| Logs | Server Logs | Logs del servidor (según la configuración) |
| Plan de ejecución | Visual Explain (`Ctrl+Alt+X`) | Explain / Explain Analyze gráfico |
| Ingeniería inversa | Database → Reverse Engineer | ERD Tool |

**Ingeniería inversa:** reconstruye el modelo (ERD) **a partir de los metadatos** de una base existente. **Límite:** reconstruye la implementación, **no la intención original del diseño**. Las relaciones que no tienen FK declarada no aparecen.

> La interfaz es una herramienta de observación: **la evidencia sigue estando en el SGBD.** Cada hallazgo se documenta con el formato **¿dónde está? → ¿qué muestra? → ¿para qué le sirve al DBA? → evidencia**.

## 5.3 Primera guardia DBA: qué mirar y con qué consulta

| Aspecto | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Versión | `SELECT VERSION();` | `SELECT version();` |
| Sesiones | `SHOW PROCESSLIST;` · `performance_schema.threads` | `SELECT pid, usename, client_addr, state, query FROM pg_stat_activity;` |
| Tamaño de la base | `SELECT table_schema, SUM(data_length + index_length) FROM information_schema.tables GROUP BY 1;` | `SELECT pg_size_pretty(pg_database_size('base'));` |
| Tamaño de una tabla | `data_length`, `index_length` en `information_schema.tables` | `pg_total_relation_size('t')`, `pg_relation_size`, `pg_indexes_size` |
| Aciertos de caché | `SHOW STATUS LIKE 'Innodb_buffer_pool_read%';` | `SELECT blks_hit, blks_read FROM pg_stat_database;` |
| Conexiones máximas | `SHOW VARIABLES LIKE 'max_connections';` | `SHOW max_connections;` |
| Consultas lentas | *slow query log*, `sys.statement_analysis` | Extensión `pg_stat_statements` |

### Indicadores típicos y cómo interpretarlos

| Indicador | Qué representa | Interpretación |
| :--- | :--- | :--- |
| Uso del buffer pool / *cache hit ratio* | Qué porcentaje de lecturas se resuelve desde RAM | Alto (> 95-99 %) es bueno. Si baja mientras suben las lecturas de disco, falta memoria o hay scans masivos. |
| Conexiones activas vs máximas | Presión sobre el servidor | Cerca del máximo: revisar el pool de la aplicación o sesiones colgadas. |
| Tráfico de red | Volumen de entrada y salida | Picos inusuales: consultas que traen demasiados datos. |
| CPU del servidor | Carga de cómputo | Alto sostenido: consultas sin índice o sorts grandes. |
| Sesiones esperando locks | Contención | Muchas en espera: transacción larga o *hot spot*. |

**Si mañana el servidor tiene problemas, lo primero que se revisa:** (1) estado del servicio y recursos (CPU, RAM, disco), (2) sesiones (picos, sesiones colgadas o bloqueantes), (3) logs de error, (4) consultas más costosas, (5) caché y E/S de disco, (6) espacio libre en disco (un disco lleno detiene el motor).

## 5.4 La aplicación también es un cliente

```
Aplicación → Driver (JDBC/ODBC/.NET/ORM) → Conexión (sesión autenticada) → SQL / transacción → SGBD
```

- **Cadena de conexión:** `mysql://usuario:clave@servidor:3306/base` · `postgresql://usuario:clave@servidor:5432/base`, con parámetros de SSL y *timeout*. **No publicar credenciales** en entregas, capturas ni repositorios: separar configuración, secretos y código.
- **Pool de conexiones:** reutiliza un conjunto de conexiones, lo que reduce la latencia de abrir una por operación y evita miles de sesiones simultáneas.

| Sin pool | Con pool | Riesgo del pool |
| :--- | :--- | :--- |
| Una conexión por operación: latencia y demasiadas sesiones | Conexiones reutilizadas y controladas | Una conexión devuelta con una **transacción abierta** o con estado de sesión (variables, aislamiento) contamina al siguiente que la usa. |

> **El pool resuelve la gestión de conexiones; no resuelve por sí solo la concurrencia ni los locks.**

## 5.5 Dónde empieza y termina una transacción

| Comando | Efecto |
| :--- | :--- |
| *Autocommit* (por defecto en ambos motores) | Cada sentencia es su propia transacción y se confirma sola. |
| `START TRANSACTION` / `BEGIN` | Abre una transacción explícita. |
| `COMMIT` | Confirma los cambios y **libera los locks**. |
| `ROLLBACK` | Revierte lo no confirmado y libera los locks. |
| `SAVEPOINT s` / `ROLLBACK TO s` | Vuelve a un punto intermedio sin descartar todo. |

**Diferencias importantes:**

| Situación | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Una sentencia falla dentro de la transacción | Se revierte **esa sentencia** y la transacción sigue abierta. | La transacción queda **abortada**: *"current transaction is aborted, commands ignored until end of transaction block"*. Solo sirve `ROLLBACK` (o `ROLLBACK TO SAVEPOINT`). |
| DDL dentro de la transacción | Commit implícito | Transaccional |
| Deadlock | Revierte **toda** la transacción víctima | Aborta la transacción víctima |
| Timeout de espera de lock (error 1205) | Por defecto revierte **solo la sentencia** | Según `lock_timeout` |

## 5.6 Schedules y serializabilidad

- **Schedule:** el orden real en que se intercalan las operaciones de transacciones concurrentes.
- **Ejecución serial:** T1 completa y después T2. Es fácil de razonar, pero desaprovecha la concurrencia.
- **Schedule serializable:** intercalado, pero con un **efecto equivalente a algún orden serial**. Es el objetivo de los mecanismos de concurrencia.
- **Two-Phase Locking (2PL)**, como modelo conceptual: cada transacción tiene una fase de **crecimiento** (adquiere locks) y una de **decrecimiento** (los libera), y **no adquiere locks después de liberar alguno**. En la variante estricta, los locks se mantienen **hasta el `COMMIT`/`ROLLBACK`**, que es lo que se observa en los motores. Garantiza serializabilidad, pero **puede producir deadlocks**.

## 5.7 Anomalías de concurrencia

| Anomalía | Qué pasa | Ejemplo |
| :--- | :--- | :--- |
| **Lectura sucia** (*dirty read*) | Se leen datos **no confirmados** que después pueden revertirse. | A ve el saldo que B modificó sin confirmar; B hace `ROLLBACK`. |
| **Lectura no repetible** | La **misma fila** cambia entre dos lecturas de la misma transacción. | A lee saldo = 1000, B confirma saldo = 2000 y A vuelve a leer 2000. |
| **Fantasma** (*phantom*) | Cambia el **conjunto de filas** que cumple una condición. | A cuenta los pedidos pendientes (5), B inserta uno y A vuelve a contar (6). |
| **Actualización perdida** (*lost update*) | Dos transacciones leen el mismo valor, calculan y escriben: una **pisa** a la otra. | Ambas leen stock = 10 y escriben 9: se vendieron dos unidades pero el stock bajó una. |
| **Anomalía de serialización** (*write skew*) | El resultado no equivale a ningún orden serial, aunque ninguna fila se haya pisado. | Dos médicos de guardia se dan de baja a la vez porque cada uno ve que "queda el otro". |

## 5.8 Niveles de aislamiento

| Nivel (estándar) | Lectura sucia | No repetible | Fantasma |
| :--- | :---: | :---: | :---: |
| `READ UNCOMMITTED` | Posible | Posible | Posible |
| `READ COMMITTED` | ✗ | Posible | Posible |
| `REPEATABLE READ` | ✗ | ✗ | Posible (según el estándar) |
| `SERIALIZABLE` | ✗ | ✗ | ✗ |

**Cómo lo implementa cada motor (lo que se observa de verdad):**

| | MySQL / InnoDB | PostgreSQL |
| :--- | :--- | :--- |
| **Nivel por defecto** | **`REPEATABLE READ`** | **`READ COMMITTED`** |
| Consultarlo | `SELECT @@transaction_isolation;` | `SHOW transaction_isolation;` |
| Cambiarlo | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` | `SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;` (al inicio de la transacción) |
| `READ UNCOMMITTED` | Permite lecturas sucias | Se comporta como `READ COMMITTED` |
| `READ COMMITTED` | Snapshot nuevo **por sentencia** | Snapshot nuevo **por sentencia** |
| `REPEATABLE READ` | Snapshot fijado en la **primera lectura** de la transacción. Los fantasmas se evitan en lecturas normales (snapshot) y en lecturas con bloqueo (*next-key locks*). | Snapshot fijado al inicio de la **primera sentencia**. Si intenta modificar una fila que otra transacción cambió y confirmó, da **error de serialización** (`40001`). |
| `SERIALIZABLE` | `SELECT` normales se vuelven `SELECT ... FOR SHARE` (bloquean) | SSI: detecta dependencias peligrosas y aborta con `40001`. La aplicación debe **reintentar**. |

### El experimento de las dos lecturas

```
Sesión A: BEGIN; SELECT saldo FROM cuenta WHERE id = 3;   -- 1000
Sesión B: UPDATE cuenta SET saldo = saldo + 1000 WHERE id = 3; COMMIT;
Sesión A: SELECT saldo FROM cuenta WHERE id = 3;          -- ¿?
```

| Motor y nivel | Segunda lectura de A | Por qué |
| :--- | :--- | :--- |
| MySQL `REPEATABLE READ` (por defecto) | **1000** (igual que la primera) | Reutiliza el snapshot de la primera lectura. |
| MySQL `READ COMMITTED` | 2000 | Cada sentencia toma un snapshot nuevo. |
| PostgreSQL `READ COMMITTED` (por defecto) | **2000** (ve el cambio) | Snapshot por sentencia: lectura no repetible. |
| PostgreSQL `REPEATABLE READ` | 1000 | Snapshot de la transacción. |

> **No se memorizan los defaults: se relaciona la configuración con la evidencia observada.** Siempre se empieza consultando el nivel real de la sesión.

> **Detalle MySQL:** si A hace `SELECT ... FOR UPDATE` en lugar de un `SELECT` normal, lee **la versión más reciente confirmada** (*locking read*), no el snapshot. Las lecturas con bloqueo no usan MVCC.

## 5.9 MVCC y locks

| MVCC (control de concurrencia multiversión) | Locks |
| :--- | :--- |
| Mantiene **versiones** de las filas para que cada transacción lea un snapshot consistente. | Protegen las modificaciones y las operaciones que requieren exclusión. |
| **Los lectores no bloquean a los escritores y los escritores no bloquean a los lectores.** | Dos `UPDATE` sobre la **misma fila**: el segundo **espera**. |
| InnoDB: versiones anteriores reconstruidas desde el **undo log**. PG: varias versiones de la fila en la tabla (`xmin`/`xmax`), que después `VACUUM` limpia. | MVCC reduce los conflictos de lectura, **no elimina los locks de escritura**. |

### Compatibilidad de locks (modelo conceptual)

| Pedido \ Existente | Compartido (S) | Exclusivo (X) |
| :--- | :---: | :---: |
| **Compartido (S)** | ✓ | ✗ espera |
| **Exclusivo (X)** | ✗ espera | ✗ espera |

- **S (lectura con bloqueo):** `SELECT ... FOR SHARE`.
- **X (modificación):** `UPDATE`, `DELETE` y `SELECT ... FOR UPDATE`.

### Granularidad y duración

| Granularidad | Efecto |
| :--- | :--- |
| **Fila / registro** | Conflicto fino, más concurrencia. |
| **Rango / gap** (InnoDB, next-key) | Protege un intervalo para evitar fantasmas; puede bloquear inserciones dentro del rango. |
| **Tabla / objeto** | Impacto amplio (`LOCK TABLES`, DDL, *metadata locks*). |
| **Duración** | Los locks se liberan con `COMMIT`/`ROLLBACK`: **una transacción larga amplía la ventana de conflicto.** |

> ⚠️ **InnoDB bloquea las filas que recorre, no solo las que modifica.** Un `UPDATE ... WHERE columna_sin_indice = X` recorre toda la tabla y puede **bloquear todas las filas**. Un índice adecuado también **reduce la contención**.

### Soluciones a la actualización perdida

| Técnica | Cómo | Cuándo conviene |
| :--- | :--- | :--- |
| **Update atómico** | `UPDATE cuenta SET saldo = saldo - 100 WHERE id = 1` (no leer, calcular en la app y escribir) | Siempre que se pueda. |
| **Bloqueo pesimista** | `SELECT ... FOR UPDATE` y después `UPDATE`, en la misma transacción | Lógica compleja entre la lectura y la escritura. |
| **Bloqueo optimista** | Columna `version`: `UPDATE ... SET ..., version = version + 1 WHERE id = 1 AND version = 7`. Si afecta 0 filas, se reintenta. | Pocos conflictos; formularios web con espera del usuario. |
| **Aislamiento más alto** | PG `REPEATABLE READ`/`SERIALIZABLE` detecta el conflicto (`40001`) | Con lógica de reintento en la aplicación. |

## 5.10 Diagnosticar una espera por lock

**Escenario:** A hace `UPDATE` de la cuenta 1 sin confirmar. B intenta modificar la misma fila y **queda esperando**.

| Pregunta | MySQL / InnoDB | PostgreSQL |
| :--- | :--- | :--- |
| ¿Quién está conectado y qué hace? | `SHOW PROCESSLIST;` | `SELECT pid, state, wait_event_type, wait_event, query FROM pg_stat_activity;` |
| ¿Qué locks existen? | `SELECT * FROM performance_schema.data_locks;` (tipo, modo `X`/`S`, `lock_status = GRANTED/WAITING`) | `SELECT * FROM pg_locks;` |
| ¿Quién bloquea a quién? | `performance_schema.data_lock_waits` · `sys.innodb_lock_waits` | `SELECT pg_blocking_pids(pid);` |
| Estado general del motor | `SHOW ENGINE INNODB STATUS;` | Logs del servidor |
| Límite de espera | `innodb_lock_wait_timeout` (50 s) → error **1205** | `lock_timeout` (0 = infinito por defecto) |
| Cancelar la consulta | `KILL QUERY id;` | `SELECT pg_cancel_backend(pid);` |
| Terminar la sesión | `KILL id;` | `SELECT pg_terminate_backend(pid);` |

**Lectura de la evidencia:** B está en espera (`WAITING`, o `wait_event_type = Lock`) de un lock **exclusivo de fila** que tiene A (`GRANTED`). **B no está lenta: está suspendida esperando un recurso.** Cuando A hace `COMMIT` o `ROLLBACK`, B continúa inmediatamente.

### ¿Lentitud o bloqueo?

| | Plan lento | Espera por lock |
| :--- | :--- | :--- |
| Síntoma para el usuario | "No termina" | "No termina" |
| CPU / E/S | Alta, trabajando | Casi nula, esperando |
| Evidencia | Plan de ejecución, filas examinadas | Estado de la sesión, `data_locks`/`pg_locks`, *wait event* |
| Solución | Índice, reescribir la consulta, estadísticas | Terminar o acortar la transacción bloqueante, rediseñar el acceso |

> Misma percepción del usuario, **causas y soluciones completamente distintas**. Antes de matar una sesión en producción hay que registrar la evidencia: quién bloquea, qué recurso, desde cuándo y qué impacto tiene cancelarla (se revierte todo su trabajo).

## 5.11 Deadlock: el abrazo mortal

```
Sesión A: BEGIN; UPDATE cuenta ... WHERE id = 1;   -- A tiene la cuenta 1
Sesión B: BEGIN; UPDATE cuenta ... WHERE id = 2;   -- B tiene la cuenta 2
Sesión A: UPDATE cuenta ... WHERE id = 2;          -- A espera a B
Sesión B: UPDATE cuenta ... WHERE id = 1;          -- B espera a A → CICLO
```

| | Espera por lock | Deadlock |
| :--- | :--- | :--- |
| Forma | Lineal: A espera a B | **Circular**: A espera a B y B espera a A |
| Se resuelve | Sola, cuando el bloqueante confirma o revierte | **Nunca sola**: el motor tiene que romper el ciclo |
| Resultado | Demora | Una transacción **abortada** (víctima) |

**Cómo lo resuelve cada motor:**

| | MySQL / InnoDB | PostgreSQL |
| :--- | :--- | :--- |
| Detección | Inmediata (grafo de esperas) | Después de esperar `deadlock_timeout` (1 s por defecto) |
| Víctima | La transacción **más "chica"** (menos filas insertadas, modificadas o borradas) | La que ejecuta la detección; no es predecible de antemano |
| Error | `ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction` | `ERROR: deadlock detected` (SQLSTATE `40P01`) |
| Evidencia | `SHOW ENGINE INNODB STATUS` → sección **LATEST DETECTED DEADLOCK** (`innodb_print_all_deadlocks` los guarda todos en el log) | Log del servidor (detalle de los procesos y locks del ciclo) |

La víctima recibe un `ROLLBACK` forzado. La otra transacción **continúa** y debe confirmar o revertir.

### Prevenir y manejar deadlocks

| Medida | Cómo ayuda |
| :--- | :--- |
| **Orden consistente de acceso** | Si todos bloquean los recursos en el mismo orden (por ejemplo, `cuenta_id` ascendente), no se puede formar un ciclo: uno espera al otro en fila. |
| **Transacciones cortas** | Menos tiempo con locks tomados. Nunca esperar una acción del usuario, ni hacer procesamiento pesado, con la transacción abierta. |
| **Acceso selectivo (índices)** | Menos filas recorridas implica menos filas bloqueadas. |
| **Reintento** | La aplicación debe capturar el error de deadlock o de serialización y **reintentar** la transacción (con una espera breve). |
| **Bloquear todo de entrada** | `SELECT ... FOR UPDATE` de todos los recursos al inicio, en orden. |
| `NOWAIT` / `SKIP LOCKED` | Fallar enseguida o saltear las filas bloqueadas (colas de trabajo). |
| **Diagnóstico** | Registrar la evidencia del motor antes de cambiar el diseño. |

> **Escalar el hardware no resuelve un deadlock:** es un problema **lógico** de orden de acceso, no de recursos.

## Preguntas de repaso · Unidad 5

1. Un compañero no puede conectarse al MySQL de la VM y recibe *connection refused*. Otro recibe *timeout*. ¿Qué revisarías en cada caso?
2. ¿Qué diferencia hay entre `bind-address` en MySQL y `pg_hba.conf` en PostgreSQL?
3. Explicá qué ve la segunda lectura de A en el experimento de aislamiento en MySQL y en PostgreSQL con sus niveles por defecto.
4. ¿MVCC elimina la necesidad de locks? ¿Por qué?
5. ¿Cómo distinguís una consulta lenta de una consulta bloqueada? ¿Qué evidencia usarías?
6. En un deadlock, ¿qué transacción elige InnoDB como víctima? ¿Qué debe hacer la aplicación?
7. Proponé dos medidas preventivas contra deadlocks que no impliquen mejorar el hardware.
8. ¿Por qué un `UPDATE` sin índice en el `WHERE` aumenta la contención en InnoDB?

---

# Unidad 6 · Seguridad, backup, réplica y alta disponibilidad

## 6.1 Idea central: proteger, recuperar, continuar

> *Si alguien borra datos en producción, ¿el problema se resuelve con permisos, con backup o con alta disponibilidad?* **Depende del incidente, del RPO/RTO y de la evidencia disponible**, y normalmente con las tres.

| Respuesta | Cuándo | Qué incluye |
| :--- | :--- | :--- |
| **Proteger** | Antes | Mínimo privilegio, auditoría, cifrado, separación de cuentas, política de backup. |
| **Recuperar** | Durante | Restore, logs, validación y **decisión del punto objetivo**. |
| **Continuar** | Después | Réplica, failover, monitoreo, mejora del plan. |

## 6.2 Seguridad en bases de datos: cuatro pilares

| Pilar | Pregunta | Mecanismos |
| :--- | :--- | :--- |
| **Autenticación** | ¿Quién es? | Usuario y credencial, plugins (`caching_sha2_password`, `scram-sha-256`), LDAP/AD, certificados. |
| **Autorización** | ¿Qué puede hacer? | Roles, privilegios sobre objetos (`GRANT`/`REVOKE`), vistas, seguridad por fila. |
| **Auditoría** | ¿Qué hizo? | Logs, tablas de auditoría, plugins de auditoría. |
| **Cifrado / ofuscación** | ¿Cómo se protege el dato? | TLS en tránsito, cifrado en reposo y **de las copias**, enmascaramiento estático y dinámico. |

## 6.3 Mínimo privilegio y separación de funciones

**Principio de mínimo privilegio (PoLP):** cada usuario, rol o servicio tiene **solo** los permisos necesarios para su función, durante el tiempo necesario.

**Permisos peligrosos típicos:**

| Situación | Riesgo |
| :--- | :--- |
| La cuenta de la **aplicación** tiene DDL (`CREATE`, `DROP`, `ALTER`) | Una inyección SQL puede ejecutar `DROP TABLE`. La app no crea tablas en tiempo de ejecución. |
| La app tiene `DELETE`/`UPDATE` sobre tablas **contables o de movimientos** | Un error o un ataque borra la historia. Los movimientos son ***append-only***: un error se corrige con un movimiento compensatorio, no borrando. |
| Un **analista/BI** tiene `UPDATE` | Rompe la separación de funciones: un perfil de consulta puede alterar saldos. |
| Cualquiera puede modificar o borrar la **tabla de auditoría** | Se puede borrar la huella de un fraude (antiforense). |
| Privilegios globales (`*.*`) o `GRANT OPTION` innecesarios | Escalada: el usuario puede otorgar permisos a otros. |
| Una cuenta compartida (todos usan `root`) | No hay trazabilidad de quién hizo qué. |

### Modelo de roles de referencia

| Rol | Lectura | Escritura | DDL | Gestión de usuarios | Auditoría |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **app** | Sí | Sí (sin `DELETE` sobre tablas inmutables) | No | No | Solo `INSERT` |
| **analista** | Sí (parcial, de negocio) | No | No | No | No |
| **auditor** | Sí (incluye auditoría) | No | No | No | Lectura |
| **operador** | Sí (operativa) | Limitada | No | No | No |
| **dba** | Sí | Sí | Sí | Sí | Sí |

> Regla de diseño: **otorgar lo necesario y probar explícitamente lo que debe quedar bloqueado.**

## 6.4 Implementación de roles en cada motor

```sql
-- MySQL 8+
CREATE ROLE rol_analista;
GRANT SELECT ON banco.cliente TO rol_analista;
GRANT SELECT ON banco.cuenta  TO rol_analista;
CREATE USER 'ana'@'%' IDENTIFIED BY '***';
GRANT rol_analista TO 'ana'@'%';
SET DEFAULT ROLE ALL TO 'ana'@'%';        -- ⚠️ sin esto, el rol NO se activa al iniciar sesión
SHOW GRANTS FOR 'ana'@'%' USING rol_analista;
REVOKE UPDATE ON banco.* FROM rol_analista;
```

```sql
-- PostgreSQL
CREATE ROLE rol_analista NOLOGIN;
GRANT CONNECT ON DATABASE banco TO rol_analista;
GRANT USAGE ON SCHEMA public TO rol_analista;
GRANT SELECT ON cliente, cuenta TO rol_analista;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO rol_analista;  -- tablas futuras
CREATE ROLE ana LOGIN PASSWORD '***';     -- en PG, un usuario es un rol con LOGIN
GRANT rol_analista TO ana;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;  -- endurecimiento típico
```

| Diferencia | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Identidad | `'usuario'@'host'`: el mismo nombre desde otro host es **otra cuenta** | Rol con `LOGIN`; el origen se controla en `pg_hba.conf` |
| Activación de roles | Hace falta `SET DEFAULT ROLE` o `activate_all_roles_on_login = ON` | Se heredan automáticamente (`INHERIT`) |
| Niveles | Global (`*.*`), base (`db.*`), tabla, columna, rutina | Base (`CONNECT`), esquema (`USAGE`/`CREATE`), tabla, columna, función |
| Tablas futuras | Un permiso sobre `db.*` las cubre | `ALTER DEFAULT PRIVILEGES` |
| Seguridad por fila | Vistas (con `WHERE`) | Vistas o **Row-Level Security** (`CREATE POLICY`) |
| `FLUSH PRIVILEGES` | **No hace falta** después de `GRANT`/`REVOKE` (solo si se editan las tablas de sistema a mano) | No existe |

**Vistas como herramienta de seguridad (nivel externo de ANSI/SPARC):** dar `SELECT` sobre una vista que oculta columnas sensibles (sueldo, CBU) o filtra filas, en lugar de sobre la tabla.

## 6.5 Probar el mínimo privilegio: éxitos y errores esperados

> No alcanza con decir "no tiene permisos": **hay que ejecutar una prueba que falle por la razón correcta.**

1. **Demostrar el acceso indebido antes de corregir** (por ejemplo, el analista hace `UPDATE` de un saldo y le funciona).
2. **Corregir:** `REVOKE ALL` y `GRANT` granular.
3. **Repetir las pruebas** y registrar lo permitido y lo rechazado:

| Prueba | Usuario | Resultado esperado |
| :--- | :--- | :--- |
| `DROP TABLE cuenta` | app | ✗ MySQL `ERROR 1142 (42000): DROP command denied...` · PG `permission denied for table cuenta` (42501) |
| `UPDATE cuenta SET saldo = ...` | analista | ✗ 1142 / 42501 |
| `DELETE FROM movimiento` | app | ✗ |
| `INSERT INTO movimiento ...` | app | ✓ (la operación legítima **tiene que seguir funcionando**) |
| `SELECT ... FROM auditoria_evento` | auditor | ✓ |

**Producto:** una **matriz de permisos antes/después** con la justificación de cada cambio y la evidencia de cada prueba.

## 6.6 Auditoría y evidencias

| Fuente | Qué registra | MySQL | PostgreSQL |
| :--- | :--- | :--- | :--- |
| Log de errores | Arranques, caídas, errores | error log | log del servidor |
| Log general / de sentencias | Todas las sentencias (costoso) | general log | `log_statement` |
| Consultas lentas | Sentencias que superan un umbral | slow query log | `log_min_duration_statement` |
| Log de cambios | Cambios de datos (y réplica) | **binary log** | **WAL** |
| Auditoría de negocio | Eventos relevantes | Tabla + trigger | Tabla + trigger |
| Plugin de auditoría | Conexiones, DDL, accesos | Enterprise Audit / plugins de terceros | extensión `pgAudit` |

> Auditar no es guardar todo: es registrar **eventos relevantes, consultables y protegidos contra la alteración** (el rol de la app solo tiene `INSERT` sobre la tabla de auditoría).

## 6.7 Backup, restore y recovery no son lo mismo

| Concepto | Qué es |
| :--- | :--- |
| **Backup** | Generar una **copia consistente** (lógica o física; completa, diferencial o incremental). |
| **Restore** | Reconstruir archivos, objetos o datos **desde esa copia**. |
| **Recovery** | Llevar la base al **estado requerido**, aplicando logs y tomando decisiones (por ejemplo, hasta qué punto). |

> "Tengo backup" **no** responde si puedo recuperar el servicio **a tiempo y con los datos correctos**.

## 6.8 Tipos de backup

| Tipo | Ventaja | Costo o límite | Uso típico |
| :--- | :--- | :--- | :--- |
| **Lógico** (sentencias SQL) | Portable entre versiones y plataformas, legible, selectivo por objeto | Restore lento en volúmenes altos (reconstruye índices) | Migraciones, bases chicas, exportar |
| **Físico** (copia de archivos) | Rápido para bases grandes | Depende del motor, la versión y la plataforma | Recuperación ante desastres, bases grandes |
| **Completo** (*full*) | Restore simple | Tiempo y espacio | Base de toda la cadena |
| **Diferencial** | Cambios desde el último full: restore = full + último diferencial | Crece con el tiempo | Intermedio |
| **Incremental** | Cambios desde el último backup de cualquier tipo: ventana de copia mínima | Restore = full + **todos** los incrementales (cadena frágil) | Producción con cambios frecuentes |
| **En caliente** | Sin detener el servicio | Requiere mecanismos de consistencia | Producción |
| **En frío** | Consistencia trivial | Hay que detener el servicio | Mantenimiento programado |

> La pregunta correcta no es "¿cuál es mejor?", sino **"¿cuál cumple el RPO/RTO con un costo razonable?"**

### Herramientas por motor

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Lógico | `mysqldump`, MySQL Shell (`util.dumpInstance`) | `pg_dump` (una base), `pg_dumpall` (todo, **incluidos roles**) |
| Restore lógico | `mysql < archivo.sql` | `psql -f` o `pg_restore` (formato custom `-Fc`, restaura en paralelo) |
| Físico | Percona XtraBackup, MySQL Enterprise Backup, plugin clone | `pg_basebackup`, pgBackRest, Barman |
| Log para PITR | **Binary log** | **WAL** + archivado (`archive_mode`) |

### Backup lógico consistente

```bash
# MySQL: snapshot consistente sin bloquear InnoDB + rotación del binlog + coordenadas
mysqldump -u root -p --single-transaction --flush-logs --source-data=2 \
          --routines --events --triggers --databases banco > backup_banco.sql

# PostgreSQL: pg_dump siempre toma un snapshot consistente
pg_dump -U postgres -Fc -d banco -f backup_banco.dump
pg_dumpall -U postgres --globals-only > roles.sql     # roles y tablespaces aparte
```

| Opción de `mysqldump` | Para qué |
| :--- | :--- |
| `--single-transaction` | Abre una transacción `REPEATABLE READ`: **snapshot consistente sin bloquear tablas** (solo sirve para InnoDB). |
| `--flush-logs` | Rota el binlog: empieza un archivo nuevo en el momento del backup. |
| `--source-data=2` (antes `--master-data`) | Escribe **como comentario** el archivo y la posición del binlog del momento del backup: el punto de partida de la recuperación. |
| `--routines --events` | Las rutinas y los eventos **no** se incluyen por defecto (los triggers sí). |

> ⚠️ `pg_dump` **no incluye roles**, y `mysqldump` de una base **no incluye usuarios**: se respaldan aparte.

## 6.9 Recuperación a un punto en el tiempo (PITR)

**El objetivo no siempre es volver al último estado.**

```
10:00          10:30               10:47              11:00
backup full    operaciones válidas DELETE accidental  detección
```

| Opción | Resultado |
| :--- | :--- |
| Restaurar solo el backup de las 10:00 | ✗ **Pierde las operaciones válidas** posteriores al backup (viola el RPO). |
| Recuperar hasta el último estado (11:00) | ✗ **Conserva el error** (reaplica el `DELETE`). |
| **Recuperar hasta 10:46:59**, justo antes del `DELETE` | ✓ Conserva lo válido y evita el incidente. |

**Cadena de recuperación = backup base + logs desde el backup hasta el punto objetivo.** Sin logs, el punto de recuperación queda limitado al último backup.

### PITR en MySQL (backup + binary log)

```sql
-- 1. Ubicar el incidente en el binlog
SHOW BINARY LOGS;
SHOW BINLOG EVENTS IN 'binlog.000002';
```
```bash
mysqlbinlog --verbose --base64-output=DECODE-ROWS /var/lib/mysql/binlog.000002 | less
# Buscar el BEGIN de la transacción del DELETE y anotar su posición (end_log_pos del evento anterior)

# 2. Restaurar el backup base
mysql -u root -p < backup_banco.sql

# 3. Reaplicar el binlog desde la posición del backup hasta justo antes del DELETE
mysqlbinlog --start-position=<pos_del_backup> --stop-position=<pos_antes_del_DELETE> \
            /var/lib/mysql/binlog.000002 | mysql -u root -p
```

**Por posición o por fecha:**
- `--stop-position` es **exacto** y es el método recomendado.
- `--stop-datetime="2026-09-22 10:46:59"` usa la **hora real en que el servidor ejecutó cada evento**, no los valores de fecha guardados en las filas. Si en un `INSERT` se cargó `fecha = '10:05'` pero se ejecutó a las 15:30, el binlog registra **15:30**. Además, con varias transacciones en el mismo segundo es impreciso.

**Alternativa mejor si hubo operaciones válidas *después* del error:** reaplicar **dos tramos** y saltear solo la transacción dañina:

```bash
mysqlbinlog --start-position=<backup> --stop-position=<inicio_DELETE> binlog.000002 | mysql -u root -p
mysqlbinlog --start-position=<fin_DELETE> binlog.000002 | mysql -u root -p
# Con GTID: mysqlbinlog --exclude-gtids='uuid:N' ...
```

### PITR en PostgreSQL (base backup + WAL archivado)

```ini
# postgresql.conf (antes del incidente: se prepara de antemano)
wal_level = replica
archive_mode = on
archive_command = 'cp %p /archivo_wal/%f'
```
```bash
pg_basebackup -D /backups/base_2026_09_22 -Fp -Xs -P      # backup físico base
```
Para recuperar: restaurar el base backup en el directorio de datos y configurar:
```ini
restore_command = 'cp /archivo_wal/%f %p'
recovery_target_time = '2026-09-22 10:46:59'      # o recovery_target_lsn / recovery_target_xid
recovery_target_inclusive = false
recovery_target_action = 'promote'
```
Crear el archivo `recovery.signal` y arrancar el servidor, que reproduce el WAL hasta el objetivo.

> ⚠️ En PostgreSQL, **`pg_dump` no sirve para PITR**: hace falta un backup **físico** + **WAL archivado**. El WAL es físico, así que **no se puede "saltear" una transacción**: se recupera hasta antes del error, y lo válido posterior se reaplica de otra forma.

### Alternativa operativa: recuperar en un entorno paralelo

En lugar de restaurar sobre producción (que detiene el servicio):
1. Restaurar backup + logs hasta antes del error en una **instancia de recuperación**.
2. Extraer **solo las filas perdidas** (por ejemplo, los movimientos borrados de la cuenta 101).
3. Reinsertarlas en producción.

**Ventaja:** menos tiempo de corte (mejor RTO) y se conservan las operaciones posteriores al incidente. **Costo:** hace falta otra instancia y cuidado con la integridad (FK, saldos derivados).

### Validar la recuperación

| Métrica | Antes del backup | Después de las operaciones válidas | Después del incidente | Después del PITR |
| :--- | :---: | :---: | :---: | :---: |
| Clientes / cuentas | = | = | = | **=** |
| Movimientos | N | N + válidos | N + válidos − borrados | **N + válidos** |
| Suma de importes | S | S' | S' − borrado | **S'** |
| Filas afectadas | presentes | presentes | ausentes | **recuperadas** |

Siempre se registran **conteos, sumas y las filas concretas** antes y después: esa es la evidencia de que la recuperación fue correcta.

> **Detalle:** al restaurar un volcado con el binlog activo, la restauración **también se escribe en el binlog**. Se puede evitar con `SET sql_log_bin = 0` en la sesión de restore.

## 6.10 RPO y RTO

| | RPO: *Recovery Point Objective* | RTO: *Recovery Time Objective* |
| :--- | :--- | :--- |
| Pregunta | **¿Cuántos datos** puede perder la organización? | **¿Cuánto tiempo** puede estar sin servicio? |
| Se mide en | Tiempo de datos perdidos (5 min, 4 h) | Tiempo de corte (20 min, 6 h) |
| Lo mejora | Backups más frecuentes, **archivado continuo de logs**, réplica síncrona | Failover automático, procedimientos probados, backups físicos, automatización |

Ejemplo: **RPO de 5 min + RTO de 30 min** exige logs enviados fuera del servidor con frecuencia, un procedimiento probado y automatización suficiente.

### Qué técnica alcanza qué objetivo (orientativo)

| Técnica | RPO típico | RTO típico |
| :--- | :--- | :--- |
| Backup diario (sin logs) | Hasta 24 h | Horas (según volumen) |
| Backup + logs archivados cada X min | ≈ X minutos | Restore + replay (minutos a horas) |
| Réplica asíncrona | Segundos (el lag) | Minutos (failover) |
| Réplica síncrona / semisíncrona | ≈ 0 ante una falla física | Minutos o menos |
| Clúster con failover automático | ≈ 0 | Segundos a minutos |

## 6.11 Plan de recuperación

**Un backup sin prueba de restore es una promesa no verificada.**

```
Inventario → Política → Ejecución → Verificación → Restauración (prueba) → Validación
```

Checklist mínimo: **qué** se copia, **dónde** queda, **quién** accede, **cómo** se cifra, **cada cuánto** se prueba el restore y **cómo** se documenta.

**Regla 3-2-1:** 3 copias, en 2 medios distintos, 1 fuera del sitio (*offsite*). Las copias también son un **activo sensible**: se cifran y se controla quién accede.

## 6.12 Alta disponibilidad no es backup

| Situación | Backup | Réplica / HA |
| :--- | :--- | :--- |
| Se cae el nodo principal | Recupera, pero puede tardar | ✓ Failover rápido |
| Se destruye el disco | ✓ Permite restaurar | ✓ Si hay réplica, reduce el corte |
| **`DELETE` accidental** | ✓ Permite volver a antes del error | ✗ **Replica el error en milisegundos** |
| Error lógico de la aplicación | ✓ Histórico recuperable | ✗ Propaga el cambio |
| Ransomware o corrupción lógica | ✓ Si la copia está aislada | ✗ |

> **Replicar un error no crea un backup.** HA protege contra fallas **físicas**; el backup + logs protege contra errores **lógicos y humanos**.

## 6.13 Replicación

| Concepto | Significado |
| :--- | :--- |
| **Primario** | Recibe las escrituras y publica los cambios. |
| **Réplica** | Recibe los cambios; puede servir lecturas o esperar un failover. |
| **Lag** | Distancia temporal entre el primario y la réplica. |

| Modalidad | Cómo confirma | Pérdida potencial | Impacto en el primario |
| :--- | :--- | :--- | :--- |
| **Asíncrona** | El primario confirma sin esperar a la réplica | Lo que esté en el lag | Mínimo |
| **Semisíncrona** (MySQL) | Espera a que **al menos una réplica reciba** el evento (no que lo aplique) | ≈ 0 mientras funcione. Si la réplica no responde a tiempo, **vuelve a asíncrona**. | Latencia de red por commit |
| **Síncrona** | Espera la confirmación de la réplica | ≈ 0 | Mayor acoplamiento: si la réplica cae, el primario puede quedar bloqueado |

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Réplica básica | Replicación por binlog (asíncrona), con GTID | *Streaming replication* por WAL (asíncrona) |
| Síncrona | Semisíncrona; **Group Replication / InnoDB Cluster** (consenso) | `synchronous_standby_names` + `synchronous_commit` |
| Lógica / selectiva | Filtros de replicación | *Logical replication* (publicaciones y suscripciones) |
| Failover | MySQL Router + InnoDB Cluster, Orchestrator, VIP con Keepalived | Patroni, repmgr, VIP con Keepalived |
| **Réplica con retardo** | `CHANGE REPLICATION SOURCE TO SOURCE_DELAY = 3600` | `recovery_min_apply_delay = '1h'` |

> **Réplica con retardo:** una réplica que aplica los cambios con, por ejemplo, 1 hora de atraso da una ventana para **frenarla antes de que aplique un `DELETE` accidental** y recuperar desde ahí. Es un punto intermedio entre HA y backup.

## 6.14 Failover: volver a dar servicio no alcanza

| Paso | Pregunta |
| :--- | :--- |
| 1. **Detectar** | ¿Es una falla real o una partición parcial de red? |
| 2. **Promover** | ¿Qué réplica asume las escrituras? ¿Está al día (lag)? |
| 3. **Reconectar** | ¿Cómo llegan las aplicaciones al nuevo nodo? (VIP, DNS, proxy) |
| 4. **Reintegrar** | ¿Qué pasa con el nodo anterior cuando vuelve? (debe volver como réplica) |

**Riesgos:**
- **Split brain:** dos nodos creen ser primarios y aceptan escrituras divergentes. Aparece con **dos nodos sin árbitro**: si se corta el enlace, cada uno cree que el otro murió.
  - Mitigaciones: **quórum** (3 nodos o un testigo/árbitro liviano), **fencing** (aislar al nodo viejo, por ejemplo verificando la salida al gateway antes de promover), failover asistido por un humano cuando la señal es ambigua.
- **Pérdida por lag** si se promueve una réplica asíncrona atrasada.
- Un failover que funciona técnicamente pero **no operacionalmente** (la app sigue apuntando al nodo viejo).

## 6.15 Diseño por criticidad: escenarios típicos

La complejidad técnica se justifica por **criticidad, costo de la caída y capacidad de operación**.

| Escenario | RPO / RTO | Estrategia razonable | Qué **no** hacer |
| :--- | :--- | :--- | :--- |
| **Data mart / reportes** (los datos se pueden regenerar) | 24 h / 24 h | Backup diario de lo que **no** se puede reconstruir (dimensiones, configuración, ETL). Lo demás se regenera desde las fuentes. | HA compleja sin evidencia de necesidad. |
| **Sistema interno de RR.HH.** (horario laboral) | 8 h / 12 h | Backup completo diario fuera de horario + logs o backup de mediodía, restore probado. | Clúster 24x7: sobrearquitectura. |
| **Sistema académico** (picos en inscripciones) | 4 h / 6 h | Full diario + logs archivados cada pocas horas (más frecuentes en período de inscripción), procedimiento documentado, bajo costo. | Pagar HA todo el año por un pico. |
| **Logística / depósitos** (2 nodos, presupuesto medio) | 15 min / 30 min | Primario + réplica semisíncrona o asíncrona con failover (VIP), backup diario + **logs enviados fuera del nodo cada ≤ 5 min**, PITR probado. Mitigar el split brain (testigo o fencing). | Confiar en la réplica para errores humanos. |
| **E-commerce 24x7** | 5 min / 20 min | Réplica con failover automatizado + archivado continuo de logs + backups físicos. Presupuesto medio: evitar el clúster multi-región. | Backup diario solo (RPO de 24 h). |
| **Core financiero crítico** | ≈ 0 / 5 min | Replicación **síncrona** o clúster con consenso (3+ nodos), failover automático, **separar HA de backup** (backups físicos + logs + réplica con retardo), sitio de DR, pruebas periódicas. | Replicación asíncrona (pierde transacciones confirmadas). |

**Toda propuesta debe incluir:** usuarios y roles, estrategia de backup (tipo, frecuencia, retención), uso de logs y PITR, réplica y modalidad si corresponde, procedimiento ante la caída del primario, tratamiento del borrado accidental, **evidencia de que cumple el RPO/RTO**, monitoreo y **al menos un costo, riesgo o limitación**.

### Costos y límites que conviene reconocer

- Más nodos implican **más costo** de hardware, licencias y operación.
- La replicación síncrona agrega **latencia** en cada commit.
- **Dos nodos no tienen quórum**: riesgo de split brain.
- Un backup más frecuente implica **más espacio y más E/S**.
- Todo procedimiento **no probado** tiene RTO desconocido.
- HA **no** protege contra errores humanos. Backup **no** da continuidad inmediata.

## Preguntas de repaso · Unidad 6

1. Nombrá tres permisos peligrosos para una cuenta de aplicación y explicá el riesgo de cada uno.
2. ¿Por qué en MySQL un usuario puede tener un rol asignado y aun así recibir *access denied*?
3. ¿Cómo demostrás que el mínimo privilegio funciona? ¿Qué evidencia presentás?
4. Diferenciá backup, restore y recovery.
5. Explicá por qué ni restaurar solo el backup ni reaplicar todo el log resuelve un `DELETE` accidental.
6. ¿Por qué `--stop-datetime` puede fallar si se usa la fecha que figura en las filas?
7. ¿Qué diferencia hay entre el PITR de MySQL (binlog) y el de PostgreSQL (WAL)?
8. ¿La alta disponibilidad reemplaza al backup? Dá un ejemplo.
9. ¿Qué es el split brain y cómo se mitiga en una topología de dos nodos?
10. Diseñá una estrategia para RPO = 15 min y RTO = 30 min con presupuesto medio. Indicá un riesgo.

---

# Integración: preguntas que cruzan unidades

Estas preguntas mezclan temas, igual que en una defensa:

| Situación | Unidades | Línea de respuesta |
| :--- | :--- | :--- |
| "La consulta no termina." | 2 · 5 | Distinguir un **plan lento** (EXPLAIN, filas examinadas) de una **espera por lock** (`data_locks`/`pg_locks`). La solución es distinta. |
| "Creamos un índice y los `INSERT` se volvieron lentos." | 2 · 1 | Cada índice se mantiene en cada escritura y genera más redo/WAL. Evaluar el costo global y considerar un índice invisible antes de borrarlo. |
| "Un `UPDATE` masivo bloquea a todo el sistema." | 2 · 5 | Sin índice, InnoDB bloquea todas las filas que recorre. Indexar el filtro y hacer el cambio en lotes con transacciones cortas. |
| "Borraron datos por error." | 6 · 4 · 1 | Permisos (¿quién podía?), **PITR** con backup + logs (recuperar), auditoría (¿quién fue?). HA no ayuda. |
| "¿Por qué el `COMMIT` es rápido si los datos no llegaron al disco?" | 1 · 6 | WAL/redo: se persiste el log. Ese mismo log sostiene la réplica y el PITR. |
| "La regla de saldo no negativo: ¿app o base?" | 4 · 6 | Ambas: la app para la experiencia de usuario y la base como última defensa (`CHECK`). La base además evita que un rol mal configurado la saltee. |
| "¿Cómo migrar a v2 sin cortar el servicio?" | 4 · 5 · 6 | Expandir → completar → validar → endurecer. Backup previo. Cuidado con los locks del DDL en tablas grandes. Rollback razonado. |
| "La réplica muestra datos viejos." | 6 · 5 | Lag de la réplica asíncrona: consistencia eventual en las lecturas de la réplica. |
| "El reporte de fin de mes tarda y bloquea." | 2 · 3 · 5 | Plan (sort a disco), reescritura con ventanas o CTE, vista materializada o réplica de lectura. Las lecturas MVCC no bloquean a los escritores. |
| "Dos procesos transfieren entre las mismas cuentas y a veces fallan." | 5 · 4 | Deadlock por orden inverso: ordenar los locks por `cuenta_id`, procedimiento con transacción corta y reintento. |

## Errores conceptuales frecuentes

| Afirmación incorrecta | Corrección |
| :--- | :--- |
| "Más índices, más rápido." | Cada índice acelera algunas lecturas y **encarece todas las escrituras**. |
| "Si creé el índice, se usa." | El optimizador decide por **costo** con estadísticas; se verifica con el plan. |
| "Un table scan siempre está mal." | En tablas chicas o filtros poco selectivos es la decisión correcta. |
| "La CTE es más rápida que la subconsulta." | Depende del motor y del plan: hay que medirlo. |
| "El `COMMIT` escribe los datos en disco." | Escribe el **log**; las páginas bajan con el checkpoint. |
| "MVCC elimina los locks." | Solo las lecturas normales no bloquean; las escrituras siguen bloqueándose. |
| "Un deadlock es una consulta lenta." | Es un **ciclo** de esperas que el motor rompe abortando una transacción. |
| "Tengo réplica, no necesito backup." | La réplica **copia los errores**. |
| "Tengo backup, estoy protegido." | Sin logs, el RPO es el intervalo entre backups. Sin restore probado, el RTO es desconocido. |
| "`FLUSH PRIVILEGES` es obligatorio después de un `GRANT`." | Solo si se editan a mano las tablas de sistema. |
| "ENUM da integridad referencial." | Da **integridad de dominio**; la referencial la da una FK. |
| "Rollback de una migración = volver atrás sin costo." | `DROP COLUMN` destruye los datos generados en la versión nueva. |

---

# Chuleta de comandos MySQL vs PostgreSQL

| Tarea | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Conectarse | `mysql -h host -P 3306 -u usr -p base` | `psql -h host -p 5432 -U usr -d base` |
| Listar bases | `SHOW DATABASES;` | `\l` |
| Cambiar de base | `USE base;` | `\c base` |
| Listar tablas | `SHOW TABLES;` | `\dt` |
| Describir una tabla | `DESCRIBE t;` · `SHOW CREATE TABLE t;` | `\d t` |
| Índices de una tabla | `SHOW INDEX FROM t;` | `\di` · `\d t` |
| Plan real | `EXPLAIN ANALYZE ...` | `EXPLAIN (ANALYZE, BUFFERS) ...` |
| Estadísticas | `ANALYZE TABLE t;` | `ANALYZE t;` |
| Aislamiento actual | `SELECT @@transaction_isolation;` | `SHOW transaction_isolation;` |
| Sesiones | `SHOW PROCESSLIST;` | `SELECT * FROM pg_stat_activity;` |
| Locks | `performance_schema.data_locks` / `data_lock_waits` | `pg_locks`, `pg_blocking_pids(pid)` |
| Último deadlock | `SHOW ENGINE INNODB STATUS;` | Log del servidor |
| Cancelar / terminar | `KILL QUERY id;` / `KILL id;` | `pg_cancel_backend(pid)` / `pg_terminate_backend(pid)` |
| Crear un rol | `CREATE ROLE r;` | `CREATE ROLE r NOLOGIN;` |
| Crear un usuario | `CREATE USER 'u'@'%' IDENTIFIED BY '...';` | `CREATE ROLE u LOGIN PASSWORD '...';` |
| Ver permisos | `SHOW GRANTS FOR 'u'@'%';` | `\du` · `\dp t` |
| Backup lógico | `mysqldump --single-transaction ...` | `pg_dump -Fc ...` |
| Restore lógico | `mysql base < dump.sql` | `pg_restore -d base dump` / `psql -f dump.sql` |
| Backup físico | XtraBackup / clone | `pg_basebackup` |
| Log para PITR | binlog + `mysqlbinlog` | WAL archivado + `recovery_target_*` |
| Ver logs de cambios | `SHOW BINARY LOGS;` · `SHOW BINLOG EVENTS IN '...';` | `pg_waldump` |
| Tamaño | `information_schema.tables` | `pg_database_size()` · `pg_total_relation_size()` |
| Escuchar en la red | `bind-address` | `listen_addresses` + `pg_hba.conf` |
| Carga masiva | `LOAD DATA INFILE` | `COPY` / `\copy` |

---

# Resoluciones de las actividades: MySQL y PostgreSQL

En el simulacro de la cátedra las preguntas fueron de opción múltiple y describían situaciones de las actividades de laboratorio. Por ejemplo: una sesión que queda esperando un lock, un índice compuesto para una igualdad y un rango, la durabilidad del `COMMIT`, un PITR con RPO, la última venta de cada cliente o la secuencia segura de una migración.

Este apartado repasa cada actividad comparando **dos resoluciones reales**, una en **MySQL** y otra en **PostgreSQL**, unidad por unidad. Para cada una hay:

- **Qué pedía** la actividad.
- **Cómo la resolvió cada motor**, en una tabla comparativa con la evidencia obtenida.
- **Lo que hay que saber explicar**, con enlaces a la teoría del apunte.
- **Errores y mejoras** detectados al revisar las dos resoluciones: son los detalles que suelen aparecer como opción incorrecta en una pregunta.

> En algunas actividades la consigna cambiaba según el motor. En Unidad 2 cada grupo tuvo un caso o un escenario distinto, y en la Fase 3 de Unidad 6 un escenario de negocio distinto. En esos casos se comparan los temas, no los números.

## U1 · Instalación y arquitectura del motor

**Qué pedía:** instalar el motor en una máquina virtual, identificar servicio, proceso y puerto, crear una base y una tabla, consultar metadatos, ubicar archivos físicos y logs, comparar un plan antes y después de crear un índice y probar que los datos persisten. Teoría: [Unidad 1](#unidad-1--arquitectura-de-motores-de-bases-de-datos).

| Aspecto | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Versión y servicio | MySQL 9.7 Community: servicio `mysql`, proceso `mysqld`, usuario del SO `mysql` | PostgreSQL 18.6: servicio `postgresql`, proceso `postgres`, usuario del SO `postgres` |
| Puerto | 3306 (y 33060, del X Protocol) | 5432 |
| Comandos usados | `systemctl status mysql` · `ps aux \| grep mysqld` · `ss -tulpn` · `SELECT VERSION();` | `psql -V` · `\conninfo` (mostró una conexión por socket local) · `ps aux` |
| Crear la base y conectarse | `CREATE DATABASE sgbd_lab; USE sgbd_lab;` | `CREATE DATABASE sgbd_lab;` y `\c sgbd_lab`: una conexión es a **una sola base** |
| Error encontrado | `ERROR 1046: No database selected` (faltaba el `USE`) | `no existe la relación «cuentas»` (se salteó el `CREATE TABLE`) |
| Metadatos | `DESCRIBE`, `SHOW INDEX`, `information_schema`. Base y esquema son lo mismo. | `information_schema.columns`, `pg_indexes` (el índice `cuentas_pkey` lo crea solo la PK). Esquema `public` **dentro** de la base. |
| Archivos físicos | Una carpeta por base dentro del directorio de datos (`/var/lib/mysql/sgbd_lab/`) con un archivo `.ibd` por tabla | Una carpeta numerada por base en `/var/lib/postgresql/18/main/base/<oid>/` y un archivo numerado por tabla e índice |
| Log transaccional | Redo log y undo log (InnoDB), más el binlog del servidor | WAL en `pg_wal/` |
| Configuración | `/etc/mysql/my.cnf` y `/etc/mysql/mysql.conf.d/` | `/etc/postgresql/18/main/postgresql.conf` (`shared_buffers` = 128 MB) |
| Plan con índice en una tabla de 5 filas | Pasó a usar el índice sobre `nro_cuenta` | **Siguió con `Seq Scan`** antes y después del índice |
| Persistencia | Insertar, confirmar, detener el servicio, reiniciarlo y consultar: el registro sigue | Igual |

**Lo que hay que saber explicar**

- **¿Un índice obliga al optimizador a usarlo? No.** La resolución en PostgreSQL lo muestra directamente: con 5 filas, leer la tabla entera cuesta menos que ir al índice y después a la tabla. Que MySQL sí lo haya usado no contradice nada: cada motor tiene su propio modelo de costos, y MySQL estima muy barato un acceso por igualdad sobre un índice. La respuesta que se defiende es **"el optimizador decide por costo, con estadísticas"** ([1.6](#16-arquitectura-interna-del-sql-al-disco) y [2.8](#28-por-qué-el-optimizador-no-usa-mi-índice)).
- **¿Por qué el registro sobrevive al reinicio?** Porque el `COMMIT` escribe el **log** (redo/WAL) en disco. La página modificada puede seguir "sucia" en memoria; si el servicio se cae antes del checkpoint, al arrancar el motor **rehace** el cambio desde el log ([1.6](#16-arquitectura-interna-del-sql-al-disco)).
  - ⚠️ Respuesta incompleta frecuente: "los cambios quedan en memoria hasta el `COMMIT` y ahí se escriben los datos en disco". En el `COMMIT` se escribe el **log**, no las páginas de datos. Los cambios que no llegaron a confirmarse **se deshacen** al recuperar.
- **Autocommit:** tanto `psql` como el cliente `mysql` confirman cada sentencia sola. Para observar una transacción hay que abrirla con `BEGIN` / `START TRANSACTION`.
- **Instancia, base y esquema** no significan lo mismo en los dos motores ([1.11](#111-instancia-base-de-datos-y-esquema-el-mismo-término-cambia-de-significado)).

**Comandos útiles para ubicar la arquitectura**

| Qué | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Directorio de datos | `SELECT @@datadir;` | `SHOW data_directory;` |
| Archivo de una tabla | Carpeta de la base dentro de `@@datadir` | `SELECT pg_relation_filepath('cuentas');` |
| Caché de datos | `SELECT @@innodb_buffer_pool_size;` | `SHOW shared_buffers;` |
| Archivo de configuración | `/etc/mysql/my.cnf` | `SHOW config_file;` |
| Logs de cambios | `SHOW BINARY LOGS;` | Carpeta `pg_wal/` |

## U2 · Actividad 1: Detectives del plan

**Qué pedía:** diagnosticar un caso de bajo rendimiento con **dos evidencias** del plan, proponer **una mejora prioritaria** (no necesariamente un índice), explicar **cómo verificarla** y reconocer **un efecto adverso**. Sin implementar cambios. Cada grupo recibió un caso distinto. Teoría: [2.11](#211-leer-un-plan-de-ejecución) y [2.13](#213-antes-de-cambiar-identificar-la-causa).

### Caso en MySQL: el ordenamiento que llega al disco

- **Consulta:** `WHERE fecha >= '2026-08-09' AND fecha < '2026-08-10' ORDER BY importe DESC LIMIT 1000` sobre 22 millones de movimientos (920.000 del día).
- **Evidencia:** el *index range scan* tarda ~2.760 ms, pero la consulta total tarda **10.980 ms**; `Sort_merge_passes` sube **+24** con `sort_buffer_size` de 4 MiB.
- **Diagnóstico:** el ordenamiento de 920.000 filas no entra en memoria y **derrama a disco** con pasadas de mezcla.

| Propuesta de la resolución | Evaluación |
| :--- | :--- |
| Agregar un piso de importe al `WHERE` | Válida si el negocio acepta el cambio de alcance del reporte. |
| Quedarse con las 1.000 mayores sin ordenar todo | Es la idea de un ordenamiento parcial (*top-N*). Hay que justificar cómo lo resuelve el motor. |
| Índice `(fecha, importe DESC)` | ⚠️ **No elimina el sort**: `fecha` se filtra por **rango**. **Corrección:** columna generada `dia = DATE(fecha)` + índice `(dia, importe DESC)` y filtrar con `dia = '2026-08-09'`. Con igualdad, el índice entrega el orden por importe y el `LIMIT` corta en 1.000 ([2.13](#213-antes-de-cambiar-identificar-la-causa)). |

**Verificación:** el nodo `Sort` desaparece del plan, `Sort_merge_passes` deja de aumentar y la mediana de tres ejecuciones baja.

### Caso en PostgreSQL: el índice que no cubre

- **Evidencia:** `Index Scan` sobre `ix_transacciones_comercio_fecha` que devuelve 65.480 filas de 18 millones, con `Buffers: shared hit=188.700 read=9.420` y **7.410 ms**. Las filas son anchas (`width=310`) por una columna `descripcion VARCHAR(250)`.
- **Diagnóstico:** el índice **localiza** las filas pero **no tiene** las columnas que pide la consulta, así que por cada fila vuelve a la tabla (heap): miles de accesos aleatorios.
- **Mejora:** índice cubriente.

```sql
CREATE INDEX ix_transacciones_cubriente
ON transacciones (comercio_id, fecha DESC) INCLUDE (transaccion_id, importe, canal);
```

- **Verificación:** el plan pasa a `Index Only Scan`, los buffers bajan más del 90 % y los `Heap Fetches` quedan cerca de cero (depende del *visibility map*, es decir, de que la tabla tenga `VACUUM` al día).
- **Efecto adverso:** más espacio en disco y en memoria, y más costo en cada `INSERT`/`UPDATE`.

> ⚠️ Un `Index Only Scan` exige que **todas** las columnas que usa la consulta estén en el índice. Si el reporte sigue pidiendo `descripcion`, el motor sigue yendo al heap. Las opciones son sacar `descripcion` del listado y traerla solo para la fila que se abre, o incluirla y aceptar un índice mucho más grande ([2.7](#27-índices-de-cobertura-y-costo-oculto-de-los-índices)).

### Lo que tienen en común

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Problema | El **ordenamiento** no entra en memoria | El índice **no cubre** las columnas pedidas |
| Señal física clave | `Sort_merge_passes` (pasadas de mezcla en disco) | `Buffers` (hit/read), `width`, `Heap Fetches` |
| Mejora | Que el índice entregue el orden (con igualdad en la primera columna) | Que el índice tenga todas las columnas |
| Efecto adverso común | Un índice mantenido en cada escritura **para un único reporte** | |

## U2 · Actividad 2: Batalla de diseño físico

**Qué pedía:** línea de base, **hipótesis antes del DDL**, como máximo dos estructuras nuevas, **tres mediciones y la mediana**, medir el costo y dar un veredicto: **mantener, modificar o revertir**. El escenario cambiaba según el motor. Teoría: [2.5](#25-índices-compuestos-el-orden-de-las-columnas-importa), [2.9](#29-particionamiento-divide-y-reinarás) y [2.12](#212-protocolo-de-medición-reproducible).

### MySQL: lectura contra escritura (300.000 pedidos)

Índices creados: `(cliente_id, fecha)` para A y `(sucursal_id, estado, fecha)` para B.

| Operación | Mediana antes | Mediana después | Cambio en el plan |
| :--- | ---: | ---: | :--- |
| A · últimos 20 pedidos de un cliente | 155 ms | 0,198 ms | `Table scan` + `Sort` → `Index lookup ... (reverse)` |
| B · pedidos pendientes por sucursal | 164 ms | 0,0215 ms | `Table scan` + `Sort` → `Index lookup` |
| Lote de 10.000 `INSERT` | 194,69 ms | 273,29 ms | Hay que mantener dos índices más |
| C · resumen trimestral (prioridad baja) | Sin cambios | Sin cambios | No se indexó, a propósito |

- **Veredicto:** mantener. Las consultas prioritarias mejoran en órdenes de magnitud y la escritura empeora de forma acotada.
- **Descartado:** un índice simple sobre `cliente_id`. Evita el scan, pero **sigue ordenando**.
- **Por qué la mediana:** la primera inserción después de crear los índices tardó **2.410 ms** y la primera lectura 32,7 ms (caché fría). Con la mediana esos valores atípicos no distorsionan el resultado.

### PostgreSQL: heap contra tabla particionada (600.000 pedidos, 48 particiones mensuales)

| Consulta | Resultado (mediana) | Qué demuestra |
| :--- | :--- | :--- |
| C · un trimestre, en la tabla heap | 11,01 ms (`Parallel Seq Scan`, 5.941 buffers) | Sin estructura de acceso, recorre todo |
| C · un trimestre, en la particionada | 7,10 ms (lee **3 de 48** particiones) | ***Partition pruning***: filtra por la clave de partición |
| A · un cliente, en la particionada | 9,28 ms (recorre **las 48** particiones) | Sin filtro por fecha **no hay pruning** |
| Contraste: rango 2022-2026, en la particionada | 43,75 ms | Un rango que cubre casi todo anula el pruning |
| A · con índice `(cliente_id, fecha)` | **0,167 ms** (`Index Scan`, 90 buffers) | La partición **no reemplaza** al índice |
| C · heap con índice `(fecha)` | 8,85 ms (`Bitmap Index Scan`) | Mejora leve: el trimestre es una porción grande de la tabla |
| C · particionada con índice | El optimizador siguió con `Seq Scan` en las particiones podadas | Leer 3 particiones completas ya es barato |

**Retención** (borrar un mes):

| Operación | Resultado | Por qué |
| :--- | :--- | :--- |
| `DELETE` del mes en la tabla heap | 40 ms, 23.573 buffers | DML fila por fila: genera WAL y deja **tuplas muertas** que después limpia `VACUUM` |
| `ALTER TABLE ... DETACH PARTITION` | Casi instantáneo | Es un cambio de **metadatos**: no toca las filas ni deja tuplas muertas |

- **Veredicto:** **modificar**. Se mantiene la tabla particionada y se agrega el índice `(cliente_id, fecha)`.
- **Descartado:** quedarse con la tabla heap e índices, porque la retención con `DELETE` no escala.

### Comparación de los dos escenarios

| Pregunta | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Costo que se midió | **Escritura** (lote de `INSERT`) | **Retención** (borrar un período) |
| Estructura elegida | Dos índices compuestos | Partición por rango + índice |
| Veredicto | Mantener | Modificar |
| Lección | Cada índice se paga en cada escritura | Índice y partición resuelven problemas distintos |

> Una hipótesis **refutada** también vale. En PostgreSQL se esperaba que la tabla particionada ganara "siempre" y no fue así: perdió en la consulta por cliente. Explicar por qué es parte de la nota.

## U3 · Actividad 1: El reporte que nadie puede resolver

**Qué pedía:** resolver dentro del motor la última venta de cada cliente, el acumulado mensual, un ranking por segmento y un recorrido jerárquico, usando al menos una CTE, una función de ventana y una CTE recursiva. También comparar dos alternativas para una consulta. Teoría: [Unidad 3](#unidad-3--sql-avanzado).

| Requerimiento | MySQL | PostgreSQL | Comentario |
| :--- | :--- | :--- | :--- |
| Última venta | CTE con `ROW_NUMBER()` sobre `cliente JOIN venta`, `ORDER BY v.fecha DESC`, y filtro `cont_venta = 1` en el `WHERE` | `ROW_NUMBER()` solo sobre `venta`, con `ORDER BY fecha DESC, venta_id DESC`, y después `cliente LEFT JOIN ... ON ... AND rowc = 1` | La de PostgreSQL **conserva los clientes sin ventas** y **desempata**. La de MySQL los pierde (por el `JOIN`) y ante un empate de fecha elige cualquiera. |
| Acumulado mensual | `SUM() OVER (PARTITION BY cliente, año, mes ORDER BY fecha, venta_id ROWS ...)` | Igual | Equivalentes |
| Ranking | CTE con `LEFT JOIN` + `COALESCE` y `DENSE_RANK()` por segmento | Igual | Equivalentes: los clientes sin ventas aparecen con 0 |
| Jerarquía | `WITH RECURSIVE`, nivel desde 0 | `WITH RECURSIVE`, nivel desde 1 | Equivalentes |
| Comparación de alternativas | Ventana frente a self-join, con `EXPLAIN ANALYZE` (`Window aggregate`, `Materialize recursive CTE`) | Ventana frente a subconsulta correlacionada, mostrando que dan el mismo resultado | |

### La versión que responde bien al requerimiento

```sql
WITH ventas_ordenadas AS (
    SELECT v.*,
           ROW_NUMBER() OVER (PARTITION BY v.cliente_id
                              ORDER BY v.fecha DESC, v.venta_id DESC) AS rn  -- desempate explícito
    FROM venta v
)
SELECT c.cliente_id, c.nombre, vo.venta_id, vo.fecha, vo.total
FROM cliente c
LEFT JOIN ventas_ordenadas vo
       ON vo.cliente_id = c.cliente_id
      AND vo.rn = 1                  -- en el ON: los clientes sin ventas quedan con NULL
ORDER BY c.cliente_id;
```

> ⚠️ Si `rn = 1` se pasa al `WHERE`, los clientes sin ventas tienen `rn = NULL`, la condición da UNKNOWN y **desaparecen**: el `LEFT JOIN` se comporta como un `INNER JOIN` ([3.4](#34-join-decidir-qué-filas-sobreviven)). Esta diferencia fue una pregunta del simulacro.

### Ventana frente a subconsulta correlacionada

```sql
SELECT v1.venta_id, v1.cliente_id, v1.fecha, v1.total,
       (SELECT SUM(v2.total) FROM venta v2
        WHERE v2.cliente_id = v1.cliente_id
          AND EXTRACT(YEAR FROM v2.fecha)  = EXTRACT(YEAR FROM v1.fecha)
          AND EXTRACT(MONTH FROM v2.fecha) = EXTRACT(MONTH FROM v1.fecha)
          AND (v2.fecha < v1.fecha OR (v2.fecha = v1.fecha AND v2.venta_id <= v1.venta_id))
       ) AS acumulado_mes
FROM venta v1;
```

- La subconsulta reproduce a mano el mismo orden que `ORDER BY fecha, venta_id` + `ROWS`. Sin el desempate por `venta_id`, dos ventas del mismo día mostrarían el mismo acumulado.
- **Costo:** la ventana ordena una vez y recorre una pasada. La subconsulta se ejecuta **una vez por fila** (salvo que el optimizador la transforme), así que con N ventas son N recorridos.

**Evidencia:** el plan que se presenta tiene que ser **de la misma consulta** que se entrega. En una de las resoluciones, el `EXPLAIN` del acumulado usaba una partición distinta a la consulta entregada.

## U3/4 · Actividad 2: La regla que no puede romperse

**Qué pedía:** saldo no negativo, auditoría de cambios de precio, una función o un procedimiento que clasifique al cliente por su total anual (Bronce < 2 M, Plata entre 2 M y 50 M, Oro > 50 M) y al menos una regla con restricción declarativa. Para cada regla: mecanismo elegido y por qué. Teoría: [4.2](#42-mapa-de-mecanismos-del-más-simple-al-más-complejo) a [4.7](#47-tabla-de-decisión-qué-mecanismo-uso).

| Regla | Mecanismo (las dos) | MySQL | PostgreSQL |
| :--- | :--- | :--- | :--- |
| Saldo ≥ 0 | `CHECK (saldo >= 0)` | `ERROR 3819 ... is violated` | `violates check constraint` |
| Precio > 0 | `CHECK (precio > 0)` | Ídem | Ídem (el límite 0 se rechaza) |
| Auditoría de precio | Trigger `AFTER UPDATE` | La condición va **dentro del cuerpo**: `IF OLD.precio <> NEW.precio` | La condición va **en la definición**: `AFTER UPDATE OF precio ... WHEN (OLD.precio IS DISTINCT FROM NEW.precio)` |
| Clasificación anual | Función `clasificar_cliente(cliente, año)` con `COALESCE(SUM(total), 0)` | Declarada `DETERMINISTIC READS SQL DATA` | `plpgsql`, con la volatilidad por defecto |
| Tabla de ventas | — | Se creó una tabla `venta` mínima porque el script base no la traía | Se usó el script complementario, y hubo que agregar los clientes 4 y 5 que faltaban (por la FK) |

```sql
-- PostgreSQL: el motor solo invoca la función si el precio cambió de verdad
CREATE TRIGGER trg_auditar_precio
AFTER UPDATE OF precio ON producto
FOR EACH ROW
WHEN (OLD.precio IS DISTINCT FROM NEW.precio)
EXECUTE FUNCTION registrar_cambio_precio();
```

MySQL no tiene `UPDATE OF columna` ni `WHEN` en los triggers. La condición va dentro del cuerpo, y la forma segura con nulos es `IF NOT (OLD.precio <=> NEW.precio)`.

### Pruebas comparadas

| Caso | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Válido | Precio 1.000 → 1.200: aparece la fila en `auditoria_precio`. Clasificación: Plata, Oro y Bronce. | Igual |
| Límite | `saldo = 0` aceptado | `saldo = 0` aceptado. Mismo precio (1.200 → 1.200): **no se audita**. `precio = 0` rechazado. Cliente sin ventas en el año → Bronce. |
| Inválido | `saldo = -500` y `precio = 0` rechazados | `saldo = -1` rechazado. `precio = NULL` rechazado. `clasificar_cliente(NULL, NULL)` devuelve **Bronce**. |

### Lo que hay que saber explicar

- **¿Por qué se rechazó `precio = NULL`?** Por el **`NOT NULL`** de la columna, no por el `CHECK`. Un `CHECK (precio > 0)` **acepta** `NULL`, porque la condición da UNKNOWN y solo se rechaza lo que da FALSE ([4.3](#43-integridad-declarativa-constraints)).
- **Parámetros inválidos:** que `clasificar_cliente(NULL, NULL)` devuelva "Bronce" es un resultado engañoso. Mejor validar y fallar:

```sql
-- PostgreSQL
IF p_cliente_id IS NULL OR NOT EXISTS (SELECT 1 FROM cliente WHERE cliente_id = p_cliente_id) THEN
    RAISE EXCEPTION 'Cliente % inexistente', p_cliente_id;
END IF;
-- MySQL: IF ... THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente inexistente'; END IF;
```

- **Atributos de la función:** una función que lee tablas no es determinística. En MySQL corresponde `NOT DETERMINISTIC READS SQL DATA` y en PostgreSQL `STABLE` ([4.4](#44-funciones-almacenadas)).
- **Filtro por año:** las dos usan `EXTRACT(YEAR FROM fecha) = p_anio`, que impide usar un índice sobre `fecha`. El rango `fecha >= inicio_del_año AND fecha < inicio_del_año_siguiente` sí lo aprovecha.
- **Bordes:** en las dos, 2.000.000 y 50.000.000 exactos dan **Plata** y solo lo mayor a 50.000.000 da Oro. Conviene probar esos valores exactos como casos límite.
- **Base, aplicación o ambas:** la regla de saldo va en la base como última defensa y también en la aplicación para la experiencia de usuario ([4.1](#41-dónde-debería-vivir-la-regla-de-negocio)).

## U3/4 · Actividad 3: Release de base de datos v2.0

**Qué pedía:** evolucionar una base v1 con datos a una v2 **sin recrearla**: estados de pedido, auditoría de cambios de estado, totales no negativos, una función de total por cliente y un rollback razonado, con scripts versionados `01` a `06`. Teoría: [4.9](#49-migraciones-una-base-de-datos-también-tiene-versiones) a [4.11](#411-scripts-versionados-y-cicd).

| Paso | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Contenedor del laboratorio | Una base de datos propia | Un **esquema** propio: `DROP SCHEMA ... CASCADE`, `CREATE SCHEMA`, `SET search_path` |
| Columna de estado | `ENUM('pendiente', 'pagado', 'enviado', 'cancelado') NOT NULL DEFAULT 'pendiente'` | `CHAR(20) NOT NULL DEFAULT 'pendiente' CHECK (estado IN (...))` |
| Estado inválido | `ERROR 1265: Data truncated for column 'estado'` (modo estricto) | `new row ... violates check constraint "pedido_estado_check"` |
| Auditoría | Tabla con FK a `pedido`; trigger `AFTER UPDATE` con `OLD.estado <> NEW.estado` | Tabla con `SERIAL` y columna `usuario`; trigger `AFTER UPDATE OF estado` con `IS DISTINCT FROM` y `CURRENT_USER` |
| Total no negativo | `CHECK (total >= 0)` | Ídem, con nombre propio (`regla_totales_no_negativos`) |
| Función de total | `calcular_total_cliente` con `COALESCE`: un cliente sin pedidos da 0,00 | Ídem |
| Continuidad de v1 | Los 3 pedidos siguen y toman `pendiente` | Ídem |
| Rollback | `DROP` de cada objeto + advertencia de hacer `mysqldump` antes | **Copia los datos de v2** a tablas de respaldo (`CREATE TABLE ... AS SELECT`) y recién después hace los `DROP` |

### Lo que hay que saber explicar

- **Atajo frente a secuencia segura:** las dos resoluciones agregaron la columna en un solo paso, con `NOT NULL DEFAULT 'pendiente'`: expandir, completar y endurecer a la vez. En una tabla chica funciona. La secuencia que se defiende para producción es **columna nullable → completar históricos → validar → `CHECK` + `NOT NULL` → trigger** ([4.9](#49-migraciones-una-base-de-datos-también-tiene-versiones)). Es la respuesta del simulacro.
  - En PostgreSQL 11+ y MySQL 8.0+ agregar una columna con un `DEFAULT` constante es casi instantáneo. Lo costoso en tablas grandes es validar restricciones sobre todas las filas.
- **Rollback:** el de PostgreSQL es mejor práctica porque **preserva** los estados y la auditoría generados en v2 antes de borrarlos. Lo ideal es combinarlo con un backup.
- **Migración atómica:** en PostgreSQL toda la migración puede ir entre `BEGIN` y `COMMIT`, porque el DDL es transaccional: si algo falla, no queda nada a medias. En MySQL cada DDL hace commit implícito ([4.10](#410-rollback-de-migraciones-avanzar-suele-ser-seguro-retroceder-es-destructivo)).
- **`CHAR(20)` rellena con espacios** (`'pendiente'` + 11 blancos). Para textos de largo variable conviene `VARCHAR` o `TEXT`.
- **`ENUM`, `CHECK` o tabla de estados:** las ventajas de cada opción están en [4.9](#tres-formas-de-restringir-un-conjunto-de-valores). El `ENUM` da integridad **de dominio**, no referencial.

## U5 · Actividad 1: Guardia DBA

**Qué pedía:** convertir el motor en un servidor accesible para todo el grupo, que cada integrante se conecte desde su equipo con la herramienta gráfica, recorrer el checklist DBA (objetos, seguridad, metadatos, ingeniería inversa), una primera guardia (sesiones, actividad, tres indicadores, espacio, mantenimiento) y la lectura de un plan. Teoría: [5.1](#51-del-motor-aislado-al-servidor-compartido) a [5.3](#53-primera-guardia-dba-qué-mirar-y-con-qué-consulta).

| Aspecto | MySQL + Workbench | PostgreSQL + pgAdmin |
| :--- | :--- | :--- |
| Servidor | VM Ubuntu en VirtualBox con **adaptador puente** | Equipo físico con Linux, **sin virtualización**, conectado al Wi-Fi del aula para compartir la subred con los clientes |
| Escuchar en la red | `bind-address = 0.0.0.0` | `listen_addresses = '*'` |
| Quién puede conectarse | Usuarios `'alumno0N'@'%'` del script de la cátedra | `pg_hba.conf`: `host all all 0.0.0.0/0 scram-sha-256` |
| Usuarios | **Uno por integrante** (`alumno01` a `alumno06`), con DML + `PROCESS` + `SELECT` en `performance_schema` | **Un rol compartido** `lab_dba` con `SUPERUSER` |
| Verificación | `ss -lntp` → `0.0.0.0:3306`; *Test Connection* en Workbench | `ss -tulpn` → `0.0.0.0:5432`; `nmap` desde otro equipo: `5432/tcp open` |
| Objetos y metadatos | Navigator → Schemas; Table Inspector | Object Explorer; pestaña Properties |
| Seguridad | Users and Privileges | Login/Group Roles |
| Ingeniería inversa | Database → Reverse Engineer | ERD For Database |
| Sesiones | Client Connections | Dashboard y `pg_stat_activity` |
| Indicadores | Tráfico de red, CPU, uso del InnoDB buffer pool | Sesiones, transacciones por segundo (commits y rollbacks), tuplas leídas y devueltas, Block I/O (hits frente a reads) |
| Espacio | Table Inspector (*data length* e *index length*) | Base ≈ 7,9 MB; tabla `cuenta` 24 kB |
| Mantenimiento | Server Logs, exportar e importar | `VACUUM`, `ANALYZE`, `REINDEX`, `CLUSTER` |
| Plan analizado | Consulta sobre `cuenta`: `Table scan` → `Filter` → `Sort` (no había un índice útil) | JOIN `cuenta`–`movimiento`: `Nested Loop` con `Index Scan` en `cuenta_pkey` y `Bitmap Heap Scan` vía `ix_mov_cuenta_fecha` |

### Lo que hay que saber explicar

- **Mínimo privilegio también en el laboratorio.** Un rol compartido con `SUPERUSER` y una regla `0.0.0.0/0` funcionan, pero abren mucho más de lo necesario y no dejan saber quién hizo qué. Lo adecuado:
  - **Un usuario por persona** con privilegios de observación: en MySQL, `PROCESS` + `SELECT` sobre `performance_schema`; en PostgreSQL, el rol predefinido **`pg_monitor`**. Es lo que propone el script de la cátedra.
  - **Restringir la red:** en `pg_hba.conf`, solo la subred del aula (por ejemplo `10.13.24.0/21`); en MySQL, `'usuario'@'192.168.1.%'` en lugar de `'%'`.
  - **No publicar contraseñas** en el informe: lo pedía la consigna.
- **Distinguir capas:** `ss` muestra si el motor escucha; `nmap` o `nc` desde otra PC muestran si el puerto es alcanzable; el error del cliente indica si falla la autenticación ([5.1](#51-del-motor-aislado-al-servidor-compartido)).
- **La herramienta también genera sesiones:** el Dashboard de pgAdmin abre conexiones propias que aparecen como `idle`. Para contar a los integrantes hay que filtrar por `client_addr` y `application_name`.
- **Bitmap Heap Scan:** cuando el índice devuelve varias filas, PostgreSQL arma un mapa de las páginas que necesita y lee cada página una sola vez, en orden físico.
- **Plan gráfico frente a texto:** el gráfico muestra mejor la forma del árbol; el texto o JSON tiene todos los números (filas, costo, buffers). Para la defensa conviene el gráfico; para la evidencia, el texto.

## U5 · Actividad 2: Concurrencia y bloqueos

**Qué pedía:** tres experimentos con dos sesiones sobre el mismo servidor (espera por lock, aislamiento con dos lecturas, deadlock controlado), con evidencia del motor antes de liberar cada espera, y dos medidas preventivas. Los scripts de la cátedra eran equivalentes en los dos motores. Teoría: [5.8](#58-niveles-de-aislamiento) a [5.11](#511-deadlock-el-abrazo-mortal).

### Experimento 1: espera por lock

| | MySQL / InnoDB | PostgreSQL |
| :--- | :--- | :--- |
| Sesión que bloquea (A) | En `SHOW PROCESSLIST` figura como `Sleep`: está ociosa pero **con la transacción abierta** (se ve en `information_schema.innodb_trx`) | `state = idle in transaction` |
| Sesión bloqueada (B) | En `performance_schema.data_locks`, lock `X` sobre la fila con `lock_status = WAITING`; `data_lock_waits` relaciona B con A | `state = active`, `wait_event_type = Lock`, `wait_event = transactionid`, `pg_blocking_pids(B) = {A}` |
| Recurso | El registro de la cuenta 1 en el índice de la PK | La fila de la cuenta 1: B espera a que **termine la transacción** de A |
| Al liberar | `COMMIT` de A → el `UPDATE` de B termina al instante | Igual |

- **¿Por qué en PostgreSQL la espera dice `transactionid`?** PostgreSQL no guarda los locks de fila en una tabla de locks: los marca en la propia fila. Quien llega después espera a que **termine la transacción** que la modificó.
- **No hubo actualización perdida:** en la prueba con PostgreSQL el saldo terminó en 9.850 = 10.000 − 100 − 50. Como el `UPDATE` es atómico (`saldo = saldo - 50`), al liberarse la fila el motor aplicó el cambio de B **sobre la versión ya confirmada por A** ([5.9](#59-mvcc-y-locks)).

### Experimento 2: dos lecturas en la misma transacción

| | MySQL (`REPEATABLE READ` por defecto) | PostgreSQL (`READ COMMITTED` por defecto) |
| :--- | :--- | :--- |
| Primera lectura de A | Saldo S | 15.000 |
| B suma 1.000 y confirma | | |
| Segunda lectura de A | **S**: reutiliza el snapshot de la primera lectura | **16.000**: snapshot nuevo por sentencia (lectura no repetible) |
| Para obtener el otro comportamiento | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` | `BEGIN ISOLATION LEVEL REPEATABLE READ;` |

> Mismo experimento, resultado opuesto, y **los dos son correctos**: dependen del nivel de aislamiento por defecto de cada motor. Por eso el primer paso siempre es consultar el nivel real (`@@transaction_isolation` / `SHOW transaction_isolation`).

### Experimento 3: deadlock controlado

| | MySQL / InnoDB | PostgreSQL |
| :--- | :--- | :--- |
| Detección | Inmediata | Después de `deadlock_timeout` (1 s por defecto) |
| Error | `ERROR 1213 (40001): Deadlock found when trying to get lock` | `ERROR: deadlock detected` (SQLSTATE `40P01`) |
| Víctima observada | Sesión B (la que cerró el ciclo) | Sesión B (la que cerró el ciclo) |
| Por qué | InnoDB aborta la transacción "más chica" (menos filas modificadas). Con pesos iguales, en la práctica suele caer la que cerró el ciclo. | La sesión que cierra el ciclo es la que lo encuentra al cumplirse su `deadlock_timeout`, y se aborta a sí misma |
| Estado de la víctima | Toda su transacción **se revierte** | Queda `idle in transaction (aborted)`: rechaza todo con *"current transaction is aborted"* hasta un `ROLLBACK` |
| Sobreviviente | Su `UPDATE` termina; debe hacer `COMMIT` o `ROLLBACK` | Igual |
| Evidencia | `SHOW ENGINE INNODB STATUS` → **LATEST DETECTED DEADLOCK** | `pg_stat_activity` (desaparece la espera) y el log del servidor |

**Medidas preventivas** propuestas en las dos resoluciones:

1. **Orden canónico de acceso:** actualizar siempre por `cuenta_id` ascendente hace imposible el ciclo.
2. **Transacciones cortas:** sin lógica pesada ni espera del usuario con la transacción abierta.

La de PostgreSQL agregó **`lock_timeout`** y **`SELECT ... FOR UPDATE NOWAIT`**, para fallar rápido en lugar de dejar conexiones colgadas ([5.11](#511-deadlock-el-abrazo-mortal)).

## U6 · Actividad 1: Operación Rescate

**Qué pedía:** Fase 1, detectar y corregir permisos excesivos con pruebas antes y después. Fase 2, backup, operaciones válidas, borrado accidental, punto objetivo y restauración validada. Fase 3, una arquitectura de continuidad para un escenario con RPO y RTO dados. Teoría: [Unidad 6](#unidad-6--seguridad-backup-réplica-y-alta-disponibilidad).

### Fase 1: el usuario infiltrado

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Permisos peligrosos del script | `rol_app` con `DELETE`, `CREATE` y `DROP` sobre toda la base; `rol_analista` con `UPDATE` | `rol_app` con `TRUNCATE` en todas las tablas y permiso para modificar y borrar la auditoría; `rol_analista` con `UPDATE` en todas las tablas |
| Cómo se detectan | `SHOW GRANTS FOR rol_app;` | `information_schema.table_privileges` (o `\dp`) |
| Accesos indebidos demostrados | La app crea y borra una tabla; el analista suma 500.000 a un saldo; la app borra la auditoría | El analista cambia un saldo; la app borra la auditoría; la app hace `TRUNCATE` de `movimiento` dentro de `BEGIN ... ROLLBACK` |
| Corrección | `REVOKE ALL PRIVILEGES, GRANT OPTION FROM ...` + `GRANT` por tabla + `SET DEFAULT ROLE ALL` | `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM ...` + `GRANT` por tabla + `USAGE, SELECT` sobre las secuencias para la app |
| Error esperado al repetir | `ERROR 1142 (42000): ... command denied to user` | `ERROR: permission denied for table ...` |
| Matriz final | app: `SELECT/INSERT/UPDATE` en cliente y cuenta, `SELECT/INSERT` en movimiento, solo `INSERT` en auditoría; analista: solo `SELECT` de negocio; auditor: solo `SELECT` | La misma |

**Diferencias entre motores que conviene saber:**

| Tema | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| `TRUNCATE` | Requiere el privilegio **`DROP`** y hace **commit implícito**: no se puede deshacer con `ROLLBACK` | Es un privilegio **propio** y es **transaccional**: por eso la prueba se pudo revertir |
| IDs autoincrementales | `AUTO_INCREMENT` no requiere permisos extra | Para insertar en columnas `SERIAL` (que llaman a `nextval`), la app necesita `USAGE` sobre la **secuencia** |
| Activación de roles | `SET DEFAULT ROLE` (si no, el rol no se activa al conectar) | Los roles se heredan |

> Quitarle `DROP` a la cuenta de la aplicación en MySQL también le impide hacer `TRUNCATE`.

### Fase 2: el DBA borró producción

**Estados medidos** (iguales en los dos motores):

| Métrica | Inicial | Después de las operaciones válidas | Después del incidente | Recuperado |
| :--- | :---: | :---: | :---: | :---: |
| Clientes / cuentas | 4 / 4 | 4 / 4 | 4 / 4 | 4 / 4 |
| Movimientos | 5 | 7 | 4 | **7** |
| Suma de importes | $73.000 | $81.000 | **$28.000** | **$81.000** |
| Movimientos de la cuenta 101 | 2 | 3 | 0 | **3** |

Después del incidente quedan 30.000 − 5.000 + 10.000 − 7.000 = **28.000**. Conviene verificar la cuenta a mano: es fácil escribir un valor equivocado en la bitácora.

| | MySQL | PostgreSQL |
| :--- | :--- | :--- |
| Backup | `mysqldump --single-transaction --flush-logs --source-data=2` | `pg_dump -Fc` (formato custom) |
| Recuperación | Restore del dump + `mysqlbinlog` desde la posición del backup hasta justo antes del `DELETE` | `TRUNCATE movimiento` + `pg_restore -t movimiento --data-only` + **reinsertar a mano** 1006 y 1007 (identificadas por la auditoría) |
| ¿Es PITR? | **Sí:** el binlog reproduce lo ocurrido hasta el punto elegido | **No:** es un restore lógico más una reaplicación manual. Funciona porque se conocían las dos operaciones posteriores. |
| Límite | Hay que ubicar la posición exacta del `DELETE` en el binlog | En producción no se conocen todas las operaciones posteriores al backup |

### Lo que hay que saber explicar

- **`pg_dump` no permite PITR:** es una foto lógica. El PITR en PostgreSQL necesita un **backup físico** (`pg_basebackup`) + **WAL archivado** + `recovery_target_time`/`_lsn`/`_xid` ([6.9](#69-recuperación-a-un-punto-en-el-tiempo-pitr)). Es justamente lo que la resolución en PostgreSQL diseñó en la Fase 3.
- **En MySQL alcanza con `mysqldump` + binlog** porque el binlog es lógico y se puede reaplicar sobre un restore lógico. Las coordenadas de partida las escribe `--source-data=2`.
- **Restaurar solo la tabla dañada** (`pg_restore -t`) reduce el corte y no pisa el resto de la base. Hay que cuidar las FK y los datos derivados, como los saldos.
- Las dos resoluciones justificaron el punto objetivo igual: el backup solo pierde 1006 y 1007, y reaplicar todo repite el `DELETE`.

### Fase 3: diseñar para sobrevivir (escenarios distintos)

| | MySQL: logística (RPO 15 min, RTO 30 min, 2 nodos, presupuesto medio) | PostgreSQL: RR.HH. (RPO 8 h, RTO 12 h, evitar sobrearquitectura) |
| :--- | :--- | :--- |
| Réplica | Primario + réplica **semisíncrona**, IP virtual con Keepalived | **Sin réplica**: con 12 h de RTO alcanza con reconstruir |
| Backup | Diario a las 02:00 (`mysqldump` o XtraBackup) | `pg_basebackup` diario a las 21:00 + `pg_dump` semanal |
| Logs | Binlogs copiados fuera del nodo cada ≤ 5 min | Archivado de WAL con `archive_timeout = 900` (≤ 15 min) |
| RPO logrado | ≈ 0 ante una falla física; ≤ 5 min ante un desastre total | ≤ 15 min |
| RTO estimado | Failover en < 3 min; PITR en 18-22 min | 1-2 h restaurando en un servidor nuevo |
| Error humano | PITR con `mysqlbinlog --stop-position` | PITR en una **instancia auxiliar** (puerto 5433) y copia de la tabla rescatada a producción |
| Monitoreo y pruebas | Chequeos de salud del failover | `pg_stat_archiver.failed_count` y un restore de prueba mensual |
| Riesgo declarado | **Split brain** con dos nodos, mitigado con *fencing* | La recuperación es **manual**: requiere a alguien del equipo |

**Lecciones y mejoras:**

- **Arquitectura proporcional al RPO/RTO.** Las dos propuestas son correctas para su escenario, aunque una tiene réplica y la otra no ([6.15](#615-diseño-por-criticidad-escenarios-típicos)).
- **La réplica no protege contra un `DELETE`**: las dos lo dijeron explícitamente ([6.12](#612-alta-disponibilidad-no-es-backup)).
- **Semisíncrona no es RPO = 0 garantizado:** si la réplica no responde a tiempo, MySQL vuelve a modo asíncrono ([6.13](#613-replicación)).
- **Punto objetivo exacto:** recuperar "un minuto antes" pierde ese minuto. Es mejor la hora exacta del incidente con `recovery_target_inclusive = false`, o `recovery_target_lsn`/`_xid`.
- **Cargar filas rescatadas** en producción a través de una tabla auxiliar, copiando solo las que faltan (`INSERT ... SELECT ... WHERE NOT EXISTS`), para no chocar con claves duplicadas.
- **Monitorear el archivado** (`pg_stat_archiver`) y **probar el restore** periódicamente: un backup sin restore probado es una promesa ([6.11](#611-plan-de-recuperación)).

## Preguntas tipo simulacro

Las preguntas 1 a 6 siguen los temas del simulacro de la cátedra; el resto cubre las demás actividades. Hay una sola opción correcta por pregunta.

### Cómo encarar la opción múltiple

| Señal | Suele indicar |
| :--- | :--- |
| Absolutos: "siempre", "necesariamente", "la única solución" | Opción incorrecta: en esta materia casi todo depende de la carga y la evidencia |
| Soluciones desproporcionadas: reiniciar el servidor, más memoria, un índice con todas las columnas, más usuarios administradores | Opción incorrecta: no atacan la causa |
| "Evaluar ... y comprobar con un nuevo plan y mediciones comparables" | Opción correcta típica: decisión + verificación con evidencia |
| El mecanismo más simple que garantiza la regla | Opción correcta típica (`CHECK` antes que un trigger) |

**P1 · U5 · Espera por lock.** Un operador reporta que un `UPDATE` de stock "no termina" desde hace tres minutos. En `pg_stat_activity` la sesión figura `active` con `wait_event_type = Lock`, y `pg_blocking_pids` devuelve el PID de otra sesión que está `idle in transaction`. ¿Cuál es el diagnóstico más apropiado?

- a) El `UPDATE` tiene un plan lento: hay que crear un índice y volver a ejecutarlo.
- b) Es un deadlock: el motor lo va a resolver solo en unos segundos.
- c) Es una espera por lock de una transacción abierta sin confirmar: hay que registrar la evidencia (bloqueante, recurso, desde cuándo) antes de decidir si se cierra o cancela la sesión bloqueante.
- d) Hay que reiniciar el servicio para liberar la fila.

> **Respuesta: c.** `wait_event_type = Lock` y `pg_blocking_pids` muestran una espera, no un plan lento. No es un deadlock porque la espera es lineal: la bloqueante está ociosa, no esperando a nadie. Reiniciar revierte el trabajo de todos sin diagnosticar.

**P2 · U2 · Índice compuesto.** `SELECT ... FROM movimiento WHERE cuenta_id = ? AND fecha >= ? AND fecha < ?` examina millones de filas para devolver unas decenas. ¿Cuál es la intervención inicial más coherente?

- a) Un índice con todas las columnas de la tabla.
- b) Evaluar un índice `(cuenta_id, fecha)` y comprobar el cambio con un nuevo plan y mediciones comparables.
- c) Un índice `(fecha, cuenta_id)`, porque el rango es lo más selectivo.
- d) Particionar por `cuenta_id`, porque la partición reemplaza al índice.

> **Respuesta: b.** Primero la igualdad y después el rango ([2.5](#25-índices-compuestos-el-orden-de-las-columnas-importa)). Con `(fecha, cuenta_id)` el rango va primero y `cuenta_id` ya no ayuda a acotar la búsqueda. La partición no reemplaza al índice. Y toda mejora se verifica con evidencia.

**P3 · U1 · Durabilidad.** Una transacción hace `UPDATE` y `COMMIT`, el motor responde OK y el servidor se apaga antes del siguiente checkpoint. Al reiniciar, el cambio está. ¿Qué lo hizo posible?

- a) La página de datos se escribe siempre en disco antes de que el `COMMIT` responda.
- b) El log transaccional (redo/WAL) persistido antes de confirmar, que la recuperación usa para rehacer el cambio.
- c) La caché de planes, que guarda la sentencia y la vuelve a ejecutar.
- d) El catálogo, que guarda una copia de las filas modificadas.

> **Respuesta: b.** El `COMMIT` fuerza el **log** a disco; la página baja después, con el checkpoint ([1.6](#16-arquitectura-interna-del-sql-al-disco)).

**P4 · U6 · PITR y RPO.** El RPO es de 10 minutos. A las 11:20 un usuario autorizado ejecuta un `DELETE` incorrecto y se detecta a las 11:35. ¿Qué estrategia es más adecuada?

- a) Restaurar el backup completo de la noche anterior.
- b) Promover la réplica de alta disponibilidad.
- c) Restaurar una copia base válida y aplicar los logs archivados hasta el instante inmediatamente anterior al `DELETE`.
- d) Restaurar hasta las 11:35, el último estado conocido.

> **Respuesta: c.** a) pierde toda la mañana. b) la réplica ya tiene el `DELETE`. d) conserva el error ([6.9](#69-recuperación-a-un-punto-en-el-tiempo-pitr)).

**P5 · U3 · Última venta por cliente.** Se necesita una sola última venta por cliente, conservar los clientes sin ventas y resolver de forma determinista dos ventas con la misma fecha. ¿Qué enfoque es correcto?

- a) `GROUP BY cliente_id` con `MAX(fecha)` como resultado final.
- b) CTE con `ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY fecha DESC, venta_id DESC)`, después `cliente LEFT JOIN cte ... WHERE rn = 1`.
- c) CTE con `ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY fecha DESC, venta_id DESC)`, después `cliente LEFT JOIN cte ON ... AND rn = 1`.
- d) `RANK()` sin filtro, porque devuelve exactamente una fila por cliente.

> **Respuesta: c.** a) no trae la fila completa ni desempata. b) en el `WHERE`, `rn = 1` elimina a los clientes sin ventas. d) `RANK` repite la posición en los empates y sin filtro devuelve todas las filas.

**P6 · U4 · Migración.** La v2 debe agregar a `pedido`, que ya tiene datos, una columna `estado` obligatoria, validar los valores permitidos y auditar los cambios. ¿Cuál es la secuencia más segura?

- a) Agregar `estado NOT NULL` sin valor inicial y corregir después las filas que fallen.
- b) Agregar la columna aceptando `NULL`, completar los históricos, validar, aplicar `CHECK` y `NOT NULL`, y después crear el trigger de auditoría.
- c) Borrar y recrear la tabla con la nueva definición.
- d) Crear primero el trigger y después la columna.

> **Respuesta: b.** Expandir → completar → validar → endurecer → programar ([4.9](#49-migraciones-una-base-de-datos-también-tiene-versiones)).

**P7 · U1 · Optimizador.** Se crea un índice sobre `nro_cuenta` en una tabla de 5 filas y el plan sigue mostrando `Seq Scan`. ¿Qué se concluye?

- a) El índice quedó corrupto: hay que hacer `REINDEX`.
- b) El optimizador estimó que leer 5 filas es más barato que pasar por el índice: el índice no obliga a usarlo.
- c) PostgreSQL no usa índices sobre columnas de texto.
- d) Hay que forzar el índice desde la consulta.

> **Respuesta: b.** El optimizador decide por costo. Con más filas o un filtro más selectivo cambiaría de plan.

**P8 · U2 · Partición.** Una tabla de pedidos está particionada por mes según `fecha`. Una consulta filtra solo por `cliente_id` y el plan recorre todas las particiones. ¿Qué conviene?

- a) Crear más particiones, una por semana.
- b) Quitar el particionamiento.
- c) Agregar un índice `(cliente_id, fecha)`: el *pruning* solo actúa cuando se filtra por la clave de partición.
- d) Aumentar `work_mem`.

> **Respuesta: c.** La partición reduce lo recorrido **por fecha**; para localizar un cliente hace falta un índice ([2.9](#29-particionamiento-divide-y-reinarás)).

**P9 · U2 · Retención.** Hay que retirar todos los pedidos de enero de 2022 de una tabla de 50 millones de filas particionada por mes. ¿Qué opción tiene menor impacto?

- a) `DELETE FROM pedido WHERE fecha >= '2022-01-01' AND fecha < '2022-02-01'`.
- b) `DETACH` o `DROP` de la partición de enero de 2022.
- c) `UPDATE` de las filas a un estado "archivado".
- d) Recrear la tabla sin ese mes.

> **Respuesta: b.** Es un cambio de metadatos. El `DELETE` recorre y borra fila por fila: genera log y locks, y en PostgreSQL deja tuplas muertas para `VACUUM`.

**P10 · U4 · CHECK y NULL.** La columna `precio` admite `NULL` y tiene `CHECK (precio > 0)`. ¿Qué pasa con `UPDATE producto SET precio = NULL WHERE producto_id = 1`?

- a) Lo rechaza el `CHECK`, porque `NULL` no es mayor que 0.
- b) Se acepta: la condición da UNKNOWN y un `CHECK` solo rechaza lo que da FALSE.
- c) Da error de tipo de dato.
- d) Depende de que exista un trigger.

> **Respuesta: b.** Para rechazar nulos hace falta `NOT NULL` ([4.3](#43-integridad-declarativa-constraints)).

**P11 · U4 · Trigger de auditoría.** Se quiere auditar solo los cambios reales de precio, aunque en algún caso el precio anterior o el nuevo pueda ser `NULL`. ¿Qué condición es correcta?

- a) `IF OLD.precio <> NEW.precio` en los dos motores.
- b) `OLD.precio IS DISTINCT FROM NEW.precio` en PostgreSQL y `NOT (OLD.precio <=> NEW.precio)` en MySQL.
- c) Un `CHECK (OLD.precio <> NEW.precio)`.
- d) Un trigger `BEFORE INSERT`.

> **Respuesta: b.** Con `<>`, un cambio de `NULL` a 100 da UNKNOWN y no se audita. Un `CHECK` no tiene `OLD`/`NEW`. El evento a capturar es un `UPDATE` ([4.6](#46-triggers-reacción-automática)).

**P12 · U5 · Aislamiento.** En PostgreSQL con la configuración por defecto, A abre una transacción y lee un saldo de 15.000; B le suma 1.000 y confirma; A vuelve a leer en la misma transacción. ¿Qué ve A?

- a) 15.000, porque A tiene un snapshot de toda la transacción.
- b) 16.000, porque en `READ COMMITTED` cada sentencia toma un snapshot nuevo.
- c) Un error de serialización.
- d) A queda esperando a que B termine.

> **Respuesta: b.** Es una lectura no repetible. En MySQL, con `REPEATABLE READ` por defecto, A vería 15.000 ([5.8](#58-niveles-de-aislamiento)).

**P13 · U5 · Después de un deadlock.** En PostgreSQL, la sesión B recibe `deadlock detected`. ¿Qué pasa si B intenta ejecutar otra sentencia?

- a) Se ejecuta con normalidad: solo se revirtió el último `UPDATE`.
- b) Recibe *"current transaction is aborted"*: hay que hacer `ROLLBACK` antes de seguir.
- c) Vuelve a quedar esperando a A.
- d) El motor reinicia la conexión automáticamente.

> **Respuesta: b.** En PostgreSQL un error deja la transacción abortada hasta el `ROLLBACK`. En MySQL el deadlock revierte la transacción completa de la víctima ([5.5](#55-dónde-empieza-y-termina-una-transacción)).

**P14 · U6 · Mínimo privilegio.** La cuenta de la aplicación debe registrar movimientos pero nunca borrarlos ni vaciar la tabla. En PostgreSQL, con IDs `SERIAL`, ¿qué permisos corresponden?

- a) `SELECT, INSERT` sobre `movimiento` y `USAGE` sobre la secuencia.
- b) `ALL PRIVILEGES` sobre `movimiento`, controlado desde la aplicación.
- c) `SELECT, INSERT, DELETE` sobre `movimiento`.
- d) `SELECT, INSERT, TRUNCATE` sobre `movimiento`.

> **Respuesta: a.** Sin `USAGE` sobre la secuencia, el `INSERT` falla al pedir el próximo ID. `DELETE` y `TRUNCATE` contradicen la regla de que los movimientos solo se agregan.

**P15 · U6 · TRUNCATE en MySQL.** ¿Qué privilegio controla `TRUNCATE TABLE` en MySQL, y por qué es más peligroso que en PostgreSQL?

- a) `DELETE`; es igual de peligroso en los dos motores.
- b) `DROP`, y además hace commit implícito: no se puede deshacer con `ROLLBACK`.
- c) `ALTER`; se puede revertir con `ROLLBACK`.
- d) No requiere privilegios.

> **Respuesta: b.** En PostgreSQL `TRUNCATE` tiene su propio privilegio y es transaccional.

**P16 · U6 · Alta disponibilidad frente a backup.** Un sistema tiene primario + réplica semisíncrona. Un operador borra por error una tabla de licencias. ¿Qué es correcto?

- a) Se promueve la réplica y el problema queda resuelto.
- b) La réplica ya aplicó el borrado: hay que recuperar con backup + logs (PITR), idealmente en una instancia auxiliar, y copiar los datos rescatados.
- c) La semisíncrona garantiza que el borrado no se replique.
- d) Hay que reiniciar los dos nodos.

> **Respuesta: b.** La alta disponibilidad protege contra fallas físicas, no contra errores lógicos ([6.12](#612-alta-disponibilidad-no-es-backup)).

**P17 · U5 · Conectividad.** Un integrante recibe `no pg_hba.conf entry for host "192.168.1.25"`. El servidor ya escucha en `0.0.0.0:5432`. ¿Qué corresponde?

- a) Cambiar `listen_addresses`.
- b) Agregar una regla en `pg_hba.conf` para la subred del aula (no `0.0.0.0/0`) y recargar la configuración.
- c) Darle `SUPERUSER` al usuario.
- d) Abrir el puerto 3306.

> **Respuesta: b.** La red y el listener funcionan: falla la regla de acceso. Hay que restringirla a la subred necesaria ([5.1](#51-del-motor-aislado-al-servidor-compartido)).

---

*Apunte elaborado a partir de las clases de la cátedra (Unidades 1 a 6, 2026) y de la práctica en laboratorio. Verificá siempre el comportamiento en tu motor y versión: el criterio de la materia es **evidencia antes que afirmación**.*
